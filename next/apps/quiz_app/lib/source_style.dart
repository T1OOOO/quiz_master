part of 'main.dart';

const _cream = Color(0xff253c34);

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
          seedColor: const Color(0xff256653),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xfff5f4ef),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                compact ? 'Quiz Master' : l10n.holidayTitle,
                                style: TextStyle(
                                  color: _cream,
                                  fontSize: compact ? 17 : 30,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (!compact) ...[
                                const SizedBox(height: 6),
                                Text(
                                  l10n.holidaySubtitle,
                                  style: const TextStyle(
                                    color: Color(0xff64756b),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
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
