import 'package:flutter/material.dart';

import 'vacanza_tokens.dart';

/// Web MapPage `theme-day` / `theme-night` ile uyumlu [ThemeData].
abstract final class AppTheme {
  static ThemeData light() {
    const tokens = VacanzaTokens.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: tokens.vividBlue,
        onPrimary: Colors.white,
        surface: tokens.cardBg,
        onSurface: tokens.textMain,
        onSurfaceVariant: tokens.textSub,
        outline: tokens.cardBorder,
      ),
      scaffoldBackgroundColor: tokens.bgMain,
      fontFamily: 'SF Pro',
      extensions: const [tokens],
    );
  }

  static ThemeData dark() {
    const tokens = VacanzaTokens.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: tokens.vividBlue,
        onPrimary: const Color(0xFF0A0A0A),
        surface: tokens.cardBg,
        onSurface: tokens.textMain,
        onSurfaceVariant: tokens.textSub,
        outline: tokens.cardBorder,
      ),
      scaffoldBackgroundColor: tokens.bgMain,
      fontFamily: 'SF Pro',
      extensions: const [tokens],
    );
  }
}

extension VacanzaTokensX on BuildContext {
  VacanzaTokens get vacanzaTokens =>
      Theme.of(this).extension<VacanzaTokens>() ?? VacanzaTokens.light;
}
