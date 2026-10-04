// Regression check: malformed hashes must not crash or leave the quiz visible.
(async () => {
  article(modules[0].metadata.id);
  startQuiz();
  let routingError = false;
  const onError = () => { routingError = true; };
  window.addEventListener('error', onError);
  try {
    for (const fragment of ['%E0%A4%A', '%']) {
      location.hash = fragment;
      await new Promise(resolve => setTimeout(resolve, 100));
      if (routingError || !main.querySelector('.cards')) throw Error('Malformed hash must route home: ' + fragment);
    }
    document.getElementById('home').click();
    return 'Malformed hash routing PASS';
  } finally {
    window.removeEventListener('error', onError);
  }
})()
