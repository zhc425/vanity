import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { flushSync } from 'react-dom';
import { displayDate, displayPrice, getExpiry, countUses, todayInShanghai } from './collection.js';
import { loadCollection, saveCollection, readLegacyRecords, mergeCollections, normalizeRecords, watchExternalChanges } from './collectionStore.js';
import CollectionEditor from './CollectionEditor.jsx';
import givenchyDetail from './preview-images/GivenchyDetail.webp';
import CircularCarousel from './components/CircularCarousel/CircularCarousel.jsx';
import fanBeautyMask from './preview-images/FanBeautyMask.webp';
import chanelCleanser from './preview-images/ChanelCleanser.webp';
import skinCeuticalsCream from './preview-images/SkinCeuticalsCream.webp';
import cleDePeauPrimer from './preview-images/CleDePeauPrimer.webp';
import yslFoundation from './preview-images/YSLFoundation.webp';
import givenchyLoosePowder from './preview-images/GivenchyLoosePowder.webp';
import narsPressedPowder from './preview-images/NARSPressedPowder.webp';
import chanelBlush from './preview-images/ChanelBlush.webp';
import maoGepingPalette from './preview-images/MaoGepingPalette.webp';
import chanelLipstick from './preview-images/ChanelLipstick.webp';
import momoWorkshopPuff from './preview-images/MomoWorkshopPuff.webp';

const items = [
  {
    id: 'mask',
    entry: true,
    src: fanBeautyMask,
    alt: 'Fan Beauty Diary mask collection',
    title: '面膜',
    subtitle: 'Mask'
  },
  {
    id: 'cleanser',
    entry: true,
    src: chanelCleanser,
    alt: 'Chanel La Mousse cleansing cream-to-foam',
    title: '洁面乳',
    subtitle: 'Cleanser'
  },
  {
    id: 'cream',
    entry: true,
    src: skinCeuticalsCream,
    alt: 'SkinCeuticals A.G.E. Interrupter Ultra cream',
    title: '面霜',
    subtitle: 'Cream'
  },
  {
    id: 'primer',
    entry: true,
    src: cleDePeauPrimer,
    alt: 'Clé de Peau correcting cream veil',
    title: '隔离',
    subtitle: 'Primer'
  },
  {
    id: 'foundation',
    entry: true,
    src: yslFoundation,
    alt: 'YSL All Hours foundation bottle on a tray',
    title: '粉底液',
    subtitle: 'Foundation'
  },
  {
    id: 'loose-powder',
    entry: true,
    src: givenchyLoosePowder,
    alt: 'Givenchy Prisme Libre loose powder',
    title: '散粉',
    subtitle: 'Loose Powder',
    cover: givenchyDetail
  },
  {
    id: 'pressed-powder',
    entry: true,
    src: narsPressedPowder,
    alt: 'NARS pressed powder compact',
    title: '蜜粉饼',
    subtitle: 'Pressed Powder'
  },
  {
    id: 'blush',
    entry: true,
    src: chanelBlush,
    alt: 'Chanel powder blush compact with brush',
    title: '腮红',
    subtitle: 'Blush'
  },
  {
    id: 'eyeshadow',
    entry: true,
    src: maoGepingPalette,
    alt: 'Mao Geping eyeshadow palette',
    title: '眼影盘',
    subtitle: 'Palette'
  },
  {
    id: 'lipstick',
    entry: true,
    src: chanelLipstick,
    alt: 'Chanel lipstick in a gold case',
    title: '口红',
    subtitle: 'Lipstick'
  },
  {
    id: 'puff',
    entry: true,
    src: momoWorkshopPuff,
    alt: "Momo's Workshop makeup puffs in a basket",
    title: '粉扑',
    subtitle: 'Puff'
  }
];


const categoryHash = category => '#' + category.id;
const recordHash = (category, id) => categoryHash(category) + '/' + encodeURIComponent(id);
const getCategory = hash => items.find(item => categoryHash(item) === hash.split('/')[0]);
const initialCard = items.findIndex(item => item.id === 'loose-powder');
const portraitName = id => 'portrait-' + id;


