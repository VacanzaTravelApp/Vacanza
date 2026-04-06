import 'package:flutter/material.dart';

import 'theme_models.dart';
import 'theme_night_schedule.dart';

ThemeMode resolveThemeMode(ThemeCubitState s) {
  switch (s.strategy) {
    case AppThemeStrategy.system:
      return ThemeMode.system;
    case AppThemeStrategy.manual:
      return s.manualMode;
    case AppThemeStrategy.scheduled:
      final now = DateTime.now();
      final m = now.hour * 60 + now.minute;
      return isNightMinutes(m, s.nightStartMinutes, s.nightEndMinutes)
          ? ThemeMode.dark
          : ThemeMode.light;
  }
}
