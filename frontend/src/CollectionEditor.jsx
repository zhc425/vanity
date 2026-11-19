import { useLayoutEffect, useRef, useState } from 'react';
import { todayInShanghai } from './collection.js';

const errorFor = '不能晚于今天';

export default function CollectionEditor({ category, mode, record, onClose, onSave, onDelete }) {
  const dialog = useRef(null);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);
  const [purchasedDate, setPurchasedDate] = useState(record?.purchasedDate ?? '');
  const closing = useRef(false);
  const today = todayInShanghai();
  const opening = mode === 'opening';
  const creating = mode === 'add';
  const title = opening ? '记录开封' : creating ? '添加藏品' : '编辑藏品';

  useLayoutEffect(() => {
    const node = dialog.current;
    if (!node.open) node.showModal();
  }, []);

  function close() {
    const node = dialog.current;
    if (closing.current) return;
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return node.close();
    closing.current = true;
    node.dataset.closing = '';
    const animation = node.animate([
      { opacity: 1, transform: 'translateY(0)' },
      { opacity: 0, transform: 'translateY(10px)' }
    ], { duration: 160, easing: 'ease-in', fill: 'forwards' });
    animation.finished.then(() => node.close()).catch(() => {});
  }

  async function save(event) {
    event.preventDefault();
    if (closing.current || saving) return;
    const fields = new FormData(event.currentTarget);
    const read = key => String(fields.get(key) ?? '').trim();
    let changes;
    if (opening) {
      const openedDate = read('openedDate');
      if (!openedDate) return setError('请选择开封日期。');
      if (openedDate > today) return setError('开封日期' + errorFor);
      if (record.purchasedDate && openedDate < record.purchasedDate) return setError('开封日期早于购买日期，请检查。');
      changes = { openedDate, paoMonths: read('paoMonths') ? Number(read('paoMonths')) : null };
    } else {
      const name = read('name');
      const price = read('price');
      const priceValue = Number(price);
      if (!name) return setError('请填写藏品名称。');
      if (price !== '' && (!Number.isFinite(priceValue) || priceValue < 0 || priceValue > 9999999.99)) return setError('价格格式不正确。');
      if (purchasedDate > today) return setError('购买日期' + errorFor);
      changes = {
        name,
        brand: read('brand') || null,
        shade: read('shade') || null,
        purchasedDate: purchasedDate || null,
        packageExpiryDate: read('packageExpiryDate') || null,
        note: read('note') || null,
        price: price === '' ? null : { minorUnits: Math.round(Number(price) * 100), currency: 'CNY' }
      };
    }
    setSaving(true);
    try {
      await onSave(changes);
      close();
    } catch (error) {
      setError(error.message || '未能保存，请重试。');
    } finally {
      setSaving(false);
    }
  }

  return (
    <dialog className="editor" ref={dialog} aria-labelledby="editor-title" onClose={onClose}
      onCancel={event => { event.preventDefault(); close(); }}
      onClick={event => { if (event.target === event.currentTarget) close(); }}>
      <div className="editor__layout">
      <aside className="editor__cover" aria-hidden="true">
        <img src={category.cover ?? category.src} alt="" />
        <div><span>{category.title}</span></div>
      </aside>
      <form onSubmit={save} className="editor__form">
        <header className="editor__bar">
          <div><p className="editor__category">{category.title}</p><h2 id="editor-title">{title}</h2></div>
          <button type="button" className="editor__close" onClick={close} aria-label="关闭">×</button>
        </header>
        {opening ? (
          <>
            <label>开封日期<input autoFocus name="openedDate" type="date" required max={today} defaultValue={record.openedDate ?? today} /></label>
            <label>开封后可用月数 <span>选填</span><input name="paoMonths" type="number" inputMode="numeric" min="1" max="120" defaultValue={record.paoMonths ?? ''} placeholder="包装标 12M，就填 12" /></label>
          </>
        ) : (
          <>
            <label>藏品名称 <span>仅此项必填</span><input autoFocus name="name" required maxLength="100" defaultValue={record?.name ?? ''} /></label>
            <div className="editor__pairs">
              <label>品牌<input name="brand" maxLength="80" defaultValue={record?.brand ?? ''} /></label>
              <label>色号或规格<input name="shade" maxLength="60" defaultValue={record?.shade ?? ''} /></label>
            </div>
            <details className="editor__optional" open={!creating}>
            <summary>购入与有效期</summary>
            <div className="editor__optional-body">
            <div className="editor__pairs">
              <div className="editor__date">
                <label>购买日期<input name="purchasedDate" type="date" max={today} value={purchasedDate} onChange={event => setPurchasedDate(event.target.value)} /></label>
                <button className="editor__today" type="button" onClick={() => setPurchasedDate(today)}>今天</button>
              </div>
              <label>实付价格（元）<input name="price" type="number" inputMode="decimal" min="0" max="9999999.99" step="0.01" defaultValue={record?.price ? record.price.minorUnits / 100 : ''} /></label>
            </div>
            <label>包装到期日<input name="packageExpiryDate" type="date" defaultValue={record?.packageExpiryDate ?? ''} /></label>
            </div>
            </details>
            <label>备注 <span>选填</span><textarea name="note" rows="3" maxLength="2000" defaultValue={record?.note ?? ''} placeholder="肤感、搭配、回购意向……" /></label>
          </>
        )}
        {error && <p className="editor__error" role="alert">{error}</p>}
        <footer className="editor__actions">
          {mode === 'edit' && onDelete && (
            <button className="action action--danger" type="button" disabled={saving} onClick={async () => {
              if (!window.confirm(`删除「${record.name}」？使用记录会一起删除。`)) return;
              setSaving(true);
              try { await onDelete(); close(); }
              catch (error) { setError(error.message || '未能删除，请重试。'); }
              finally { setSaving(false); }
            }}>删除藏品</button>
          )}
          <button className="action action--quiet" type="button" onClick={close}>取消</button>
          <button className="action action--primary" type="submit" disabled={saving}>{saving ? '保存中…' : opening ? '保存开封记录' : '保存藏品'}</button>
        </footer>
      </form>
      </div>
    </dialog>
  );
}
