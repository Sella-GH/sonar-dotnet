(function () {
  var STORAGE_KEY = 'theme';
  var LABELS = { auto: 'Auto', light: 'Light', dark: 'Dark' };
  var NEXT = { auto: 'light', light: 'dark', dark: 'auto' };

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
      button.textContent = 'Theme: ' + LABELS[current];
      button.setAttribute('aria-label', 'Toggle color theme, currently ' + LABELS[current]);
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
