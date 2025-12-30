import yaml
import re
import os

def extract_questions(file_path):
    print(f"Extracting from {file_path}...")
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Try to find YAML blocks in markdown if present
    yaml_blocks = re.findall(r'```yaml\n(.*?)\n```', content, re.DOTALL)
    if not yaml_blocks:
        # If no markdown blocks, assume the whole file is YAML or a subset
        # But wait, some files have 'quiz:' root element, others are just lists
        try:
            data = yaml.safe_load(content)
            if isinstance(data, dict) and 'quiz' in data:
                qs = data['quiz'].get('questions', [])
            elif isinstance(data, dict) and 'questions' in data:
                qs = data['questions']
            elif isinstance(data, list):
                qs = data
            else:
                return []
            
            # Normalize 'answer' field to 'correct_answer'
            for q in qs:
                if 'answer' in q and 'correct_answer' not in q:
                    q['correct_answer'] = q['answer']
            return qs
        except:
            return []
    
    all_qs = []
    for block in yaml_blocks:
        try:
            q_list = yaml.safe_load(block)
            if isinstance(q_list, list):
                all_qs.extend(q_list)
        except Exception as e:
            print(f"  Error parsing block in {file_path}: {e}")
    return all_qs

def normalize_text(text):
    if not text: return ""
    return re.sub(r'\s+', ' ', text.strip().lower())

def deduplicate(questions):
    unique_qs = []
    seen_texts = set()
    
    for q in questions:
        norm_text = normalize_text(q.get('text', ''))
        if norm_text and norm_text not in seen_texts:
            seen_texts.add(norm_text)
            unique_qs.append(q)
    
    print(f"Total questions: {len(questions)}, Unique: {len(unique_qs)}")
    return unique_qs

