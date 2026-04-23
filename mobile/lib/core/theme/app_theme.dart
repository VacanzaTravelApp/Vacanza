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

  /// Auth accent: light uses amber, dark uses blue.
  Color get authAccent {
    final t = vacanzaTokens;
    return Theme.of(this).brightness == Brightness.light
        ? t.vividCoral
        : t.vividBlue;
  }

  /// Auth gradient ends for logo/title/button in light/dark.
  List<Color> get authAccentGradientColors {
    final a = authAccent;
    final isLight = Theme.of(this).brightness == Brightness.light;
    final b = Color.lerp(a, Colors.white, isLight ? 0.16 : 0.18) ?? a;
    return <Color>[a, b];
  }

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

  /// Assistant message bubble fill in light mode.
  ///
  /// More contrast than [lightGlassFieldFill] (which is tuned for inputs/chips),
  /// but still keeps the airy “glass” feel.
  Color get lightGlassBubbleFill {
    final cs = Theme.of(this).colorScheme;
    if (Theme.of(this).brightness != Brightness.light) {
      return cs.surfaceContainerHighest.withValues(alpha: 0.45);
    }

    final base = vacanzaTokens.glassBg;
    // Nudge towards opaque white to stand off from bgMain.
    final lifted = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.86),
      base.withValues(alpha: 0.92),
    );
    // Then blend slightly with surface to avoid “chalky” whites.
    return Color.alphaBlend(
      cs.surface.withValues(alpha: 0.10),
      lifted,
    );
  }
}
