import { useState } from 'react';
import { countUses, getExpiry } from '../collection.js';
import { IconJar, IconPlus, IconSort } from '../ui/Icons.jsx';
import { EmptyState, LargeTitle, Menu, NavBar, useCollapsedTitle } from '../ui/parts.jsx';
import { RecordRow } from '../ui/RecordRow.jsx';

const SORT_KEY = 'vanity.sort';
const sorts = [
  { value: 'recent', label: '最近添加' },
  { value: 'expiry', label: '最先到期' },
  { value: 'usage', label: '使用最多' },
  { value: 'name', label: '名称' }
];
const collator = new Intl.Collator('zh-CN', { numeric: true });

function sortRecords(records, sort) {
  const byName = (a, b) => collator.compare(a.name, b.name);
  switch (sort) {
    case 'expiry':
      return [...records].sort((a, b) => {
        const x = getExpiry(a).date ?? '9999-12-31';
        const y = getExpiry(b).date ?? '9999-12-31';
        return x === y ? byName(a, b) : x < y ? -1 : 1;
      });
    case 'usage':
      return [...records].sort((a, b) => countUses(b) - countUses(a) || byName(a, b));
    case 'name':
      return [...records].sort(byName);
    default:
      return records; // 存储顺序本身就是新的在前
  }
}

function readSort() {
  try {
    const value = localStorage.getItem(SORT_KEY);
    return sorts.some(item => item.value === value) ? value : 'recent';
  } catch {
    return 'recent';
  }
}

export default function CategoryView({ category, records, backLabel, onBack, onRecord, onAdd, onUse }) {
  const [sort, setSort] = useState(readSort);
  const [titleRef, collapsed] = useCollapsedTitle();
  const choose = value => {
    setSort(value);
    try { localStorage.setItem(SORT_KEY, value); } catch { /* 无法保存排序偏好时忽略 */ }
  };
  const visible = sortRecords(records, sort);

  return (
    <div className="page">
      <NavBar backLabel={backLabel} onBack={onBack} title={category.title} collapsed={collapsed}>
        {records.length > 0 && <Menu label="排序方式" icon={<IconSort size={22} />} items={sorts} value={sort} onSelect={choose} />}
        <button type="button" className="icon-button" aria-label={`添加${category.title}`} onClick={onAdd}><IconPlus size={24} /></button>
      </NavBar>
      <div className="content">
        <LargeTitle titleRef={titleRef}>{category.title}</LargeTitle>
        {records.length ? (
          <>
            <p className="section-header">{records.length} 件，按{sorts.find(item => item.value === sort).label}排序</p>
            <ul className="group">
              {visible.map(record => (
                <RecordRow key={record.id} record={record} onOpen={() => onRecord(record.id)} onUse={() => onUse(record.id)} />
              ))}
            </ul>
          </>
        ) : (
          <EmptyState
            icon={<IconJar size={48} />}
            title={`还没有${category.title}`}
            description={`添加第一件${category.title}，记录开封日期和使用次数。`}
            action={<button type="button" className="capsule-button" onClick={onAdd}>添加{category.title}</button>}
          />
        )}
      </div>
    </div>
  );
}
