import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
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

  await configureDependencies();

  runApp(
    ProviderScope(
      child: DevicePreview(
        enabled: !kReleaseMode,
        builder: (context) => const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeProvider);
    final themeConfig = themeConfigs[themeType]!;
    final locale = ref.watch(localeProvider);
    final effectiveLocale = kReleaseMode
        ? locale
        : (DevicePreview.locale(context) ?? locale);

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      locale: effectiveLocale,
      theme: _buildTheme(themeConfig, false),
      darkTheme: _buildTheme(themeConfig, true),
      themeMode: ThemeMode.dark,
      supportedLocales: supportedLocales,
      localizationsDelegates: localizationsDelegates,
      builder: DevicePreview.appBuilder,
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
