// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

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
}
