import 'dart:math' as math;

import 'package:intl/intl.dart';

String formatCountryNumber(num? value, {required bool russian}) {
  if (value == null || !value.isFinite) return '—';
  if (value == 0) return '0';
  final magnitude = math.pow(
    10,
    (math.log(value.abs()) / math.ln10).floor() - 1,
  );
  final rounded = (value / magnitude).round() * magnitude;
  final abs = rounded.abs();
  final divisor = abs >= 1000000000
      ? 1000000000
      : abs >= 1000000
      ? 1000000
      : abs >= 1000
      ? 1000
      : 1;
  final suffix = divisor == 1000000000
      ? (russian ? ' млрд' : ' billion')
      : divisor == 1000000
      ? (russian ? ' млн' : ' million')
      : divisor == 1000
      ? (russian ? ' тыс.' : ' thousand')
      : '';
  final formatted = NumberFormat.decimalPattern(russian ? 'ru' : 'en')
    ..maximumFractionDigits = abs < 1
        ? (1 - (math.log(abs) / math.ln10).floor()).clamp(2, 20)
        : 2;
  final label = formatted.format(rounded / divisor);
  return '≈ $label$suffix';
}