function VanityMark({ compact = false }) {
  const Heading = compact ? 'span' : 'h1';
  return (
    <Heading className={compact ? 'detail__mark' : 'brand__title'}>
      <span className="brand__initial">V</span>anit<span className="brand__tail">y</span>
    </Heading>
  );
}

function Chevron({ left = false }) {
  return <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true">
    <path d={left ? 'm14 6-6 6 6 6' : 'm10 6 6 6-6 6'} fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
  </svg>;
}


function RouteLink({ href, onNavigate, children, ...props }) {
  return (
    <a {...props} href={href} onClick={event => {
      if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button !== 0) return;
      event.preventDefault();
      onNavigate(event);
    }}>{children}</a>
  );
}

function ThemeToggle({ dark, onToggle }) {
  return (
    <button type="button" className="theme-toggle" aria-label={dark ? '切换到白天模式' : '切换到夜间模式'} onClick={onToggle}>
      <svg viewBox="0 0 24 24" width="19" height="19" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        {dark ? <><circle cx="12" cy="12" r="4" /><path d="M12 2v2m0 16v2M2 12h2m16 0h2M5 5l1.5 1.5m11 11L19 19M5 19l1.5-1.5m11-11L19 5" /></> : <path d="M20.8 14a8.9 8.9 0 0 1-10.8-10.8A9 9 0 1 0 20.8 14Z" />}
      </svg>
    </button>
  );
}

function InnerHeader({ category, parent, onReturn, onIndex, themeControl }) {
  return (
    <header className="detail__bar">
      <RouteLink className="detail__back" href={parent === 'category' ? categoryHash(category) : '#'} onNavigate={onReturn}>
        <Chevron left />{parent === 'category' ? '返回' + category.title : '返回封面'}
      </RouteLink>
      <VanityMark compact />
      <div className="header-tools"><button className="quiet-button" onClick={onIndex}>全部分类</button>{themeControl}</div>
    </header>
  );
}

function Status({ status }) {
  return status && <span className="expiry" data-tone={status.tone}><span aria-hidden="true" />{status.label}</span>;
}

function SampleArt({ record }) {
  if (!record.imageUrl && !record.demo) {
    return <div className="collection-placeholder" aria-hidden="true"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.2"><rect x="3" y="4" width="18" height="16" rx="2" /><path d="m3 16 5-5 5 5 3-3 5 5" /><circle cx="16" cy="9" r="1" /></svg></div>;
  }
  return record.imageUrl
    ? <img className="sample-image" src={record.imageUrl} alt={record.imageAlt ?? record.name} />
    : <div className="sample-art" data-color={record.color} aria-hidden="true"><div className="sample-art__jar"><span /></div></div>;
}

