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

  /// No description provided for @holidayTitle.
  ///
  /// In en, this message translates to:
  /// **'A little quiz, every day'**
  String get holidayTitle;

  /// No description provided for @holidaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a topic. Play in short rounds.'**
  String get holidaySubtitle;

  /// No description provided for @roundLabel.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String roundLabel(int number);

  /// No description provided for @allQuestions.
  ///
  /// In en, this message translates to:
  /// **'All questions'**
  String get allQuestions;

  /// No description provided for @nextRound.
  ///
  /// In en, this message translates to:
  /// **'Next round'**
  String get nextRound;

  /// No description provided for @roundQuestions.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String roundQuestions(int count);

  /// No description provided for @browseQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Browse quizzes'**
  String get browseQuizzes;

  /// No description provided for @searchQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Search by title, description or category'**
  String get searchQuizzes;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @difficultyNightmare.
  ///
  /// In en, this message translates to:
  /// **'Nightmare'**
  String get difficultyNightmare;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @catalogRoot.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get catalogRoot;

  /// No description provided for @catalogInventory.
  ///
  /// In en, this message translates to:
  /// **'{packs} quizzes · {questions} questions'**
  String catalogInventory(int packs, int questions);

  /// No description provided for @catalogPreview.
  ///
  /// In en, this message translates to:
  /// **'The full collection is being migrated. Only Home Alone 1 (Part 1) is playable in the new API so far.'**
  String get catalogPreview;

  /// No description provided for @packPending.
  ///
  /// In en, this message translates to:
  /// **'Play is not connected yet'**
  String get packPending;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No quizzes match your search.'**
  String get noSearchResults;

  /// No description provided for @catalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz catalog'**
  String get catalogTitle;

  /// No description provided for @galleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Public fixture gallery'**
  String get galleryTitle;

  /// No description provided for @joinAdmissionOnly.
  ///
  /// In en, this message translates to:
  /// **'This token is admission-only. It never grants host authority.'**
  String get joinAdmissionOnly;

  /// No description provided for @yourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get yourAnswer;

  /// No description provided for @submitAnswer.
  ///
  /// In en, this message translates to:
  /// **'Submit answer'**
  String get submitAnswer;

  /// No description provided for @openGallery.
  ///
  /// In en, this message translates to:
  /// **'Open gallery'**
  String get openGallery;

  /// No description provided for @practiceUnranked.
  ///
  /// In en, this message translates to:
  /// **'Practice is unranked'**
  String get practiceUnranked;

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join live quiz'**
  String get joinTitle;

  /// No description provided for @inviteToken.
  ///
  /// In en, this message translates to:
  /// **'Invite token: {token}'**
  String inviteToken(String token);

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System theme'**
  String get systemTheme;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer: {answer}'**
  String answer(String answer);

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @startQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start quiz'**
  String get startQuiz;

  /// No description provided for @finishQuiz.
  ///
  /// In en, this message translates to:
  /// **'Finish quiz'**
  String get finishQuiz;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No completed quizzes yet'**
  String get noHistory;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get submitting;

  /// No description provided for @finishing.
  ///
  /// In en, this message translates to:
  /// **'Finishing…'**
  String get finishing;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String score(int score);

  /// No description provided for @questionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String questionsCount(int count);

  /// No description provided for @catalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No quizzes are available yet.'**
  String get catalogEmpty;

  /// No description provided for @catalogLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load quizzes.'**
  String get catalogLoadError;

  /// No description provided for @historyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load history.'**
  String get historyLoadError;

  /// No description provided for @resultsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load results.'**
  String get resultsLoadError;

  /// No description provided for @journeyError.
  ///
  /// In en, this message translates to:
  /// **'Unable to continue.'**
  String get journeyError;

  /// No description provided for @newQuiz.
  ///
  /// In en, this message translates to:
  /// **'New quiz'**
  String get newQuiz;

  /// No description provided for @resumeAutoAdvance.
  ///
  /// In en, this message translates to:
  /// **'Resume auto advance'**
  String get resumeAutoAdvance;

  /// No description provided for @autoAdvanceIn.
  ///
  /// In en, this message translates to:
  /// **'Next in {seconds}s · Pause'**
  String autoAdvanceIn(int seconds);

  /// No description provided for @studyLibrary.
  ///
  /// In en, this message translates to:
  /// **'Study library'**
  String get studyLibrary;

  /// No description provided for @studyIntro.
  ///
  /// In en, this message translates to:
  /// **'Understand a topic through examples and connections, then try a twenty-question self-check.'**
  String get studyIntro;

  /// No description provided for @studyRead.
  ///
  /// In en, this message translates to:
  /// **'Read the article'**
  String get studyRead;

  /// No description provided for @studyContents.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get studyContents;

  /// No description provided for @studyPractice.
  ///
  /// In en, this message translates to:
  /// **'Self-check · 20 questions'**
  String get studyPractice;

  /// No description provided for @studySources.
  ///
  /// In en, this message translates to:
  /// **'Sources and further reading'**
  String get studySources;

  /// No description provided for @studyObjectives.
  ///
  /// In en, this message translates to:
  /// **'After studying, you will be able to'**
  String get studyObjectives;

  /// No description provided for @studyUnranked.
  ///
  /// In en, this message translates to:
  /// **'Study self-check · unranked'**
  String get studyUnranked;

  /// No description provided for @studyCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get studyCorrect;

  /// No description provided for @studyIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Let\'s understand why'**
  String get studyIncorrect;

  /// No description provided for @studyPause.
  ///
  /// In en, this message translates to:
  /// **'Pause transition'**
  String get studyPause;

  /// No description provided for @studyContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get studyContinue;

  /// No description provided for @studyNextSecond.
  ///
  /// In en, this message translates to:
  /// **'Next question in one second'**
  String get studyNextSecond;

  /// No description provided for @studyComplete.
  ///
  /// In en, this message translates to:
  /// **'Self-check complete'**
  String get studyComplete;

  /// No description provided for @studyRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get studyRetry;

  /// No description provided for @studyBackArticle.
  ///
  /// In en, this message translates to:
  /// **'Back to article'**
  String get studyBackArticle;

  /// No description provided for @studyMissing.
  ///
  /// In en, this message translates to:
  /// **'Article not found'**
  String get studyMissing;

  /// No description provided for @studyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load study materials'**
  String get studyLoadError;

  /// No description provided for @studyReadingMinutes.
  ///
  /// In en, this message translates to:
  /// **'≈ {minutes} min read'**
  String studyReadingMinutes(int minutes);

  /// No description provided for @studyScore.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total}'**
  String studyScore(int correct, int total);
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
