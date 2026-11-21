(() => {
  const isAtlas = () => location.hash.split('?')[0] === '#/atlas/map-preview';
  if (isAtlas()) {
    const atlasEngine = document.createElement('link');
    atlasEngine.rel = 'modulepreload';
    // Keep this URL in sync with the web map engine loader.
    atlasEngine.href = 'https://unpkg.com/maplibre-gl@6.4.1/dist/maplibre-gl.mjs';
    document.head.append(atlasEngine);
  }
  const startup = document.getElementById('app-startup');
  const message = document.getElementById('startup-message');
  const retry = document.getElementById('startup-retry');
  if (isAtlas()) {
    const preview = document.createElement('div');
    preview.id = 'atlas-start-map';
    preview.setAttribute('aria-hidden', 'true');
    const image = new Image();
    let revealed = false;
    const leaveAtlas = () => {
      if (!isAtlas()) revealAtlas();
    };
    const revealAtlas = () => {
      if (revealed) return;
      revealed = true;
      clearTimeout(revealDeadline);
      window.removeEventListener('hashchange', leaveAtlas);
      delete window.quizAtlasLandReady;
      if (preview.isConnected) {
        preview.remove();
        performance.mark('atlas-preview-dismissed');
      }
      startup.classList.remove('atlas-startup');
    };
    const revealDeadline = setTimeout(revealAtlas, 25000);
    window.quizAtlasLandReady = revealAtlas;
    window.addEventListener('hashchange', leaveAtlas);
    image.src = 'atlas-overview.webp';
    image.decode().then(() => {
      if (revealed) return;
      startup.classList.add('atlas-startup');
      message.textContent = 'Загружаем карту…';
      document.body.prepend(preview);
      requestAnimationFrame(() => requestAnimationFrame(() => {
        if (preview.isConnected) performance.mark('atlas-preview-painted');
      }));
    }).catch(revealAtlas);
  }
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
    window.quizAtlasLandReady?.();
    window.clearTimeout(delayed);
    message.textContent = 'Не удалось загрузить приложение. Проверьте подключение и повторите попытку.';
    retry.hidden = false;
  }, true);
})();
