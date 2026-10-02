part of 'main.dart';

const _cream = Color(0xfffff5df);

// The original React holiday assets, not a replacement illustration.
class SourceScaffold extends ConsumerWidget {
  const SourceScaffold({super.key, required this.body});
  final Widget body;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/home-alone-bg.jpg',
            fit: BoxFit.cover,
            cacheWidth: 1600,
          ),
        ),
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: .48)),
        ),
        Theme(
          data: _theme(Brightness.light).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff991b1b),
              surface: _cream,
            ),
            cardTheme: CardThemeData(
              color: _cream,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: _cream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _cream),
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            drawer: Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    ListTile(
                      title: Text(
                        l10n.holidayTitle,
                        style: const TextStyle(
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
                      leading: const Icon(Icons.history),
                      title: Text(l10n.history),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/history');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(l10n.russian),
                      onTap: () {
                        ref
                            .read(localeProvider.notifier)
                            .select(const Locale('ru'));
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(l10n.english),
                      onTap: () {
                        ref
                            .read(localeProvider.notifier)
                            .select(const Locale('en'));
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
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🎄 ${l10n.holidayTitle}',
                                    style: TextStyle(
                                      color: _cream,
                                      fontSize:
                                          MediaQuery.sizeOf(context).width < 600
                                          ? 27
                                          : 42,
                                      fontFamily: 'serif',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.holidaySubtitle,
                                    style: const TextStyle(
                                      color: _cream,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Builder(
                              builder: (context) => IconButton.filled(
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xff991b1b),
                                  foregroundColor: _cream,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                tooltip: MaterialLocalizations.of(context)
                                    .openAppDrawerTooltip,
                                onPressed: () =>
                                    Scaffold.of(context).openDrawer(),
                                icon: const Icon(Icons.menu),
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
  });
  final String title, category;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (category.split('/').first) {
      'Кино' => (const Color(0xffb91c1c), Icons.movie),
      'Гастрономия' => (const Color(0xffb45309), Icons.restaurant),
      'Природа' => (const Color(0xff047857), Icons.eco),
      'Филии' => (const Color(0xffbe185d), Icons.favorite),
      'Психология' => (const Color(0xff6d28d9), Icons.psychology),
      'Филология' => (const Color(0xff92400e), Icons.menu_book),
      'Новый Год' => (const Color(0xff991b1b), Icons.card_giftcard),
      _ => (const Color(0xff334155), Icons.folder),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('folder-$title'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 145,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cream.withValues(alpha: .7), width: 2),
            image: const DecorationImage(
              image: AssetImage('assets/bg_soft_premium.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: .92),
                        color.withValues(alpha: .75),
                        Colors.black.withValues(alpha: .5),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -8,
                bottom: -12,
                child: Icon(
                  icon,
                  color: _cream.withValues(alpha: .12),
                  size: 110,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _cream.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: _cream, size: 24),
                    ),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _cream,
                        fontFamily: 'serif',
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
