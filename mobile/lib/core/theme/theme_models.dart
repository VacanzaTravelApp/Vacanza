import 'package:flutter/material.dart';

/// Uygulama görünüm stratejisi.
enum AppThemeStrategy {
  /// Cihazın açık/koyu ayarı ([ThemeMode.system]).
  system,

  /// Yerel saate göre gece penceresi (varsayılan akşam → sabah).
  scheduled,

  /// Kullanıcı elle gündüz/gece seçer; harita toggle’ı da buna geçirir.
  manual,
}

/// Kalıcı depolama ve [ThemeCubit] için tek kaynak state.
class ThemeCubitState {
  const ThemeCubitState({
    required this.strategy,
    required this.manualMode,
    required this.nightStartMinutes,
    required this.nightEndMinutes,
    required this.resolvedThemeMode,
  });

  final AppThemeStrategy strategy;

  /// Yalnızca [AppThemeStrategy.manual] iken anlamlı; [ThemeMode.light] veya [ThemeMode.dark].
  final ThemeMode manualMode;

  /// Gece başlangıcı, günün dakikası 0–1439 (örn. 20:00 → 1200).
  final int nightStartMinutes;

  /// Gece bitişi (örn. 07:00 → 420). [nightStartMinutes] > [nightEndMinutes] ise gece penceresi gece yarısını aşar.
  final int nightEndMinutes;

  /// [MaterialApp.themeMode] için (light / dark / system).
  final ThemeMode resolvedThemeMode;

  static const int defaultNightStartMinutes = 20 * 60;
  static const int defaultNightEndMinutes = 7 * 60;

  ThemeCubitState copyWith({
    AppThemeStrategy? strategy,
    ThemeMode? manualMode,
    int? nightStartMinutes,
    int? nightEndMinutes,
    ThemeMode? resolvedThemeMode,
  }) {
    return ThemeCubitState(
      strategy: strategy ?? this.strategy,
      manualMode: manualMode ?? this.manualMode,
      nightStartMinutes: nightStartMinutes ?? this.nightStartMinutes,
      nightEndMinutes: nightEndMinutes ?? this.nightEndMinutes,
      resolvedThemeMode: resolvedThemeMode ?? this.resolvedThemeMode,
    );
  }
}
