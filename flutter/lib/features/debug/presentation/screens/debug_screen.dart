import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_master/core/config/app_config.dart';
import 'package:quiz_master/core/debug/debug_mode_provider.dart';
import 'package:quiz_master/core/localization/app_localizations_provider.dart';
import 'package:quiz_master/core/localization/l10n_extensions.dart';
import 'package:quiz_master/core/theme/theme_localizer.dart';
import 'package:quiz_master/core/theme/theme_provider.dart';
import 'package:quiz_master/features/auth/presentation/providers/auth_providers.dart';

final debugHealthProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final dio = Dio(BaseOptions(baseUrl: AppConfig.serverBaseUrl));
  final response = await dio.get('/healthz');
  return {'statusCode': response.statusCode, 'body': response.data};
});

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final auth = authState.asData?.value;
    final theme = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final debugEnabled = ref.watch(debugModeProvider);
    final health = ref.watch(debugHealthProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.debugTitle),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(debugHealthProvider),
            icon: const Icon(Icons.refresh),
            tooltip: context.l10n.debugRefresh,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DebugCard(
            title: context.l10n.debugEnvironment,
            children: [
              _DebugRow(
                label: context.l10n.debugServerBaseUrl,
                value: AppConfig.serverBaseUrl,
              ),
              _DebugRow(
                label: context.l10n.debugApiBaseUrl,
                value: AppConfig.apiBaseUrl,
              ),
              _DebugRow(
                label: context.l10n.debugPlatform,
                value: defaultTargetPlatform.name,
              ),
              _DebugRow(
                label: context.l10n.settingsLanguage,
                value: locale.languageCode,
              ),
              _DebugRow(
                label: context.l10n.settingsTheme,
                value: localizeTheme(context, theme),
              ),
              _DebugRow(
                label: context.l10n.settingsDebugMode,
                value: debugEnabled.toString(),
              ),
            ],
          ),
          _DebugCard(
            title: context.l10n.debugAuth,
            children: [
              _DebugRow(
                label: context.l10n.debugCurrentUser,
                value: auth?.user.username ?? context.l10n.debugAnonymous,
              ),
              _DebugRow(
                label: context.l10n.settingsRole,
                value: auth?.user.role ?? context.l10n.debugNoRole,
              ),
              _DebugRow(
                label: context.l10n.debugTokenPresent,
                value: (auth?.token.isNotEmpty ?? false).toString(),
              ),
            ],
          ),
          _DebugCard(
            title: context.l10n.debugServerHealth,
            children: [
              health.when(
                data: (data) => Column(
                  children: [
                    _DebugRow(
                      label: context.l10n.debugStatusCode,
                      value: '${data['statusCode']}',
                    ),
                    _DebugRow(
                      label: context.l10n.debugPayload,
                      value: '${data['body']}',
                    ),
                  ],
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${context.l10n.debugHealthError}: $error',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebugCard extends StatelessWidget {
  const _DebugCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  const _DebugRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label)),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: SelectableText(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
