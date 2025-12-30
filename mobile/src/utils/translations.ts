export const CATEGORY_TRANSLATIONS: Record<string, string> = {
    // General
    'General': 'Общее',
    'General Knowledge': 'Общие знания',
    
    // Entertainment
    'Cinema': 'Кино',
    'cinema': 'Кино',
    'Movies': 'Фильмы',
    'Film': 'Фильмы',
    'Cartoons': 'Мультфильмы',
    'cartoons': 'Мультфильмы',
    'Anime': 'Аниме',
    'Music': 'Музыка',
    'Games': 'Игры',
    'Video Games': 'Видеоигры',
    'Books': 'Книги',
    'Literature': 'Литература',
    'Comics': 'Комиксы',

    // Franchise Specific
    'Transformers': 'Трансформеры',
    'transformers': 'Трансформеры',
    'Harry Potter': 'Гарри Поттер',
    'Star Wars': 'Звездные Войны',
    'Marvel': 'Марвел',
    'DC': 'DC',
    'Lord of the Rings': 'Властелин Колец',
    'LOTR': 'Властелин Колец', // Added abbreviation

    // Knowledge/School
    'Science': 'Наука',
    'History': 'История',
    'Geography': 'География',
    'Math': 'Математика',
    'Physics': 'Физика',
    'Chemistry': 'Химия',
    'Biology': 'Биология',
    'Technology': 'Технологии',
    'Computers': 'Компьютеры',
    'Programming': 'Программирование',
    
    // Lifestyle
    'Nature': 'Природа',
    'Animals': 'Животные',
    'Space': 'Космос',
    'Sports': 'Спорт',
    'Food': 'Еда',
    'Gastronomy': 'Гастрономия', // Added
    'Cooking': 'Кулинария',
    'Art': 'Искусство',
    'Automotive': 'Автомобили',
    'Cars': 'Машины',
    'Fashion': 'Мода',
    'Politics': 'Политика',
    'Economy': 'Экономика',
    'Etiquette': 'Этикет',
    'Cheese': 'Сыр',
    'Drinks': 'Напитки',
    'Animation': 'Анимация', // General animation

    // Holidays
    'Christmas': 'Рождество',
    'New Year': 'Новый Год'
};

export const translateCategory = (text: string = ''): string => {
    if (!text) return '';
    const trimmed = text.trim();
    // Try exact match
    if (CATEGORY_TRANSLATIONS[trimmed]) return CATEGORY_TRANSLATIONS[trimmed];
    
    // Try Title Case (e.g. "cheese" -> "Cheese")
    const titleCase = trimmed.charAt(0).toUpperCase() + trimmed.slice(1).toLowerCase();
    if (CATEGORY_TRANSLATIONS[titleCase]) return CATEGORY_TRANSLATIONS[titleCase];

    // Try Lowercase
    if (CATEGORY_TRANSLATIONS[trimmed.toLowerCase()]) return CATEGORY_TRANSLATIONS[trimmed.toLowerCase()];

    return trimmed;
};
