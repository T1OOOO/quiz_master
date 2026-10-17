(async () => {
  const source = await fetch('/public-pack.json').then(r => { if (!r.ok) throw Error('catalog HTTP'); return r.json(); });
  const questions = source.quiz.questions;
  if (questions.length !== 195) throw Error('expected 195 questions');
  async function decode(url, expectedDigest) {
    const response = await fetch(url, {cache: 'no-store'});
    if (response.status !== 200) throw Error('image HTTP ' + response.status);
    if (response.headers.get('content-type').split(';')[0] !== 'image/png') throw Error('image MIME');
    const bytes = await response.arrayBuffer();
    const digest = [...new Uint8Array(await crypto.subtle.digest('SHA-256', bytes))].map(b => b.toString(16).padStart(2, '0')).join('');
    if (digest !== expectedDigest) throw Error('image digest');
    const image = await createImageBitmap(new Blob([bytes], {type: 'image/png'}));
    if (image.width <= 0 || image.height <= 0) throw Error('empty image');
    const result = {url, sha256: digest, width: image.width, height: image.height};
    image.close();
    return result;
  }
  const controls = {};
  for (const [name, url] of [['html_rejected', '/not-a-flag.html'], ['missing_rejected', '/flags/absent.png']]) {
    try { await decode(url, '0'.repeat(64)); controls[name] = false; }
    catch (error) { controls[name] = String(error).includes(name === 'html_rejected' ? 'MIME' : 'HTTP 404'); }
  }
  if (!Object.values(controls).every(Boolean)) throw Error('negative control failed');
  const expected = questions.map(q => {
    if (q.media.length !== 1 || !/^https:\/\/quiz\.kotopedia\.org\/flags\/[a-f0-9]{64}\.png$/.test(q.media[0].uri)) throw Error('unexpected media URI');
    const name = q.media[0].uri.split('/').pop();
    return {question_id: q.question_id, url: '/flags/' + name, digest: name.slice(0, -4)};
  });
  if (new Set(expected.map(x => x.digest)).size !== 195) throw Error('duplicate media identity');
  const images = [];
  for (let start = 0; start < expected.length; start += 8) {
    images.push(...await Promise.all(expected.slice(start, start + 8).map(async item => ({question_id: item.question_id, ...await decode(item.url, item.digest)}))));
  }
  const main = document.createElement('main');
  const title = document.createElement('h1'); title.textContent = 'Media QA: 195 / 195 PNG decoded'; main.append(title);
  const note = document.createElement('p'); note.textContent = 'Isolated asset validation. Flutter, nginx and publication have not been verified.'; main.append(note);
  const gallery = document.createElement('div'); gallery.style.cssText = 'display:grid;grid-template-columns:repeat(4,1fr);gap:20px';
  for (const item of images.filter((_, index) => index % 16 === 0).slice(0, 12)) {
    const figure = document.createElement('figure'); const image = document.createElement('img'); image.src = item.url; image.alt = 'Flag image QA sample'; image.style.cssText = 'width:160px;height:100px;object-fit:contain';
    const caption = document.createElement('figcaption'); caption.textContent = item.question_id; figure.append(image, caption); gallery.append(figure);
  }
  main.append(gallery); document.body.replaceChildren(main);
  document.body.style.cssText = 'font:16px sans-serif;padding:24px;background:#f5f6fa;color:#20232a';
  await Promise.all([...gallery.querySelectorAll('img')].map(img => img.decode()));
  return {status: 'pass_browser_media_only', browser: navigator.userAgent, total: images.length, max_concurrent_fetches: 8, negative_controls: controls, images, flutter_verified: false, container_verified: false, publication_attempted: false};
})()
