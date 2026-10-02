// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get holidayTitle => 'Holiday quizzes';

  @override
  String get holidaySubtitle =>
      'A cozy evening, curious questions and your favorite topics';

  @override
  String get browseQuizzes => 'Browse quizzes';

  @override
  String get searchQuizzes => 'Search by title, description or category';

  @override
  String get categories => 'Categories';

  @override
  String get catalogRoot => 'All categories';

  @override
  String catalogInventory(int packs, int questions) {
    return '$packs quizzes · $questions questions';
  }

  @override
  String get catalogPreview =>
      'The full collection is being migrated. Only Home Alone 1 (Part 1) is playable in the new API so far.';

  @override
  String get packPending => 'Play is not connected yet';

  @override
  String get noSearchResults => 'No quizzes match your search.';

  @override
  String get catalogTitle => 'Quiz catalog';

  @override
  String get galleryTitle => 'Public fixture gallery';

  @override
  String get joinAdmissionOnly =>
      'This token is admission-only. It never grants host authority.';

  @override
  String get yourAnswer => 'Your answer';

  @override
  String get submitAnswer => 'Submit answer';

  @override
  String get openGallery => 'Open gallery';

  @override
  String get practiceUnranked => 'Practice is unranked';

  @override
  String get joinTitle => 'Join live quiz';

  @override
  String inviteToken(String token) {
    return 'Invite token: $token';
  }

  @override
  String get english => 'English';

  @override
  String get russian => 'Русский';

  @override
  String get theme => 'Theme';

  @override
  String get lightTheme => 'Light theme';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get systemTheme => 'System theme';

  @override
  String answer(String answer) {
    return 'Answer: $answer';
  }

  @override
  String get displayName => 'Display name';

  @override
  String get continueLabel => 'Continue';

  @override
  String get startQuiz => 'Start quiz';

  @override
  String get finishQuiz => 'Finish quiz';

  @override
  String get history => 'History';

  @override
  String get noHistory => 'No completed quizzes yet';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading…';

  @override
  String get submitting => 'Submitting…';

  @override
  String get finishing => 'Finishing…';

  @override
  String score(int score) {
    return 'Score: $score';
  }

  @override
  String questionsCount(int count) {
    return '$count questions';
  }

  @override
  String get catalogEmpty => 'No quizzes are available yet.';

  @override
  String get catalogLoadError => 'Unable to load quizzes.';

  @override
  String get historyLoadError => 'Unable to load history.';

  @override
  String get resultsLoadError => 'Unable to load results.';

  @override
  String get journeyError => 'Unable to continue.';

  @override
  String get newQuiz => 'New quiz';
}
