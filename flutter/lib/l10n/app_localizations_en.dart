// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Quiz Master';

  @override
  String get homeTitle => 'Quizzes';

  @override
  String get homeSubtitle => 'Choose a topic';

  @override
  String get homeHolidayTitle => '🎄 Holiday Quizzes';

  @override
  String get homeHolidaySubtitle => 'Find a gift under the tree';

  @override
  String get searchPlaceholder => 'Search...';

  @override
  String get quizDefaultDesc => 'Interesting quiz to test your knowledge.';

  @override
  String questionsCount(int count) {
    return '$count Questions';
  }

  @override
  String get play => 'Play';

  @override
  String get categories => 'CATEGORIES';

  @override
  String get quizzes => 'QUIZZES';

  @override
  String get home => 'Home';

  @override
  String get loading => 'Loading...';

  @override
  String get errorLoad => 'Failed to load quiz';

  @override
  String get goBack => 'Go Back';

  @override
  String questionTitle(int count) {
    return 'Question $count';
  }

  @override
  String get question => 'Question';

  @override
  String get correct => '🎉 Correct';

  @override
  String get incorrect => '❌ Incorrect';

  @override
  String get explanationTitle => '✨ Interesting Fact';

  @override
  String get noExplanation => 'No explanation available.';

  @override
  String get finish => 'Finish';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get reset => 'Reset';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get categoryCinema => 'Cinema';

  @override
  String get categoryGastronomy => 'Gastronomy';

  @override
  String get categoryNature => 'Nature';

  @override
  String get categoryPhilias => 'Philias';

  @override
  String get categoryPsychology => 'Psychology';

  @override
  String get categoryPhilology => 'Philology';

  @override
  String get categoryNewYear => 'New Year';

  @override
  String get categoryGeneral => 'General';

  @override
  String get noQuestions => 'No questions available';

  @override
  String get quizFallbackTitle => 'Quiz';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Russian';

  @override
  String get noSearchResults => 'No quizzes match your search';

  @override
  String get noQuizzesAvailable => 'No quizzes available yet';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAdvanced => 'Advanced';

  @override
  String get settingsDebugMode => 'Debug mode';

  @override
  String get settingsDebugModeDescription =>
      'Show diagnostics and development tools';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsSignedOut => 'You are not signed in';

  @override
  String get settingsSignedOutDescription =>
      'Sign in, register, or continue as guest';

  @override
  String get settingsRole => 'Role';

  @override
  String get settingsLoggedOut => 'Signed out successfully';

  @override
  String get settingsAccountError => 'Failed to load account state';

  @override
  String get settingsNavigation => 'Navigation';

  @override
  String get authLogin => 'Sign in';

  @override
  String get authRegister => 'Register';

  @override
  String get authGuest => 'Continue as guest';

  @override
  String get authLogout => 'Sign out';

  @override
  String get authUsername => 'Username';

  @override
  String get authPassword => 'Password';

  @override
  String get authEmailOptional => 'Email (optional)';

  @override
  String get authUsernameRequired => 'Enter a username';

  @override
  String get authSuccess => 'Authentication successful';

  @override
  String get authError => 'Authentication failed';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get debugTitle => 'Debug';

  @override
  String get debugSubtitle => 'Inspect environment, auth, and health';

  @override
  String get debugRefresh => 'Refresh diagnostics';

  @override
  String get debugEnvironment => 'Environment';

  @override
  String get debugServerBaseUrl => 'Server base URL';

  @override
  String get debugApiBaseUrl => 'API base URL';

  @override
  String get debugPlatform => 'Platform';

  @override
  String get debugAuth => 'Authentication';

  @override
  String get debugCurrentUser => 'Current user';

  @override
  String get debugAnonymous => 'Anonymous';

  @override
  String get debugNoRole => 'No role';

  @override
  String get debugTokenPresent => 'Token present';

  @override
  String get debugServerHealth => 'Server health';

  @override
  String get debugStatusCode => 'Status code';

  @override
  String get debugPayload => 'Payload';

  @override
  String get debugHealthError => 'Failed to load server health';

  @override
  String get adminTitle => 'Admin';

  @override
  String get adminSubtitle => 'Admin dashboard and moderation tools';

  @override
  String get adminAccessHint =>
      'Sign in with an admin account to access this section';

  @override
  String get adminUnauthorized =>
      'Admin access is required to view this screen';

  @override
  String get adminSummary => 'Summary';

  @override
  String get adminCurrentRole => 'Current role';

  @override
  String get adminCurrentUser => 'Current user';

  @override
  String get adminTokenState => 'Token state';

  @override
  String get adminTokenPresent => 'Present';

  @override
  String get adminTokenMissing => 'Missing';

  @override
  String get adminContent => 'Content';

  @override
  String get adminQuizCount => 'Quiz count';

  @override
  String get adminLeaderboard => 'Leaderboard';

  @override
  String get adminNoLeaderboardData => 'No leaderboard data yet';

  @override
  String get adminLoadError => 'Failed to load admin data';

  @override
  String get themeHoliday => 'Holiday';

  @override
  String get themeNight => 'Night';

  @override
  String get themeSummer => 'Summer';

  @override
  String get themeCyber => 'Cyber';

  @override
  String get themeAutumn => 'Autumn';

  @override
  String get themeRomance => 'Romance';

  @override
  String get languageRussianShort => 'RU';

  @override
  String get languageEnglishShort => 'EN';

  @override
  String get drawerGuest => 'Guest mode';

  @override
  String get openMenu => 'Open menu';
}
