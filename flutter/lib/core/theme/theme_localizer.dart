import 'package:flutter/material.dart';
import 'package:quiz_master/core/localization/l10n_extensions.dart';

import 'theme_config.dart';

String localizeTheme(BuildContext context, ThemeType theme) {
  switch (theme) {
    case ThemeType.holiday:
      return context.l10n.themeHoliday;
    case ThemeType.night:
      return context.l10n.themeNight;
    case ThemeType.summer:
      return context.l10n.themeSummer;
    case ThemeType.cyber:
      return context.l10n.themeCyber;
    case ThemeType.autumn:
      return context.l10n.themeAutumn;
    case ThemeType.romance:
      return context.l10n.themeRomance;
  }
}
