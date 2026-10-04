"""Root's proposed repairs; writes reviewable drafts, never production sources."""
import copy
import json
import re
from pathlib import Path

TASK = Path(__file__).resolve().parent
BOOK1 = 'https://ae-lib.org.ua/texts-c/tolkien__the_lord_of_the_rings_1__en.htm'
BOOK2 = 'https://ae-lib.org.ua/texts-c/tolkien__the_lord_of_the_rings_2__en.htm'
BOOK3 = 'https://ae-lib.org.ua/texts-c/tolkien__the_lord_of_the_rings_3__en.htm'
HOBBIT = 'https://ae-lib.org.ua/texts-c/tolkien__the_hobbit__en.htm'
FILM1 = 'https://imsdb.com/scripts/Lord-of-the-Rings-Fellowship-of-the-Ring,-The.html'

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

fixes = {
    'q_lotr_0_lotr-q1': ('Кто упал в огонь Ородруина вместе с Кольцом Всевластия?',None,None,'Голлум завладел Кольцом и упал вместе с ним в огонь; это не было сознательным решением уничтожить Кольцо.',BOOK3,'Book VI, Mount Doom','ambiguity'),
    'lotr_f_1': ('Как называлось жилище Бильбо и Фродо Бэггинсов в Хоббитоне?',None,None,None,BOOK1,'Book I, A Long-expected Party','wording'),
    'lotr_f_4': ('Какой сорт трубочного зелья Бильбо хвалит в фильме «Братство Кольца»?',None,None,'В сцене курения Бильбо называет сорт «Старый Тоби».',FILM1,'Bag End porch scene, Old Toby','canon'),
    'lotr_f_9': ('Какое английское прозвище Арагорна используют жители Бри?', ['Strider','Wormtongue','Evenstar','Oakenshield','Greyhame','Stormcrow'],0,'В английском оригинале жители Бри называют Арагорна Strider.',BOOK1,'Book I, At the Sign of the Prancing Pony / Strider','aliases'),
    'lotr_f_11': ('Кто в фильме «Братство Кольца» увозит раненого Фродо на коне от назгулов?', ['Гэндальф','Арагорн','Арвен','Леголас','Глорфиндел','Элронд'],2,'В фильме Фродо увозит Арвен; в книге коня раненому Фродо предоставляет Глорфиндел.',FILM1,'Flight to the Ford scene', 'canon'),
    'lotr_f_13': ('Чью гробницу Братство находит в Мории?',None,None,None,BOOK1,'Book II, The Bridge of Khazad-dum','kinship'),
    'lotr_f_15': ('Сколько хоббитов вошло в Братство Кольца?', ['2','3','4','5','6','7'],2,'В Братство вошли Фродо, Сэм, Мерри и Пиппин.',BOOK1,'Book II, The Ring Goes South','duplicate'),
    'lotr_f_17': ('Как звали отца Леголаса?',None,None,'Леголас — сын Трандуила.',BOOK1,'Book II, The Mirror of Galadriel, greeting of Legolas','wording'),
    'lotr_f_18': ('Как называлась Мория на языке гномов?', ['Кхазад-дум','Эребор','Железные Холмы','Агларонд','Гундабад','Эред Луин'],0,'Кхазад-дум — гномье название; Мория — эльфийское название этих копей.',BOOK1,'Book II, The Council of Elrond / The Ring Goes South','fact'),
    'lotr_f_21': (None,['Золотую чашу','Драгоценный камень','Её волос','Эльфийский плащ','Секиру','Мифрил'],2,'Гимли попросил один волос Галадриэль; она дала ему три.',BOOK1,'Book II, Farewell to Lorien','precision'),
    'lotr_f_22': ('Как называется пара огромных статуй у Андуина, мимо которых проплывает Братство?', ['Аргонат','Амон Хен','Карадрас','Миндоллуин','Ортханк','Амон Сул'],0,'Аргонат — огромные статуи у реки Андуин, мимо которых проходит Братство.',BOOK1,'Book II, The Great River','canon-explanation'),
    'lotr_f_25': (None,['Тенегрив','Билл','Асфалот','Брего','Хасуфель','Аррод'],1,None,BOOK1,'Book II, A Journey in the Dark','aliases'),
    'lotr_f_27': ('Как называется эльфийский путевой хлеб, полученный Братством в Лориэне?', ['Крам','Лембас','Мирувор','Мёд','Орехи','Сухари'],1,'Эльфы называют свой путевой хлеб лембасом.',BOOK1,'Book II, Farewell to Lorien','quantity-and-alias'),
    'lotr_f_31': ('Какой цвет входил в прозвище Гэндальфа в начале «Братства Кольца»?', ['Серый','Белый','Синий','Чёрный','Красный','Зелёный'],0,'В начале истории он известен как Гэндальф Серый.',FILM1,'Saruman greeting: Gandalf the Grey','unsupported-premise'),
    'lotr_f_32': (None,['Саурон','Балрог','Саруман Белый','Грима Гнилоуст','Король-чародей','Радагаст'],2,None,FILM1,'Isengard betrayal scenes','off-universe-distractor'),
    'lotr_f_33': ('Какое чувство, по словам Гэндальфа, удержало Бильбо от убийства Голлума?', ['Страх','Гордость','Жалость','Зависть','Гнев','Стыд'],2,'Гэндальф объясняет, что Бильбо пощадил Голлума из жалости.',BOOK1,'Book I, The Shadow of the Past','unsupported-quote'),
    'lotr_f_34': ('Какую роль Гэндальф отвёл Бильбо в походе гномов в книге «Хоббит»?', ['Проводника','Взломщика','Переводчика','Лекаря','Кузнеца','Летописца'],1,'Бильбо приглашают в поход как взломщика.',HOBBIT,'An Unexpected Party, Gloin reads the door mark','aliases'),
    'lotr_f_35': ('Как в английском оригинале называется река, протекающая через Хоббитон?', ['Brandywine','Silverlode','The Water','Anduin','Bruinen','Isen'],2,'Река Хоббитона в английском тексте называется The Water; русские названия зависят от перевода.',BOOK1,'Book I, Three is Company, crossing west of Hobbiton','translation-aliases'),
    'lotr_f_37': ('Сколько всего было назгулов, служивших Саурону?',None,None,'Назгулов было девять; в отдельных сценах появляется только часть из них.',BOOK1,'Book I, The Shadow of the Past / Book II, The Ring Goes South','scope'),
    'lotr_f_38': ('Как Бильбо назвал свою книгу о путешествии с гномами?', ['Падение Гондолина','Туда и обратно','Повесть лет','История Галадриэль','Песнь о Лейтиан','Охота за Кольцом'],1,'Бильбо записал свой поход с гномами в книге «Туда и обратно» — There and Back Again.',BOOK1,'Book II, Many Meetings, Bilbo discusses his book title','multiple-defensible-hobbies'),
    'lotr_f_39': (None,['Моргот','Саурон','Келебримбор','Саруман','Элронд','Ауле'],1,None,BOOK1,'Book II, The Council of Elrond','aliases'),
    'lotr_f_40': (None,['Квенья','Синдарин','Чёрное Наречие','Кхуздул','Вестрон','Адунаик'],2,'Надпись передаёт слова на Чёрном Наречии; письмо и язык — разные понятия.',FILM1,'Bag End reading / Rivendell Council Black Speech','language-versus-writing'),
    'lotr_f_41': ('Как переводится имя «Митрандир», которым называют Гэндальфа?', ['Белый всадник','Серый паломник','Мудрый друг','Драгоценный камень','Огненный владыка','Свет Востока'],1,'В эльфийском плаче имя Митрандир соответствует словам «Серый паломник» — Pilgrim Grey.',BOOK1,'Book II, Lothlorien, elven lament Mithrandir / Pilgrim Grey','spelling-and-translation'),
    'lotr_f_44': ('Какой диапазон роста хоббитов указан в прологе «Властелина колец»?', ['60–120 см','125–140 см','40–55 см','145–160 см','165–180 см','185–200 см'],0,'В прологе указан диапазон от двух до четырёх футов — примерно от 60 до 120 см.',BOOK1,'Prologue, Concerning Hobbits','range-and-overlap'),
    'lotr_f_45': ('В каком поселении Шира находятся Смиалы, родовой дом Туков?', ['Хоббитон','Тукборо','Сток','Баклбери','Мичел Делвинг','Байуотер'],1,'Смиалы Туков находятся в Тукборо; Тукланд — родовая область, а не название этого поселения.',BOOK3,'Book VI, The Scouring of the Shire, Pippin rides to the Smials in Tuckborough','town-versus-region'),
    'lotr_f_46': ('Как звали командира урук-хай, который стреляет в Боромира в фильме «Братство Кольца»?',None,None,'В фильме в Боромира стреляет Лурц.',FILM1,'Amon Hen, Lurtz shooting Boromir','canon'),
    'lotr_f_47': ('Сколько лодок эльфы Лориэна подготовили для Братства в книге?', ['1','2','3','4','5','6'],2,'Перед отплытием для Братства подготовлены три небольшие серые лодки.',BOOK1,'Book II, Farewell to Lorien','equivalent-option-names'),
    'lotr_f_49': ('Из какого материала была сделана кольчуга Фродо?', ['Итильдин','Мифрил','Сталь','Медь','Железо','Бронза'],1,'Кольчуга сделана из мифрила — лёгкого материала, более прочного, чем закалённая сталь.',BOOK1,'Book II, A Journey in the Dark, Gandalf explains mithril','alias-and-false-etymology'),
    'lotr_f_10': ('На какой возвышенности назгулы ранили Фродо моргульским клинком?', ['Карадрас','Заверть','Амон Хен','Миндоллуин','Амон Лау','Ородруин'],1,None,BOOK1,'Book I, A Knife in the Dark','plausible-distractors'),
    'lotr_f_16': (None,['Арагорн и Боромир','Гэндальф и Арагорн','Теоден и Эомер','Фарамир и Денетор','Исильдур и Элендил','Бард и Беорн'],0,None,BOOK1,'Book II, The Ring Goes South','plausible-distractors'),
    'lotr_f_26': ('Какое эльфийское слово Гэндальф произносит, чтобы открыть западные врата Мории?', ['Меллон','Элберет','Намариэ','Мае гованнен','Эдро','Варда'],0,'Гэндальф понял, что надпись предлагает сказать слово «друг»: меллон. После этого врата открылись.',BOOK1,'Book II, A Journey in the Dark','plausible-distractors'),
    'lotr_f_28': (None,['Лихолесье','Старый лес','Лотлориэн','Фангорн','Леса Итилиэна','Бретиль'],2,None,BOOK1,'Book II, Lothlorien','plausible-distractors'),
    'lotr_f_30': (None,None,None,'Гэндальф нашёл Гламдринг в пещере троллей; Элронд опознал его как меч короля Гондолина.',HOBBIT,'A Short Rest','explanation-scope'),
    'lotr_f_42': ('Что Гэндальф разрушил, чтобы преградить путь Балрогу в Мории?', ['Мост','Лестницу','Колонну','Арку','Ворота','Плотину'],0,'Гэндальф разрушил каменный мост Кхазад-дум под Балрогом.',BOOK1,'Book II, The Bridge of Khazad-dum','plausible-distractors'),
    'lotr_f_50': (None,None,None,'Братство сопровождало Фродо, которому поручили уничтожить Кольцо в Ородруине.',BOOK1,'Book II, The Council of Elrond','unsupported-absolute'),
}

