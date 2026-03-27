import 'package:flutter/material.dart';

enum ThemeType { holiday, night, summer, cyber, autumn, romance }

class ThemeConfig {
  final String name;
  final String? backgroundImage;
  final Color primaryColor;
  final Color secondaryColor;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentColor;
  final Color successColor;
  final Color errorColor;

  const ThemeConfig({
    required this.name,
    this.backgroundImage,
    required this.primaryColor,
    required this.secondaryColor,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.accentColor,
    required this.successColor,
    required this.errorColor,
  });
}

final themeConfigs = {
  ThemeType.holiday: ThemeConfig(
    name: 'Новый год',
    backgroundImage: 'assets/images/home-alone-bg.jpg',
    primaryColor: const Color(0xFF450A0A), // red-950
    secondaryColor: const Color(0xFF7F1D1D), // red-900
    cardColor: const Color(0xFFFFFBF0), // ivory-50
    textPrimary: const Color(0xFF0F172A), // slate-900
    textSecondary: const Color(0xFF475569), // slate-600
    accentColor: const Color(0xFFDC2626), // red-600
    successColor: const Color(0xFF22C55E), // green-500
    errorColor: const Color(0xFFEF4444), // red-500
  ),
  ThemeType.night: ThemeConfig(
    name: 'Ночь',
    primaryColor: const Color(0xFF0F172A), // slate-900
    secondaryColor: const Color(0xFF1E293B), // slate-800
    cardColor: const Color(0xFF1E293B), // slate-800
    textPrimary: const Color(0xFFF8FAFC), // slate-50
    textSecondary: const Color(0xFF94A3B8), // slate-400
    accentColor: const Color(0xFF3B82F6), // blue-500
    successColor: const Color(0xFF22C55E), // green-500
    errorColor: const Color(0xFFEF4444), // red-500
  ),
  ThemeType.summer: ThemeConfig(
    name: 'Лето',
    primaryColor: const Color(0xFFFEF3C7), // amber-100
    secondaryColor: const Color(0xFFFDE68A), // amber-200
    cardColor: const Color(0xFFFFFFFF),
    textPrimary: const Color(0xFF78350F), // amber-900
    textSecondary: const Color(0xFF92400E), // amber-800
    accentColor: const Color(0xFFF59E0B), // amber-500
    successColor: const Color(0xFF22C55E), // green-500
    errorColor: const Color(0xFFEF4444), // red-500
  ),
  ThemeType.cyber: ThemeConfig(
    name: 'Кибер',
    primaryColor: const Color(0xFF0A0E27),
    secondaryColor: const Color(0xFF1A1F3A),
    cardColor: const Color(0xFF1A1F3A),
    textPrimary: const Color(0xFF00FF88), // cyber green
    textSecondary: const Color(0xFF00CC6A),
    accentColor: const Color(0xFF00FF88),
    successColor: const Color(0xFF00FF88),
    errorColor: const Color(0xFFFF0066), // cyber pink
  ),
  ThemeType.autumn: ThemeConfig(
    name: 'Осень',
    primaryColor: const Color(0xFF7C2D12), // orange-900
    secondaryColor: const Color(0xFF9A3412), // orange-800
    cardColor: const Color(0xFFFFF7ED), // orange-50
    textPrimary: const Color(0xFF7C2D12), // orange-900
    textSecondary: const Color(0xFF9A3412), // orange-800
    accentColor: const Color(0xFFEA580C), // orange-600
    successColor: const Color(0xFF22C55E), // green-500
    errorColor: const Color(0xFFEF4444), // red-500
  ),
  ThemeType.romance: ThemeConfig(
    name: 'Романтика',
    primaryColor: const Color(0xFF831843), // pink-900
    secondaryColor: const Color(0xFF9F1239), // rose-900
    cardColor: const Color(0xFFFFF1F2), // rose-50
    textPrimary: const Color(0xFF831843), // pink-900
    textSecondary: const Color(0xFF9F1239), // rose-900
    accentColor: const Color(0xFFEC4899), // pink-500
    successColor: const Color(0xFF22C55E), // green-500
    errorColor: const Color(0xFFEF4444), // red-500
  ),
};
