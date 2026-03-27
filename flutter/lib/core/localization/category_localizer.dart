import 'package:flutter/material.dart';

import 'l10n_extensions.dart';

String localizeCategory(BuildContext context, String value) {
  switch (value.trim()) {
    case 'Cinema':
    case 'Кино':
      return context.l10n.categoryCinema;
    case 'Gastronomy':
    case 'Гастрономия':
      return context.l10n.categoryGastronomy;
    case 'Nature':
    case 'Природа':
      return context.l10n.categoryNature;
    case 'Philias':
    case 'Филии':
      return context.l10n.categoryPhilias;
    case 'Psychology':
    case 'Психология':
      return context.l10n.categoryPsychology;
    case 'Philology':
    case 'Филология':
      return context.l10n.categoryPhilology;
    case 'NewYear':
    case 'New Year':
    case 'Holiday':
    case 'Новый Год':
    case 'Новый год':
      return context.l10n.categoryNewYear;
    case 'Разное':
    case 'General':
      return context.l10n.categoryGeneral;
    default:
      return value;
  }
}

String localizeCategoryPath(BuildContext context, String value) {
  return value
      .split(RegExp(r'[/\\]'))
      .map((part) => localizeCategory(context, part))
      .join(' / ');
}
