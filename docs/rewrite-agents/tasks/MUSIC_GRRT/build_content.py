"""Deterministic original educational copy; sources are reviewed separately."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
ASSETS = ROOT / 'next/apps/quiz_app/assets/quizipedia'
sources = []

def source(id, title, url):
    sources.append(dict(id=id, title=title, url=url, checked_on='2026-10-19'))
    return id

notation = source('notation', 'Open Music Theory · Basic notation', 'https://openmusictheory.github.io/basicNotation.html')
rhythm = source('rhythm', 'Open Music Theory · Rhythmic values', 'https://openmusictheory.github.io/rhythmicValues.html')
meter = source('meter', 'Open Music Theory · Meter and time signatures', 'https://openmusictheory.github.io/meter.html')
performance = source('performance', 'Open Music Theory · Other aspects of notation', 'https://viva.pressbooks.pub/openmusictheorycopy/chapter/other-aspects-of-notation/')
scales = source('scales', 'Open Music Theory · Scales', 'https://openmusictheory.github.io/scales.html')
intervals = source('intervals', 'Open Music Theory · Intervals', 'https://openmusictheory.github.io/intervals.html')
chords = source('chords', 'Open Music Theory · Triads and seventh chords', 'https://openmusictheory.github.io/triads.html')

entries = []
def add(id, category, ru, en, dr, de, er, ee, src, visual=None):
    row = dict(id=id, category=category, name_ru=ru, name_en=en,
               description_ru=dr, description_en=de, example_ru=er, example_en=ee,
               source_ids=[src])
    if visual is not None:
        row['visual'] = visual
    entries.append(row)

glyphs = json.loads((Path(__file__).parent/'smufl-glyphnames.json').read_text(encoding='utf-8'))
def glyph(name):
    return {'glyph': int(glyphs[name]['codepoint'][2:], 16)}

for i, (ru, en, where_ru, where_en) in enumerate([
    ('До первой октавы', 'C4 · middle C', 'на добавочной линейке под нотным станом', 'on the ledger line below the staff'),
    ('Ре первой октавы', 'D4', 'под первой линейкой', 'just below the bottom line'),
    ('Ми первой октавы', 'E4', 'на первой линейке', 'on the bottom line'),
    ('Фа первой октавы', 'F4', 'между первой и второй линейками', 'in the first space'),
    ('Соль первой октавы', 'G4', 'на второй линейке', 'on the second line from the bottom'),
    ('Ля первой октавы', 'A4', 'между второй и третьей линейками', 'in the second space'),
    ('Си первой октавы', 'B4', 'на третьей линейке', 'on the middle line'),
]):
    add(f'note-{i}', 'notes', ru, en, f'В скрипичном ключе эта нота находится {where_ru}. Линейки считаются снизу.',
        f'In treble clef this note sits {where_en}. Count staff lines from the bottom.',
        'Положение показано для скрипичного ключа и первой октавы.', 'Shown in treble clef, octave 4 in scientific pitch notation.', notation, {'note': i})

for id, ru, en, dr, de, er, ee, g in [
    ('treble','Скрипичный ключ','Treble clef','Закрепляет соль первой октавы на второй линейке снизу.','Places G4 on the second line from the bottom.','Ключ задаёт высоты нот, а не длительности.','A clef locates pitches, not durations.','gClef'),
    ('bass','Басовый ключ','Bass clef','Фа малой октавы находится на четвёртой линейке снизу.','Places F3 on the fourth line from the bottom.','Две точки располагаются по сторонам этой линейки.','Its two dots bracket that line.','fClef'),
    ('alto','Альтовый ключ','Alto clef','В альтовом ключе середина знака до указывает на третью линейку: до первой октавы.','In alto clef the C-clef centre marks middle C on the third line.','Применяется, в частности, для альта.','Used notably for the viola.','cClef'),
    ('sharp','Диез','Sharp','Повышает ноту на полутон относительно её натуральной высоты.','Raises a note one semitone from its natural pitch.','Фа-диез выше фа на полутон.','F sharp is one semitone above F.','accidentalSharp'),
    ('flat','Бемоль','Flat','Понижает ноту на полутон относительно её натуральной высоты.','Lowers a note one semitone from its natural pitch.','Си-бемоль ниже си на полутон.','B flat is one semitone below B.','accidentalFlat'),
    ('natural','Бекар','Natural','Возвращает ноте натуральную высоту, отменяя действующую альтерацию.','Restores a note to its natural pitch, cancelling an active accidental.','После фа-диеза знак бекар возвращает фа.','After F sharp, a natural restores F.','accidentalNatural'),
    ('double-sharp','Дубль-диез','Double sharp','Повышает натуральную ноту на два полутона.','Raises a natural note by two semitones.','До-дубль-диез звучит как ре на равномерно темперированном фортепиано.','C double sharp sounds like D on an equal-tempered piano.','accidentalDoubleSharp'),
    ('double-flat','Дубль-бемоль','Double flat','Понижает натуральную ноту на два полутона.','Lowers a natural note by two semitones.','Ре-дубль-бемоль звучит как до на равномерно темперированном фортепиано.','D double flat sounds like C on an equal-tempered piano.','accidentalDoubleFlat'),
]:
    add(id,'notation',ru,en,dr,de,er,ee,notation,glyph(g))
add('staff','notation','Нотный стан','Staff','Пять параллельных линеек; ноты пишут на линейках и между ними.','Five parallel lines; notes occupy lines and spaces.','Высоту читают с учётом ключа.','Read pitch together with the clef.',notation,{'text':'─────\n─────\n─────\n─────\n─────'})
add('ledger','notation','Добавочная линейка','Ledger line','Короткая линейка продолжает стан для нот вне его пяти линеек.','A short line extends the staff for notes beyond its five lines.','До первой октавы в скрипичном ключе требует добавочной линейки.','Middle C in treble clef uses a ledger line.',notation,{'note':0})

for id, ru, en, dr, de, er, ee, g in [
    ('whole','Целая нота','Whole note','Длится столько же, сколько две половинные ноты.','Lasts as long as two half notes.','В размере 4/4 — четыре четвертные доли.','In 4/4 it lasts four quarter-note beats.','noteWhole'),
    ('half','Половинная нота','Half note','Половина длительности целой ноты.','Half the duration of a whole note.','В размере 4/4 — две четвертные доли.','In 4/4 it lasts two quarter-note beats.','noteHalfUp'),
    ('quarter','Четвертная нота','Quarter note','Четверть длительности целой ноты.','One quarter of a whole note.','В 4/4 это единица счёта, но не во всех размерах.','It is the beat unit in 4/4, but not in every meter.','noteQuarterUp'),
    ('eighth','Восьмая нота','Eighth note','Половина длительности четвертной.','Half the duration of a quarter note.','Две восьмые равны одной четвертной.','Two eighths equal one quarter note.','note8thUp'),
    ('sixteenth','Шестнадцатая нота','Sixteenth note','Половина длительности восьмой.','Half the duration of an eighth note.','Четыре шестнадцатые равны четверти.','Four sixteenths equal one quarter note.','note16thUp'),
    ('whole-rest','Целая пауза','Whole rest','Знак молчания длительностью в целую ноту; также обозначает пустой такт в обычной записи.','Silence lasting a whole note; also used for a full silent measure in conventional notation.','Прямоугольник висит под линейкой.','Its rectangle hangs below a staff line.','restWhole'),
    ('half-rest','Половинная пауза','Half rest','Молчание длительностью в половинную ноту.','Silence lasting a half note.','Прямоугольник стоит на линейке.','Its rectangle sits above a staff line.','restHalf'),
    ('quarter-rest','Четвертная пауза','Quarter rest','Молчание длительностью в четвертную ноту.','Silence lasting a quarter note.','В 4/4 занимает одну четвертную долю.','In 4/4 it occupies one quarter-note beat.','restQuarter'),
    ('eighth-rest','Восьмая пауза','Eighth rest','Молчание длительностью в восьмую ноту.','Silence lasting an eighth note.','Половина четвертной паузы.','Half the duration of a quarter rest.','rest8th'),
    ('sixteenth-rest','Шестнадцатая пауза','Sixteenth rest','Молчание длительностью в шестнадцатую ноту.','Silence lasting a sixteenth note.','Четверть длительности четвертной паузы.','One quarter of a quarter rest.','rest16th'),
]:
    add(id,'rhythm',ru,en,dr,de,er,ee,rhythm,glyph(g))
for id,ru,en,dr,de,er,ee,text,src in [
    ('dot','Точка продления','Augmentation dot','Добавляет половину исходной длительности.','Adds half the original duration.','Четверть с точкой равна трём восьмым.','A dotted quarter equals three eighths.','·',rhythm),
    ('tie','Лига продления','Tie','Соединяет две ноты одной высоты в один непрерывный звук.','Joins two notes of the same pitch into one sustained sound.','Длительности складываются; повторной атаки нет.','Add their durations without a new attack.','tie',rhythm),
    ('meter44','Размер 4/4','4/4 meter','В такте четыре доли, единица доли — четверть.','Four beats per bar, with a quarter note as the beat unit.','Четыре четверти заполняют такт.','Four quarter notes fill one bar.','4\n4',meter),
    ('meter34','Размер 3/4','3/4 meter','В такте три четвертные доли.','Three quarter-note beats per bar.','Счёт: раз-два-три.','Count: one-two-three.','3\n4',meter),
    ('meter68','Размер 6/8','6/8 meter','Обычно две основные доли, каждая делится на три восьмых.','Usually two main beats, each divided into three eighth notes.','Две четверти с точкой; не шесть основных долей.','Two dotted-quarter beats, rather than six main beats.','6\n8',meter),
    ('triplet','Триоль','Triplet','Три равные длительности звучат за время двух таких же обычных длительностей.','Three equal values occupy the time normally given to two of those values.','Три восьмые триоли занимают одну четверть.','Three triplet eighths occupy one quarter note.','3',meter),
]:
    add(id,'rhythm',ru,en,dr,de,er,ee,src,{'text':text})

for id,ru,en,dr,de,text in [
    ('pp','Пианиссимо','Pianissimo','Очень тихо.','Very softly.','pp'),
    ('p','Пиано','Piano','Тихо; это обозначение громкости, а не название инструмента.','Softly; a dynamic marking, distinct from the instrument name.','p'),
    ('mp','Меццо-пиано','Mezzo piano','Умеренно тихо.','Moderately softly.','mp'),
    ('mf','Меццо-форте','Mezzo forte','Умеренно громко.','Moderately loudly.','mf'),
    ('f','Форте','Forte','Громко.','Loudly.','f'),
    ('ff','Фортиссимо','Fortissimo','Очень громко.','Very loudly.','ff'),
    ('crescendo','Крещендо','Crescendo','Постепенно усиливать громкость.','Gradually increase loudness.','crescendo'),
    ('diminuendo','Диминуэндо','Diminuendo','Постепенно уменьшать громкость.','Gradually decrease loudness.','dim.'),
]:
    add(id,'dynamics',ru,en,dr,de,'Динамика относительна: учитываются инструмент и музыкальный контекст.','Dynamics are relative to the instrument and musical context.',performance,{'text':text})
for id,ru,en,dr,de in [
    ('largo','Ларго','Largo','Широко, медленно.','Broadly and slowly.'),
    ('adagio','Адажио','Adagio','Медленно, спокойно.','Slowly, at ease.'),
    ('andante','Анданте','Andante','В темпе спокойного шага.','At a walking pace.'),
    ('moderato','Модерато','Moderato','Умеренный темп.','At a moderate tempo.'),
    ('allegro','Аллегро','Allegro','Быстрый, оживлённый темп.','A fast, lively tempo.'),
    ('presto','Престо','Presto','Очень быстро.','Very fast.'),
    ('accelerando','Аччелерандо','Accelerando','Постепенно ускорять темп.','Gradually speed up.'),
    ('ritardando','Ритардандо','Ritardando','Постепенно замедлять темп.','Gradually slow down.'),
    ('a-tempo','А темпо','A tempo','Вернуться к прежнему темпу после отклонения.','Return to the previous tempo after a change.'),
]:
    add(id,'tempo',ru,en,dr,de,'Словесные темпы не задают универсального точного числа ударов в минуту.','Verbal tempo markings do not specify a universal exact BPM.',performance,{'text':en})
for id,ru,en,dr,de,er,ee,vis in [
    ('staccato','Стаккато','Staccato','Исполнять звуки коротко, отделяя их друг от друга.','Play notes short and detached.','Точка над или под нотой — штрих; точка справа — продление.','A dot above/below is articulation; a dot to the right adds duration.',glyph('articStaccatoAbove')),
    ('legato','Легато','Legato','Исполнять звуки связно.','Play notes smoothly connected.','Дуга над разными высотами обычно обозначает лигу артикуляции.','A slur over different pitches commonly indicates connected articulation.',{'text':'legato'}),
    ('accent','Акцент','Accent','Выделить ноту относительно окружающих звуков.','Emphasise a note relative to surrounding notes.','Знак не означает ускорение темпа.','The sign does not mean speeding up.',glyph('articAccentAbove')),
    ('fermata','Фермата','Fermata','Продлить ноту или паузу сверх записанной длительности.','Hold a note or rest beyond its written duration.','Точное продление зависит от исполнения.','The exact extension depends on the performance.',glyph('fermataAbove')),
    ('pizzicato','Пиццикато','Pizzicato','На смычковых: извлекать звук щипком струны.','On bowed strings: pluck the string.','Arco указывает на возвращение к игре смычком.','Arco asks for a return to the bow.',{'text':'pizz.'}),
    ('arco','Арко','Arco','На смычковых: играть смычком.','On string instruments: play with the bow.','Часто стоит после pizzicato.','Often follows pizzicato.',{'text':'arco'}),
    ('repeat','Реприза','End repeat','Повторить раздел от соответствующего знака начала повтора или от начала.','Repeat the section from the matching start repeat, or from the beginning.','Дополнительные указания и вольты уточняют порядок исполнения.','Other instructions and alternate endings can qualify the route.',glyph('repeatRight')),
    ('segno','Сеньо','Segno','Ориентир для возврата по указанию Dal segno.','A reference sign used by a Dal segno instruction.','Один знак сеньо не требует немедленного прыжка.','The sign alone does not command an immediate jump.',glyph('segno')),
    ('coda','Кода','Coda sign','Знак перехода к заключительному разделу по соответствующему указанию.','Marks a destination in the ending section when a corresponding jump is instructed.','Следуйте указаниям To Coda и порядку повторов.','Follow To Coda and the repeat instructions.',glyph('coda')),
]:
    add(id,'technique',ru,en,dr,de,er,ee,performance,vis)

for id,ru,en,dr,de,er,ee,src in [
    ('semitone','Полутон','Semitone','Минимальное расстояние между соседними клавишами равномерно темперированного фортепиано.','The distance between adjacent keys on an equal-tempered piano.','Ми–фа и си–до — полутоны.','E–F and B–C are semitones.',notation),
    ('tone','Целый тон','Whole tone','Расстояние в два полутона.','A distance of two semitones.','До–ре — целый тон.','C–D is a whole tone.',notation),
    ('octave','Октава','Octave','Интервал из восьми диатонических ступеней; чистая октава — двенадцать полутонов.','An interval spanning eight diatonic steps; a perfect octave is twelve semitones.','До первой — до второй октавы.','C4 to C5 is a perfect octave.',intervals),
    ('major','Мажорная гамма','Major scale','Последовательность шагов: тон, тон, полутон, тон, тон, тон, полутон.','Step pattern: whole, whole, half, whole, whole, whole, half.','До мажор: до–ре–ми–фа–соль–ля–си–до.','C major: C–D–E–F–G–A–B–C.',scales),
    ('minor','Натуральный минор','Natural minor','Последовательность шагов: тон, полутон, тон, тон, полутон, тон, тон.','Step pattern: whole, half, whole, whole, half, whole, whole.','Ля минор: ля–си–до–ре–ми–фа–соль–ля.','A natural minor: A–B–C–D–E–F–G–A.',scales),
    ('triad','Трезвучие','Triad','Аккорд из трёх звуков, которые можно расположить по терциям.','A three-note chord that can be arranged in stacked thirds.','До–ми–соль — мажорное трезвучие.','C–E–G is a major triad.',chords),
    ('arpeggio','Арпеджио','Arpeggio','Последовательное исполнение звуков аккорда.','Playing the notes of a chord successively.','До, затем ми, затем соль вместо одновременного созвучия.','C, then E, then G instead of all three together.',chords),
]:
    add(id,'harmony',ru,en,dr,de,er,ee,src,{'text':en})

for id,ru,en,dr,de,er,ee in [
    ('violin','Скрипка','Violin','Высокий струнный смычковый инструмент с четырьмя струнами.','A high bowed-string instrument with four strings.','Обычный строй: соль–ре–ля–ми.','Usual tuning: G–D–A–E.'),
    ('viola','Альт','Viola','Струнный смычковый инструмент, крупнее скрипки и ниже по строю.','A bowed-string instrument larger and lower-tuned than the violin.','Обычный строй: до–соль–ре–ля.','Usual tuning: C–G–D–A.'),
    ('cello','Виолончель','Cello','Низкий струнный смычковый инструмент, который держат между коленями с опорой на шпиль.','A low bowed-string instrument held between the knees and supported by an endpin.','Обычный строй на октаву ниже альта.','Its usual tuning is an octave below the viola.'),
    ('double-bass','Контрабас','Double bass','Самый низкий обычный инструмент оркестровой группы смычковых.','The lowest usual member of the orchestral bowed-string section.','Четырёхструнный вариант обычно настроен по квартам.','The four-string version is usually tuned in fourths.'),
    ('flute','Флейта','Flute','Деревянный духовой по классификации; звук возникает от струи воздуха у края отверстия.','Classed as woodwind; an air jet meets the edge of an opening to produce sound.','Современная оркестровая флейта часто металлическая.','The modern orchestral flute is often metal.'),
    ('oboe','Гобой','Oboe','Деревянный духовой инструмент с двойной тростью.','A woodwind instrument with a double reed.','Не путайте с одинарной тростью кларнета.','Contrast the clarinet’s single reed.'),
    ('clarinet','Кларнет','Clarinet','Деревянный духовой инструмент с одинарной тростью.','A woodwind instrument with a single reed.','Трость закреплена на мундштуке.','The reed is attached to the mouthpiece.'),
    ('bassoon','Фагот','Bassoon','Низкий деревянный духовой инструмент с двойной тростью.','A low woodwind instrument with a double reed.','Длинная воздушная трубка сложена внутри корпуса.','Its long air column is folded within the body.'),
    ('horn','Валторна','Horn','Медный духовой инструмент с длинной свёрнутой трубкой.','A brass instrument with a long coiled tube.','Звук начинается с вибрации губ в мундштуке.','Lip vibration in the mouthpiece starts the sound.'),
    ('trumpet','Труба','Trumpet','Медный духовой инструмент; современные оркестровые модели обычно имеют клапаны.','A brass instrument; modern orchestral models usually have valves.','Клапаны изменяют длину воздушного пути.','Valves change the length of the air path.'),
    ('trombone','Тромбон','Trombone','Медный духовой инструмент, обычно с выдвижной кулисой.','A brass instrument usually equipped with a slide.','Кулиса позволяет плавно менять длину трубки.','The slide continuously changes the tube length.'),
    ('tuba','Туба','Tuba','Низкий медный духовой инструмент оркестра.','A low brass instrument in the orchestra.','В отличие от контрабаса, относится к духовым.','Unlike the double bass, it belongs to the wind instruments.'),
    ('timpani','Литавры','Timpani','Ударные с определённой высотой звука; мембрана натянута над котлом.','Pitched percussion with a membrane stretched over a bowl.','Изменение натяжения мембраны меняет высоту.','Changing membrane tension changes pitch.'),
    ('harp','Арфа','Harp','Струнный щипковый инструмент с рамой и рядом струн.','A plucked-string instrument with a frame and a row of strings.','Педали концертной арфы меняют высоту групп струн.','Concert-harp pedals change the pitches of groups of strings.'),
    ('piano','Фортепиано','Piano instrument','Клавишный инструмент: молоточки ударяют по струнам.','A keyboard instrument whose hammers strike strings.','По способу звукоизвлечения — ударяемые струны.','Its sound is produced by struck strings.'),
]:
    slug = {'double-bass':'double-bass','horn':'horn','piano':'piano'}.get(id,id)
    src = source(id+'-source','Philharmonia · '+en,'https://philharmonia.co.uk/resources/instruments/'+slug+'/')
    add(id,'instruments',ru,en,dr,de,er,ee,src)

world = [
 ('duduk','Дудук','Duduk','Духовой инструмент с двойной тростью, связанный с армянской музыкальной традицией.','A double-reed woodwind associated with Armenian musical tradition.','Армения; традиция также известна за пределами страны.','Armenia; the tradition is also known beyond the country.','duduk-source','UNESCO · Djivan Gasparyan and the duduk','https://www.unesco.org/en/articles/unesco-remembers-djivan-gasparyan-armenian-musician',['AM']),
 ('angklung','Ангклунг','Angklung','Бамбуковые трубки в раме звучат при встряхивании или постукивании.','Bamboo tubes in a frame sound when shaken or tapped.','Индонезия; мелодии часто исполняют совместно несколько музыкантов.','Indonesia; melodies often require several players cooperating.','angklung-source','UNESCO Archives · Indonesian Angklung','https://www.unesco.org/archives/multimedia/document-1681',['ID']),
 ('dombra','Домбра','Dombra','Длинношейный двухструнный щипковый инструмент; казахский кюй — традиция сольного исполнения.','A long-necked two-string plucked instrument; Kazakh kuy is a solo-performance tradition.','Казахстан: в подборке показана именно традиция домбра-кюй.','Kazakhstan: this reference specifically covers dombra kuy.','dombra-source','UNESCO · Kazakh Dombra Kuy','https://ich.unesco.org/en/RL/traditional-art-of-dombra-kuy-in-kazakhstan-00996',['KZ']),
 ('mbira','Мбира','Mbira','Инструмент с металлическими язычками на деревянной деке, которые защипывают пальцами.','An instrument with metal tongues on a wooden soundboard, plucked with the fingers.','В этой карточке — традиция народа шона в Зимбабве.','This card describes the Shona tradition in Zimbabwe.','mbira-source','Bath Spa University · Mbira Hut','https://www.bathspa.ac.uk/projects/mbira-hut/',['ZW']),
 ('koto','Кото','Koto','Японская щипковая цитра; распространённый традиционный вариант имеет 13 струн и подвижные подставки.','A Japanese plucked zither; a common traditional version has 13 strings and movable bridges.','Японская традиция сформировалась с учётом китайских предшественников.','The Japanese tradition developed from Chinese predecessors.','japan-source','Ministry of Foreign Affairs of Japan · Traditional music','https://web-japan.org/kidsweb/virtual/koto/koto01.html',['JP']),
 ('shamisen','Сямисэн','Shamisen','Трёхструнный японский инструмент с длинным грифом; играют крупным плектром бати.','A three-string Japanese long-necked instrument played with a large bachi plectrum.','Часто сопровождает пение.','Often accompanies singing.','japan-source','','',['JP']),
 ('shakuhachi','Сякухати','Shakuhachi','Японская продольная бамбуковая флейта; типичный вариант имеет пять игровых отверстий.','A Japanese end-blown bamboo flute; a typical form has five finger holes.','Четыре отверстия спереди и одно сзади.','Four holes in front and one at the back.','japan-source','','',['JP']),
 ('sitar','Ситар','Sitar','Щипковый струнный инструмент, важный для североиндийской классической музыки.','A plucked-string instrument important in North Indian classical music.','Имеет игровые и резонирующие струны.','Has playing strings and sympathetic strings.','india-source','Metropolitan Museum · Instruments of the Indian subcontinent','https://www.metmuseum.org/essays/musical-instruments-of-the-indian-subcontinent',['IN']),
 ('tabla','Табла','Tabla','Пара ручных барабанов в североиндийской музыкальной традиции.','A pair of hand drums in North Indian musical tradition.','Два барабана различаются размером и высотой.','The two drums differ in size and pitch.','india-source','','',['IN']),
]
countries = {}
for id,ru,en,dr,de,er,ee,sid,title,url,ids in world:
    if title:
        source(sid,title,url)
    add(id,'world',ru,en,dr,de,er,ee,sid)
    for country in ids:
        countries.setdefault(country,[]).append(dict(id=id,kind='instrument',name_ru=ru,name_en=en,relation_ru=dr+' '+er,relation_en=de+' '+ee,source_id=sid,checked='2026-10-19'))

for id,ru,en,dr,de,sid,title,url,ids in [
    ('gamelan','Гамелан','Gamelan','Индонезийская ансамблевая традиция с гонгами, металлофонами, барабанами и другими инструментами.','An Indonesian ensemble tradition featuring gongs, metallophones, drums and other instruments.','gamelan-source','UNESCO · Gamelan','https://www.unesco.org/en/articles/gamelan-another-indonesian-tradition-unesco-representative-list-intangible-cultural-heritage',['ID']),
    ('flamenco','Фламенко','Flamenco','Пение, танец и инструментальное сопровождение; основные корни — в Андалусии, Испания.','Singing, dance and instrumental accompaniment, rooted especially in Andalusia, Spain.','flamenco-source','UNESCO Archives · Flamenco','https://www.unesco.org/archives/multimedia/document-1696',['ES']),
    ('tango','Танго','Tango','Музыкальная и танцевальная традиция Рио-де-ла-Платы; связана с Аргентиной и Уругваем.','A music and dance tradition of the Rio de la Plata, associated with Argentina and Uruguay.','tango-source','UNESCO · Tango','https://ich.unesco.org/en/RL/tango-00258',['AR','UY']),
    ('aitysh','Айтыс','Aitysh / Aitys','Состязание в импровизированной поэзии с музыкальным сопровождением; совместная традиция Казахстана и Кыргызстана.','A contest of improvised poetry with musical accompaniment; a shared tradition of Kazakhstan and Kyrgyzstan.','aitysh-source','UNESCO · Aitysh/Aitys','https://ich.unesco.org/en/RL/aitysaitys-art-of-improvisation-00997',['KZ','KG']),
    ('bagpipe-culture','Культура волынки','Bagpipe culture','Словацкая традиция включает исполнение, изготовление инструментов, песни и танцы.','The Slovak tradition includes playing, instrument making, songs and dances.','bagpipe-source','UNESCO · Bagpipe culture','https://ich.unesco.org/en/RL/bagpipe-culture-01075',['SK']),
]:
    if title:
        source(sid,title,url)
    add(id,'world',ru,en,dr,de,'Указана конкретная культурная связь, а не исключительная принадлежность стране.','A specific cultural association, not exclusive national ownership.',sid)
    for country in ids:
        countries.setdefault(country,[]).append(dict(id=id,kind='culture',name_ru=ru,name_en=en,relation_ru=dr,relation_en=de,source_id=sid,checked='2026-10-19'))

# Explicit prompts prevent automatically treating similar definitions as unique answers.
questions=[]
def question(correct, options, ru, en, visual=None):
    e=next(x for x in entries if x['id']==correct)
    q=dict(id='q-'+correct,stem_ru=ru,stem_en=en,option_ids=options,correct_id=correct,
           explanation_ru=e['description_ru']+' '+e['example_ru'],explanation_en=e['description_en']+' '+e['example_en'],source_ids=e['source_ids'])
    if visual: q['visual']=visual
    questions.append(q)
for i in range(7):
    ids=[f'note-{j}' for j in [(i+1)%7,(i+3)%7,i,(i+5)%7]]
    question(f'note-{i}',ids,'Какая нота показана в скрипичном ключе?','Which note is shown in treble clef?',{'note':i})
for correct,opts,ru,en in [
 ('sharp',['flat','sharp','natural','double-flat'],'Какой знак повышает натуральную ноту на полутон?','Which sign raises a natural note by one semitone?'),
 ('flat',['natural','double-sharp','flat','sharp'],'Какой знак понижает натуральную ноту на полутон?','Which sign lowers a natural note by one semitone?'),
 ('natural',['flat','sharp','double-flat','natural'],'Какой знак возвращает натуральную высоту ноты?','Which sign restores the natural pitch of a note?'),
 ('whole',['whole','half','quarter','eighth'],'Какая длительность равна двум половинным нотам?','Which duration equals two half notes?'),
 ('eighth',['sixteenth','eighth','quarter','half'],'Какая нота вдвое короче четвертной?','Which note lasts half as long as a quarter?'),
 ('dot',['tie','fermata','dot','accent'],'Какой знак справа от ноты добавляет половину её длительности?','Which sign to the right of a note adds half its duration?'),
 ('tie',['legato','accent','staccato','tie'],'Что объединяет ноты одной высоты в непрерывный звук без повторной атаки?','What joins notes of the same pitch into one sound without a new attack?'),
 ('meter68',['meter68','meter34','meter44','triplet'],'Какой размер обычно содержит две основные доли по три восьмых?','Which meter usually has two main beats of three eighths each?'),
 ('crescendo',['diminuendo','crescendo','ritardando','accelerando'],'Как называется постепенное усиление громкости?','What means gradually increasing loudness?'),
 ('ritardando',['accelerando','crescendo','ritardando','a-tempo'],'Как называется постепенное замедление темпа?','What means gradually slowing the tempo?'),
 ('p',['f','mf','ff','p'],'Какое обозначение означает «тихо»?','Which marking means softly?'),
 ('staccato',['staccato','legato','arco','fermata'],'Какой штрих требует коротких, отделённых звуков?','Which articulation calls for short, detached notes?'),
 ('fermata',['accent','fermata','segno','coda'],'Какой знак продлевает ноту или паузу по усмотрению исполнителя?','Which sign extends a note or rest at the performer’s discretion?'),
 ('pizzicato',['arco','legato','pizzicato','staccato'],'Как называется извлечение звука щипком на смычковом инструменте?','What is plucking the strings of a bowed-string instrument called?'),
 ('oboe',['flute','clarinet','trumpet','oboe'],'У какого инструмента двойная трость?','Which instrument uses a double reed?'),
 ('trombone',['trombone','trumpet','horn','tuba'],'Какой медный духовой обычно использует выдвижную кулису?','Which brass instrument usually uses a slide?'),
 ('piano',['harp','piano','violin','cello'],'В каком инструменте молоточки ударяют по струнам?','In which instrument do hammers strike strings?'),
 ('duduk',['sitar','angklung','duduk','koto'],'Какой инструмент связан с армянской традицией и имеет двойную трость?','Which instrument is associated with Armenian tradition and has a double reed?'),
 ('angklung',['dombra','shamisen','mbira','angklung'],'Какой индонезийский инструмент делают из бамбуковых трубок в раме?','Which Indonesian instrument uses bamboo tubes in a frame?'),
 ('koto',['koto','tabla','shakuhachi','dombra'],'Какая японская цитра в распространённом варианте имеет 13 струн?','Which Japanese zither commonly has 13 strings?'),
 ('triad',['octave','triad','tone','semitone'],'Как называется аккорд из трёх звуков, располагаемых по терциям?','What is a three-note chord arranged in stacked thirds called?'),
]:
    question(correct,opts,ru,en)

# Balance the saved answer positions independently of runtime option shuffling.
for q in questions:
    target = {'q-note-0':0,'q-note-1':0,'q-note-2':1,'q-note-3':3,'q-note-4':3}.get(q['id'])
    if target is not None:
        q['option_ids'].remove(q['correct_id'])
        q['option_ids'].insert(target,q['correct_id'])
assert [sum(q['option_ids'].index(q['correct_id']) == i for q in questions) for i in range(4)] == [7,7,7,7]

music=dict(schema='qm-music-learning/v1',sources=sources,entries=entries,questions=questions)
culture=dict(sources=sources,countries=countries)
for name,value in [('music_learning.json',music),('country_culture.json',culture)]:
    (ASSETS/name).write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print(f'{len(entries)} cards, {len(questions)} questions, {len(countries)} countries, {sum(map(len,countries.values()))} cultural links')
