// Pipe into: agent-browser --session <owned-session> eval --stdin
// Run only on the generated local study reader, not production.
(async () => {
  const check = (condition, message) => { if (!condition) throw Error(message); };
  const results = [];
  for (const module of modules) {
    article(module.metadata.id);
    startQuiz();
    check(new Set(questions.map(q => q.id)).size === 20, 'Unique question IDs');
    for (let n = 0; n < 20; n++) {
      const question = questions[n];
      const original = module.questions.find(q => q.id === question.id);
      check(question.options[question.correct_answer] === original.options[original.correct_answer], 'Shuffled answer mapping');
      const wrong = n === 0;
      const selected = wrong ? (question.correct_answer + 1) % 4 : question.correct_answer;
      document.querySelector('[data-answer="' + selected + '"]').click();
      check(!feedback.hidden, 'Feedback modal is visible');
      check(document.getElementById('feedback-explanation').textContent === question.explanation, 'Explanation matches key');
      if (wrong) check(timer === null, 'Incorrect answer waits for Continue');
      else {
        document.getElementById('pause').click();
        check(timer === null, 'Pause cancels transition');
      }
      document.getElementById('next').click();
    }
    check(answers.length === 20 && answers.filter(a => a.correct).length === 19, 'Round score');
    results.push(module.metadata.id + ': 20 mappings, explanations, modal, pause and score PASS');
  }
  article(modules[0].metadata.id);
  startQuiz();
  document.querySelector('[data-answer="' + questions[0].correct_answer + '"]').click();
  await new Promise(resolve => setTimeout(resolve, 1200));
  check(questionIndex === 1 && feedback.hidden, 'One-second auto advance');
  check(document.activeElement === main.querySelector('h1'), 'Next question receives keyboard focus');
  results.push('One-second auto advance PASS');
  document.getElementById('home').click();
  return results;
})()
