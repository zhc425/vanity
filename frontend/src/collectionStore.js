export const STORAGE_KEY = 'vanity.collection.v2';
export const LEGACY_KEY = 'vanity.collection.v1';
export const BACKUP_KEY = 'vanity.collection.v2.backup';
export const STORAGE_VERSION = 2;
export const MAX_RECORDS = 2000;
export const MAX_USES = 10000;

/**
 * @typedef {'mask'|'cleanser'|'cream'|'primer'|'foundation'|'loose-powder'
 *   |'pressed-powder'|'blush'|'eyeshadow'|'lipstick'|'puff'} CategoryId
 * @typedef {'light'|'dark'} ThemeName
 * @typedef {'persistent'|'memory'} StorageMode
 * @typedef {'none'|'empty'|'corrupt'|'unavailable'|'skipped'} LoadProblem
 * @typedef {Object} Money
 * @property {number} minorUnits
 * @property {'CNY'} currency
 * @typedef {Object} UseEntry
 * @property {string} id
 * @property {string} date
 * @typedef {Object} CollectionRecord
 * @property {string} id
 * @property {CategoryId} categoryId
 * @property {string} name
 * @property {string} [brand]
 * @property {string} [shade]
 * @property {string} [purchasedDate]
 * @property {string} [packageExpiryDate]
 * @property {string} [openedDate]
 * @property {number} [paoMonths]
 * @property {Money} [price]
 * @property {string} [note]
 * @property {number} [usageCount]
 * @property {UseEntry[]} [uses]
 * @property {string} [imageUrl]
 * @property {string} [imageAlt]
 * @property {boolean} [demo]
 * @typedef {Object} LoadResult
 * @property {CollectionRecord[]} records
 * @property {StorageMode} storage
 * @property {LoadProblem} problem
 * @property {number} skipped
 * @typedef {Object} SaveResult
 * @property {boolean} persisted
 */

export const CATEGORY_IDS = Object.freeze([
  'mask', 'cleanser', 'cream', 'primer', 'foundation', 'loose-powder',
  'pressed-powder', 'blush', 'eyeshadow', 'lipstick', 'puff'
]);

const CATEGORY_SET = new Set(CATEGORY_IDS);
const ID_PATTERN = /^[a-zA-Z0-9_-]{1,80}$/;
const DATE_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;

const ERROR_MESSAGES = {
  quota: '本机存储空间不足，未能保存，请清理空间后重试',
  blocked: '当前浏览器禁止保存数据，关闭页面后藏品会丢失',
  unknown: '未能保存，请重试'
};

export class StorageError extends Error {
  constructor(code, message) {
    super(message || ERROR_MESSAGES[code] || ERROR_MESSAGES.unknown);
    this.name = 'StorageError';
    this.code = code;
  }
}

let cachedMode;
let currentStoredValue = null;
let pendingCorruptRaw = null;

export function storageMode() {
  if (cachedMode) return cachedMode;
  try {
    const probe = '__vanity_storage_probe__';
    window.localStorage.setItem(probe, '1');
    window.localStorage.removeItem(probe);
    cachedMode = 'persistent';
  } catch {
    cachedMode = 'memory';
  }
  return cachedMode;
}

function isDate(value) {
  if (typeof value !== 'string') return false;
  const match = DATE_PATTERN.exec(value);
  if (!match) return false;
  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  if (year < 1900 || year > 9800) return false;
  const date = new Date(Date.UTC(year, month - 1, day));
  return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day;
}

function pickDate(value) {
  return isDate(value) ? value : null;
}

function pickText(value, limit) {
  if (typeof value !== 'string') return null;
  const text = value.trim();
  return text && text.length <= limit ? text : null;
}

function pickInteger(value, min, max) {
  return Number.isInteger(value) && value >= min && value <= max ? value : null;
}

function pickPrice(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const { minorUnits, currency } = value;
  if (!Number.isInteger(minorUnits) || minorUnits < 0 || minorUnits > 999999999) return null;
  if (currency !== 'CNY') return null;
  return { minorUnits, currency };
}

function pickUses(value) {
  if (!Array.isArray(value)) return null;
  const seen = new Set();
  const uses = [];
  for (const item of value) {
    if (uses.length >= MAX_USES) break;
    if (!item || typeof item !== 'object' || Array.isArray(item)) continue;
    if (typeof item.id !== 'string' || !ID_PATTERN.test(item.id)) continue;
    if (!isDate(item.date) || seen.has(item.id)) continue;
    seen.add(item.id);
    uses.push({ id: item.id, date: item.date });
  }
  return uses;
}

