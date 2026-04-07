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
        secondary: tokens.vividCoral,
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
        secondary: tokens.vividBlue,
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

  /// Harita rozetleri / aktif action: sabah web coral (AI pill), gece mavi.
  Color get mapControlAccent {
    final t = vacanzaTokens;
    return Theme.of(this).brightness == Brightness.light
        ? t.vividCoral
        : t.vividBlue;
  }

  /// [ActionIconButton] `isActive` (kalem/3D) ile aynı doğrusal gradyan uçları.
  List<Color> get mapControlActiveGradientColors {
    final vivid = mapControlAccent;
    final vividHi = Theme.of(this).brightness == Brightness.light
        ? const Color(0xFFEE5253)
        : Color.lerp(vivid, Colors.white, 0.15)!;
    return <Color>[vivid, vividHi];
  }

  /// Light-mode glass panel tint (use with [BackdropFilter]). Airy white, not muddy gray.
  Color get lightGlassPanelColor {
    final cs = Theme.of(this).colorScheme;
    if (Theme.of(this).brightness != Brightness.light) return cs.surface;
    return Color.alphaBlend(
      Colors.white.withValues(alpha: 0.90),
      cs.surface.withValues(alpha: 0.94),
    );
  }

  /// Inputs / chips on light glass — warm white inset, not [surfaceContainerHighest] gray.
  Color get lightGlassFieldFill {
    final cs = Theme.of(this).colorScheme;
    if (Theme.of(this).brightness != Brightness.light) {
      return cs.surfaceContainerHighest.withValues(alpha: 0.65);
    }
    return Color.alphaBlend(
      Colors.white.withValues(alpha: 0.76),
      cs.surface.withValues(alpha: 0.98),
    );
  }
}
