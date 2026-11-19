import { useLayoutEffect, useRef, useState } from 'react';
import { addMonths, todayInShanghai } from '../collection.js';
import { categories, categoryById } from '../categories.js';

const PAO_CHOICES = [3, 6, 12, 18, 24, 36];
const reducedMotion = () => window.matchMedia('(prefers-reduced-motion: reduce)').matches;

function Toggle({ label, checked, onChange, id }) {
  return (
    <label className="cell cell--toggle" htmlFor={id}>
      <span className="cell__label">{label}</span>
      <input id={id} type="checkbox" role="switch" className="switch" checked={checked} onChange={event => onChange(event.target.checked)} />
    </label>
  );
}

/**
 * 添加 / 编辑 / 记录开封的表单。iOS Form 样式：移动端从底部滑出，桌面居中。
 * mode: 'add' | 'edit' | 'opening'
 */
export default function EditorSheet({ mode, categoryId, record, onClose, onSave }) {
  const dialog = useRef(null);
  const closing = useRef(false);
  const today = todayInShanghai();
  const opening = mode === 'opening';
  const adding = mode === 'add';
  const title = opening ? '记录开封' : adding ? '添加藏品' : '编辑藏品';

  const [name, setName] = useState(record?.name ?? '');
  const [brand, setBrand] = useState(record?.brand ?? '');
  const [shade, setShade] = useState(record?.shade ?? '');
  const [category, setCategory] = useState(categoryId ?? record?.categoryId ?? 'lipstick');
  const [hasPurchased, setHasPurchased] = useState(Boolean(record?.purchasedDate));
  const [purchasedDate, setPurchasedDate] = useState(record?.purchasedDate ?? today);
  const [price, setPrice] = useState(record?.price ? String(record.price.minorUnits / 100) : '');
  const [hasPackage, setHasPackage] = useState(Boolean(record?.packageExpiryDate));
  const [packageExpiryDate, setPackageExpiryDate] = useState(record?.packageExpiryDate ?? addMonths(today, 24));
  const [isOpened, setIsOpened] = useState(opening || Boolean(record?.openedDate));
  const [openedDate, setOpenedDate] = useState(record?.openedDate ?? today);
  const [pao, setPao] = useState(record?.paoMonths ?? null);
  const [note, setNote] = useState(record?.note ?? '');
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  useLayoutEffect(() => {
    const node = dialog.current;
    if (!node.open) node.showModal();
  }, []);

  function close() {
    const node = dialog.current;
    if (!node || closing.current) return;
    if (reducedMotion()) { node.close(); return; }
    closing.current = true;
    node.dataset.closing = '';
    const sheet = node.querySelector('.sheet');
    const onEnd = () => node.close();
    sheet.addEventListener('animationend', onEnd, { once: true });
    window.setTimeout(onEnd, 400);
  }

  function validate() {
    if (!opening) {
      if (!name.trim()) return '请填写藏品名称。';
      if (price.trim() !== '') {
        const value = Number(price);
        if (!Number.isFinite(value) || value < 0 || value > 9999999.99) return '价格格式不正确。';
      }
      if (hasPurchased && !purchasedDate) return '请选择购买日期。';
      if (hasPurchased && purchasedDate > today) return '购买日期不能晚于今天。';
      if (hasPackage && !packageExpiryDate) return '请选择包装到期日。';
    }
    if (isOpened) {
      if (!openedDate) return '请选择开封日期。';
      if (openedDate > today) return '开封日期不能晚于今天。';
      const bought = opening ? record?.purchasedDate : hasPurchased ? purchasedDate : null;
      if (bought && openedDate < bought) return '开封日期早于购买日期，请检查。';
    }
    if (pao !== null && (!Number.isInteger(pao) || pao < 1 || pao > 120)) return '开封后可用月数应在 1–120 之间。';
    return '';
  }

  async function submit(event) {
    event.preventDefault();
    if (closing.current || saving) return;
    const problem = validate();
    setError(problem);
    if (problem) return;
    const openingChanges = isOpened
      ? { openedDate, paoMonths: pao }
      : { openedDate: null, paoMonths: null };
    const changes = opening ? openingChanges : {
      name: name.trim(),
      brand: brand.trim() || null,
      shade: shade.trim() || null,
      purchasedDate: hasPurchased ? purchasedDate : null,
      packageExpiryDate: hasPackage ? packageExpiryDate : null,
      price: price.trim() === '' ? null : { minorUnits: Math.round(Number(price) * 100), currency: 'CNY' },
      note: note.trim() || null,
      ...openingChanges
    };
    setSaving(true);
    try {
      await onSave(changes, adding ? category : undefined);
      close();
    } catch (failure) {
      setError(failure.message || '未能保存，请重试。');
    } finally {
      setSaving(false);
    }
  }

  const openingSection = (
    <section className="section" aria-label="开封">
      <h3 className="section-header">开封</h3>
      <div className="group">
        {!opening && <Toggle id="f-opened" label="已开封" checked={isOpened} onChange={setIsOpened} />}
        {isOpened && <>
          <label className="cell" htmlFor="f-opened-date">
            <span className="cell__label">开封日期</span>
            <input id="f-opened-date" type="date" className="date-input" max={today} required value={openedDate} onChange={event => setOpenedDate(event.target.value)} />
          </label>
          <div className="cell">
            <span className="cell__label" id="f-pao-label">开封后可用</span>
            <span className="stepper" role="group" aria-labelledby="f-pao-label">
              <span className="stepper__value" aria-live="polite">{pao ? `${pao} 个月` : '未填写'}</span>
              <span className="stepper__buttons">
                <button type="button" aria-label="减少一个月" disabled={!pao} onClick={() => setPao(pao && pao > 1 ? pao - 1 : null)}>−</button>
                <span className="stepper__divider" aria-hidden="true" />
                <button type="button" aria-label="增加一个月" disabled={pao >= 120} onClick={() => setPao(Math.min(120, (pao ?? 0) + 1))}>+</button>
              </span>
            </span>
          </div>
          <div className="cell chips" role="radiogroup" aria-label="常见开封后期限">
            {PAO_CHOICES.map(months => (
              <button key={months} type="button" role="radio" aria-checked={pao === months} className="chip" onClick={() => setPao(pao === months ? null : months)}>{months}M</button>
            ))}
          </div>
        </>}
      </div>
      {isOpened && <p className="section-footer">包装上开盖罐子图标旁的数字，例如 12M 就是开封后 12 个月。</p>}
    </section>
  );

  return (
    <dialog className="sheet-dialog" ref={dialog} aria-labelledby="editor-title" onClose={onClose}
      onCancel={event => { event.preventDefault(); close(); }}
      onClick={event => { if (event.target === event.currentTarget) close(); }}>
      <form className="sheet" onSubmit={submit} noValidate>
        <header className="sheet__bar">
          <button type="button" className="text-button" onClick={close}>取消</button>
          <h2 id="editor-title" className="sheet__title">{title}</h2>
          <button type="submit" className="text-button text-button--bold" disabled={saving}>{saving ? '保存中…' : adding ? '添加' : '完成'}</button>
        </header>
        <div className="sheet__body">
          {opening && record && <p className="sheet__context">{record.name}</p>}
          {!opening && <>
            <section className="section" aria-label="基本信息">
              <div className="group">
                <label className="cell cell--field"><span className="visually-hidden">名称（必填）</span>
                  <input autoFocus className="field" placeholder="名称（必填）" maxLength={100} value={name} onChange={event => setName(event.target.value)} aria-invalid={error === '请填写藏品名称。' || undefined} />
                </label>
                <label className="cell cell--field"><span className="visually-hidden">品牌</span>
                  <input className="field" placeholder="品牌" maxLength={80} value={brand} onChange={event => setBrand(event.target.value)} />
                </label>
                <label className="cell cell--field"><span className="visually-hidden">色号或规格</span>
                  <input className="field" placeholder="色号或规格" maxLength={60} value={shade} onChange={event => setShade(event.target.value)} />
                </label>
                {adding ? (
                  <label className="cell" htmlFor="f-category">
                    <span className="cell__label">分类</span>
                    <select id="f-category" className="select" value={category} onChange={event => setCategory(event.target.value)}>
                      {categories.map(item => <option key={item.id} value={item.id}>{item.title}</option>)}
                    </select>
                  </label>
                ) : (
                  <div className="cell"><span className="cell__label">分类</span><span className="cell__value">{categoryById(category)?.title}</span></div>
                )}
              </div>
            </section>

            <section className="section" aria-label="购入与有效期">
              <h3 className="section-header">购入与有效期</h3>
              <div className="group">
                <Toggle id="f-purchased" label="购买日期" checked={hasPurchased} onChange={setHasPurchased} />
                {hasPurchased && (
                  <label className="cell cell--sub" htmlFor="f-purchased-date">
                    <span className="cell__label">日期</span>
                    <input id="f-purchased-date" type="date" className="date-input" max={today} value={purchasedDate} onChange={event => setPurchasedDate(event.target.value)} />
                  </label>
                )}
                <label className="cell" htmlFor="f-price">
                  <span className="cell__label">实付</span>
                  <span className="price-field"><span aria-hidden="true">¥</span>
                    <input id="f-price" className="field field--trailing" type="number" inputMode="decimal" min="0" max="9999999.99" step="0.01" placeholder="0.00" value={price} onChange={event => setPrice(event.target.value)} />
                  </span>
                </label>
                <Toggle id="f-package" label="包装到期日" checked={hasPackage} onChange={setHasPackage} />
                {hasPackage && (
                  <label className="cell cell--sub" htmlFor="f-package-date">
                    <span className="cell__label">日期</span>
                    <input id="f-package-date" type="date" className="date-input" value={packageExpiryDate} onChange={event => setPackageExpiryDate(event.target.value)} />
                  </label>
                )}
              </div>
            </section>
          </>}

          {openingSection}

          {!opening && (
            <section className="section" aria-label="备注">
              <h3 className="section-header">备注</h3>
              <div className="group">
                <label className="cell cell--field"><span className="visually-hidden">备注</span>
                  <textarea className="field field--area" rows={3} maxLength={2000} placeholder="肤感、搭配、回购意向……" value={note} onChange={event => setNote(event.target.value)} />
                </label>
              </div>
            </section>
          )}
          {error && <p className="form-error" role="alert">{error}</p>}
        </div>
      </form>
    </dialog>
  );
}