chapters = {
    1:'Book I, A Long-expected Party',2:'Book I, A Long-expected Party',3:'Book I, A Long-expected Party',
    4:'Prologue, Concerning Pipe-weed / film Bag End porch',5:'Book I, A Long-expected Party',6:'Book I, The Shadow of the Past',
    7:'Book I, Three is Company / At the Sign of the Prancing Pony',8:'Book I, At the Sign of the Prancing Pony',9:'Book I, Strider',10:'Book I, A Knife in the Dark',11:'Book I, Flight to the Ford / film',12:'Book II, Many Meetings',13:'Book II, The Bridge of Khazad-dum',14:'Book II, The Ring Goes South',15:'Book II, The Ring Goes South',16:'Book II, The Ring Goes South',17:'Book II, The Mirror of Galadriel',18:'Book II, The Council of Elrond',19:'Book II, The Bridge of Khazad-dum',20:'Book II, Farewell to Lorien',21:'Book II, Farewell to Lorien',22:'Book II, The Great River',23:'Film Amon Hen scene',24:'Book VI, The Grey Havens',25:'Book II, A Journey in the Dark',26:'Book II, A Journey in the Dark',27:'Book II, Farewell to Lorien',28:'Book II, Lothlorien',29:'Book II, The Mirror of Galadriel',30:'The Hobbit, A Short Rest',31:'Film Isengard greeting',32:'Book II, The Council of Elrond',33:'Book I, The Shadow of the Past',34:'The Hobbit, An Unexpected Party',35:'Book I, Three is Company',36:'Book I, At the Sign of the Prancing Pony',37:'Book II, The Ring Goes South',38:'Prologue, Note on the Shire Records',39:'Book II, The Council of Elrond',40:'Book I, The Shadow of the Past / film Council',41:'Book II, Lothlorien',42:'Book II, The Bridge of Khazad-dum',43:'Book II, Many Meetings',44:'Prologue, Concerning Hobbits',45:'Book VI, The Scouring of the Shire',46:'Film Amon Hen scene',47:'Book II, Farewell to Lorien',48:'Book I, The Shadow of the Past',49:'Book II, A Journey in the Dark',50:'Book II, The Council of Elrond',
}

