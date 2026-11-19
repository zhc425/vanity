
export const collectionPreview = [
  { id: 'sample-a', demo: true, categoryId: 'loose-powder', brand: '示例品牌 A', name: '柔焦定妆散粉', shade: '透明色', color: 'lavender', purchasedDate: '2026-04-18', openedDate: '2026-04-18', paoMonths: 12, usageCount: 18, price: { minorUnits: 28900, currency: 'CNY' } },
  { id: 'sample-b', demo: true, categoryId: 'loose-powder', brand: '示例品牌 B', name: '轻透矿物散粉', shade: '自然色', color: 'sand', purchasedDate: '2025-12-02', packageExpiryDate: '2026-12-02', usageCount: 6, price: { minorUnits: 15900, currency: 'CNY' } },
  { id: 'sample-c', demo: true, categoryId: 'loose-powder', brand: '示例品牌 C', name: '柔雾蜜粉', color: 'rose', usageCount: 0 }
];


const shanghaiDate = new Intl.DateTimeFormat('sv-SE', { timeZone: 'Asia/Shanghai' });
const dateFormat = new Intl.DateTimeFormat('zh-CN', { dateStyle: 'medium', timeZone: 'UTC' });
export const todayInShanghai = () => shanghaiDate.format(new Date());
export const displayDate = date => date ? dateFormat.format(new Date(date + 'T00:00:00Z')) : '未记录';
export const displayUsage = count => `${count} 次`;
export const countUses = record => (record.usageCount ?? 0) + (record.uses?.length ?? 0);
export const displayPrice = price => price
  ? new Intl.NumberFormat('zh-CN', { style: 'currency', currency: 'CNY' }).format(price.minorUnits / 100)
  : '未记录';

export function addMonths(date, months) {
  const [year, month, day] = date.split('-').map(Number);
  const limit = new Date(Date.UTC(year, month - 1 + months + 1, 0)).getUTCDate();
  return new Date(Date.UTC(year, month - 1 + months, Math.min(day, limit))).toISOString().slice(0, 10);
}

export function getExpiry(record, today = todayInShanghai()) {
  const { packageExpiryDate, openedDate, paoMonths } = record;
  const afterOpening = openedDate && paoMonths ? addMonths(openedDate, paoMonths) : null;
  const byPackage = packageExpiryDate && (!afterOpening || packageExpiryDate <= afterOpening);
  const date = (byPackage ? packageExpiryDate : afterOpening) || null;
  const basis = date ? (byPackage ? '按包装有效期' : '按开封后期限') : null;
  const prompt = openedDate && !paoMonths ? '补录开封后月数' : !date ? '可补录包装到期日，或记录开封' : null;
  const days = date ? (Date.parse(date) - Date.parse(today)) / 86400000 : null;
  const status = days === null ? null
    : days < 0 ? { label: '已过期', tone: 'expired' }
    : days === 0 ? { label: '今日到期', tone: 'warning' }
    : days <= 30 ? { label: `还有 ${days} 天到期`, tone: 'warning' }
    : null;
  return { date, basis, prompt, status };
}

