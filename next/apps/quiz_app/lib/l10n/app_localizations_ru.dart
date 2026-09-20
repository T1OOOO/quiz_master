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
}
