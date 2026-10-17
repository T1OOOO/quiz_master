(() => {
  if (location.hostname !== '127.0.0.1' || window.__qmMediaQA) return;
  const mode = new URL(location.href).searchParams.get('qa_media');
  if (!['broken', 'restored'].includes(mode)) return;
  window.__qmMediaQA = {mode, requests: []};
  function redirect(value, transport) {
    const match = /^https:\/\/quiz\.kotopedia\.org\/flags\/([a-f0-9]{64}\.png)$/.exec(String(value));
    if (!match) return value;
    const local = location.origin + '/qa-media/' + mode + '/' + match[1];
    window.__qmMediaQA.requests.push({transport, original: String(value), local});
    return local;
  }
  const fetchOriginal = window.fetch;
  window.fetch = function(input, options) {
    if (input instanceof Request) {
      const next = redirect(input.url, 'fetch');
      return fetchOriginal.call(this, next === input.url ? input : new Request(next, input), options);
    }
    return fetchOriginal.call(this, redirect(input, 'fetch'), options);
  };
  const openOriginal = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function(method, url, ...args) {
    return openOriginal.call(this, method, redirect(url, 'xhr'), ...args);
  };
})();
