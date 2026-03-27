import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:quiz_master/l10n/app_localizations.dart';
import 'package:quiz_master/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_localizations_provider.g.dart';

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  static const _localeKey = 'app_locale';

  @override
  Locale build() {
    final prefs = getIt<SharedPreferences>();
    final code = prefs.getString(_localeKey) ?? 'ru';
    return Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setString(_localeKey, locale.languageCode);
    state = locale;
  }
}

// Locale provider is auto-generated in app_localizations_provider.g.dart
// Use localeProvider from generated file

final supportedLocales = [const Locale('ru'), const Locale('en')];

final localizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
