import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_master/core/di/injection.dart';
import 'package:quiz_master/core/localization/app_localizations_provider.dart';
import 'package:quiz_master/core/localization/l10n_extensions.dart';
import 'package:quiz_master/core/theme/theme_config.dart';
import 'package:quiz_master/core/theme/theme_provider.dart';
import 'package:quiz_master/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await configureDependencies();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeProvider);
    final themeConfig = themeConfigs[themeType]!;
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(themeConfig, false),
      darkTheme: _buildTheme(themeConfig, true),
      themeMode: ThemeMode.dark,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: localizationsDelegates,
      routerConfig: ref.watch(routerProvider),
    );
  }

  ThemeData _buildTheme(ThemeConfig config, bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: config.accentColor,
        onPrimary: config.textPrimary,
        secondary: config.secondaryColor,
        onSecondary: config.textPrimary,
        error: config.errorColor,
        onError: Colors.white,
        surface: config.cardColor,
        onSurface: config.textPrimary,
      ),
      scaffoldBackgroundColor: config.primaryColor,
      cardColor: config.cardColor,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: config.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: config.textPrimary),
        bodyMedium: TextStyle(color: config.textSecondary),
      ),
    );
  }
}
