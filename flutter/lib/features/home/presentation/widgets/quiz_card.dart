import 'package:flutter/material.dart';
import 'package:quiz_master/core/localization/category_localizer.dart';
import 'package:quiz_master/core/localization/l10n_extensions.dart';
import 'package:quiz_master/core/theme/theme_config.dart';
import 'package:quiz_master/core/theme/theme_provider.dart';
import 'package:quiz_master/features/quiz/domain/entities/quiz_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuizCard extends ConsumerWidget {
  final Quiz quiz;
  final VoidCallback onTap;

  const QuizCard({super.key, required this.quiz, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeProvider);
    final themeConfig = themeConfigs[themeType]!;
    final isHoliday = themeType == ThemeType.holiday;
    final count = quiz.questionsCount;
    final categoryName = quiz.categoryString ?? quiz.category?.title ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isHoliday
              ? const Color(0xFFFFFBF0) // ivory-50
              : Colors.grey[900]?.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isHoliday
                ? Colors.amber.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: isHoliday
                  ? Colors.amber.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      quiz.title,
                      style: TextStyle(
                        color: isHoliday
                            ? const Color(0xFF1E293B) // slate-900
                            : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (categoryName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: localizeCategoryPath(context, categoryName)
                            .split(RegExp(r'[/\\]'))
                            .map(
                              (part) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (part !=
                                      localizeCategoryPath(
                                        context,
                                        categoryName,
                                      ).split(RegExp(r'[/\\]')).first)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        '›',
                                        style: TextStyle(
                                          color: isHoliday
                                              ? Colors.amber.shade400
                                              : Colors.grey.shade400,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    part.trim(),
                                    style: TextStyle(
                                      color: isHoliday
                                          ? Colors.amber.shade700
                                          : Colors.grey.shade400,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      quiz.description,
                      style: TextStyle(
                        color: isHoliday
                            ? const Color(0xFF475569) // slate-600
                            : Colors.grey.shade400,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isHoliday ? Colors.white : Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                      border: isHoliday
                          ? Border.all(color: Colors.amber.shade200)
                          : null,
                    ),
                    child: Text(
                      context.l10n.questionsCount(count),
                      style: TextStyle(
                        color: isHoliday ? Colors.amber.shade800 : Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isHoliday
                          ? Colors.amber.shade100.withValues(alpha: 0.5)
                          : themeConfig.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: isHoliday
                          ? Colors.amber.shade900
                          : themeConfig.accentColor,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
