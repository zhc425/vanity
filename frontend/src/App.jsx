import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react';
import { todayInShanghai } from './collection.js';
import { loadCollection, saveCollection, readLegacyRecords, mergeCollections, normalizeRecords, watchExternalChanges } from './collectionStore.js';
import { categoryById } from './categories.js';
import { expiringSoon } from './format.js';
import { IconCheck, IconClock, IconGear, IconGrid } from './ui/Icons.jsx';
import LibraryView from './views/LibraryView.jsx';
import CategoryView from './views/CategoryView.jsx';
import RecordView from './views/RecordView.jsx';
import ExpiringView from './views/ExpiringView.jsx';
import SettingsView from './views/SettingsView.jsx';
import EditorSheet from './views/EditorSheet.jsx';

const THEME_KEY = 'vanity.theme';
const THEME_COLORS = { light: '#F2F2F7', dark: '#000000' };

/**
 * 路由（hash）：
 *   ''                  藏品首页
 *   #<分类>             分类页
 *   #<分类>/<藏品 id>    藏品详情
 *   #expiring[/<id>]    到期页 / 从到期页打开的详情
 *   #settings           设置
 */
function parseRoute(hash) {
  const [first = '', rawId] = hash.replace(/^#/, '').split('/');
  const recordId = rawId ? decodeURIComponent(rawId) : null;
  if (first === 'expiring') return { tab: 'expiring', recordId };
  if (first === 'settings') return { tab: 'settings', recordId: null };
  if (categoryById(first)) return { tab: 'library', categoryId: first, recordId };
  return { tab: 'library', recordId: null };
}

const recordHash = (record, tab) => (tab === 'expiring' ? '#expiring/' : `#${record.categoryId}/`) + encodeURIComponent(record.id);

function routeLabel(hash) {
  const route = parseRoute(hash ?? '');
  if (route.tab === 'expiring') return '到期';
  if (route.tab === 'settings') return '设置';
  if (route.categoryId && !route.recordId) return categoryById(route.categoryId).title;
  return '藏品';
}

function parentHash(hash) {
  const route = parseRoute(hash);
  if (route.tab === 'expiring') return '#expiring';
  if (route.categoryId && route.recordId) return '#' + route.categoryId;
  return '';
}

const tabs = [
  { id: 'library', hash: '', label: '藏品', Icon: IconGrid },
  { id: 'expiring', hash: '#expiring', label: '到期', Icon: IconClock },
  { id: 'settings', hash: '#settings', label: '设置', Icon: IconGear }
];

function readTheme() {
  try {
    const value = localStorage.getItem(THEME_KEY);
    return value === 'light' || value === 'dark' ? value : 'auto';
  } catch {
    return 'auto';
  }
}

function applyTheme(theme) {
  const root = document.documentElement;
  root.dataset.theme = theme;
  const dark = theme === 'dark' || (theme === 'auto' && window.matchMedia('(prefers-color-scheme: dark)').matches);
  document.querySelector('meta[name="theme-color"]')?.setAttribute('content', dark ? THEME_COLORS.dark : THEME_COLORS.light);
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

  const [theme, setTheme] = useState(readTheme);
  const [hash, setHash] = useState(() => window.location.hash);
  const [direction, setDirection] = useState(null);
  const scrollPositions = useRef(new Map());
  const [editor, setEditor] = useState(null);
  const [notice, setNotice] = useState(null);
  const noticeKey = useRef(0);

  // ---------- 主题 ----------
  useEffect(() => {
    applyTheme(theme);
    if (theme !== 'auto') return undefined;
    const query = window.matchMedia('(prefers-color-scheme: dark)');
    const onChange = () => applyTheme('auto');
    query.addEventListener('change', onChange);
    return () => query.removeEventListener('change', onChange);
  }, [theme]);

  const chooseTheme = value => {
    setTheme(value);
    try {
      if (value === 'auto') localStorage.removeItem(THEME_KEY);
      else localStorage.setItem(THEME_KEY, value);
    } catch { /* 无法保存主题偏好时只在本次生效 */ }
  };

  // ---------- 导航 ----------
  const depth = () => history.state?.vanityDepth ?? 0;

  const navigate = useCallback((target, { animate = true } = {}) => {
    scrollPositions.current.set(window.location.hash, window.scrollY);
    history.pushState({ vanity: true, from: window.location.hash, vanityDepth: depth() + 1 }, '', target || window.location.pathname + window.location.search);
    setDirection(animate ? 'forward' : null);
    setHash(window.location.hash);
  }, []);

  const goBack = useCallback(() => {
    if (history.state?.vanity) {
      history.back();
      return;
    }
    const target = parentHash(window.location.hash);
    history.replaceState(null, '', target || window.location.pathname + window.location.search);
    setDirection('back');
    setHash(window.location.hash);
  }, []);

  useEffect(() => {
    let lastDepth = depth();
    const onPop = () => {
      const nextDepth = depth();
      setDirection(nextDepth < lastDepth ? 'back' : nextDepth > lastDepth ? 'forward' : null);
      lastDepth = nextDepth;
      setHash(window.location.hash);
    };
    const onPush = () => { lastDepth = depth(); };
    window.addEventListener('popstate', onPop);
    window.addEventListener('hashchange', onPop);
    window.addEventListener('vanity:navigated', onPush);
    return () => {
      window.removeEventListener('popstate', onPop);
      window.removeEventListener('hashchange', onPop);
      window.removeEventListener('vanity:navigated', onPush);
    };
  }, []);
  useEffect(() => { window.dispatchEvent(new Event('vanity:navigated')); }, [hash]);

  const route = parseRoute(hash);
  const record = route.recordId ? records.find(item => item.id === route.recordId) : null;
  const category = route.categoryId ? categoryById(route.categoryId) : null;
  const view = record ? 'record' : route.tab === 'library' && category ? 'category' : route.tab;
  const backLabel = routeLabel(history.state?.from ?? parentHash(hash));

  useLayoutEffect(() => {
    document.title = view === 'record' ? `${record.name} · Vanity`
      : view === 'category' ? `${category.title} · Vanity`
      : view === 'expiring' ? '到期 · Vanity'
      : view === 'settings' ? '设置 · Vanity'
      : 'Vanity · 我的美妆藏品';
    // 只在页面切换时调整滚动位置
  }, [view, record?.name, category?.title]);

  useLayoutEffect(() => {
    const saved = direction === 'back' ? scrollPositions.current.get(hash) : null;
    window.scrollTo(0, saved ?? 0);
  }, [hash]);

  const selectTab = tab => {
    if (tab.hash === hash) {
      window.scrollTo({ top: 0, behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth' });
      return;
    }
    navigate(tab.hash, { animate: false });
  };

  // ---------- 存储 ----------
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

  const show = (text, undo = null) => {
    noticeKey.current += 1;
    setNotice({ text, undo, key: noticeKey.current });
  };
  const unsaved = persisted => (persisted ? '' : '，但未保存到本机');

  const saveEditor = async (changes, newCategoryId) => {
    const adding = editor.mode === 'add';
    const id = adding ? crypto.randomUUID() : editor.id;
    // 清空的字段直接移除，保持与 normalizeRecords 一致的存储格式
    const clean = record => Object.fromEntries(Object.entries(record).filter(([, value]) => value !== null && value !== undefined));
    const next = adding
      ? [clean({ id, categoryId: newCategoryId, ...changes }), ...records]
      : records.map(item => (item.id === id ? clean({ ...item, ...changes }) : item));
    const persisted = await saveRecords(next);
    const text = adding ? '藏品已添加' : editor.mode === 'opening' ? '开封记录已保存' : '藏品已更新';
    show(text + unsaved(persisted));
    if (adding) navigate(recordHash({ id, categoryId: newCategoryId }, 'library'));
    return true;
  };

  const logUse = async (id, date = todayInShanghai()) => {
    const use = { id: crypto.randomUUID(), date };
    const next = records.map(item => (item.id === id ? { ...item, uses: [...(item.uses ?? []), use] } : item));
    try {
      const persisted = await saveRecords(next);
      const label = date === todayInShanghai() ? '已记下今天的一次使用' : '已补记一次使用';
      show(label + unsaved(persisted), { type: 'use', id, useId: use.id });
    } catch (error) {
      show(error.message || '未能保存使用记录，请重试。');
    }
  };

  const removeUse = async (id, useId) => {
    const target = records.find(item => item.id === id);
    const use = target?.uses?.find(entry => entry.id === useId);
    if (!use) return;
    const next = records.map(item => (item.id === id ? { ...item, uses: item.uses.filter(entry => entry.id !== useId) } : item));
    try {
      const persisted = await saveRecords(next);
      show('已删除一条使用记录' + unsaved(persisted), { type: 'restoreUse', id, use });
    } catch (error) {
      show(error.message || '未能删除，请重试。');
    }
  };

  const deleteRecord = async id => {
    const target = records.find(item => item.id === id);
    if (!target) return;
    try {
      const persisted = await saveRecords(records.filter(item => item.id !== id));
      show(`已删除「${target.name}」` + unsaved(persisted), { type: 'delete', record: target });
      if (route.recordId === id) goBack();
    } catch (error) {
      show(error.message || '未能删除，请重试。');
    }
  };

  const undoNotice = async () => {
    const undo = notice?.undo;
    if (!undo) return;
    let next;
    let label;
    if (undo.type === 'delete') {
      next = [undo.record, ...records.filter(item => item.id !== undo.record.id)];
      label = `已恢复「${undo.record.name}」`;
    } else if (undo.type === 'restoreUse') {
      next = records.map(item => (item.id === undo.id ? { ...item, uses: [...(item.uses ?? []), undo.use] } : item));
      label = '已恢复这条使用记录';
    } else {
      next = records.map(item => (item.id === undo.id ? { ...item, uses: (item.uses ?? []).filter(use => use.id !== undo.useId) } : item));
      label = '已撤销这次使用';
    }
    try {
      const persisted = await saveRecords(next);
      show(label + unsaved(persisted));
    } catch (error) {
      show(error.message || '未能撤销，请重试。');
    }
  };

  // ---------- 备份 ----------
  const exportBackup = () => {
    const blob = new Blob([JSON.stringify({ version: 2, records }, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = Object.assign(document.createElement('a'), { href: url, download: `vanity-backup-${todayInShanghai()}.json` });
    document.body.append(link);
    link.click();
    link.remove();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
    show('备份已导出');
  };

  const importBackup = async file => {
    if (!file) return;
    try {
      const parsed = JSON.parse(await file.text());
      const list = Array.isArray(parsed) ? parsed : parsed?.records;
      const { records: incoming, skipped } = normalizeRecords(list);
      const fresh = incoming.filter(item => !records.some(old => old.id === item.id));
      if (!fresh.length) { show(incoming.length ? '这些藏品都已存在' : '文件里没有可导入的藏品'); return; }
      const persisted = await saveRecords(mergeCollections(records, fresh));
      show(`已导入 ${fresh.length} 件藏品` + (skipped ? `，跳过 ${skipped} 条无效记录` : '') + unsaved(persisted));
    } catch {
      show('无法读取这个文件，请选择 Vanity 导出的 JSON');
    }
  };

  const importable = legacy.filter(old => !records.some(item => item.id === old.id));
  const importOldRecords = async () => {
    if (!importable.length) { show('未找到可导入的旧藏品'); return; }
    try {
      const persisted = await saveRecords(mergeCollections(records, importable));
      show('旧藏品已导入' + unsaved(persisted));
    } catch (error) {
      show(error.message || '未能导入旧藏品，请重试。');
    }
  };

  useEffect(() => {
    if (!notice) return undefined;
    const timeout = window.setTimeout(() => setNotice(null), notice.undo ? 8000 : 4000);
    return () => window.clearTimeout(timeout);
  }, [notice]);

  useEffect(() => watchExternalChanges(() => setExternalChange(true)), []);

  // ---------- 渲染 ----------
  const badge = expiringSoon(records).length;
  const openRecord = tab => id => {
    const target = records.find(item => item.id === id);
    if (target) navigate(recordHash(target, tab));
  };

  let page;
  if (view === 'record') {
    page = (
      <RecordView key={record.id} record={record} backLabel={backLabel} onBack={goBack}
        onUse={logUse} onRemoveUse={removeUse} onDelete={deleteRecord}
        onEdit={() => setEditor({ mode: 'edit', id: record.id })}
        onOpening={() => setEditor({ mode: 'opening', id: record.id })} />
    );
  } else if (view === 'category') {
    page = (
      <CategoryView key={category.id} category={category} backLabel={backLabel} onBack={goBack}
        records={records.filter(item => item.categoryId === category.id)}
        onRecord={openRecord('library')} onUse={id => logUse(id)}
        onAdd={() => setEditor({ mode: 'add', categoryId: category.id })} />
    );
  } else if (view === 'expiring') {
    page = <ExpiringView records={records} onRecord={openRecord('expiring')} />;
  } else if (view === 'settings') {
    page = <SettingsView records={records} theme={theme} onTheme={chooseTheme} onExport={exportBackup} onImport={importBackup} />;
  } else {
    page = (
      <LibraryView records={records} onCategory={id => navigate('#' + id)} onRecord={openRecord('library')}
        onAdd={categoryId => setEditor({ mode: 'add', categoryId })} />
    );
  }

  return (
    <div className="app">
      <nav className="tabbar material" aria-label="主导航">
        <p className="tabbar__brand" aria-hidden="true">Vanity</p>
        <ul className="tabbar__list">
          {tabs.map(tab => {
            const current = route.tab === tab.id;
            return (
              <li key={tab.id}>
                <button type="button" className="tabbar__item" aria-current={current ? 'page' : undefined} onClick={() => selectTab(tab)}
                  aria-label={tab.id === 'expiring' && badge ? `${tab.label}，${badge} 件需要留意` : tab.label}>
                  <span className="tabbar__icon"><tab.Icon size={24} /></span>
                  <span className="tabbar__label">{tab.label}</span>
                  {tab.id === 'expiring' && badge > 0 && <span className="badge" aria-hidden="true">{badge > 99 ? '99+' : badge}</span>}
                </button>
              </li>
            );
          })}
        </ul>
      </nav>

      <main className="main">
        {storage === 'memory' ? (
          <div className="banner" role="alert"><span>当前浏览器禁止保存数据，关闭页面后藏品会丢失。</span></div>
        ) : externalChange ? (
          <div className="banner" role="status">
            <span>数据已在其他页签更新，请刷新后再继续。</span>
            <button type="button" className="text-button text-button--bold" onClick={() => window.location.reload()}>刷新</button>
          </div>
        ) : importable.length > 0 && !importDismissed ? (
          <div className="banner" role="status">
            <span>此浏览器里还有 {importable.length} 件旧版藏品。</span>
            <button type="button" className="text-button" onClick={() => setImportDismissed(true)}>稍后</button>
            <button type="button" className="text-button text-button--bold" onClick={importOldRecords}>导入</button>
          </div>
        ) : null}
        <div key={hash} className="transition" data-direction={direction ?? undefined}>{page}</div>
      </main>

      {editor && (
        <EditorSheet mode={editor.mode} categoryId={editor.categoryId}
          record={editor.id ? records.find(item => item.id === editor.id) : null}
          onClose={() => setEditor(null)} onSave={saveEditor} />
      )}

      <div className="toast-region" aria-live="polite">
        {notice && (
          <div key={notice.key} className="toast material" role="status">
            <IconCheck size={18} strokeWidth={2.4} className="toast__icon" />
            <span className="toast__text">{notice.text}</span>
            {notice.undo && <button type="button" className="toast__undo" onClick={undoNotice}>撤销</button>}
          </div>
        )}
      </div>
    </div>
  );
}
