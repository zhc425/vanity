import { countUses, getExpiry, todayInShanghai } from './collection.js';

export const identityOf = record => [record.brand, record.shade].filter(Boolean).join(' ');

export function daysBetween(from, to) {
  if (!from || !to) return null;
  return Math.round((Date.parse(to) - Date.parse(from)) / 86400000);
}

export const daysLeft = (record, today = todayInShanghai()) => daysBetween(today, getExpiry(record, today).date);

export function relativeDays(days) {
  if (days === null || days === undefined) return '';
  if (days < 0) return `已过 ${-days} 天`;
  if (days === 0) return '今天';
  return `${days} 天后`;
}

const shortFormat = new Intl.DateTimeFormat('zh-CN', { month: 'numeric', day: 'numeric', timeZone: 'UTC' });
const yearShortFormat = new Intl.DateTimeFormat('zh-CN', { year: 'numeric', month: 'numeric', day: 'numeric', timeZone: 'UTC' });
export function shortDate(date, today = todayInShanghai()) {
  if (!date) return '未记录';
  const value = new Date(date + 'T00:00:00Z');
  return date.slice(0, 4) === today.slice(0, 4) ? shortFormat.format(value) : yearShortFormat.format(value);
}

export function lastUsed(record) {
  const uses = record.uses ?? [];
  return uses.reduce((latest, use) => (!latest || use.date > latest ? use.date : latest), null);
}

/** 已用掉的有效期比例（0–1），无法计算时为 null。 */
export function lifeProgress(record, today = todayInShanghai()) {
  const end = getExpiry(record, today).date;
  const start = record.openedDate ?? record.purchasedDate;
  const total = daysBetween(start, end);
  const passed = daysBetween(start, today);
  if (!end || !start || !total || total <= 0 || passed === null) return null;
  return Math.min(1, Math.max(0, passed / total));
}

/** 已过期或 30 天内到期，按到期日升序。 */
export function expiringSoon(records, today = todayInShanghai()) {
  return records
    .map(record => ({ record, days: daysLeft(record, today) }))
    .filter(item => item.days !== null && item.days <= 30)
    .sort((a, b) => a.days - b.days)
    .map(item => item.record);
}

export const totalUses = records => records.reduce((sum, record) => sum + countUses(record), 0);
export const totalSpent = records => records.reduce((sum, record) => sum + (record.price?.minorUnits ?? 0), 0);

export function matchesQuery(record, query, categoryTitle = '') {
  const needle = query.trim().toLowerCase();
  if (!needle) return true;
  return [record.name, record.brand, record.shade, record.note, categoryTitle]
    .some(value => value && value.toLowerCase().includes(needle));
}