def categorize(questions):
    themes = {
        "ny_myth": [],        # Mythology & Folklore
        "ny_trad": [],        # World Traditions & Rituals
        "ny_food": [],        # Food & Drinks
        "ny_cinema_ru": [],    # Russian Cinema
        "ny_cinema_intl": [],  # International Cinema & TV
        "ny_arts": [],         # Music & Literature
        "ny_hist_sci": []      # History, Records & Science
    }
    
    # Refined keyword-based categorization
    for q in questions:
        text = q.get('text', '').lower()
        expl = q.get('explanation', '').lower()
        combined = text + " " + expl
        
        # Priority order: Cinema > Arts > Mythology > Food > History/Science > Traditions
        
        # Russian Cinema
        ru_cinema_kw = [
            'ирония судьбы', 'ёлки', 'чародеи', 'морозко', 'зигзаг удачи', 'карнавальная ночь', 
            'советск', 'шурик', 'гайдай', 'рязанов', 'мягков', 'яковлев', 'брыльска',
            'новогодние приключения маши и вити', 'старый новый год', 'сирота казанская',
            'бедная саша', 'президент и его внучка', "никулин", "миронов", "папанов", "вицин", "моргунов",
            "абдулов", "фарада", "яковлев", "чурикова", "гурченко", "талызина", "надя шевелева", "лукашин",
            "заливная рыба", "ленинград", "москва", "баня", "ипполит", "женя лукашин", "огурцов", "пять минут",
            "карьера димы горина", "чук и гек"
        ]
        
        # International Cinema
        intl_cinema_kw = [
            'home alone', 'один дома', 'die hard', 'крепкий орешек', 'гринч', 'grinch',
            'harry potter', 'гарри поттер', 'реальная любовь', 'love actually',
            'bad santa', 'плохой санта', 'курбангалеева', 'нассау', 'маккалей',
            'кевин маккалистер', 'брюс уиллис', 'шварценеггер', 'подарок на рождество',
            'эльф', 'интуиция', 'отпуск по обмену', 'кошмар перед рождеством', 
            'гремлины', 'олаф', 'холодное сердце', 'frozen', 'nightmare before',
            "film", "hollywood", "oscar", "disney", "elf", "christmas movie", "mccallister", "kevin", "buzz", "gruber", "nakatomi",
            "polar express", "полярный экспресс", "в поисках санты", "bad santa", "плохой санта"
        ]

        # Music & Literature
        arts_kw = [
            'песня', 'музыка', 'композитор', 'певец', 'группа', 'хит', 'сингл', 'альбом',
            'книга', 'автор', 'писатель', 'повесть', 'рассказ', 'стихотворение', 'поэт',
            "music", "song", "composer", "singer", "band", "hit", "single", "book", "author", "writer", "poem", "poet",
            "jingle bells", "last christmas", "let it snow", "white christmas", "silent night", "carol of the bells",
            "диккенс", "dickens", "скрудж", "scrooge", "стругацкие", "понедельник начинается в субботу", 
            "толкин", "tolkien", "нарния", "narnia", "о. генри", "o. henry", "дары волхвов", "gift of the magi",
            "nutcracker", "щелкунчик", "гофман", "майя кристалинская", "а снег идет"
        ]

        # Mythology & Folklore
        myth_kw = [
            'миф', 'легенд', 'бог', 'дух', 'монстр', 'существо', 'эльф', 'фея', 'тролль',
            'крампус', 'krampus', 'бефана', 'befana', 'йоль', 'yule', 'пер-ноэль', 'баба-яга',
            'дед мороз', 'санта-клаус', 'снегурочка', 'claus', 'santa', 'saint nicholas',
            'грила', 'gryla', 'йольский кот', 'yule cat', 'перхта', 'perchta', 'ниан', 'nian',
            'калликанцар', 'kallikantzaroi', 'мари луид', 'mari lwyd', 'nisse', 'tomte',
            'фольклор', 'folklore'
        ]

        # Food & Drinks
        food_kw = [
            'еда', 'блюдо', 'кухня', 'кулинар', 'рецепт', 'ужин', 'завтрак', 'обед', 'напиток',
            'вино', 'шампанское', 'водка', 'пиво', 'коктейль', 'фрукт', 'овощ', 'десерт', 'торт', 'пирог',
            "food", "drink", "dish", "cuisine", "wine", "fruit", "meal", "dinner", "cake", "bread",
            "оливье", "селедка под шубой", "заливная рыба", "мандарин", "gingerbread", "имбирный",
            "eggnog", "гоголь-моголь", "глювайн", "глинтвейн", "mulled wine", "pudding", "пудинг",
            "lentil", "чечевица", "горох", "pea", "pork", "свинина", "herring", "сельдь", "soba", "соба",
            "mochi", "моти", "oliebollen", "олиболлен", "hoppin john", "tamale", "тамале", "dumpling", "пельмен",
            "василопита", "vasilopita", "nian gao", "kfc", "курица", "chicken", "профитрол", "безе", "павлова",
            "pavlova", "марципан", "marzipan", "bread", "хлеб", "глювайн", "punsh", "пунш", "egg", "яйцо"
        ]
        
        # History & Science
        hist_sci_kw = [
            'история', 'дата', 'год', 'век', 'рекорд', 'гиннесс', 'первый', 'событие', 'указ',
            'наука', 'физика', 'химия', 'биология', 'астрономия', 'космос', 'природа', 'животное',
            'градус', 'температура', 'снежинка', 'молекула', 'лед', 'холод', 'погода',
            "history", "record", "science", "nature", "animal", "space", "planet", "solar",
            "temperature", "snowflake", "molecular", "evolution", "discovery", "invention",
            "calendar", "календарь", "реформа", "century", "stats", "statistics", 'археолог', 'ученый',
            "сублимация", "sublimation", "sms", "сообщение", "пуансеттия", "poinsettia", "хлопушка", "cracker",
            "перья", "feather", "федеральн"
        ]
        
        # Traditions & Rituals (General/Catch-all)
        trad_kw = [
            'традиция', 'обычай', 'ритуал', 'обряд', 'праздник', 'фестиваль', 'карнавал',
            'страна', 'город', 'народ', 'культура', 'регион', 'место',
            "tradition", "custom", "ritual", "celebration", "festival", "culture", "country", "nation"
        ]
        
        # Exclusion list for non-thematic or overly generic topics
        exclusions = [
            "самое маленькое млекопитающее", "свиноносая летучая мышь", "хоккей", "кёрлинг", "бобслей", 
            "скелетон", "шорт-трек", "биатлон", "лыжные гонки", "конькобежный", "фигурное катание",
            "тройной аксель", "четверной лутц", "олимпийские кольца", "замбони", "vlogmas", "espanto",
            "джентльмены удачи", "бриллиантовая рука", "королева бензоколонки", "берегись автомобиля",
            "женитьба бальзаминова"
        ]
        
        if any(exc in combined for exc in exclusions):
            continue # Skip this question
        
        if any(kw in combined for kw in ru_cinema_kw):
            themes['ny_cinema_ru'].append(q)
        elif any(kw in combined for kw in intl_cinema_kw):
            themes['ny_cinema_intl'].append(q)
        elif any(kw in combined for kw in arts_kw):
            themes['ny_arts'].append(q)
        elif any(kw in combined for kw in myth_kw):
            themes['ny_myth'].append(q)
        elif any(kw in combined for kw in food_kw):
            themes['ny_food'].append(q)
        elif any(kw in combined for kw in hist_sci_kw):
            themes['ny_hist_sci'].append(q)
        else:
            themes['ny_trad'].append(q)
            
    return themes

