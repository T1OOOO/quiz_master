import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Initialize and configure all dependencies
Future<void> configureDependencies() async {
  // External Dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
}

/// Check if dependencies are configured
bool get isDependenciesConfigured => getIt.isRegistered<SharedPreferences>();
