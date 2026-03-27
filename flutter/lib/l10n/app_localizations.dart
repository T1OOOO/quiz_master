import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// Application title
  ///
  /// In ru, this message translates to:
  /// **'Quiz Master'**
  String get appTitle;

  /// Home screen title
  ///
  /// In ru, this message translates to:
  /// **'Викторины'**
  String get homeTitle;

  /// Home screen subtitle
  ///
  /// In ru, this message translates to:
  /// **'Выберите тему'**
  String get homeSubtitle;

  /// Holiday theme home title
  ///
  /// In ru, this message translates to:
  /// **'🎄 Новогодние викторины'**
  String get homeHolidayTitle;

  /// Holiday theme home subtitle
  ///
  /// In ru, this message translates to:
  /// **'Выберите подарок под елкой'**
  String get homeHolidaySubtitle;

  /// Search input placeholder
  ///
  /// In ru, this message translates to:
  /// **'Поиск...'**
  String get searchPlaceholder;

  /// Default quiz description
  ///
  /// In ru, this message translates to:
  /// **'Интересная викторина для проверки знаний.'**
  String get quizDefaultDesc;

  /// Questions count text
  ///
  /// In ru, this message translates to:
  /// **'{count} вопр.'**
  String questionsCount(int count);

  /// Play button text
  ///
  /// In ru, this message translates to:
  /// **'Играть'**
  String get play;

  /// Categories section title
  ///
  /// In ru, this message translates to:
  /// **'КАТЕГОРИИ'**
  String get categories;

  /// Quizzes section title
  ///
  /// In ru, this message translates to:
  /// **'ВИКТОРИНЫ'**
  String get quizzes;

  /// Home breadcrumb
  ///
  /// In ru, this message translates to:
  /// **'Главная'**
  String get home;

  /// Loading text
  ///
  /// In ru, this message translates to:
  /// **'Загрузка...'**
  String get loading;

  /// Error loading quiz
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить квиз'**
  String get errorLoad;

  /// Go back button
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get goBack;

  /// Question title with number
  ///
  /// In ru, this message translates to:
  /// **'Вопрос {count}'**
  String questionTitle(int count);

  /// Question label
  ///
  /// In ru, this message translates to:
  /// **'Вопрос'**
  String get question;

  /// Correct answer feedback
  ///
  /// In ru, this message translates to:
  /// **'🎉 Верно'**
  String get correct;

  /// Incorrect answer feedback
  ///
  /// In ru, this message translates to:
  /// **'❌ Ошибка'**
  String get incorrect;

  /// Explanation section title
  ///
  /// In ru, this message translates to:
  /// **'✨ Интересный факт'**
  String get explanationTitle;

  /// No explanation available
  ///
  /// In ru, this message translates to:
  /// **'Нет объяснения.'**
  String get noExplanation;

  /// Finish quiz button
  ///
  /// In ru, this message translates to:
  /// **'Завершить'**
  String get finish;

  /// Next button
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get next;

  /// Previous button
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get previous;

  /// Reset quiz button
  ///
  /// In ru, this message translates to:
  /// **'Сброс'**
  String get reset;

  /// Shuffle questions button
  ///
  /// In ru, this message translates to:
  /// **'Перемешать'**
  String get shuffle;

  /// Cinema category
  ///
  /// In ru, this message translates to:
  /// **'Кино'**
  String get categoryCinema;

  /// Gastronomy category
  ///
  /// In ru, this message translates to:
  /// **'Гастрономия'**
  String get categoryGastronomy;

  /// Nature category
  ///
  /// In ru, this message translates to:
  /// **'Природа'**
  String get categoryNature;

  /// Philias category
  ///
  /// In ru, this message translates to:
  /// **'Филии'**
  String get categoryPhilias;

  /// Psychology category
  ///
  /// In ru, this message translates to:
  /// **'Психология'**
  String get categoryPsychology;

  /// Philology category
  ///
  /// In ru, this message translates to:
  /// **'Филология'**
  String get categoryPhilology;

  /// New Year category
  ///
  /// In ru, this message translates to:
  /// **'Новый Год'**
  String get categoryNewYear;

  /// General category
  ///
  /// In ru, this message translates to:
  /// **'Разное'**
  String get categoryGeneral;

  /// No questions state in quiz screen
  ///
  /// In ru, this message translates to:
  /// **'Нет вопросов'**
  String get noQuestions;

  /// Fallback quiz title
  ///
  /// In ru, this message translates to:
  /// **'Квиз'**
  String get quizFallbackTitle;

  /// Tooltip for language switcher
  ///
  /// In ru, this message translates to:
  /// **'Сменить язык'**
  String get changeLanguage;

  /// English language label
  ///
  /// In ru, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Russian language label
  ///
  /// In ru, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No search results state
  ///
  /// In ru, this message translates to:
  /// **'По вашему запросу ничего не найдено'**
  String get noSearchResults;

  /// Empty quizzes state
  ///
  /// In ru, this message translates to:
  /// **'Пока нет доступных викторин'**
  String get noQuizzesAvailable;

  /// Settings screen title
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// Appearance section title
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get settingsAppearance;

  /// Theme setting label
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get settingsTheme;

  /// Language setting label
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get settingsLanguage;

  /// Advanced settings section
  ///
  /// In ru, this message translates to:
  /// **'Дополнительно'**
  String get settingsAdvanced;

  /// Debug mode toggle
  ///
  /// In ru, this message translates to:
  /// **'Режим отладки'**
  String get settingsDebugMode;

  /// Debug mode description
  ///
  /// In ru, this message translates to:
  /// **'Показывать диагностику и инструменты разработки'**
  String get settingsDebugModeDescription;

  /// Account section title
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get settingsAccount;

  /// Signed out state
  ///
  /// In ru, this message translates to:
  /// **'Вы не вошли в систему'**
  String get settingsSignedOut;

  /// Signed out description
  ///
  /// In ru, this message translates to:
  /// **'Войдите, зарегистрируйтесь или продолжайте как гость'**
  String get settingsSignedOutDescription;

  /// Role label
  ///
  /// In ru, this message translates to:
  /// **'Роль'**
  String get settingsRole;

  /// Logged out snackbar
  ///
  /// In ru, this message translates to:
  /// **'Вы вышли из аккаунта'**
  String get settingsLoggedOut;

  /// Account error state
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить состояние аккаунта'**
  String get settingsAccountError;

  /// Navigation section title
  ///
  /// In ru, this message translates to:
  /// **'Навигация'**
  String get settingsNavigation;

  /// Login action
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get authLogin;

  /// Register action
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get authRegister;

  /// Guest login action
  ///
  /// In ru, this message translates to:
  /// **'Продолжить как гость'**
  String get authGuest;

  /// Logout action
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get authLogout;

  /// Username field label
  ///
  /// In ru, this message translates to:
  /// **'Имя пользователя'**
  String get authUsername;

  /// Password field label
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get authPassword;

  /// Optional email label
  ///
  /// In ru, this message translates to:
  /// **'Email (необязательно)'**
  String get authEmailOptional;

  /// Username validation error
  ///
  /// In ru, this message translates to:
  /// **'Введите имя пользователя'**
  String get authUsernameRequired;

  /// Authentication success message
  ///
  /// In ru, this message translates to:
  /// **'Аутентификация успешна'**
  String get authSuccess;

  /// Authentication error prefix
  ///
  /// In ru, this message translates to:
  /// **'Ошибка аутентификации'**
  String get authError;

  /// Cancel button
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// Confirm button
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get confirm;

  /// Debug screen title
  ///
  /// In ru, this message translates to:
  /// **'Отладка'**
  String get debugTitle;

  /// Debug screen subtitle
  ///
  /// In ru, this message translates to:
  /// **'Проверка окружения, авторизации и состояния сервера'**
  String get debugSubtitle;

  /// Refresh debug data action
  ///
  /// In ru, this message translates to:
  /// **'Обновить диагностику'**
  String get debugRefresh;

  /// Environment section title
  ///
  /// In ru, this message translates to:
  /// **'Окружение'**
  String get debugEnvironment;

  /// Server base URL label
  ///
  /// In ru, this message translates to:
  /// **'Базовый URL сервера'**
  String get debugServerBaseUrl;

  /// API base URL label
  ///
  /// In ru, this message translates to:
  /// **'Базовый URL API'**
  String get debugApiBaseUrl;

  /// Platform label
  ///
  /// In ru, this message translates to:
  /// **'Платформа'**
  String get debugPlatform;

  /// Authentication section title
  ///
  /// In ru, this message translates to:
  /// **'Авторизация'**
  String get debugAuth;

  /// Current user label
  ///
  /// In ru, this message translates to:
  /// **'Текущий пользователь'**
  String get debugCurrentUser;

  /// Anonymous user label
  ///
  /// In ru, this message translates to:
  /// **'Анонимный'**
  String get debugAnonymous;

  /// No role label
  ///
  /// In ru, this message translates to:
  /// **'Нет роли'**
  String get debugNoRole;

  /// Token present label
  ///
  /// In ru, this message translates to:
  /// **'Токен присутствует'**
  String get debugTokenPresent;

  /// Server health section title
  ///
  /// In ru, this message translates to:
  /// **'Состояние сервера'**
  String get debugServerHealth;

  /// Status code label
  ///
  /// In ru, this message translates to:
  /// **'Код статуса'**
  String get debugStatusCode;

  /// Payload label
  ///
  /// In ru, this message translates to:
  /// **'Payload'**
  String get debugPayload;

  /// Health check error
  ///
  /// In ru, this message translates to:
  /// **'Не удалось получить состояние сервера'**
  String get debugHealthError;

  /// Admin screen title
  ///
  /// In ru, this message translates to:
  /// **'Админка'**
  String get adminTitle;

  /// Admin screen subtitle
  ///
  /// In ru, this message translates to:
  /// **'Панель администратора и инструменты модерации'**
  String get adminSubtitle;

  /// Admin access hint
  ///
  /// In ru, this message translates to:
  /// **'Войдите под администратором, чтобы открыть этот раздел'**
  String get adminAccessHint;

  /// Unauthorized admin message
  ///
  /// In ru, this message translates to:
  /// **'Для просмотра этого экрана нужны права администратора'**
  String get adminUnauthorized;

  /// Admin summary section title
  ///
  /// In ru, this message translates to:
  /// **'Сводка'**
  String get adminSummary;

  /// Current role label
  ///
  /// In ru, this message translates to:
  /// **'Текущая роль'**
  String get adminCurrentRole;

  /// Current user label
  ///
  /// In ru, this message translates to:
  /// **'Текущий пользователь'**
  String get adminCurrentUser;

  /// Token state label
  ///
  /// In ru, this message translates to:
  /// **'Состояние токена'**
  String get adminTokenState;

  /// Token present state
  ///
  /// In ru, this message translates to:
  /// **'Есть'**
  String get adminTokenPresent;

  /// Token missing state
  ///
  /// In ru, this message translates to:
  /// **'Отсутствует'**
  String get adminTokenMissing;

  /// Content section title
  ///
  /// In ru, this message translates to:
  /// **'Контент'**
  String get adminContent;

  /// Quiz count label
  ///
  /// In ru, this message translates to:
  /// **'Количество квизов'**
  String get adminQuizCount;

  /// Admin leaderboard title
  ///
  /// In ru, this message translates to:
  /// **'Лидерборд'**
  String get adminLeaderboard;

  /// No leaderboard data
  ///
  /// In ru, this message translates to:
  /// **'Данных лидерборда пока нет'**
  String get adminNoLeaderboardData;

  /// Admin load error
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить данные админки'**
  String get adminLoadError;

  /// Holiday theme name
  ///
  /// In ru, this message translates to:
  /// **'Новый год'**
  String get themeHoliday;

  /// Night theme name
  ///
  /// In ru, this message translates to:
  /// **'Ночь'**
  String get themeNight;

  /// Summer theme name
  ///
  /// In ru, this message translates to:
  /// **'Лето'**
  String get themeSummer;

  /// Cyber theme name
  ///
  /// In ru, this message translates to:
  /// **'Кибер'**
  String get themeCyber;

  /// Autumn theme name
  ///
  /// In ru, this message translates to:
  /// **'Осень'**
  String get themeAutumn;

  /// Romance theme name
  ///
  /// In ru, this message translates to:
  /// **'Романтика'**
  String get themeRomance;

  /// Short Russian language label
  ///
  /// In ru, this message translates to:
  /// **'RU'**
  String get languageRussianShort;

  /// Short English language label
  ///
  /// In ru, this message translates to:
  /// **'EN'**
  String get languageEnglishShort;

  /// Drawer guest label
  ///
  /// In ru, this message translates to:
  /// **'Гостевой режим'**
  String get drawerGuest;

  /// Open menu tooltip
  ///
  /// In ru, this message translates to:
  /// **'Открыть меню'**
  String get openMenu;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
