import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_master/core/localization/l10n_extensions.dart';
import 'package:quiz_master/features/auth/presentation/providers/auth_providers.dart';
import 'package:quiz_master/features/admin/presentation/providers/admin_providers.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final auth = authState.asData?.value;
    final leaderboard = ref.watch(adminLeaderboardProvider(10));
    final quizzes = ref.watch(adminQuizzesProvider);

    final isAdmin = auth?.user.role == 'admin';

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.adminTitle)),
      body: !isAdmin
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.adminUnauthorized,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AdminSummaryCard(
                  title: context.l10n.adminSummary,
                  items: [
                    _AdminItem(
                      label: context.l10n.adminCurrentRole,
                      value: auth?.user.role ?? 'admin',
                    ),
                    _AdminItem(
                      label: context.l10n.adminCurrentUser,
                      value: auth?.user.username ?? '-',
                    ),
                    _AdminItem(
                      label: context.l10n.adminTokenState,
                      value: auth?.token.isNotEmpty == true
                          ? context.l10n.adminTokenPresent
                          : context.l10n.adminTokenMissing,
                    ),
                  ],
                ),
                _AdminSummaryCard(
                  title: context.l10n.adminContent,
                  items: [
                    _AdminItem(
                      label: context.l10n.adminQuizCount,
                      value: quizzes.maybeWhen(
                        data: (value) => '${value.length}',
                        orElse: () => context.l10n.loading,
                      ),
                    ),
                    const _AdminItem(
                      label: 'HTTP',
                      value: '/api/admin/quizzes, /api/admin/leaderboard',
                    ),
                  ],
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.adminLeaderboard,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        leaderboard.when(
                          data: (entries) => Column(
                            children: entries.isEmpty
                                ? [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        context.l10n.adminNoLeaderboardData,
                                      ),
                                    ),
                                  ]
                                : entries
                                      .asMap()
                                      .entries
                                      .map(
                                        (entry) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: CircleAvatar(
                                            child: Text('${entry.key + 1}'),
                                          ),
                                          title: Text(entry.value.username),
                                          subtitle: Text(
                                            entry.value.quizTitle ??
                                                context.l10n.quizFallbackTitle,
                                          ),
                                          trailing: Text(
                                            '${entry.value.score}/${entry.value.total}',
                                          ),
                                        ),
                                      )
                                      .toList(),
                          ),
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (error, _) =>
                              Text('${context.l10n.adminLoadError}: $error'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _AdminSummaryCard extends StatelessWidget {
  const _AdminSummaryCard({required this.title, required this.items});

  final String title;
  final List<_AdminItem> items;

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
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(item.label)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item.value, textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminItem {
  const _AdminItem({required this.label, required this.value});

  final String label;
  final String value;
}
