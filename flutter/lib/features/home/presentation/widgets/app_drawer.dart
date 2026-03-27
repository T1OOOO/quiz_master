import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_master/core/debug/debug_mode_provider.dart';
import 'package:quiz_master/core/localization/l10n_extensions.dart';
import 'package:quiz_master/features/auth/presentation/providers/auth_providers.dart';
import 'package:quiz_master/router/app_router.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final auth = authState.asData?.value;
    final debugEnabled = ref.watch(debugModeProvider);
    final isAdmin = auth?.user.role == 'admin';

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.appTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    auth == null
                        ? context.l10n.drawerGuest
                        : '${auth.user.username} • ${auth.user.role}',
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(context.l10n.home),
              onTap: () {
                Navigator.of(context).pop();
                const HomeRoute().go(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(context.l10n.settingsTitle),
              onTap: () {
                Navigator.of(context).pop();
                const SettingsRoute().go(context);
              },
            ),
            if (debugEnabled)
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: Text(context.l10n.debugTitle),
                onTap: () {
                  Navigator.of(context).pop();
                  const DebugRoute().go(context);
                },
              ),
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: Text(context.l10n.adminTitle),
                onTap: () {
                  Navigator.of(context).pop();
                  const AdminRoute().go(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
