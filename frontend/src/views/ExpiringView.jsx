import { getExpiry, todayInShanghai } from '../collection.js';
import { categoryById } from '../categories.js';
import { daysBetween, relativeDays, shortDate } from '../format.js';
import { IconChevronRight, IconSeal } from '../ui/Icons.jsx';
import { EmptyState, LargeTitle, NavBar, RecordThumb, useCollapsedTitle } from '../ui/parts.jsx';

/** 按紧急程度分组，参考「提醒事项」的智能列表。 */
export function expiringGroups(records, today = todayInShanghai()) {
  const dated = records
    .map(record => {
      const expiry = getExpiry(record, today);
      return { record, expiry, days: daysBetween(today, expiry.date) };
    })
    .filter(item => item.expiry.date)
    .sort((a, b) => a.days - b.days);
  const missing = records
    .map(record => ({ record, expiry: getExpiry(record, today), days: null }))
    .filter(item => item.expiry.prompt);
  return [
    { id: 'expired', title: '已过期', footer: '过期的化妆品可能滋生细菌，建议停用。', items: dated.filter(item => item.days < 0) },
    { id: 'soon', title: '30 天内', items: dated.filter(item => item.days >= 0 && item.days <= 30) },
    { id: 'later', title: '之后', items: dated.filter(item => item.days > 30) },
    { id: 'missing', title: '待补全', footer: '记录开封日期或包装到期日后，就能算出到期时间。', items: missing }
  ].filter(group => group.items.length);
}

export default function ExpiringView({ records, onRecord }) {
  const [titleRef, collapsed] = useCollapsedTitle();
  const today = todayInShanghai();
  const groups = expiringGroups(records, today);
  return (
    <div className="page">
      <NavBar title="到期" collapsed={collapsed} />
      <div className="content">
        <LargeTitle titleRef={titleRef} focusOnMount={false}>到期</LargeTitle>
        {groups.length ? groups.map(group => (
          <section className="section" key={group.id} aria-labelledby={`group-${group.id}`}>
            <h2 id={`group-${group.id}`} className="section-header">{group.title}</h2>
            <ul className="group">
              {group.items.map(({ record, expiry, days }) => (
                <li className="row-item" key={record.id}>
                  <button type="button" className="row row--compact" onClick={() => onRecord(record.id)}>
                    <RecordThumb record={record} size={44} radius={10} />
                    <span className="row__text">
                      <span className="row__title">{record.name}</span>
                      <span className="row__subtitle">{group.id === 'missing' ? expiry.prompt : categoryById(record.categoryId)?.title}</span>
                    </span>
                    <span className="row__trailing">
                      {group.id !== 'missing' && (
                        <span className="row__date">
                          <span data-tone={expiry.status?.tone}>{shortDate(expiry.date, today)}</span>
                          <small>{relativeDays(days)}</small>
                        </span>
                      )}
                      <IconChevronRight size={16} className="row__chevron" />
                    </span>
                  </button>
                </li>
              ))}
            </ul>
            {group.footer && <p className="section-footer">{group.footer}</p>}
          </section>
        )) : (
          <EmptyState icon={<IconSeal size={48} />} title="没有需要留意的藏品" description="记录开封日期后，快到期的化妆品会出现在这里。" />
        )}
      </div>
    </div>
  );
}
