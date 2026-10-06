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
  String get allQuestions => 'All questions';

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
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyNightmare => 'Nightmare';

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

  @override
  String get feedbackDeleteReport => "Delete report?";

  @override
  String get feedbackCancel => "Cancel";

  @override
  String get feedbackDelete => "Delete";

  @override
  String get feedbackReport => "Report";

  @override
  String get feedbackScreenshotUnavailable => "Screenshot unavailable";

  @override
  String get feedbackClose => "Close";

  @override
  String get feedbackAllQuizzes => "All quizzes";

  @override
  String get feedbackReports => "Reports";

  @override
  String get feedbackRefresh => "Refresh";

  @override
  String get feedbackLogout => "Logout";

  @override
  String get feedbackOperatorToken => "Operator token";

  @override
  String get feedbackSignIn => "Sign in";

  @override
  String get feedbackOpen => "Open";

  @override
  String get feedbackResolved => "Resolved";

  @override
  String get feedbackAll => "All";

  @override
  String get feedbackOperationFailedCheckTheTokenAndRetry =>
      "Operation failed. Check the token and retry.";

  @override
  String get feedbackNoReports => "No reports";

  @override
  String get feedbackResolve => "Resolve";

  @override
  String get feedbackReopen => "Reopen";

  @override
  String get feedbackPrevious => "Previous";

  @override
  String get feedbackNext => "Next";

  @override
  String get feedbackSendFeedback => "Send feedback";

  @override
  String get feedbackThankYouForYourFeedback => "Thank you for your feedback";

  @override
  String get feedbackFeedback => "Feedback";

  @override
  String get feedbackApplicationProblem => "Application problem";

  @override
  String get feedbackQuestionProblem => "Question problem";

  @override
  String get feedbackSuggestion => "Suggestion";

  @override
  String get feedbackComment => "Comment";

  @override
  String get feedbackAttachScreenshot => "Attach screenshot";

  @override
  String get feedbackScreenshotUnavailableYouCanSendAComment =>
      "Screenshot unavailable. You can send a comment.";

  @override
  String get feedbackCouldNotSendYourTextIsSavedPleaseRetry =>
      "Could not send. Your text is saved — please retry.";

  @override
  String get feedbackSending => "Sending…";

  @override
  String get feedbackSend => "Send";
}
