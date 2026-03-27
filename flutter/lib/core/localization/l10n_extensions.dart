import 'package:flutter/material.dart';
import 'package:quiz_master/l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
