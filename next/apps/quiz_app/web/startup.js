(() => {
  if (location.hash.split('?')[0] === '#/atlas/map-preview') {
    const atlasEngine = document.createElement('link');
    atlasEngine.rel = 'modulepreload';
    // Keep this URL in sync with the web map engine loader.
    atlasEngine.href = 'https://unpkg.com/maplibre-gl@6.4.1/dist/maplibre-gl.mjs';
    document.head.append(atlasEngine);
  }
  const startup = document.getElementById('app-startup');
  const message = document.getElementById('startup-message');
  const retry = document.getElementById('startup-retry');
  const delayed = window.setTimeout(() => {
    message.textContent = 'Первый запуск может занять больше времени: загружается приложение. Проверьте подключение, если загрузка не завершается.';
    retry.hidden = false;
  }, 15000);
  retry.addEventListener('click', () => window.location.reload());
  window.addEventListener('flutter-first-frame', () => {
    window.clearTimeout(delayed);
    startup.remove();
  }, { once: true });
  // Capture failures of the app bootstrap without hiding the retry action.
  window.addEventListener('error', (event) => {
    if (event.target?.id !== 'flutter-startup') return;
    window.clearTimeout(delayed);
    message.textContent = 'Не удалось загрузить приложение. Проверьте подключение и повторите попытку.';
    retry.hidden = false;
  }, true);
})();
