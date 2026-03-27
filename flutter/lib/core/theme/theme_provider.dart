import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:quiz_master/core/di/injection.dart';
import 'package:quiz_master/core/theme/theme_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  static const _themeKey = 'selected_theme';

  @override
  ThemeType build() {
    final prefs = getIt<SharedPreferences>();
    final stored = prefs.getString(_themeKey);
    return ThemeType.values.firstWhere(
      (theme) => theme.name == stored,
      orElse: () => ThemeType.holiday,
    );
  }

  Future<void> setTheme(ThemeType theme) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setString(_themeKey, theme.name);
    state = theme;
  }

  Future<void> toggleTheme() async {
    final themes = ThemeType.values;
    final currentIndex = themes.indexOf(state);
    final nextIndex = (currentIndex + 1) % themes.length;
    await setTheme(themes[nextIndex]);
  }
}

// Theme provider is auto-generated in theme_provider.g.dart
