import { useLayoutEffect, useRef, useState } from 'react';
import { countUses, displayDate, displayPrice, getExpiry, todayInShanghai } from '../collection.js';
import { categoryById } from '../categories.js';
import { daysBetween, identityOf, lastUsed, lifeProgress } from '../format.js';
import { IconCalendarPlus, IconChevronRight, IconJar, IconPlus, IconSeal, IconTrash } from '../ui/Icons.jsx';
import { ConfirmSheet, NavBar, useCollapsedTitle } from '../ui/parts.jsx';

function Row({ label, children, tone }) {
  return (
    <div className="cell">
      <span className="cell__label">{label}</span>
      <span className="cell__value" data-tone={tone}>{children}</span>
    </div>
  );
}

function Gauge({ value }) {
  const percent = Math.round(value * 100);
  return (
    <div className="cell cell--stack">
      <div className="gauge__labels"><span>已用期限</span><span className="gauge__value">{percent}%</span></div>
      <div className="gauge" role="meter" aria-label="已用期限" aria-valuemin={0} aria-valuemax={100} aria-valuenow={percent} aria-valuetext={`${percent}%`}>
        <span className="gauge__knob" style={{ left: `${percent}%` }} />
      </div>
    </div>
  );
}

export default function RecordView({ record, backLabel, onBack, onUse, onRemoveUse, onEdit, onOpening, onDelete }) {
  const [titleRef, collapsed] = useCollapsedTitle();
  const [showHistory, setShowHistory] = useState(false);
  const [backfill, setBackfill] = useState(null);
  const [confirming, setConfirming] = useState(false);
  const heading = useRef(null);
  useLayoutEffect(() => { heading.current?.focus({ preventScroll: true }); }, [record.id]);
  const today = todayInShanghai();
  const expiry = getExpiry(record, today);
  const left = daysBetween(today, expiry.date);
  const progress = lifeProgress(record, today);
  const uses = countUses(record);
  const latest = lastUsed(record);
  const history = [...(record.uses ?? [])].sort((a, b) => (a.date < b.date ? 1 : a.date > b.date ? -1 : 0));
  const identity = identityOf(record);
  const category = categoryById(record.categoryId);
  const meta = [expiry.basis, expiry.prompt].filter(Boolean).join('。');

  return (
    <div className="page">
      <NavBar backLabel={backLabel} onBack={onBack} title={record.name} collapsed={collapsed}>
        <button type="button" className="text-button" onClick={onEdit}>编辑</button>
      </NavBar>
      <div className="content">
        <header className="record-head">
          <div className="record-head__photo">
            {record.imageUrl
              ? <img src={record.imageUrl} alt={record.imageAlt ?? record.name} />
              : <span className="record-head__placeholder" aria-hidden="true"><IconJar size={56} strokeWidth={1.4} /><span>暂无照片</span></span>}
          </div>
          <div ref={titleRef}>
            <p className="record-head__category">{category?.title}</p>
            <h1 className="record-head__title" tabIndex={-1} ref={heading}>{record.name}</h1>
          </div>
          {identity && <p className="record-head__identity">{identity}</p>}
        </header>

        <section className="section" aria-labelledby="use-title">
          <h2 id="use-title" className="section-header">使用</h2>
          <div className="group">
            <div className="cell usage">
              <div>
                <p className="usage__count"><span className="rounded-num">{uses}</span><span className="usage__unit">次</span></p>
                <p className="usage__last">{latest ? `上次 ${displayDate(latest)}` : '还没有使用记录'}</p>
              </div>
              <button type="button" className="capsule-button capsule-button--large" onClick={() => onUse(record.id)}>
                <IconPlus size={18} strokeWidth={2.4} />使用一次
              </button>
            </div>
            {history.length > 0 && (
              <button type="button" className="cell cell--button" aria-expanded={showHistory} onClick={() => setShowHistory(!showHistory)}>
                <span className="cell__label">使用记录</span>
                <span className="cell__value">{history.length} 条<IconChevronRight size={16} className="cell__chevron" data-open={showHistory || undefined} /></span>
              </button>
            )}
            {showHistory && history.map(use => (
              <div className="cell cell--sub" key={use.id}>
                <span className="cell__label">{displayDate(use.date)}</span>
                <button type="button" className="icon-button icon-button--danger" aria-label={`删除 ${displayDate(use.date)} 的使用记录`} onClick={() => onRemoveUse(record.id, use.id)}>
                  <IconTrash size={18} />
                </button>
              </div>
            ))}
            {backfill === null ? (
              <button type="button" className="cell cell--button cell--accent" onClick={() => setBackfill(today)}>
                <span className="cell__label"><IconCalendarPlus size={20} />补记一次使用</span>
              </button>
            ) : (
              <form className="cell backfill" onSubmit={event => { event.preventDefault(); if (backfill && backfill <= today) { onUse(record.id, backfill); setBackfill(null); } }}>
                <label className="cell__label" htmlFor="backfill-date">使用日期</label>
                <input id="backfill-date" type="date" className="date-input" required max={today} value={backfill} onChange={event => setBackfill(event.target.value)} />
                <button type="button" className="text-button text-button--quiet" onClick={() => setBackfill(null)}>取消</button>
                <button type="submit" className="text-button text-button--bold" disabled={!backfill || backfill > today}>添加</button>
              </form>
            )}
          </div>
          {record.usageCount > 0 && <p className="section-footer">其中 {record.usageCount} 次来自导入，没有具体日期。</p>}
        </section>

        <section className="section" aria-labelledby="expiry-title">
          <h2 id="expiry-title" className="section-header">有效期</h2>
          <div className="group">
            <div className="cell">
              <span className="cell__label">到期日</span>
              <span className="cell__value cell__value--stack">
                <span data-tone={expiry.status?.tone}>{displayDate(expiry.date)}</span>
                {expiry.status
                  ? <small data-tone={expiry.status.tone}>{expiry.status.label}</small>
                  : left !== null && <small>还有 {left} 天</small>}
              </span>
            </div>
            {progress !== null && <Gauge value={progress} />}
            {record.openedDate && <>
              <Row label="开封日期">{displayDate(record.openedDate)}</Row>
              <Row label="开封后可用">{record.paoMonths ? `${record.paoMonths} 个月` : '未填写'}</Row>
            </>}
            {record.packageExpiryDate && <Row label="包装到期日">{displayDate(record.packageExpiryDate)}</Row>}
            <button type="button" className="cell cell--button cell--accent" onClick={onOpening}>
              <span className="cell__label"><IconSeal size={20} />{record.openedDate ? '修改开封日期' : '记录开封'}</span>
            </button>
          </div>
          {meta && <p className="section-footer">{meta}。</p>}
        </section>

        {(record.price || record.purchasedDate) && (
          <section className="section" aria-labelledby="purchase-title">
            <h2 id="purchase-title" className="section-header">购买</h2>
            <div className="group">
              {record.purchasedDate && <Row label="购买日期">{displayDate(record.purchasedDate)}</Row>}
              {record.price && <Row label="实付">{displayPrice(record.price)}</Row>}
              {record.price && uses > 0 && <Row label="每次使用约">{displayPrice({ minorUnits: Math.round(record.price.minorUnits / uses), currency: 'CNY' })}</Row>}
            </div>
          </section>
        )}

        {record.note && (
          <section className="section" aria-labelledby="note-title">
            <h2 id="note-title" className="section-header">备注</h2>
            <div className="group"><p className="cell note">{record.note}</p></div>
          </section>
        )}

        <section className="section">
          <div className="group">
            <button type="button" className="cell cell--button cell--destructive" onClick={() => setConfirming(true)}>删除藏品</button>
          </div>
        </section>
      </div>
      {confirming && (
        <ConfirmSheet title={`删除「${record.name}」？`} message="使用记录会一起删除。" confirmLabel="删除藏品"
          onConfirm={() => onDelete(record.id)} onClose={() => setConfirming(false)} />
      )}
    </div>
  );
}
