import 'package:flutter/material.dart';

class CategoryStyle {
  final List<Color> gradientColors;
  final IconData icon;

  const CategoryStyle({required this.gradientColors, required this.icon});
}

final categoryStyles = <String, CategoryStyle>{
  // Cinema: Red/Wine
  'Cinema': CategoryStyle(
    gradientColors: [
      const Color.fromRGBO(220, 38, 38, 0.85),
      const Color.fromRGBO(153, 27, 27, 0.95),
    ],
    icon: Icons.movie,
  ),
  'Кино': CategoryStyle(
    gradientColors: [
      const Color.fromRGBO(220, 38, 38, 0.85),
      const Color.fromRGBO(153, 27, 27, 0.95),
    ],
    icon: Icons.movie,
  ),

  // Gastronomy: Orange/Amber
  'Gastronomy': CategoryStyle(
    gradientColors: [
      const Color.fromRGBO(245, 158, 11, 0.85),
      const Color.fromRGBO(180, 83, 9, 0.95),
    ],
    icon: Icons.restaurant,
  ),
  'Гастрономия': CategoryStyle(
    gradientColors: [
      const Color.fromRGBO(245, 158, 11, 0.85),
      const Color.fromRGBO(180, 83, 9, 0.95),
    ],
    icon: Icons.restaurant,
  ),

  // Nature: Emerald/Forest
  'Nature': CategoryStyle(
    gradientColors: [
      const Color.fromRGBO(16, 185, 129, 0.85),
      const Color.fromRGBO(6, 95, 70, 0.95),
    ],
    icon: Icons.eco,
  ),
  'Природа': CategoryStyle(
    gradientColors: [
      const Color.fromRGBO(16, 185, 129, 0.85),
      const Color.fromRGBO(6, 95, 70, 0.95),
    ],
    icon: Icons.eco,
  ),

  // Philias: Pink/Rose
  'Philias': CategoryStyle(
    gradientColors: [
      const Color.fromRGBO(236, 72, 153, 0.85),
      const Color.fromRGBO(157, 23, 77, 0.95),
    ],
    icon: Icons.favorite,
  ),
  'Филии': CategoryStyle(
    gradientColors: [
      const Color.fromRGBO(236, 72, 153, 0.85),
      const Color.fromRGBO(157, 23, 77, 0.95),
    ],
    icon: Icons.favorite,
  ),

  // Psychology: Violet/Indigo
  'Psychology': CategoryStyle(
    gradientColors: [
      const Color.fromRGBO(139, 92, 246, 0.85),
      const Color.fromRGBO(91, 33, 182, 0.95),
    ],
    icon: Icons.psychology,
  ),
  'Психология': CategoryStyle(
    gradientColors: [
      const Color.fromRGBO(139, 92, 246, 0.85),
      const Color.fromRGBO(91, 33, 182, 0.95),
    ],
    icon: Icons.psychology,
  ),

  // Philology: Amber/Brown
  'Philology': CategoryStyle(
    gradientColors: [
      const Color.fromRGBO(217, 119, 6, 0.85),
      const Color.fromRGBO(120, 53, 15, 0.95),
    ],
    icon: Icons.menu_book,
  ),
  'Филология': CategoryStyle(
    gradientColors: [
      const Color.fromRGBO(217, 119, 6, 0.85),
      const Color.fromRGBO(120, 53, 15, 0.95),
    ],
    icon: Icons.menu_book,
  ),

  // New Year: Red/Slate
  'NewYear': CategoryStyle(
    gradientColors: [
      const Color.fromRGBO(220, 38, 38, 0.9),
      const Color.fromRGBO(15, 23, 42, 0.95),
    ],
    icon: Icons.card_giftcard,
  ),
  'New Year': CategoryStyle(
    gradientColors: [
      const Color.fromRGBO(220, 38, 38, 0.9),
      const Color.fromRGBO(15, 23, 42, 0.95),
    ],
    icon: Icons.card_giftcard,
  ),
  'Holiday': CategoryStyle(
    gradientColors: [
      const Color.fromRGBO(220, 38, 38, 0.9),
      const Color.fromRGBO(15, 23, 42, 0.95),
    ],
    icon: Icons.card_giftcard,
  ),
  'Новый Год': CategoryStyle(
    gradientColors: [
      const Color.fromRGBO(220, 38, 38, 0.9),
      const Color.fromRGBO(15, 23, 42, 0.95),
    ],
    icon: Icons.card_giftcard,
  ),
  'Новый год': CategoryStyle(
    gradientColors: [
      const Color.fromRGBO(220, 38, 38, 0.9),
      const Color.fromRGBO(15, 23, 42, 0.95),
    ],
    icon: Icons.card_giftcard,
  ),
};

CategoryStyle getCategoryStyle(String folder) {
  // Try exact match first
  if (categoryStyles.containsKey(folder)) {
    return categoryStyles[folder]!;
  }

  // Try case-insensitive search
  final foundKey = categoryStyles.keys.firstWhere(
    (k) =>
        folder.toLowerCase().contains(k.toLowerCase()) ||
        k.toLowerCase().contains(folder.toLowerCase()),
    orElse: () => '',
  );

  if (foundKey.isNotEmpty) {
    return categoryStyles[foundKey]!;
  }

  // Default style
  return const CategoryStyle(
    gradientColors: [
      Color.fromRGBO(100, 116, 139, 0.9),
      Color.fromRGBO(71, 85, 105, 0.95),
    ],
    icon: Icons.folder,
  );
}
