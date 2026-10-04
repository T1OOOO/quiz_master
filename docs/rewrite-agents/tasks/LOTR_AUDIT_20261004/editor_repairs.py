"""Additional source-checked editor fixes; independent final review still required."""
import json
from pathlib import Path

TASK = Path(__file__).resolve().parent
APP_A = 'https://thefreenovelsread.com/the-return-of-the-king/book-vi-appendix-a-128582'
APP_B = 'https://thefreenovelsread.com/the-return-of-the-king/book-vi-appendix-b-128583'
HOBBIT = 'https://ae-lib.org.ua/texts-c/tolkien__the_hobbit__en.htm'
path = TASK/'revised-return-king/lotr_return_king_bts_100.json'
pack = json.loads(path.read_text(encoding='utf-8'))
fixes = {
    'lotr_rk_19': {
        'text':'О каких двух участниках Братства говорится в Приложении A, что они вместе отплыли на Запад?',
        'options':['Гимли и Леголас','Мерри и Пиппин','Арагорн и Боромир','Сэм и Мерри','Гэндальф и Пиппин','Фродо и Сэм'],
        'correct_answer':0,
        'explanation':'В разделе «Народ Дурина» передано предание о том, что Леголас взял с собой Гимли, отправляясь за Море.',
        'source':APP_A+'; Appendix A III, Durin’s Folk, final note'},
    'lotr_rk_67': {
        'text':'Из каких материалов гномы Гимли сделали новые ворота Минас Тирита, согласно Приложению A?',
        'options':['Мифрил и сталь','Золото и серебро','Бронза и медь','Гранит и железо','Дуб и бронза','Мрамор и золото'],
        'correct_answer':0,
        'explanation':'Гномы Гимли выковали для Минас Тирита ворота из мифрила и стали взамен разрушенных Королём-чародеем.',
        'source':APP_A+'; Appendix A III, Durin’s Folk, works of Gimli'},
    'lotr_rk_55': {
        'text':'Под какой горой находился дом гномов, захваченный Смаугом в «Хоббите»?',
        'options':['Эребор','Карадрас','Ородруин','Миндоллуин','Гундабад','Зиракзигиль'],
        'correct_answer':0,
        'explanation':'Дом гномов находился под Эребором, Одинокой горой, которую захватил Смауг.',
        'source':HOBBIT+'; An Unexpected Party, Thorin tells of the Mountain'},
    'lotr_rk_92': {
        'text':'В каком году Третьей Эпохи Бильбо нашёл Кольцо в пещере Голлума?',
        'options':['2901','2921','2941','2961','2981','3001'],
        'correct_answer':2,
        'explanation':'«Повесть лет» в Приложении B относит находку Бильбо к 2941 году Третьей Эпохи.',
        'source':APP_B+'; Appendix B, Third Age, entry 2941'},
    'lotr_rk_30': {
        'text':'Какой следопыт принёс Арагорну знамя, сделанное Арвен, в книге «Возвращение короля»?',
        'options':['Халбарад','Берегонд','Дамрод','Маблунг','Имрахиль','Эомер'],
        'correct_answer':0,
        'explanation':'Халбарад принёс Арагорну знамя от Арвен, когда Серая дружина прибыла из северных земель.',
        'source':'https://ae-lib.org.ua/texts-c/tolkien__the_lord_of_the_rings_3__en.htm; Book V, The Passing of the Grey Company'},
    'lotr_rk_5': {
        'text':'Каким титулом называют предводителя Клятвопреступников в фильме «Возвращение короля»?',
        'explanation':'В фильме это Король Мёртвых; в книге предводитель назван Королём Гор.',
        'source':'https://imsdb.com/scripts/Lord-of-the-Rings-Return-of-the-King.html; Paths of the Dead; '+APP_A},
    'lotr_rk_18': {
        'explanation':'Одного из сыновей Сэма и Рози назвали Фродо в честь Фродо Бэггинса. Их первым ребёнком была дочь Эланор.',
        'source':APP_B+'; Third Age3021 firstborn Elanor; source family framing in Prologue'},
    'lotr_rk_50': {
        'text':'За какую песню фильм «Возвращение короля» получил «Оскар» в категории «Лучшая песня»?',
        'options':['Into the West','May It Be','Gollum’s Song','The Last Goodbye','I See Fire','Song of the Lonely Mountain'],
        'correct_answer':0,
        'explanation':'На церемонии 2004 года «Оскар» за лучшую песню получила Into the West; авторами указаны Фрэн Уолш, Говард Шор и Энни Леннокс.',
        'source':'https://www.oscars.org/oscars/ceremonies/2004; Music Original Song, Into the West'},
}
records = []
for q in pack['questions']:
    if q['id'] not in fixes: continue
    fix = fixes[q['id']]
    original = dict(q)
    q.update({k:v for k,v in fix.items() if k!='source'})
    records.append({'id':q['id'],'before':original,'after':dict(q),'source':fix['source']})
assert len(records)==8
path.write_bytes((json.dumps(pack,ensure_ascii=False,indent=2)+'\n').encode())
(TASK/'editor-repairs.json').write_bytes((json.dumps({'records':records},ensure_ascii=False,indent=2)+'\n').encode())
print('Prepared eight additional editor repairs; no production source changes.')
