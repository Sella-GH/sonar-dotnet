(function () {
  var STORAGE_KEY = 'theme';
  var LABELS = { auto: 'Auto', light: 'Light', dark: 'Dark' };
  var NEXT = { auto: 'light', light: 'dark', dark: 'auto' };
  var ICONS = {
    auto: '<svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="14" rx="2"></rect><line x1="8" y1="21" x2="16" y2="21"></line><line x1="12" y1="18" x2="12" y2="21"></line></svg>',
    light: '<svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>',
    dark: '<svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true" fill="currentColor"><path d="M12 3a9 9 0 1 0 9 9 7 7 0 0 1-9-9z"></path></svg>'
  };

  function readStoredTheme() {
    try {
      return localStorage.getItem(STORAGE_KEY);
    } catch (e) {
      return null;
    }
  }

  function writeStoredTheme(mode) {
    try {
      if (mode === 'auto') {
        localStorage.removeItem(STORAGE_KEY);
      } else {
        localStorage.setItem(STORAGE_KEY, mode);
      }
    } catch (e) {
      /* localStorage unavailable (e.g. private mode) - theme just won't persist */
    }
  }

  function updateThemeColorMetas(mode) {
    var effectiveIsDark = mode === 'dark' || (mode === 'auto' && matchMedia('(prefers-color-scheme: dark)').matches);
    var color = effectiveIsDark ? '#16181d' : '#ffffff';
    var metas = document.querySelectorAll('meta[name="theme-color"]');
    for (var i = 0; i < metas.length; i++) {
      metas[i].setAttribute('content', color);
    }
  }

  function applyTheme(mode) {
    if (mode === 'light' || mode === 'dark') {
      document.documentElement.setAttribute('data-theme', mode);
    } else {
      document.documentElement.removeAttribute('data-theme');
    }
    updateThemeColorMetas(mode);
  }

  var initialTheme = readStoredTheme() === 'light' || readStoredTheme() === 'dark' ? readStoredTheme() : 'auto';
  applyTheme(initialTheme);

  document.addEventListener('DOMContentLoaded', function () {
    var button = document.getElementById('theme-toggle');
    if (!button) return;

    var current = initialTheme;

    function render() {
      button.innerHTML = ICONS[current];
      button.setAttribute('aria-label', 'Toggle color theme, currently ' + LABELS[current]);
      button.setAttribute('title', 'Theme: ' + LABELS[current]);
    }
    render();

    button.addEventListener('click', function () {
      current = NEXT[current];
      applyTheme(current);
      writeStoredTheme(current);
      render();
    });
  });
})();