def generate_ids(questions, prefix):
    for i, q in enumerate(questions):
        q['id'] = f"{prefix}_{i+1}"
    return questions

import random

def save_quiz(questions, filename, title, prefix):
    processed_qs = generate_ids(questions, prefix)
    
    # Shuffle options and update answer index
    for q in processed_qs:
        if 'options' in q and 'correct_answer' in q:
            original_answer_idx = q['correct_answer']
            if 0 <= original_answer_idx < len(q['options']):
                correct_text = q['options'][original_answer_idx]
                options = q['options'][:] # Copy
                random.shuffle(options)
                new_answer_idx = options.index(correct_text)
                q['options'] = options
                q['correct_answer'] = new_answer_idx

    data = {
        "id": prefix,
        "title": title,
        "questions": processed_qs
    }
    with open(filename, 'w', encoding='utf-8') as f:
        yaml.dump(data, f, allow_unicode=True, sort_keys=False)
    print(f"Saved {len(questions)} questions to {filename} (prefix: {prefix})")

def main():
    files = [
        "quizzes/new_year_customs.yaml",
        "quizzes/new_year_traditions.yaml",
        "quizzes/new_year_history_geo.yaml",
        "quizzes/new_year_food_symbols.yaml",
        "quizzes/new_year_ru_movies.yaml",
        "quizzes/new_year_intl_movies.yaml",
        "quizzes/new_year_science_records_modern.yaml",
        "quizzes/new_year_sports_myths.yaml",
        "quizzes/new_year_mythology.yaml",
        "quizzes/new_year_food_drinks.yaml",
        "quizzes/new_year_cinema_ru.yaml",
        "quizzes/new_year_cinema_intl.yaml",
        "quizzes/new_year_arts_literature.yaml",
        "quizzes/new_year_history_science.yaml",
        "quizzes/new_questions_pool.yaml",
        "quizzes/final_batch.yaml",
        "quizzes/batch_11.yaml",
        "quizzes/batch_12.yaml"
    ]
    
    all_questions = []
    for f in files:
        if os.path.exists(f):
            all_questions.extend(extract_questions(f))
    
    unique_questions = deduplicate(all_questions)
    themed_questions = categorize(unique_questions)
    
    save_quiz(themed_questions['ny_myth'], "quizzes/new_year_mythology.yaml", "Мифология и фольклор", "nym")
    save_quiz(themed_questions['ny_trad'], "quizzes/new_year_traditions.yaml", "Традиции народов мира", "nyt")
    save_quiz(themed_questions['ny_food'], "quizzes/new_year_food_drinks.yaml", "Праздничная еда и напитки", "nyf")
    save_quiz(themed_questions['ny_cinema_ru'], "quizzes/new_year_cinema_ru.yaml", "Отечественное новогоднее кино", "nycr")
    save_quiz(themed_questions['ny_cinema_intl'], "quizzes/new_year_cinema_intl.yaml", "Зарубежное новогоднее кино", "nyci")
    save_quiz(themed_questions['ny_arts'], "quizzes/new_year_arts_literature.yaml", "Музыка и литература", "nya")
    save_quiz(themed_questions['ny_hist_sci'], "quizzes/new_year_history_science.yaml", "История и наука Нового года", "nyhs")




if __name__ == "__main__":
    main()
