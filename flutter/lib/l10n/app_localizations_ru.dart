// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Quiz Master';

  @override
  String get homeTitle => 'Викторины';

  @override
  String get homeSubtitle => 'Выберите тему';

  @override
  String get homeHolidayTitle => '🎄 Новогодние викторины';

  @override
  String get homeHolidaySubtitle => 'Выберите подарок под елкой';

  @override
  String get searchPlaceholder => 'Поиск...';

  @override
  String get quizDefaultDesc => 'Интересная викторина для проверки знаний.';

  @override
  String questionsCount(int count) {
    return '$count вопр.';
  }

  @override
  String get play => 'Играть';

  @override
  String get categories => 'КАТЕГОРИИ';

  @override
  String get quizzes => 'ВИКТОРИНЫ';

  @override
  String get home => 'Главная';

  @override
  String get loading => 'Загрузка...';

  @override
  String get errorLoad => 'Не удалось загрузить квиз';

  @override
  String get goBack => 'Назад';

  @override
  String questionTitle(int count) {
    return 'Вопрос $count';
  }

  @override
  String get question => 'Вопрос';

  @override
  String get correct => '🎉 Верно';

  @override
  String get incorrect => '❌ Ошибка';

  @override
  String get explanationTitle => '✨ Интересный факт';

  @override
  String get noExplanation => 'Нет объяснения.';

  @override
  String get finish => 'Завершить';

  @override
  String get next => 'Далее';

  @override
  String get previous => 'Назад';

  @override
  String get reset => 'Сброс';

  @override
  String get shuffle => 'Перемешать';

  @override
  String get categoryCinema => 'Кино';

  @override
  String get categoryGastronomy => 'Гастрономия';

  @override
  String get categoryNature => 'Природа';

  @override
  String get categoryPhilias => 'Филии';

  @override
  String get categoryPsychology => 'Психология';

  @override
  String get categoryPhilology => 'Филология';

  @override
  String get categoryNewYear => 'Новый Год';

  @override
  String get categoryGeneral => 'Разное';

  @override
  String get noQuestions => 'Нет вопросов';

  @override
  String get quizFallbackTitle => 'Квиз';

  @override
  String get changeLanguage => 'Сменить язык';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get noSearchResults => 'По вашему запросу ничего не найдено';

  @override
  String get noQuizzesAvailable => 'Пока нет доступных викторин';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsAppearance => 'Оформление';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsAdvanced => 'Дополнительно';

  @override
  String get settingsDebugMode => 'Режим отладки';

  @override
  String get settingsDebugModeDescription =>
      'Показывать диагностику и инструменты разработки';

  @override
  String get settingsAccount => 'Аккаунт';

  @override
  String get settingsSignedOut => 'Вы не вошли в систему';

  @override
  String get settingsSignedOutDescription =>
      'Войдите, зарегистрируйтесь или продолжайте как гость';

  @override
  String get settingsRole => 'Роль';

  @override
  String get settingsLoggedOut => 'Вы вышли из аккаунта';

  @override
  String get settingsAccountError => 'Не удалось загрузить состояние аккаунта';

  @override
  String get settingsNavigation => 'Навигация';

  @override
  String get authLogin => 'Войти';

  @override
  String get authRegister => 'Регистрация';

  @override
  String get authGuest => 'Продолжить как гость';

  @override
  String get authLogout => 'Выйти';

  @override
  String get authUsername => 'Имя пользователя';

  @override
  String get authPassword => 'Пароль';

  @override
  String get authEmailOptional => 'Email (необязательно)';

  @override
  String get authUsernameRequired => 'Введите имя пользователя';

  @override
  String get authSuccess => 'Аутентификация успешна';

  @override
  String get authError => 'Ошибка аутентификации';

  @override
  String get cancel => 'Отмена';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get debugTitle => 'Отладка';

  @override
  String get debugSubtitle =>
      'Проверка окружения, авторизации и состояния сервера';

  @override
  String get debugRefresh => 'Обновить диагностику';

  @override
  String get debugEnvironment => 'Окружение';

  @override
  String get debugServerBaseUrl => 'Базовый URL сервера';

  @override
  String get debugApiBaseUrl => 'Базовый URL API';

  @override
  String get debugPlatform => 'Платформа';

  @override
  String get debugAuth => 'Авторизация';

  @override
  String get debugCurrentUser => 'Текущий пользователь';

  @override
  String get debugAnonymous => 'Анонимный';

  @override
  String get debugNoRole => 'Нет роли';

  @override
  String get debugTokenPresent => 'Токен присутствует';

  @override
  String get debugServerHealth => 'Состояние сервера';

  @override
  String get debugStatusCode => 'Код статуса';

  @override
  String get debugPayload => 'Payload';

  @override
  String get debugHealthError => 'Не удалось получить состояние сервера';

  @override
  String get adminTitle => 'Админка';

  @override
  String get adminSubtitle => 'Панель администратора и инструменты модерации';

  @override
  String get adminAccessHint =>
      'Войдите под администратором, чтобы открыть этот раздел';

  @override
  String get adminUnauthorized =>
      'Для просмотра этого экрана нужны права администратора';

  @override
  String get adminSummary => 'Сводка';

  @override
  String get adminCurrentRole => 'Текущая роль';

  @override
  String get adminCurrentUser => 'Текущий пользователь';

  @override
  String get adminTokenState => 'Состояние токена';

  @override
  String get adminTokenPresent => 'Есть';

  @override
  String get adminTokenMissing => 'Отсутствует';

  @override
  String get adminContent => 'Контент';

  @override
  String get adminQuizCount => 'Количество квизов';

  @override
  String get adminLeaderboard => 'Лидерборд';

  @override
  String get adminNoLeaderboardData => 'Данных лидерборда пока нет';

  @override
  String get adminLoadError => 'Не удалось загрузить данные админки';

  @override
  String get themeHoliday => 'Новый год';

  @override
  String get themeNight => 'Ночь';

  @override
  String get themeSummer => 'Лето';

  @override
  String get themeCyber => 'Кибер';

  @override
  String get themeAutumn => 'Осень';

  @override
  String get themeRomance => 'Романтика';

  @override
  String get languageRussianShort => 'RU';

  @override
  String get languageEnglishShort => 'EN';

  @override
  String get drawerGuest => 'Гостевой режим';

  @override
  String get openMenu => 'Открыть меню';
}