function CategoryPage({ category, records, onReturn, onIndex, onRecord, onAdd, onUse, fromFrame, restoreId, themeControl }) {
  const headline = useRef(null);
  const photo = useRef(null);
  const restored = useRef(null);

  useLayoutEffect(() => {
    (restoreId && restored.current ? restored.current : headline.current).focus({ preventScroll: true });
    if (!fromFrame || fromFrame.width < 30 || fromFrame.height < 30 ||
        window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    const img = photo.current;
    const end = img.getBoundingClientRect();
    if (!end.width || !end.height) return;
    const animation = img.animate([
      {
        transform: `translate(${fromFrame.left - end.left}px, ${fromFrame.top - end.top}px) scale(${fromFrame.width / end.width}, ${fromFrame.height / end.height})`,
        opacity: 0.54
      },
      { transform: 'none', opacity: 1 }
    ], { duration: 420, easing: 'cubic-bezier(.22,.75,.24,1)' });
    return () => animation.cancel();
  }, [fromFrame, restoreId]);

  return (
    <div className="detail">
      <InnerHeader category={category} parent="cover" onReturn={onReturn} onIndex={onIndex} themeControl={themeControl} />
      <main className="collection" aria-labelledby="category-heading">
        <section className="collection__intro">
          <div className="collection__intro-copy">
            <h1 id="category-heading" ref={headline} tabIndex={-1}>{category.title}</h1>
            <p className="collection__subtitle"><span lang="en">{category.subtitle}</span><span>{records.length} 件</span></p>
            <button className="action action--primary collection__add" type="button" onClick={onAdd}>＋ 添加藏品</button>
          </div>
          <figure className="collection__cover">
            <img ref={photo} src={category.cover ?? category.src} alt={category.alt} />
          </figure>
        </section>
        <section className="collection__records" aria-labelledby="record-list-title">
          <div className="collection__head">
            <h2 id="record-list-title">藏品</h2>
            {records.length > 0 && <><span aria-hidden="true">使用</span><span aria-hidden="true">到期</span></>}
          </div>
          {records.length ? (
            <ul className="collection__list">
              {records.map(record => {
                const expiry = getExpiry(record);
                const identity = [record.brand, record.shade, record.demo ? '演示藏品' : null].filter(Boolean).join(' / ');
                return (
                  <li key={record.id}>
                    <RouteLink className="collection__row" ref={record.id === restoreId ? restored : undefined} href={recordHash(category, record.id)} onNavigate={() => onRecord(record.id)}>
                      <div className="collection__thumb" style={{ viewTransitionName: portraitName(record.id) }}><SampleArt record={record} /></div>
                      <div className="collection__identity">
                        <strong>{record.name}</strong>
                        {identity && <span>{identity}</span>}
                      </div>
                      <div className="collection__use"><span className="collection__metric-label">使用</span><strong><span className="numeric">{countUses(record)}</span> 次</strong></div>
                      <div className="collection__expiry">
                        <div><span className="collection__metric-label">到期</span><strong>{displayDate(expiry.date)}</strong></div>
                        <Status status={expiry.status} />
                      </div>
                    </RouteLink>
                    <button className="action collection__use-button" type="button" aria-label={`记一次使用：${record.name}`} onClick={() => onUse(record.id)}><span aria-hidden="true">＋</span> 记一次使用</button>
                  </li>
                );
              })}
            </ul>
          ) : <p className="collection__empty">还没有藏品</p>}
        </section>
      </main>
    </div>
  );
}

function RecordPage({ category, record, onReturn, onIndex, onUse, onEdit, onOpening, themeControl }) {
  const headline = useRef(null);
  const expiry = getExpiry(record);
  const identity = [record.brand, record.shade, record.demo ? '演示藏品' : null].filter(Boolean).join(' / ');

  useLayoutEffect(() => {
    headline.current.focus({ preventScroll: true });
  }, []);

  return (
    <div className="detail">
      <InnerHeader category={category} parent="category" onReturn={onReturn} onIndex={onIndex} themeControl={themeControl} />
      <main className="detail__layout record" aria-labelledby="record-title">
        <header className="record__heading">
            <h1 id="record-title" ref={headline} tabIndex={-1}>{record.name}</h1>
            {identity && <p className="record__variant">{identity}</p>}
        </header>
        <figure className="detail__figure record__figure">
          <div className="record__portrait" style={{ viewTransitionName: portraitName(record.id) }}><SampleArt record={record} /></div>
          {!record.imageUrl && !record.demo && <figcaption>暂无照片</figcaption>}
        </figure>
        <div className="detail__information record__archive">
          <section className="record__section record__usage" aria-labelledby="use-title">
            <div className="record__use-row">
              <div><h2 id="use-title">使用记录</h2><p className="record__value"><span className="numeric">{countUses(record)}</span> <span className="record__unit">次</span></p></div>
              <button className="action action--primary" type="button" onClick={() => onUse(record.id)}>＋ 记一次使用</button>
            </div>
          </section>
          <section className="record__section" aria-labelledby="expiry-title">
            <div className="record__section-top">
              <h2 id="expiry-title">到期日</h2>
              <button className="record__edit" type="button" onClick={() => onOpening(record.id)}>{record.openedDate ? '修改开封记录' : '记录开封'}</button>
            </div>
            <div className="record__date"><p className="record__value">{displayDate(expiry.date)}</p><Status status={expiry.status} /></div>
            {(expiry.basis || expiry.prompt) && <p className="record__meta">{[expiry.basis, expiry.prompt].filter(Boolean).join('。')}</p>}
            {record.openedDate && <p className="record__meta">开封于 {displayDate(record.openedDate)}{record.paoMonths ? `，开封后可用 ${record.paoMonths} 个月` : ''}</p>}
          </section>
          <section className="record__section record__purchase" aria-labelledby="purchase-title">
            <div className="record__section-top">
              <h2 id="purchase-title">购入信息</h2>
              <button className="record__edit" type="button" onClick={() => onEdit(record.id)}>编辑藏品</button>
            </div>
            <dl><div><dt>购买日期</dt><dd>{displayDate(record.purchasedDate)}</dd></div><div><dt>实付价格</dt><dd>{displayPrice(record.price)}</dd></div></dl>
          </section>
          {record.note && <p className="detail__description">{record.note}</p>}
        </div>
      </main>
    </div>
  );
}

export default function App() {
  const [initial] = useState(() => loadCollection());
  const storageRef = useRef(initial.storage);
  const [storage, setStorage] = useState(initial.storage);
  const [records, setRecords] = useState(initial.records);
  const [externalChange, setExternalChange] = useState(false);
  const [legacy] = useState(() => readLegacyRecords());
  const [importDismissed, setImportDismissed] = useState(false);
  const writing = useRef(false);
  const [dark, setDark] = useState(() => document.documentElement.dataset.theme === 'dark');
  const themeControl = <ThemeToggle dark={dark} onToggle={() => {
    const theme = dark ? 'light' : 'dark';
    document.documentElement.dataset.theme = theme;
    document.querySelector('meta[name="theme-color"]').content = dark ? '#f7f5f8' : '#141318';
    try { localStorage.setItem('vanity.theme', theme); } catch {}
    setDark(!dark);
  }} />;
  const [hash, setHash] = useState(() => window.location.hash);
  const renderedHash = useRef(hash);
  const viewTransition = useRef(null);
  const [editor, setEditor] = useState(null);
  const [notice, setNotice] = useState(null);
  const category = getCategory(hash);
  const record = category && records.find(item => item.categoryId === category.id && recordHash(category, item.id) === hash);
  const page = record ? 'item' : category ? 'category' : 'cover';
  const coverIndex = useRef(category ? items.indexOf(category) : initialCard);
  const [active, setActive] = useState(coverIndex.current);
  const carousel = useRef(null);
  const indexDialog = useRef(null);
  const coverEntered = useRef(false);
  const coverAction = useRef(null);
  const fromFrame = useRef(null);
  const lastRecord = useRef(null);
  const categoryScroll = useRef(0);
  const hasVisitedCategory = useRef(page !== 'cover');
  const current = items[active];

  const sync = () => {
    const next = window.location.hash;
    if (next === renderedHash.current) return;
    const previous = renderedHash.current;
    renderedHash.current = next;
    const nextCategory = getCategory(next);
    if (nextCategory) coverIndex.current = items.indexOf(nextCategory);
    else setActive(coverIndex.current);
    const update = () => setHash(next);
    const intoRecord = next.includes('/') || previous.includes('/');
    if (intoRecord && nextCategory && getCategory(previous) &&
        document.startViewTransition && !document.querySelector('dialog[open]') &&
        !window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      viewTransition.current?.skipTransition();
      const transition = document.startViewTransition(() => {
        if (renderedHash.current === next) flushSync(update);
      });
      viewTransition.current = transition;
      transition.finished.catch(() => {}).finally(() => {
        if (viewTransition.current === transition) viewTransition.current = null;
      });
    } else {
      viewTransition.current?.skipTransition();
      update();
    }
  };

  useEffect(() => {
    const onPop = () => {
      fromFrame.current = null;
      sync();
    };
    window.addEventListener('popstate', onPop);
    window.addEventListener('hashchange', onPop);
    return () => {
      window.removeEventListener('popstate', onPop);
      window.removeEventListener('hashchange', onPop);
    };
  }, []);

  const recordName = record?.name;
  const categoryTitle = category?.title;
  useLayoutEffect(() => {
    document.title = page === 'item' ? `${recordName} · Vanity` : page === 'category' ? categoryTitle + ' · Vanity' : 'Vanity · 我的美妆藏品';
    window.scrollTo(0, page === 'category' && lastRecord.current ? categoryScroll.current : 0);
    if (page === 'cover' && hasVisitedCategory.current) coverAction.current?.focus({ preventScroll: true });
  }, [page, recordName, categoryTitle, records]);

  useEffect(() => { if (page === 'cover') coverEntered.current = true; }, [page]);

  const openCategory = (target, frame = null) => {
    indexDialog.current?.close();
    if (target.id === category?.id && page === 'category') return;
    hasVisitedCategory.current = true;
    fromFrame.current = frame;
    lastRecord.current = null;
    categoryScroll.current = 0;
    history.pushState({ vanityParent: page === 'cover' ? 'cover' : null }, '', categoryHash(target));
    sync();
  };

  const openRecord = id => {
    fromFrame.current = null;
    lastRecord.current = id;
    categoryScroll.current = window.scrollY;
    history.pushState({ vanityParent: 'category' }, '', recordHash(category, id));
    sync();
  };

  const backTo = parent => {
    fromFrame.current = null;
    if (history.state?.vanityParent === parent) {
      history.back();
      return;
    }
    const target = parent === 'category' ? categoryHash(category) : window.location.pathname + window.location.search;
    history.replaceState(null, '', target);
    sync();
  };

  const browseIndex = () => indexDialog.current?.showModal();

  const saveRecords = async next => {
    if (writing.current) throw new Error('正在保存，请稍候。');
    writing.current = true;
    try {
      if (storageRef.current === 'memory') {
        setRecords(next);
        return false;
      }
      try {
        saveCollection(next);
      } catch (error) {
        if (error.code === 'blocked') {
          storageRef.current = 'memory';
          setStorage('memory');
          setRecords(next);
          return false;
        }
        throw error;
      }
      setRecords(next);

      return true;
    } finally {
      writing.current = false;
    }
  };

  const saveEditor = async changes => {
    const adding = editor.mode === 'add';
    const id = adding ? crypto.randomUUID() : editor.id;
    const next = adding
      ? [{ id, categoryId: editor.category.id, ...changes }, ...records]
      : records.map(item => item.id === id ? { ...item, ...changes } : item);
    const persisted = await saveRecords(next);
    const text = adding ? '藏品已添加' : editor.mode === 'opening' ? '开封记录已保存' : '藏品已更新';
    setNotice({ text: persisted ? text : text + '，但未保存到本机' });
    if (adding) openRecord(id);
    return true;
  };

  const logUse = async id => {
    const use = { id: crypto.randomUUID(), date: todayInShanghai() };
    const next = records.map(item => item.id === id ? { ...item, uses: [...(item.uses ?? []), use] } : item);
    try {
      const persisted = await saveRecords(next);
      setNotice({ text: '已记下今天的一次使用' + (persisted ? '' : '，但未保存到本机'), undo: { type: 'use', id, useId: use.id } });
    } catch (error) { setNotice({ text: error.message || '未能保存使用记录，请重试。' }); }
  };

  const undoNotice = async () => {
    const undo = notice?.undo;
    if (!undo) return;
    const next = undo.type === 'delete'
      ? [undo.record, ...records.filter(item => item.id !== undo.record.id)]
      : records.map(item => item.id === undo.id ? { ...item, uses: (item.uses ?? []).filter(use => use.id !== undo.useId) } : item);
    const label = undo.type === 'delete' ? `已恢复「${undo.record.name}」` : '已撤销这次使用';
    try {
      const persisted = await saveRecords(next);
      setNotice({ text: persisted ? label : label + '，但未保存到本机' });
    } catch (error) { setNotice({ text: error.message || '未能撤销，请重试。' }); }
  };

  const deleteRecord = async () => {
    const target = records.find(item => item.id === editor.id);
    if (!target) return;
    const persisted = await saveRecords(records.filter(item => item.id !== target.id));
    setNotice({ text: `已删除「${target.name}」` + (persisted ? '' : '，但未保存到本机'), undo: { type: 'delete', record: target } });
    if (page === 'item') backTo('category');
  };

  const exportBackup = () => {
    const blob = new Blob([JSON.stringify({ version: 2, records }, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = Object.assign(document.createElement('a'), { href: url, download: `vanity-backup-${todayInShanghai()}.json` });
    document.body.append(link);
    link.click();
    link.remove();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  };

  const importBackup = async file => {
    if (!file) return;
    try {
      const parsed = JSON.parse(await file.text());
      const list = Array.isArray(parsed) ? parsed : parsed?.records;
      const { records: incoming, skipped } = normalizeRecords(list);
      const fresh = incoming.filter(item => !records.some(old => old.id === item.id));
      if (!fresh.length) { setNotice({ text: incoming.length ? '这些藏品都已存在' : '文件里没有可导入的藏品' }); return; }
      const persisted = await saveRecords(mergeCollections(records, fresh));
      setNotice({ text: `已导入 ${fresh.length} 件藏品` + (skipped ? `，跳过 ${skipped} 条无效记录` : '') + (persisted ? '' : '，但未保存到本机') });
      indexDialog.current?.close();
    } catch {
      setNotice({ text: '无法读取这个文件，请选择 Vanity 导出的 JSON' });
    }
  };

  const importable = legacy.filter(old => !records.some(item => item.id === old.id));
  const importOldRecords = async () => {
    if (!importable.length) { setNotice({ text: '未找到可导入的旧藏品' }); return; }
    try {
      const persisted = await saveRecords(mergeCollections(records, importable));
      setNotice({ text: persisted ? '旧藏品已导入' : '旧藏品已导入，但未保存到本机' });
    } catch (error) {
      setNotice({ text: error.message || '未能导入旧藏品，请重试。' });
    }
  };

  useEffect(() => {
    if (!notice) return undefined;
    const timeout = window.setTimeout(() => setNotice(null), notice.undo ? 8000 : 4000);
    return () => window.clearTimeout(timeout);
  }, [notice]);

  useEffect(() => watchExternalChanges(() => setExternalChange(true)), []);

  return (
    <>
      {page === 'item' ? (
        <RecordPage key={record.id} category={category} record={record} onReturn={() => backTo('category')} onIndex={browseIndex} onUse={logUse} onEdit={id => setEditor({ mode: 'edit', id, category })} onOpening={id => setEditor({ mode: 'opening', id, category })} themeControl={themeControl} />
      ) : page === 'category' ? (
        <CategoryPage key={category.id} category={category} records={records.filter(item => item.categoryId === category.id)} onReturn={() => backTo('cover')} onIndex={browseIndex} onRecord={openRecord} onUse={logUse} onAdd={() => setEditor({ mode: 'add', category })} fromFrame={fromFrame.current} restoreId={lastRecord.current} themeControl={themeControl} />
      ) : (
        <main className="app">
          <header className="brand">
            <VanityMark />
          </header>
          <div className="cover-tools header-tools"><button className="quiet-button" onClick={browseIndex}>全部分类</button>{themeControl}</div>
          <div className="app__stage">
            <CircularCarousel
              items={items}
              controlsRef={carousel}
              initialIndex={coverIndex.current}
              showcase
              intro={hasVisitedCategory.current || coverEntered.current ? 'none' : 'assemble'}
              cardWidth={260}
              gap={21}
              scale={1.22}
              autoplay="drift"
              speed={12}
              pauseOnHover
              draggable
              focusOnClick={false}
              onChange={setActive}
              onItemClick={(item, index) => openCategory(item, carousel.current?.currentFrame(index))}
              parallax={0.12}
              cornerRadius={14}
              offsetY={0.02}
              compactOffsetY={-0.035}
              fadeColor="var(--carousel-shade)"
            />
          </div>
          <div className="cover-caption">
            <button type="button" className="cover-caption__step" aria-label="上一个分类" onClick={() => carousel.current?.stepBy(-1)}><Chevron left /></button>
            <div className="cover-caption__label">
              <p className="cover-caption__count">{String(active + 1).padStart(2, '0')} / {items.length}</p>
              <h2>{current.title}</h2>
              <RouteLink className="cover-caption__open" href={categoryHash(current)} ref={coverAction} onNavigate={() => openCategory(current, carousel.current?.currentFrame(active))}>
                查看{current.title} <Chevron />
              </RouteLink>
            </div>
            <button type="button" className="cover-caption__step" aria-label="下一个分类" onClick={() => carousel.current?.stepBy(1)}><Chevron /></button>
          </div>
        </main>
      )}
      <dialog className="category-index" ref={indexDialog} aria-labelledby="category-title" onClick={event => {
        if (event.target === event.currentTarget) event.currentTarget.close();
      }}>
        <div className="category-index__body">
          <header>
            <h2 id="category-title">全部分类</h2>
            <form method="dialog"><button type="submit" aria-label="关闭分类目录">×</button></form>
          </header>
          <ul>
            {items.map(item => (
              <li key={item.id}>
                {item.id === category?.id && page === 'category' ? (
                  <div aria-current="page"><span>{item.title}</span><span aria-label="当前分类">✓</span></div>
                ) : (
                  <RouteLink href={categoryHash(item)} onNavigate={() => openCategory(item)}>
                    <span>{item.title}</span><Chevron />
                  </RouteLink>
                )}
              </li>
            ))}
          </ul>
          <footer className="category-index__backup">
            <button type="button" onClick={exportBackup} disabled={!records.length}>导出备份</button>
            <label>导入备份<input type="file" accept="application/json,.json" hidden onChange={event => { importBackup(event.target.files?.[0]); event.target.value = ''; }} /></label>
          </footer>
        </div>
      </dialog>
      {editor && <CollectionEditor category={editor.category} mode={editor.mode} record={records.find(item => item.id === editor.id)} onClose={() => setEditor(null)} onSave={saveEditor} onDelete={deleteRecord} />}
      {storage === 'memory' ? (
        <div className="system-region" role="alert"><span>当前浏览器禁止保存数据，关闭页面后藏品会丢失</span></div>
      ) : externalChange ? (
        <div className="system-region" role="status">
          <span>数据已在其他页签更新，请刷新后重试</span>
          <button type="button" onClick={() => window.location.reload()}>刷新</button>
        </div>
      ) : importable.length > 0 && !importDismissed ? (
        <div className="system-region" role="status">
          <span>此浏览器有 {importable.length} 件旧藏品</span>
          <button type="button" onClick={importOldRecords}>导入此浏览器的藏品</button>
          <button type="button" onClick={() => setImportDismissed(true)}>稍后</button>
        </div>
      ) : null}
      <div className="notice-region">
        <div role="status">{notice?.text}</div>
        {notice?.undo && <><button type="button" onClick={undoNotice}>撤销</button><button type="button" aria-label="关闭提示" onClick={() => setNotice(null)}>×</button></>}
      </div>
    </>
  );
}


