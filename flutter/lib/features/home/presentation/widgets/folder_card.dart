import 'package:flutter/material.dart';
import 'package:quiz_master/core/localization/category_localizer.dart';
import 'package:quiz_master/core/theme/category_styles.dart';
import 'package:quiz_master/core/theme/theme_config.dart';
import 'package:quiz_master/core/theme/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FolderCard extends ConsumerWidget {
  final String folder;
  final VoidCallback onTap;

  const FolderCard({super.key, required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeProvider);
    final isHoliday = themeType == ThemeType.holiday;
    final style = getCategoryStyle(folder);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: style.gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHoliday
                ? Colors.amber.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
            width: isHoliday ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative icon in background
            Positioned(
              right: -16,
              bottom: -16,
              child: Icon(
                style.icon,
                size: 110,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            // Glass effect overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(style.icon, color: Colors.white, size: 18),
                  ),
                  // Folder name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizeCategory(context, folder),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 2,
                        width: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
