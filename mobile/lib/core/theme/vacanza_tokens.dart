import 'package:flutter/material.dart';

/// Web [MapPage.css] `.theme-day` / `.theme-night` ile hizalı yüzey ve metin token’ları.
@immutable
class VacanzaTokens extends ThemeExtension<VacanzaTokens> {
  const VacanzaTokens({
    required this.bgMain,
    required this.cardBg,
    required this.glassBg,
    required this.cardBorder,
    required this.textMain,
    required this.textSub,
    required this.vividBlue,
    required this.vividAmber,
    required this.vividCoral,
    required this.vividSubtleBg,
    required this.pillSurface,
    required this.pillBorder,
    required this.pillShadowAccent,
    required this.overlayScrim,
    required this.actionBarInactiveBg,
    required this.actionBarIcon,
    required this.actionBarBorder,
  });

  /// `--bg-main`
  final Color bgMain;

  /// `--card-bg`
  final Color cardBg;

  /// `--glass-bg` (solid yaklaşım)
  final Color glassBg;

  /// `--card-border`
  final Color cardBorder;

  /// `--text-main`
  final Color textMain;

  /// `--text-sub`
  final Color textSub;

  /// `--vivid-blue` (accent)
  final Color vividBlue;

  /// Web `:root` `--vivid-amber`
  final Color vividAmber;

  /// Web `:root` `--vivid-coral` (Ask Vacanza AI pill, sabah harita vurgusu)
  final Color vividCoral;

  /// `--vivid-subtle-bg`
  final Color vividSubtleBg;

  /// Chat pill vb. yüzen yüzey
  final Color pillSurface;
  final Color pillBorder;
  final Color pillShadowAccent;

  /// Filtre overlay karartma
  final Color overlayScrim;

  /// Action bar pasif düğme arka planı
  final Color actionBarInactiveBg;
  final Color actionBarIcon;
  final Color actionBarBorder;

  /// Web `.theme-day` (MapPage.css ~632–643)
  static const VacanzaTokens light = VacanzaTokens(
    // Neutral soft white page (less blue-gray than F8FAFF).
    bgMain: Color(0xFFF7F7F8),
    cardBg: Color(0xFFFFFFFF),
    glassBg: Color(0xF2E0F7FA),
    cardBorder: Color(0x14000000),
    // Slightly softer than near-black for light mode typography.
    textMain: Color(0xFF3A4658),
    textSub: Color(0xFF5A6B7A),
    vividBlue: Color(0xFF00B4D8),
    vividAmber: Color(0xFFFFB347),
    vividCoral: Color(0xFFFF6B6B),
    vividSubtleBg: Color(0x0A000000),
    pillSurface: Color(0xEBFFFFFF),
    pillBorder: Color(0xF2FFFFFF),
    pillShadowAccent: Color(0x2338BDF8),
    overlayScrim: Color(0x1A000000),
    actionBarInactiveBg: Color(0xEBFFFFFF),
    actionBarIcon: Color(0xDE000000),
    actionBarBorder: Color(0x8CFFFFFF),
  );

  /// Web `.theme-night` (MapPage.css ~645–658)
  static const VacanzaTokens dark = VacanzaTokens(
    bgMain: Color(0xFF13141C),
    cardBg: Color(0xFF1A1B26),
    glassBg: Color(0xD91A1B26),
    cardBorder: Color(0x3338BDF8),
    textMain: Color(0xFFF8FAFC),
    textSub: Color(0xFF94A3B8),
    vividBlue: Color(0xFF38BDF8),
    vividAmber: Color(0xFFFFB347),
    vividCoral: Color(0xFFFF6B6B),
    vividSubtleBg: Color(0x14FFFFFF),
    pillSurface: Color(0xD9262732),
    pillBorder: Color(0x3338BDF8),
    pillShadowAccent: Color(0x4038BDF8),
    overlayScrim: Color(0x66000000),
    actionBarInactiveBg: Color(0xD91A1B26),
    actionBarIcon: Color(0xFFF8FAFC),
    actionBarBorder: Color(0x3338BDF8),
  );

  @override
  VacanzaTokens copyWith({
    Color? bgMain,
    Color? cardBg,
    Color? glassBg,
    Color? cardBorder,
    Color? textMain,
    Color? textSub,
    Color? vividBlue,
    Color? vividAmber,
    Color? vividCoral,
    Color? vividSubtleBg,
    Color? pillSurface,
    Color? pillBorder,
    Color? pillShadowAccent,
    Color? overlayScrim,
    Color? actionBarInactiveBg,
    Color? actionBarIcon,
    Color? actionBarBorder,
  }) {
    return VacanzaTokens(
      bgMain: bgMain ?? this.bgMain,
      cardBg: cardBg ?? this.cardBg,
      glassBg: glassBg ?? this.glassBg,
      cardBorder: cardBorder ?? this.cardBorder,
      textMain: textMain ?? this.textMain,
      textSub: textSub ?? this.textSub,
      vividBlue: vividBlue ?? this.vividBlue,
      vividAmber: vividAmber ?? this.vividAmber,
      vividCoral: vividCoral ?? this.vividCoral,
      vividSubtleBg: vividSubtleBg ?? this.vividSubtleBg,
      pillSurface: pillSurface ?? this.pillSurface,
      pillBorder: pillBorder ?? this.pillBorder,
      pillShadowAccent: pillShadowAccent ?? this.pillShadowAccent,
      overlayScrim: overlayScrim ?? this.overlayScrim,
      actionBarInactiveBg: actionBarInactiveBg ?? this.actionBarInactiveBg,
      actionBarIcon: actionBarIcon ?? this.actionBarIcon,
      actionBarBorder: actionBarBorder ?? this.actionBarBorder,
    );
  }

  @override
  VacanzaTokens lerp(ThemeExtension<VacanzaTokens>? other, double t) {
    if (other is! VacanzaTokens) return this;
    return VacanzaTokens(
      bgMain: Color.lerp(bgMain, other.bgMain, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      glassBg: Color.lerp(glassBg, other.glassBg, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      textMain: Color.lerp(textMain, other.textMain, t)!,
      textSub: Color.lerp(textSub, other.textSub, t)!,
      vividBlue: Color.lerp(vividBlue, other.vividBlue, t)!,
      vividAmber: Color.lerp(vividAmber, other.vividAmber, t)!,
      vividCoral: Color.lerp(vividCoral, other.vividCoral, t)!,
      vividSubtleBg: Color.lerp(vividSubtleBg, other.vividSubtleBg, t)!,
      pillSurface: Color.lerp(pillSurface, other.pillSurface, t)!,
      pillBorder: Color.lerp(pillBorder, other.pillBorder, t)!,
      pillShadowAccent: Color.lerp(pillShadowAccent, other.pillShadowAccent, t)!,
      overlayScrim: Color.lerp(overlayScrim, other.overlayScrim, t)!,
      actionBarInactiveBg:
          Color.lerp(actionBarInactiveBg, other.actionBarInactiveBg, t)!,
      actionBarIcon: Color.lerp(actionBarIcon, other.actionBarIcon, t)!,
      actionBarBorder: Color.lerp(actionBarBorder, other.actionBarBorder, t)!,
    );
  }
}
