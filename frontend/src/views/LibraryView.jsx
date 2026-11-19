import { useState } from 'react';
import { categories, categoryById } from '../categories.js';
import { countUses } from '../collection.js';
import { expiringSoon, matchesQuery } from '../format.js';
import { IconPlus, IconSearch, IconXCircle } from '../ui/Icons.jsx';
import { EmptyState, LargeTitle, NavBar, useCollapsedTitle } from '../ui/parts.jsx';
import { RecordRow } from '../ui/RecordRow.jsx';

export default function LibraryView({ records, onCategory, onRecord, onAdd }) {
  const [query, setQuery] = useState('');
  const [titleRef, collapsed] = useCollapsedTitle();
  const searching = query.trim() !== '';
  const results = searching
    ? records.filter(record => matchesQuery(record, query, categoryById(record.categoryId)?.title))
    : [];
  const attention = expiringSoon(records);
  const opened = records.filter(record => record.openedDate).length;
  const uses = records.reduce((sum, record) => sum + countUses(record), 0);

  return (
    <div className="page">
      <NavBar title="藏品" collapsed={collapsed}>
        <button type="button" className="icon-button" aria-label="添加藏品" onClick={() => onAdd(null)}><IconPlus size={24} /></button>
      </NavBar>
      <div className="content content--wide">
        <LargeTitle titleRef={titleRef} focusOnMount={false}>藏品</LargeTitle>
        <div className="search" role="search">
          <IconSearch size={17} className="search__icon" />
          <input type="search" className="search__input" placeholder="搜索全部藏品" aria-label="搜索全部藏品"
            value={query} onChange={event => setQuery(event.target.value)}
            onKeyDown={event => { if (event.key === 'Escape') setQuery(''); }} />
          {searching && (
            <button type="button" className="search__clear" aria-label="清除搜索" onClick={() => setQuery('')}><IconXCircle size={17} /></button>
          )}
        </div>

        {searching ? (
          results.length ? (
            <section aria-label="搜索结果">
              <p className="section-header">{results.length} 个结果</p>
              <ul className="group">
                {results.map(record => <RecordRow key={record.id} record={record} compact showCategory onOpen={() => onRecord(record.id)} />)}
              </ul>
            </section>
          ) : (
            <EmptyState icon={<IconSearch size={44} />} title={`没有“${query.trim()}”的结果`} description="试试品牌、色号或分类名称。" />
          )
        ) : (
          <>
            {records.length ? (
              <p className="summary">共 {records.length} 件，{opened} 件已开封，累计使用 {uses} 次。</p>
            ) : (
              <section className="welcome group-card">
                <h2 className="welcome__title">把梳妆台收进口袋</h2>
                <p className="welcome__text">记下每件化妆品的开封日期和使用次数，快到期时一眼就能看到。从下面任意一个分类开始。</p>
                <button type="button" className="capsule-button" onClick={() => onAdd(null)}><IconPlus size={18} strokeWidth={2.4} />添加第一件藏品</button>
              </section>
            )}

            {attention.length > 0 && (
              <section className="block" aria-labelledby="attention-title">
                <div className="block__head">
                  <h2 id="attention-title" className="title3">需要留意</h2>
                  {attention.length > 3 && <span className="block__aside">另有 {attention.length - 3} 件</span>}
                </div>
                <ul className="group">
                  {attention.slice(0, 3).map(record => <RecordRow key={record.id} record={record} compact showCategory onOpen={() => onRecord(record.id)} />)}
                </ul>
              </section>
            )}

            <section className="block" aria-labelledby="categories-title">
              <div className="block__head"><h2 id="categories-title" className="title3">分类</h2></div>
              <ul className="tiles">
                {categories.map(category => {
                  const count = records.filter(record => record.categoryId === category.id).length;
                  return (
                    <li key={category.id}>
                      <button type="button" className="tile" onClick={() => onCategory(category.id)} aria-label={`${category.title}，${count} 件`}>
                        <span className="tile__photo"><img src={category.src} alt="" loading="lazy" /></span>
                        <span className="tile__name">{category.title}</span>
                        <span className="tile__count">{count ? `${count} 件` : '暂无藏品'}</span>
                      </button>
                    </li>
                  );
                })}
              </ul>
            </section>
          </>
        )}
      </div>
    </div>
  );
}
