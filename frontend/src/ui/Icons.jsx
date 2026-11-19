/* 线性图标，风格参照 SF Symbols：1.8 描边、圆角端点。 */
const base = {
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 1.8,
  strokeLinecap: 'round',
  strokeLinejoin: 'round',
  'aria-hidden': true,
  focusable: false
};

const make = paths => function Icon({ size = 22, ...props }) {
  return <svg width={size} height={size} {...base} {...props}>{paths}</svg>;
};

export const IconGrid = make(<><rect x="3.5" y="3.5" width="7" height="7" rx="2" /><rect x="13.5" y="3.5" width="7" height="7" rx="2" /><rect x="3.5" y="13.5" width="7" height="7" rx="2" /><rect x="13.5" y="13.5" width="7" height="7" rx="2" /></>);
export const IconClock = make(<><circle cx="12" cy="12" r="8.5" /><path d="M12 7.5V12l3 2" /></>);
export const IconGear = make(<><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1Z" /></>);
export const IconSearch = make(<><circle cx="10.5" cy="10.5" r="6.5" /><path d="m20 20-4.8-4.8" /></>);
export const IconPlus = make(<path d="M12 5v14M5 12h14" />);
export const IconChevronLeft = make(<path d="m15 5-7 7 7 7" />);
export const IconChevronRight = make(<path d="m9 5 7 7-7 7" />);
export const IconCheck = make(<path d="m5 12.5 4.5 4.5L19 7.5" />);
export const IconClockFill = make(<><circle cx="12" cy="12" r="9" fill="currentColor" stroke="none" /><path d="M12 7.5V12l2.8 1.8" stroke="var(--icon-knockout, #fff)" /></>);
export const IconAlertFill = make(<><circle cx="12" cy="12" r="9" fill="currentColor" stroke="none" /><path d="M12 7.5v5.5" stroke="var(--icon-knockout, #fff)" /><path d="M12 16.4v.1" stroke="var(--icon-knockout, #fff)" strokeWidth="2.4" /></>);
export const IconSort = make(<><path d="M7 4v16M3.5 16.5 7 20l3.5-3.5" /><path d="M17 20V4M13.5 7.5 17 4l3.5 3.5" /></>);
export const IconXCircle = make(<><circle cx="12" cy="12" r="9" fill="currentColor" stroke="none" /><path d="m9 9 6 6M15 9l-6 6" stroke="var(--icon-knockout, #fff)" strokeWidth="1.8" /></>);
export const IconCalendarPlus = make(<><rect x="3.5" y="5" width="17" height="15" rx="3" /><path d="M3.5 10h17M8 3v4M16 3v4M12 13v5M9.5 15.5h5" /></>);
export const IconSeal = make(<><path d="M12 3.2 14 5l2.7-.3.8 2.6 2.4 1.3-.9 2.5.9 2.5-2.4 1.3-.8 2.6L14 19l-2 1.8L10 19l-2.7.3-.8-2.6-2.4-1.3.9-2.5-.9-2.5 2.4-1.3.8-2.6L10 5Z" /></>);
export const IconTrash = make(<><path d="M4.5 7h15M9.5 7V4.5h5V7M6.5 7l1 13h9l1-13" /></>);
export const IconExport = make(<><path d="M12 15V3.5M7.5 8 12 3.5 16.5 8" /><path d="M5 12v6.5A1.5 1.5 0 0 0 6.5 20h11a1.5 1.5 0 0 0 1.5-1.5V12" /></>);
export const IconImport = make(<><path d="M12 3.5V15M7.5 10.5 12 15l4.5-4.5" /><path d="M5 12v6.5A1.5 1.5 0 0 0 6.5 20h11a1.5 1.5 0 0 0 1.5-1.5V12" /></>);
export const IconLink = make(<><path d="M10 14a4.5 4.5 0 0 0 6.4 0l3-3a4.5 4.5 0 0 0-6.4-6.4l-1 1" /><path d="M14 10a4.5 4.5 0 0 0-6.4 0l-3 3a4.5 4.5 0 0 0 6.4 6.4l1-1" /></>);
/** 中性占位：一只简笔瓶子，不用 emoji。 */
export const IconJar = make(<><rect x="6.5" y="9" width="11" height="11" rx="3" /><path d="M8.5 9V6.5A1.5 1.5 0 0 1 10 5h4a1.5 1.5 0 0 1 1.5 1.5V9" /></>);