function normalizeRecord(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const id = typeof value.id === 'string' ? value.id : '';
  if (!ID_PATTERN.test(id)) return null;
  if (!CATEGORY_SET.has(value.categoryId)) return null;
  if (typeof value.name !== 'string') return null;
  const name = value.name.trim();
  if (!name || name.length > 100) return null;

  const record = { id, categoryId: value.categoryId, name };
  const brand = pickText(value.brand, 80);
  if (brand) record.brand = brand;
  const shade = pickText(value.shade, 60);
  if (shade) record.shade = shade;
  const note = pickText(value.note, 2000);
  if (note) record.note = note;
  const purchasedDate = pickDate(value.purchasedDate);
  if (purchasedDate) record.purchasedDate = purchasedDate;
  const packageExpiryDate = pickDate(value.packageExpiryDate);
  if (packageExpiryDate) record.packageExpiryDate = packageExpiryDate;
  const openedDate = pickDate(value.openedDate);
  if (openedDate) record.openedDate = openedDate;
  const paoMonths = pickInteger(value.paoMonths, 1, 120);
  if (paoMonths !== null) record.paoMonths = paoMonths;
  const usageCount = pickInteger(value.usageCount, 0, 100000);
  if (usageCount !== null && usageCount > 0) record.usageCount = usageCount;
  const price = pickPrice(value.price);
  if (price) record.price = price;
  const uses = pickUses(value.uses);
  if (uses && uses.length) record.uses = uses;
  const imageUrl = pickText(value.imageUrl, 2048);
  if (imageUrl) record.imageUrl = imageUrl;
  const imageAlt = pickText(value.imageAlt, 200);
  if (imageAlt) record.imageAlt = imageAlt;
  return record;
}

export function normalizeRecords(value) {
  if (!Array.isArray(value)) return { records: [], skipped: 0 };
  const seen = new Set();
  const records = [];
  let skipped = 0;
  for (const item of value) {
    if (item && typeof item === 'object' && !Array.isArray(item) && item.demo === true) continue;
    const record = normalizeRecord(item);
    if (!record || seen.has(record.id)) {
      skipped += 1;
      continue;
    }
    seen.add(record.id);
    records.push(record);
  }
  return { records, skipped };
}

export function loadCollection() {
  const storage = storageMode();
  if (storage === 'memory') {
    return { records: [], storage, problem: 'unavailable', skipped: 0 };
  }
  let raw;
  try {
    raw = window.localStorage.getItem(STORAGE_KEY);
  } catch {
    return { records: [], storage: 'memory', problem: 'unavailable', skipped: 0 };
  }
  if (raw === null) {
    currentStoredValue = null;
    return { records: [], storage, problem: 'empty', skipped: 0 };
  }
  currentStoredValue = raw;
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    pendingCorruptRaw = raw;
    return { records: [], storage, problem: 'corrupt', skipped: 0 };
  }
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed) ||
      typeof parsed.version !== 'number' || !Array.isArray(parsed.records)) {
    pendingCorruptRaw = raw;
    return { records: [], storage, problem: 'corrupt', skipped: 0 };
  }
  const { records, skipped } = normalizeRecords(parsed.records);
  return { records, storage, problem: skipped > 0 ? 'skipped' : 'none', skipped };
}

export function saveCollection(records) {
  if (!Array.isArray(records)) throw new StorageError('unknown');
  if (records.length > MAX_RECORDS) {
    throw new StorageError('unknown', `藏品数量已达上限（${MAX_RECORDS} 件），未能保存`);
  }
  if (storageMode() === 'memory') throw new StorageError('blocked');
  if (pendingCorruptRaw !== null) {
    try {
      window.localStorage.setItem(BACKUP_KEY, pendingCorruptRaw);
      pendingCorruptRaw = null;
    } catch {}
  }
  const payload = JSON.stringify({ version: STORAGE_VERSION, records });
  try {
    window.localStorage.setItem(STORAGE_KEY, payload);
  } catch (error) {
    const code = error?.name === 'QuotaExceededError' || error?.code === 22 || error?.code === 1014
      ? 'quota'
      : error?.name === 'SecurityError' || error?.code === 18
        ? 'blocked'
        : 'unknown';
    throw new StorageError(code);
  }
  currentStoredValue = payload;
  return { persisted: true };
}

export function readLegacyRecords() {
  try {
    const raw = window.localStorage.getItem(LEGACY_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return normalizeRecords(parsed).records;
  } catch {
    return [];
  }
}

export function mergeCollections(current, incoming) {
  const seen = new Set(current.map(item => item.id));
  const merged = [...current];
  for (const item of incoming) {
    if (seen.has(item.id)) continue;
    seen.add(item.id);
    merged.push(item);
  }
  return merged;
}

export function watchExternalChanges(listener) {
  const handler = event => {
    if (event.key !== STORAGE_KEY || !event.newValue) return;
    if (event.newValue === currentStoredValue) return;
    let parsed;
    try {
      parsed = JSON.parse(event.newValue);
    } catch {
      return;
    }
    if (!parsed || typeof parsed !== 'object' || !Array.isArray(parsed.records)) return;
    currentStoredValue = event.newValue;
    listener(normalizeRecords(parsed.records).records);
  };
  window.addEventListener('storage', handler);
  return () => window.removeEventListener('storage', handler);
}