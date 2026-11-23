/* Shared theme state. Storage failures retain a working in-memory preference. */
(() => {
  'use strict';
  const key = 'syncpilot:theme';
  const root = document.documentElement;
  const system = window.matchMedia('(prefers-color-scheme: dark)');
  const valid = value => ['system', 'light', 'dark'].includes(value);
  let preference = 'system';
  try { const saved = localStorage.getItem(key); if (valid(saved)) preference = saved; } catch {}
  const effective = () => preference === 'system' ? (system.matches ? 'dark' : 'light') : preference;
  function apply() {
    const theme = effective();
    root.dataset.theme = theme;
    root.dataset.themePreference = preference;
    document.querySelectorAll('.theme-toggle').forEach(button => {
      const current = theme === 'dark' ? '深色' : '浅色';
      const next = theme === 'dark' ? '浅色' : '深色';
      const mode = preference === 'system' ? `跟随系统（${current}）` : current;
      const label = `当前主题：${mode}；切换为${next}。Shift 加点击或 Shift 加回车恢复跟随系统`;
      button.setAttribute('aria-label', label);
      button.setAttribute('aria-pressed', String(theme === 'dark'));
      button.title = label;
    });
  }
  function set(value) {
    if (!valid(value)) return;
    preference = value;
    try { if (value === 'system') localStorage.removeItem(key); else localStorage.setItem(key, value); } catch {}
    apply();
  }
  apply();
  system.addEventListener('change', () => { if (preference === 'system') apply(); });
  window.addEventListener('storage', event => {
    if (event.key !== key && event.key !== null) return;
    preference = valid(event.newValue) ? event.newValue : 'system';
    apply();
  });
  function bind() {
    document.querySelectorAll('.theme-toggle').forEach(button => {
      button.addEventListener('click', event => set(event.shiftKey ? 'system' : effective() === 'dark' ? 'light' : 'dark'));
      button.addEventListener('keydown', event => {
        if (event.shiftKey && ['Enter', ' '].includes(event.key)) { event.preventDefault(); set('system'); }
      });
    });
    apply();
  }
  window.SyncPilotTheme = Object.freeze({ set, get preference() { return preference; }, get effective() { return effective(); } });
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', bind, { once: true }); else bind();
})();
