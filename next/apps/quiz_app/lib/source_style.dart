part of 'main.dart';

const _cream = Color(0xffe7d8c4);

class SourceScaffold extends ConsumerWidget {
  const SourceScaffold({
    super.key,
    required this.body,
    this.compact = false,
    this.backLocation,
  });
  final Widget body;
  final bool compact;
  final String? backLocation;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/home-alone-bg.jpg',
            fit: BoxFit.cover,
            cacheWidth: 1024,
            excludeFromSemantics: true,
          ),
        ),
        const Positioned.fill(child: ColoredBox(color: Color(0x99502f1c))),
        Theme(
          data: _theme(Brightness.light).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xffe8791b),
              surface: const Color(0xffead9bf),
            ),
            scaffoldBackgroundColor: Colors.transparent,
            textTheme: _theme(Brightness.light).textTheme.apply(
              bodyColor: const Color(0xff655444),
              displayColor: const Color(0xff655444),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xffead9bf),
              elevation: 2,
              shadowColor: const Color(0x38603612),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
                side: const BorderSide(color: Color(0xfff5e6cf), width: 2),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xffead9bf),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
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
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(l10n.studyLibrary),
                      onTap: () {
                        Navigator.pop(context);
                        context.go('/study');
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
                    for (final locale in [
                      const Locale('ru'),
                      const Locale('en'),
                    ])
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(
                          locale.languageCode == 'ru'
                              ? l10n.russian
                              : l10n.english,
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
                                if (backLocation != null) {
                                  context.go(backLocation!);
                                  return;
                                }
                                final uri = GoRouterState.of(context).uri;
                                final folder =
                                    uri.queryParameters['folder'] ?? '';
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
                                  Localizations.localeOf(context)
                                          .languageCode ==
                                      'ru'
                                  ? 'Домой'
                                  : 'Home',
                              onPressed: () => context.go('/library'),
                              icon: const Icon(
                                Icons.home_outlined,
                                color: _cream,
                              ),
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
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (!compact) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.holidaySubtitle,
                                      style: const TextStyle(
                                        color: _cream,
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
                                onPressed: () =>
                                    Scaffold.of(context).openDrawer(),
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
        ),
      ],
    );
  }
}

class SourceFolderCard extends StatelessWidget {
  const SourceFolderCard({
    super.key,
    required this.title,
    required this.category,
    required this.onTap,
    this.coverHeight = 112,
    this.coverAsset,
  });
  final String title, category;
  final VoidCallback onTap;
  final double coverHeight;
  final String? coverAsset;
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
      'Литература' => 'philology',
      'География' => 'geography',
      'Музыка' => 'music',
      'История' => 'history',
      'Мифология' => 'mythology',
      _ => 'nature',
    };
    return Material(
      color: const Color(0xffead9bf),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xfff5e6cf), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('folder-$title'),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              coverAsset ?? 'assets/categories/$cover.jpg',
              height: coverHeight,
              fit: BoxFit.cover,
              cacheWidth: 600,
              excludeFromSemantics: true,
            ),
            Padding(
              padding: coverHeight < 112
                  ? const EdgeInsets.all(8)
                  : const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xff655444),
                  fontSize: coverHeight < 112 ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
