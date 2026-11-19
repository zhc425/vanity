import { useRef } from 'react';
import { displayPrice } from '../collection.js';
import { totalSpent, totalUses } from '../format.js';
import { IconChevronRight, IconExport, IconImport, IconLink } from '../ui/Icons.jsx';
import { LargeTitle, NavBar, useCollapsedTitle } from '../ui/parts.jsx';

const themes = [
  { value: 'auto', label: '自动' },
  { value: 'light', label: '浅色' },
  { value: 'dark', label: '深色' }
];

export default function SettingsView({ records, theme, onTheme, onExport, onImport }) {
  const [titleRef, collapsed] = useCollapsedTitle();
  const file = useRef(null);
  const spent = totalSpent(records);
  return (
    <div className="page">
      <NavBar title="设置" collapsed={collapsed} />
      <div className="content">
        <LargeTitle titleRef={titleRef} focusOnMount={false}>设置</LargeTitle>

        <section className="section" aria-labelledby="appearance-title">
          <h2 id="appearance-title" className="section-header">外观</h2>
          <div className="group">
            <div className="cell">
              <div className="segmented" role="radiogroup" aria-labelledby="appearance-title">
                {themes.map(item => (
                  <button key={item.value} type="button" role="radio" aria-checked={theme === item.value}
                    className="segmented__item" onClick={() => onTheme(item.value)}>{item.label}</button>
                ))}
              </div>
            </div>
          </div>
          <p className="section-footer">“自动”会跟随系统的浅色或深色外观。</p>
        </section>

        <section className="section" aria-labelledby="stats-title">
          <h2 id="stats-title" className="section-header">统计</h2>
          <div className="group">
            <div className="cell"><span className="cell__label">藏品</span><span className="cell__value">{records.length} 件</span></div>
            <div className="cell"><span className="cell__label">累计使用</span><span className="cell__value">{totalUses(records)} 次</span></div>
            <div className="cell"><span className="cell__label">记录的花费</span><span className="cell__value">{spent ? displayPrice({ minorUnits: spent, currency: 'CNY' }) : '未记录'}</span></div>
          </div>
        </section>

        <section className="section" aria-labelledby="data-title">
          <h2 id="data-title" className="section-header">数据</h2>
          <div className="group">
            <button type="button" className="cell cell--button cell--accent" onClick={onExport} disabled={!records.length}>
              <span className="cell__label"><IconExport size={20} />导出备份 JSON</span>
            </button>
            <button type="button" className="cell cell--button cell--accent" onClick={() => file.current?.click()}>
              <span className="cell__label"><IconImport size={20} />从备份导入</span>
            </button>
            <input ref={file} type="file" accept="application/json,.json" hidden
              onChange={event => { onImport(event.target.files?.[0]); event.target.value = ''; }} />
          </div>
          <p className="section-footer">导入只会添加新的藏品，不会覆盖已有记录。</p>
        </section>

        <section className="section" aria-labelledby="about-title">
          <h2 id="about-title" className="section-header">关于</h2>
          <div className="group">
            <div className="cell"><span className="cell__label">版本</span><span className="cell__value">1.1.0</span></div>
            <a className="cell cell--button" href="https://github.com/zhc425/vanity" target="_blank" rel="noreferrer">
              <span className="cell__label"><IconLink size={20} className="cell__icon" />GitHub</span>
              <span className="cell__value">zhc425/vanity<IconChevronRight size={16} className="cell__chevron" /></span>
            </a>
          </div>
          <p className="section-footer">所有数据仅保存在本机。</p>
        </section>
      </div>
    </div>
  );
}
