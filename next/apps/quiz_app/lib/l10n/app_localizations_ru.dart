// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get holidayTitle => 'Викторины на каждый день';

  @override
  String get holidaySubtitle => 'Выбирайте тему. Играйте короткими раундами.';

  @override
  String roundLabel(int number) {
    return 'Раунд $number';
  }

  @override
  String get nextRound => 'Следующий раунд';

  @override
  String roundQuestions(int count) {
    return '$count вопросов';
  }

  @override
  String get browseQuizzes => 'Все викторины';

  @override
  String get searchQuizzes => 'Поиск по названию, описанию или категории';

  @override
  String get categories => 'Категории';

  @override
  String get catalogRoot => 'Все категории';

  @override
  String catalogInventory(int packs, int questions) {
    return 'Викторин: $packs · вопросов: $questions';
  }

  @override
  String get catalogPreview =>
      'Полная коллекция переносится. В новом API пока можно пройти только «Один дома 1 (Часть 1)».';

  @override
  String get packPending => 'Прохождение ещё не подключено';

  @override
  String get noSearchResults => 'По вашему запросу ничего не найдено.';

  @override
  String get catalogTitle => 'Каталог викторин';

  @override
  String get galleryTitle => 'Галерея публичных примеров';

  @override
  String get joinAdmissionOnly =>
      'Этот токен предназначен только для входа и не даёт прав ведущего.';

  @override
  String get yourAnswer => 'Ваш ответ';

  @override
  String get submitAnswer => 'Отправить ответ';

  @override
  String get openGallery => 'Открыть галерею';

  @override
  String get practiceUnranked => 'Тренировка без рейтинга';

  @override
  String get joinTitle => 'Присоединиться к викторине';

  @override
  String inviteToken(String token) {
    return 'Токен приглашения: $token';
  }

  @override
  String get english => 'English';

  @override
  String get russian => 'Русский';

  @override
  String get theme => 'Тема';

  @override
  String get lightTheme => 'Светлая тема';

  @override
  String get darkTheme => 'Тёмная тема';

  @override
  String get systemTheme => 'Системная тема';

  @override
  String answer(String answer) {
    return 'Ответ: $answer';
  }

  @override
  String get displayName => 'Имя';

  @override
  String get continueLabel => 'Продолжить';

  @override
  String get startQuiz => 'Начать викторину';

  @override
  String get finishQuiz => 'Завершить викторину';

  @override
  String get history => 'История';

  @override
  String get noHistory => 'Завершённых викторин пока нет';

  @override
  String get retry => 'Повторить';

  @override
  String get loading => 'Загрузка…';

  @override
  String get submitting => 'Отправка…';

  @override
  String get finishing => 'Завершение…';

  @override
  String score(int score) {
    return 'Счёт: $score';
  }

  @override
  String questionsCount(int count) {
    return 'Вопросов: $count';
  }

  @override
  String get catalogEmpty => 'Доступных викторин пока нет.';

  @override
  String get catalogLoadError => 'Не удалось загрузить викторины.';

  @override
  String get historyLoadError => 'Не удалось загрузить историю.';

  @override
  String get resultsLoadError => 'Не удалось загрузить результаты.';

  @override
  String get journeyError => 'Не удалось продолжить.';

  @override
  String get newQuiz => 'Новая викторина';

  @override
  String get resumeAutoAdvance => 'Продолжить автоматически';

  @override
  String autoAdvanceIn(int seconds) {
    return 'Следующий через $seconds с · Пауза';
  }

  @override
  String get studyLibrary => 'Учебная библиотека';

  @override
  String get studyIntro =>
      'Разберитесь в теме через примеры и связи, затем проверьте себя на 20 вопросах.';

  @override
  String get studyRead => 'Читать материал';

  @override
  String get studyContents => 'Содержание';

  @override
  String get studyPractice => 'Самопроверка · 20 вопросов';

  @override
  String get studySources => 'Источники и дальнейшее чтение';

  @override
  String get studyObjectives => 'После изучения вы сможете';

  @override
  String get studyUnranked => 'Учебная самопроверка · без рейтинга';

  @override
  String get studyCorrect => 'Верно';

  @override
  String get studyIncorrect => 'Попробуем разобраться';

  @override
  String get studyPause => 'Остановить переход';

  @override
  String get studyContinue => 'Продолжить';

  @override
  String get studyNextSecond => 'Следующий вопрос через 1 секунду';

  @override
  String get studyComplete => 'Самопроверка завершена';

  @override
  String get studyRetry => 'Попробовать ещё раз';

  @override
  String get studyBackArticle => 'К статье';

  @override
  String get studyMissing => 'Материал не найден';

  @override
  String get studyLoadError => 'Не удалось загрузить материалы';

  @override
  String studyReadingMinutes(int minutes) {
    return '≈ $minutes мин чтения';
  }

  @override
  String studyScore(int correct, int total) {
    return '$correct из $total';
  }
}
