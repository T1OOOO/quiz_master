"""Finite local-practice checks using observed agent-browser accessibility refs."""
import json
import base64
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(os.environ.get('QM_MOBILE_QA_OUTPUT', str(Path(__file__).resolve().parent)))
ROOT.mkdir(parents=True, exist_ok=True)
URL = os.environ.get('QM_MOBILE_QA_URL', 'http://127.0.0.1:8791/#/quizipedia')
SESSION = 'feedback_20261019'
CLI = shutil.which('agent-browser.cmd') or shutil.which('agent-browser')
LABELS = {
    'countries': 'Страны мира', 'sky': 'Атлас созвездий',
    'endocrine': 'Эндокринная система', 'landmarks': 'Фотографии достопримечательностей',
    'organs': 'Атлас органов и желёз', 'music': 'Музыка: ноты',
    'history': 'История человечества', 'works': 'Фильмы, книги и опера',
    'people': 'Люди и их произведения', 'brands': 'Бренды и компании',
    'food': 'Блюда и кухни мира', 'greek': 'Древнегреческие боги',
    'religions': 'Религии и традиции',
}

def command(*args):
    result = subprocess.run([CLI, '--session', SESSION, *args, '--json'],
                            capture_output=True, text=True, encoding='utf-8', timeout=40)
    response = json.loads(result.stdout)
    if result.returncode or not response.get('success'):
        if args[0] in ('open', 'reload') and 'outcome_unknown' in str(response):
            subprocess.run([CLI, '--session', SESSION, 'doctor', '--offline', '--quick'],
                           capture_output=True, timeout=40)
            current = command('get', 'url')
            if current.get('url') == (args[1] if args[0] == 'open' else URL):
                return current
        raise RuntimeError((args, response, result.stderr))
    return response['data']

def wheel(amount):
    panes = command('eval', "Array.from(document.querySelectorAll('flt-semantics')).filter(e=>e.clientHeight>160 && e.scrollHeight>e.clientHeight+20 && getComputedStyle(e).overflowY==='scroll').map(e=>({id:e.id,height:e.clientHeight})).sort((a,b)=>b.height-a.height)").get('result', [])
    if panes:
        command('scroll', 'down' if amount > 0 else 'up', str(abs(amount)), '--selector', '#' + panes[0]['id'])
    else:
        command('mouse', 'move', '195', '420')
        command('mouse', 'wheel', str(amount))


def snapshot(interactive=True):
    return command('snapshot', *(['-i'] if interactive else []))

def ref_named(name, prefix=False):
    for _ in range(6):
        data = snapshot()
        for ref, value in data.get('refs', {}).items():
            if value['role'] == 'button' and (value['name'].startswith(name) if prefix else value['name'] == name):
                return ref
        wheel(420)
    raise AssertionError(f'No observed button: {name}')

def click(ref):
    command('scrollintoview', '@' + ref)
    for _ in range(10):
        box = command('get', 'box', '@' + ref)
        box = box.get('box', box)
        y = box['y'] + box['height'] / 2
        if 8 <= y <= 700:
            command('click', '@' + ref)
            return
        wheel(320 if y > 700 else -320)
    raise AssertionError(f'Cannot bring observed ref {ref} into phone viewport')

def ready(name):
    for _ in range(20):
        data = snapshot()
        if any(value.get('name') == name for value in data.get('refs', {}).values()):
            return data
        for ref, value in data.get('refs', {}).items():
            if value.get('name') == 'Enable accessibility':
                command('eval', '-b', base64.b64encode(b"document.querySelector('flt-semantics-placeholder').click()").decode())
        if name == 'Завершить':
            wheel(320)
        time.sleep(.1)
    raise AssertionError(f'Page did not expose {name}')

def save(name):
    (ROOT / (name + '.txt')).write_text(snapshot(False)['snapshot'], encoding='utf-8')
    command('screenshot', str(ROOT / (name + '.png')))

def options():
    data = ready('К списку фактов')
    excluded = {'Назад', 'Проверить', 'К списку фактов', 'Отправить отзыв', 'Завершить', 'Дальше'}
    return [(r, v['name']) for r, v in data['refs'].items() if v['role'] == 'button' and v['name'] not in excluded]

def grade(option):
    click(option)
    ready('Завершить')
    value = snapshot(False)['snapshot']
    match = re.search(r'Правильный ответ: (.*)"\s*$', value, re.M)
    assert match, value
    answer = match.group(1)
    return answer, 'group "Верно Правильный ответ:' in value

def first_fact():
    excluded = {'Назад', 'Начать тренировку', 'Отправить отзыв'}
    for _ in range(5):
        data = snapshot()
        candidates = [(r, v['name']) for r, v in data['refs'].items() if v['role'] == 'button'
                      and v['name'] not in excluded and not v['name'].startswith(('Тип факта', 'Раздел'))]
        if candidates:
            return candidates[0]
        wheel(300)
    raise AssertionError('No individual fact is reachable')

def check(scope):
    print(f'{scope}: opening section', flush=True)
    command('open', URL)
    command('reload')
    for ref, item in snapshot().get('refs', {}).items():
        if item['name'] == 'Enable accessibility':
            command('eval', '-b', base64.b64encode(b"document.querySelector('flt-semantics-placeholder').click()").decode())
            break
    ready('Квизипедия')
    click(ref_named(LABELS[scope], prefix=True))
    ready('Вопросы по всем фактам')
    save(scope + '-explore')
    click(ref_named('Вопросы по всем фактам'))
    ready('Начать тренировку')
    print(f'{scope}: fact bank loaded', flush=True)
    fact_ref, fact_name = first_fact()
    click(fact_ref)
    initial = options()
    answer, was_correct = grade(initial[0][0])
    if was_correct:
        click(ref_named('К списку фактов'))
        ready('Начать тренировку')
        click(ref_named(fact_name))
        choices = options()
        wrong = next(r for r, name in choices if name != answer)
        _, was_correct = grade(wrong)
        assert not was_correct
    save(scope + '-wrong')
    click(ref_named('Завершить'))
    ready('Повторить ошибки')
    click(ref_named('Повторить ошибки'))
    choices = options()
    correct = ref_named(answer)
    _, was_correct = grade(correct)
    assert was_correct
    save(scope + '-correct')
    click(ref_named('Завершить'))
    ready('Следующий раунд')
    summary = snapshot(False)['snapshot']
    assert 'Верных ответов: 1 из 1' in summary, summary
    result = {'scope': scope, 'fact': fact_name, 'wrong_checked': True, 'retry_correct_checked': True, 'score': '1/1'}
    (ROOT / (scope + '-browser.json')).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(result, ensure_ascii=False), flush=True)

if __name__ == '__main__':
    for selected_scope in sys.argv[1:]:
        if selected_scope not in LABELS:
            raise ValueError(selected_scope)
        check(selected_scope)
