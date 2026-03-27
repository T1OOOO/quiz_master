import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_master/core/debug/debug_mode_provider.dart';
import 'package:quiz_master/core/localization/app_localizations_provider.dart';
import 'package:quiz_master/core/localization/l10n_extensions.dart';
import 'package:quiz_master/core/theme/theme_config.dart';
import 'package:quiz_master/core/theme/theme_localizer.dart';
import 'package:quiz_master/core/theme/theme_provider.dart';
import 'package:quiz_master/features/auth/presentation/providers/auth_providers.dart';
import 'package:quiz_master/router/app_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final theme = ref.watch(themeProvider);
    final debugEnabled = ref.watch(debugModeProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(title: context.l10n.settingsAppearance),
          Card(
            child: ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(context.l10n.settingsTheme),
              subtitle: Text(localizeTheme(context, theme)),
              trailing: DropdownButton<ThemeType>(
                value: theme,
                underline: const SizedBox.shrink(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(themeProvider.notifier).setTheme(value);
                  }
                },
                items: ThemeType.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(localizeTheme(context, value)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(context.l10n.settingsLanguage),
              subtitle: Text(
                locale.languageCode == 'ru'
                    ? context.l10n.languageRussian
                    : context.l10n.languageEnglish,
              ),
              trailing: SegmentedButton<Locale>(
                segments: [
                  ButtonSegment(
                    value: const Locale('ru'),
                    label: Text(context.l10n.languageRussianShort),
                  ),
                  ButtonSegment(
                    value: const Locale('en'),
                    label: Text(context.l10n.languageEnglishShort),
                  ),
                ],
                selected: {locale},
                onSelectionChanged: (selection) {
                  ref.read(localeProvider.notifier).setLocale(selection.first);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: context.l10n.settingsAdvanced),
          SwitchListTile(
            value: debugEnabled,
            onChanged: (value) {
              ref.read(debugModeProvider.notifier).setEnabled(value);
            },
            secondary: const Icon(Icons.bug_report_outlined),
            title: Text(context.l10n.settingsDebugMode),
            subtitle: Text(context.l10n.settingsDebugModeDescription),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: context.l10n.settingsAccount),
          authState.when(
            data: (auth) {
              if (auth == null) {
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(context.l10n.settingsSignedOut),
                        subtitle: Text(
                          context.l10n.settingsSignedOutDescription,
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton(
                              onPressed: () => _showAuthDialog(
                                context,
                                ref,
                                mode: _AuthDialogMode.login,
                              ),
                              child: Text(context.l10n.authLogin),
                            ),
                            OutlinedButton(
                              onPressed: () => _showAuthDialog(
                                context,
                                ref,
                                mode: _AuthDialogMode.register,
                              ),
                              child: Text(context.l10n.authRegister),
                            ),
                            TextButton(
                              onPressed: () => _showAuthDialog(
                                context,
                                ref,
                                mode: _AuthDialogMode.guest,
                              ),
                              child: Text(context.l10n.authGuest),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: Text(auth.user.username),
                      subtitle: Text(
                        '${context.l10n.settingsRole}: ${auth.user.role}',
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: Text(context.l10n.authLogout),
                      onTap: () async {
                        await ref.read(authStateProvider.notifier).logout();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.settingsLoggedOut),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(context.l10n.settingsAccountError),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: context.l10n.settingsNavigation),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: Text(context.l10n.debugTitle),
                  subtitle: Text(context.l10n.debugSubtitle),
                  onTap: () => const DebugRoute().go(context),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final authState = ref.watch(authStateProvider);
                    final auth = authState.asData?.value;
                    final canOpenAdmin = auth?.user.role == 'admin';
                    return ListTile(
                      leading: const Icon(Icons.admin_panel_settings_outlined),
                      title: Text(context.l10n.adminTitle),
                      subtitle: Text(
                        canOpenAdmin
                            ? context.l10n.adminSubtitle
                            : context.l10n.adminAccessHint,
                      ),
                      enabled: canOpenAdmin,
                      onTap: canOpenAdmin
                          ? () => const AdminRoute().go(context)
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAuthDialog(
    BuildContext context,
    WidgetRef ref, {
    required _AuthDialogMode mode,
  }) async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final emailController = TextEditingController();
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(switch (mode) {
            _AuthDialogMode.login => context.l10n.authLogin,
            _AuthDialogMode.register => context.l10n.authRegister,
            _AuthDialogMode.guest => context.l10n.authGuest,
          }),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: context.l10n.authUsername,
                ),
              ),
              if (mode != _AuthDialogMode.guest) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.authPassword,
                  ),
                ),
              ],
              if (mode == _AuthDialogMode.register) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: context.l10n.authEmailOptional,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.confirm),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      switch (mode) {
        case _AuthDialogMode.login:
          if (usernameController.text.trim().isEmpty ||
              passwordController.text.isEmpty) {
            throw Exception(l10n.authUsernameRequired);
          }
          await ref
              .read(authStateProvider.notifier)
              .login(usernameController.text.trim(), passwordController.text);
        case _AuthDialogMode.register:
          if (usernameController.text.trim().isEmpty ||
              passwordController.text.isEmpty) {
            throw Exception(l10n.authUsernameRequired);
          }
          await ref
              .read(authStateProvider.notifier)
              .register(
                usernameController.text.trim(),
                passwordController.text,
                email: emailController.text.trim().isEmpty
                    ? null
                    : emailController.text.trim(),
              );
        case _AuthDialogMode.guest:
          await ref
              .read(authStateProvider.notifier)
              .guestLogin(usernameController.text.trim());
      }

      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.authSuccess)));
    } catch (error) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('${l10n.authError}: $error')),
      );
    } finally {
      usernameController.dispose();
      passwordController.dispose();
      emailController.dispose();
    }
  }
}

enum _AuthDialogMode { login, register, guest }

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
