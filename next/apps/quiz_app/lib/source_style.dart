part of 'main.dart';

const _cream = Color(0xff25170c);

class SourceScaffold extends ConsumerWidget {
  const SourceScaffold({super.key, required this.body, this.compact = false});
  final Widget body;
  final bool compact;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Theme(
      data: _theme(Brightness.light).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffe8791b),
          surface: const Color(0xfffffcf6),
        ),
        scaffoldBackgroundColor: const Color(0xfff7f0e7),
        cardTheme: CardThemeData(
          color: const Color(0xfffbf3e8),
          elevation: 2,
          shadowColor: const Color(0x38603612),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xfffffcf6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _cream),
        ),
      ),
      child: Scaffold(
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              children: [
                const ListTile(
                  title: Text(
                    'Quiz Master',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: Text(l10n.browseQuizzes),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/library');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(l10n.history),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/history');
                  },
                ),
                for (final locale in [const Locale('ru'), const Locale('en')])
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(
                      locale.languageCode == 'ru' ? l10n.russian : l10n.english,
                    ),
                    onTap: () {
                      ref.read(localeProvider.notifier).select(locale);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1032),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      compact ? 4 : 16,
                      20,
                      compact ? 4 : 12,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          key: const Key('nav-back'),
                          tooltip: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                              return;
                            }
                            final uri = GoRouterState.of(context).uri;
                            final folder = uri.queryParameters['folder'] ?? '';
                            final parent = folder
                                .split('/')
                                .take(folder.split('/').length - 1)
                                .join('/');
                            context.go(
                              Uri(
                                path: '/library',
                                queryParameters: parent.isEmpty
                                    ? null
                                    : {'folder': parent},
                              ).toString(),
                            );
                          },
                          icon: const Icon(Icons.arrow_back, color: _cream),
                        ),
                        IconButton(
                          key: const Key('nav-home'),
                          tooltip:
                              Localizations.localeOf(context).languageCode ==
                                  'ru'
                              ? 'Домой'
                              : 'Home',
                          onPressed: () => context.go('/library'),
                          icon: const Icon(Icons.home_outlined, color: _cream),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quiz Master',
                                style: TextStyle(
                                  color: _cream,
                                  fontSize: compact ? 17 : 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (!compact) ...[
                                const SizedBox(height: 6),
                                Text(
                                  l10n.holidaySubtitle,
                                  style: const TextStyle(
                                    color: Color(0xff6e563c),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Builder(
                          builder: (context) => IconButton(
                            tooltip: MaterialLocalizations.of(context)
                                .openAppDrawerTooltip,
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            icon: const Icon(Icons.menu, color: _cream),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: _cream),
                  child: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SourceFolderCard extends StatelessWidget {
  const SourceFolderCard({
    super.key,
    required this.title,
    required this.category,
    required this.onTap,
  });
  final String title, category;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final cover = switch (category.split('/').first) {
      'Гастрономия' => 'food',
      'Кино' => 'cinema',
      'Новый Год' => 'holiday',
      'Природа' => 'nature',
      'Психология' => 'psychology',
      'Филии' => 'philias',
      'Филология' => 'philology',
      _ => 'nature',
    };
    return Material(
      color: const Color(0xfffbf3e8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Colors.white, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('folder-$title'),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'assets/categories/$cover.jpg',
              height: 112,
              fit: BoxFit.cover,
              cacheWidth: 600,
              excludeFromSemantics: true,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _cream,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