records = []
for name in ['lotr.json','lotr_fellowship_100.json']:
    candidate = read(TASK/'candidates'/name)
    keys = {r['id']:r for r in read(TASK/'keys'/name)['records']}
    legacy = copy.deepcopy(candidate)
    for q in legacy['questions']:
        q.update({k:v for k,v in keys[q['id']].items() if k!='id'})
        original = copy.deepcopy(q)
        qid = q['id']
        if qid in fixes:
            stem, options, answer, explanation, url, reference, issue = fixes[qid]
            if stem is not None: q['text']=stem
            if options is not None: q['options']=options
            if answer is not None: q['correct_answer']=answer
            if explanation is not None: q['explanation']=explanation
        else:
            url = BOOK1
            reference = chapters[int(qid.rsplit('_',1)[1])] if qid.startswith('lotr_f_') else 'Book II, The Ring Goes South'
            if qid=='q_lotr_2_lotr-q3': url,reference=BOOK2,'Book III, The White Rider'
            if qid=='lotr_f_24': url=BOOK3
            if qid=='lotr_f_30': url=HOBBIT
            if qid=='lotr_f_23': url=FILM1
            issue='none'
        q['options']=[re.sub(r'\s*\([^()]*\)','',o).strip().replace('Андрил','Андурил').replace('Митранир','Митрандир') for o in q['options']]
        assert len(q['options'])==len(set(q['options']))==len(original['options'])
        assert 0<=q['correct_answer']<len(q['options'])
        changed = q!=original
        records.append({'id':qid,'original_verdict':'revise' if changed else 'accept','issue':issue if issue!='none' else ('option-cue' if changed else 'none'),'source_url':url,'primary_reference':reference,'proposed_question':q if changed else None})
    if name=='lotr_fellowship_100.json':
        legacy['description']='50 вопросов о начале путешествия: книги Толкина и фильм «Братство Кольца». Версия произведения уточнена в вопросах, где это важно.'
    save(TASK/'revised-root'/name,legacy)
save(TASK/'review-root'/'review.json',{'records':records,'scope':'53 original questions; root proposals require fresh independent recheck before integration'})
print('Prepared root53 audit and frozen reviewable proposals; no production edits')
