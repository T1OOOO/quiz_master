import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_master/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

final debugModeProvider = NotifierProvider<DebugModeNotifier, bool>(
  DebugModeNotifier.new,
);

class DebugModeNotifier extends Notifier<bool> {
  static const _debugModeKey = 'debug_mode_enabled';

  @override
  bool build() {
    final prefs = getIt<SharedPreferences>();
    return prefs.getBool(_debugModeKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setBool(_debugModeKey, value);
    state = value;
  }
}
