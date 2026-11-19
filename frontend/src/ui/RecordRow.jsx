import { countUses, getExpiry } from '../collection.js';
import { categoryById } from '../categories.js';
import { identityOf } from '../format.js';
import { IconChevronRight, IconPlus } from './Icons.jsx';
import { RecordThumb, StatusLabel } from './parts.jsx';

/**
 * 列表中的一行藏品。
 * compact：用于「需要留意」和搜索结果，行尾显示状态而不是次数。
 */
export function RecordRow({ record, onOpen, onUse, compact = false, showCategory = false, trailing }) {
  const expiry = getExpiry(record);
  const uses = countUses(record);
  const subtitle = [showCategory ? categoryById(record.categoryId)?.title : null, identityOf(record) || null].filter(Boolean).join('，');
  return (
    <li className="row-item">
      <button type="button" className={'row' + (compact ? ' row--compact' : '')} onClick={onOpen}>
        <RecordThumb record={record} size={compact ? 46 : 54} radius={compact ? 10 : 12} />
        <span className="row__text">
          <span className="row__title">{record.name}</span>
          {subtitle && <span className="row__subtitle">{subtitle}</span>}
          {!compact && <StatusLabel status={expiry.status} />}
        </span>
        {trailing ?? (compact ? (
          <span className="row__trailing"><StatusLabel status={expiry.status} /><IconChevronRight size={16} className="row__chevron" /></span>
        ) : (
          <span className="row__count" aria-label={`使用 ${uses} 次`}>
            <span className="rounded-num" data-zero={uses === 0 || undefined}>{uses}</span>
            <span className="row__count-unit">次</span>
          </span>
        ))}
      </button>
      {onUse && (
        <button type="button" className="row__use" aria-label={`使用一次：${record.name}`} onClick={onUse}>
          <span className="row__use-dot"><IconPlus size={18} strokeWidth={2.4} /></span>
        </button>
      )}
    </li>
  );
}
