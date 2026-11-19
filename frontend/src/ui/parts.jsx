import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { IconAlertFill, IconChevronLeft, IconClockFill, IconJar } from './Icons.jsx';

/** 藏品缩略图：有照片显示照片，否则中性底色 + 瓶子图标。 */
export function RecordThumb({ record, size = 54, radius = 12, className = '' }) {
  const style = { width: size, height: size, borderRadius: radius };
  return record.imageUrl
    ? <img className={'thumb ' + className} style={style} src={record.imageUrl} alt="" loading="lazy" />
    : <span className={'thumb thumb--empty ' + className} style={style} aria-hidden="true"><IconJar size={Math.round(size * 0.46)} /></span>;
}

/** 到期状态：图标 + 文字，颜色只做强调。 */
export function StatusLabel({ status }) {
  if (!status) return null;
  const Icon = status.tone === 'expired' ? IconAlertFill : IconClockFill;
  return <span className="status" data-tone={status.tone}><Icon size={14} />{status.label}</span>;
}

/** 大标题滚出视口后，导航栏显示小标题（iOS 行为）。 */
export function useCollapsedTitle() {
  const ref = useRef(null);
  const [collapsed, setCollapsed] = useState(false);
  useEffect(() => {
    const node = ref.current;
    if (!node || !('IntersectionObserver' in window)) return undefined;
    const observer = new IntersectionObserver(([entry]) => setCollapsed(!entry.isIntersecting), { rootMargin: '-52px 0px 0px 0px' });
    observer.observe(node);
    return () => observer.disconnect();
  }, []);
  return [ref, collapsed];
}

/** 顶部导航栏：返回按钮、居中小标题、右侧操作。 */
export function NavBar({ backLabel, onBack, title, collapsed = true, children }) {
  return (
    <header className="navbar" data-collapsed={collapsed || undefined}>
      <div className="navbar__leading">
        {onBack && (
          <button type="button" className="navbar__back" onClick={onBack} aria-label={`返回${backLabel}`}>
            <IconChevronLeft size={24} strokeWidth={2.2} /><span>{backLabel}</span>
          </button>
        )}
      </div>
      <div className="navbar__title" aria-hidden={!collapsed}>{title}</div>
      <div className="navbar__trailing">{children}</div>
    </header>
  );
}

/** 页面主标题，挂载后获得焦点，方便读屏用户知道已切换页面。 */
export function LargeTitle({ children, titleRef, focusOnMount = true, id }) {
  const local = useRef(null);
  useLayoutEffect(() => {
    if (focusOnMount) local.current?.focus({ preventScroll: true });
  }, [focusOnMount]);
  return (
    <div ref={titleRef} className="large-title-wrap">
      <h1 className="large-title" id={id} tabIndex={-1} ref={local}>{children}</h1>
    </div>
  );
}

/** 简单弹出菜单（iOS Menu 的网页近似）。 */
export function Menu({ label, icon, items, value, onSelect }) {
  const [open, setOpen] = useState(false);
  const root = useRef(null);
  useEffect(() => {
    if (!open) return undefined;
    const onDown = event => { if (!root.current?.contains(event.target)) setOpen(false); };
    const onKey = event => { if (event.key === 'Escape') setOpen(false); };
    document.addEventListener('pointerdown', onDown);
    document.addEventListener('keydown', onKey);
    root.current?.querySelector('[role="menuitemradio"][aria-checked="true"]')?.focus();
    return () => {
      document.removeEventListener('pointerdown', onDown);
      document.removeEventListener('keydown', onKey);
    };
  }, [open]);
  return (
    <div className="menu" ref={root}>
      <button type="button" className="icon-button" aria-label={label} aria-haspopup="menu" aria-expanded={open} onClick={() => setOpen(!open)}>{icon}</button>
      {open && (
        <div className="menu__popover material" role="menu" aria-label={label}>
          {items.map(item => (
            <button key={item.value} type="button" role="menuitemradio" aria-checked={item.value === value}
              className="menu__item" onClick={() => { onSelect(item.value); setOpen(false); }}>
              <span className="menu__check" aria-hidden="true">{item.value === value ? '✓' : ''}</span>{item.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

/** 确认操作表（iOS confirmationDialog）。 */
export function ConfirmSheet({ title, message, confirmLabel, onConfirm, onClose }) {
  const dialog = useRef(null);
  useLayoutEffect(() => { dialog.current?.showModal(); }, []);
  return (
    <dialog className="action-sheet" ref={dialog} aria-labelledby="confirm-title" onClose={onClose}
      onClick={event => { if (event.target === event.currentTarget) dialog.current.close(); }}>
      <div className="action-sheet__group">
        <div className="action-sheet__head">
          <p id="confirm-title" className="action-sheet__title">{title}</p>
          {message && <p className="action-sheet__message">{message}</p>}
        </div>
        <button type="button" className="action-sheet__button action-sheet__button--destructive" onClick={() => { onConfirm(); dialog.current.close(); }}>{confirmLabel}</button>
      </div>
      <div className="action-sheet__group">
        <button type="button" autoFocus className="action-sheet__button action-sheet__button--cancel" onClick={() => dialog.current.close()}>取消</button>
      </div>
    </dialog>
  );
}

/** 空状态（ContentUnavailableView）。 */
export function EmptyState({ icon, title, description, action }) {
  return (
    <div className="empty">
      {icon && <span className="empty__icon" aria-hidden="true">{icon}</span>}
      <h2 className="empty__title">{title}</h2>
      {description && <p className="empty__description">{description}</p>}
      {action}
    </div>
  );
}
