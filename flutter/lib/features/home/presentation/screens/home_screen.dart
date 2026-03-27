import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_master/core/localization/category_localizer.dart';
import 'package:quiz_master/core/localization/l10n_extensions.dart';
import 'package:quiz_master/core/theme/theme_config.dart';
import 'package:quiz_master/core/theme/theme_provider.dart';
import 'package:quiz_master/features/home/presentation/providers/home_providers.dart';
import 'package:quiz_master/features/home/presentation/widgets/app_drawer.dart';
import 'package:quiz_master/features/home/presentation/widgets/folder_card.dart';
import 'package:quiz_master/features/home/presentation/widgets/quiz_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToFolder(String folder) {
    ref.read(currentPathProvider.notifier).add(folder);
  }

  void _navigateBreadcrumb(int index) {
    ref.read(currentPathProvider.notifier).navigateTo(index);
  }

  void _selectQuiz(String id) {
    final pathStack = ref.read(currentPathProvider);
    if (pathStack.length > 1) {
      final categories = pathStack.sublist(1).join('/');
      context.push('/quiz/$categories/$id');
    } else {
      context.push('/quiz/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayData = ref.watch(filteredQuizzesProvider);
    final pathStack = ref.watch(currentPathProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final themeType = ref.watch(themeProvider);
    final themeConfig = themeConfigs[themeType]!;
    final isHoliday = themeType == ThemeType.holiday;

    return Scaffold(
      drawer: const AppDrawer(),
      body: Container(
        decoration: themeConfig.backgroundImage != null
            ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(themeConfig.backgroundImage!),
                  fit: BoxFit.cover,
                ),
              )
            : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    themeConfig.primaryColor,
                    themeConfig.secondaryColor,
                  ],
                ),
              ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: isHoliday ? 0.1 : 0.3),
                Colors.black.withValues(alpha: isHoliday ? 0.2 : 0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHoliday
                                  ? context.l10n.homeHolidayTitle
                                  : context.l10n.homeTitle,
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isHoliday
                                  ? context.l10n.homeHolidaySubtitle
                                  : context.l10n.homeSubtitle,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          tooltip: context.l10n.openMenu,
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).update(value);
                    },
                    decoration: InputDecoration(
                      hintText: context.l10n.searchPlaceholder,
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[900]?.withValues(alpha: 0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 24),

                  // Breadcrumbs
                  if (searchQuery.isEmpty && pathStack.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: pathStack.asMap().entries.map((entry) {
                        final index = entry.key;
                        final part = entry.value;
                        return GestureDetector(
                          onTap: () => _navigateBreadcrumb(index),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (index == 0)
                                const Icon(
                                  Icons.home,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              Text(
                                index == 0
                                    ? context.l10n.home
                                    : localizeCategory(context, part),
                                style: TextStyle(
                                  color: index == pathStack.length - 1
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: index == pathStack.length - 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (index < pathStack.length - 1)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    Icons.chevron_right,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  if (searchQuery.isEmpty && pathStack.isNotEmpty)
                    const SizedBox(height: 24),

                  // Categories Section
                  if (displayData.folders.isNotEmpty) ...[
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.categories,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                      itemCount: displayData.folders.length,
                      itemBuilder: (context, index) {
                        final folder = displayData.folders[index];
                        return FolderCard(
                          folder: folder,
                          onTap: () => _navigateToFolder(folder),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Quizzes Section
                  if (displayData.items.isNotEmpty) ...[
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.quizzes,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 360;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 1,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: isCompact ? 1.45 : 2.5,
                              ),
                          itemCount: displayData.items.length,
                          itemBuilder: (context, index) {
                            final quiz = displayData.items[index];
                            return QuizCard(
                              quiz: quiz,
                              onTap: () => _selectQuiz(quiz.id),
                            );
                          },
                        );
                      },
                    ),
                  ],
                  if (displayData.folders.isEmpty && displayData.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          searchQuery.isNotEmpty
                              ? context.l10n.noSearchResults
                              : context.l10n.noQuizzesAvailable,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
