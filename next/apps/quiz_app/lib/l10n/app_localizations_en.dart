// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get holidayTitle => 'A little quiz, every day';

  @override
  String get holidaySubtitle => 'Pick a topic. Play in short rounds.';

  @override
  String roundLabel(int number) {
    return 'Round $number';
  }

  @override
  String get nextRound => 'Next round';

  @override
  String roundQuestions(int count) {
    return '$count questions';
  }

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

  @override
  String get resumeAutoAdvance => 'Resume auto advance';

  @override
  String autoAdvanceIn(int seconds) {
    return 'Next in ${seconds}s · Pause';
  }

  @override
  String get studyLibrary => 'Study library';

  @override
  String get studyIntro =>
      'Understand a topic through examples and connections, then try a twenty-question self-check.';

  @override
  String get studyRead => 'Read the article';

  @override
  String get studyContents => 'Contents';

  @override
  String get studyPractice => 'Self-check · 20 questions';

  @override
  String get studySources => 'Sources and further reading';

  @override
  String get studyObjectives => 'After studying, you will be able to';

  @override
  String get studyUnranked => 'Study self-check · unranked';

  @override
  String get studyCorrect => 'Correct';

  @override
  String get studyIncorrect => 'Let\'s understand why';

  @override
  String get studyPause => 'Pause transition';

  @override
  String get studyContinue => 'Continue';

  @override
  String get studyNextSecond => 'Next question in one second';

  @override
  String get studyComplete => 'Self-check complete';

  @override
  String get studyRetry => 'Try again';

  @override
  String get studyBackArticle => 'Back to article';

  @override
  String get studyMissing => 'Article not found';

  @override
  String get studyLoadError => 'Unable to load study materials';

  @override
  String studyReadingMinutes(int minutes) {
    return '≈ $minutes min read';
  }

  @override
  String studyScore(int correct, int total) {
    return '$correct of $total';
  }
}
