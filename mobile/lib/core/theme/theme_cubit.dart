import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_models.dart';
import 'theme_resolve.dart';

export 'theme_models.dart';

const _kThemeModeKey = 'vacanza_theme_mode';
const _kStrategyKey = 'vacanza_theme_strategy';
const _kNightStartKey = 'vacanza_theme_night_start_m';
const _kNightEndKey = 'vacanza_theme_night_end_m';

/// Görünüm + kalıcılık. Web `vacanza-theme` (`day`/`night`) manuel modda uyumludur.
class ThemeCubit extends Cubit<ThemeCubitState> {
  ThemeCubit()
      : super(
          ThemeCubitState(
            strategy: AppThemeStrategy.manual,
            manualMode: ThemeMode.light,
            nightStartMinutes: ThemeCubitState.defaultNightStartMinutes,
            nightEndMinutes: ThemeCubitState.defaultNightEndMinutes,
            resolvedThemeMode: ThemeMode.light,
          ),
        ) {
    _load();
  }

  Timer? _scheduleTimer;

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();

    final strategyStr = p.getString(_kStrategyKey);
    final legacyMode = p.getString(_kThemeModeKey);

    AppThemeStrategy strategy;
    if (strategyStr == 'system') {
      strategy = AppThemeStrategy.system;
    } else if (strategyStr == 'scheduled') {
      strategy = AppThemeStrategy.scheduled;
    } else if (strategyStr == 'manual') {
      strategy = AppThemeStrategy.manual;
    } else {
      // Eski kurulum: yalnızca day/night
      strategy = AppThemeStrategy.manual;
    }

    ThemeMode manual = ThemeMode.light;
    if (legacyMode == 'night') {
      manual = ThemeMode.dark;
    } else if (legacyMode == 'day') {
      manual = ThemeMode.light;
    }

    final nightStart =
        p.getInt(_kNightStartKey) ?? ThemeCubitState.defaultNightStartMinutes;
    final nightEnd =
        p.getInt(_kNightEndKey) ?? ThemeCubitState.defaultNightEndMinutes;

    final s = ThemeCubitState(
      strategy: strategy,
      manualMode: manual,
      nightStartMinutes: nightStart.clamp(0, 1439),
      nightEndMinutes: nightEnd.clamp(0, 1439),
      resolvedThemeMode: ThemeMode.light,
    );
    final resolved = resolveThemeMode(s);
    emit(s.copyWith(resolvedThemeMode: resolved));
    _startScheduleTimerIfNeeded();
  }

  void _startScheduleTimerIfNeeded() {
    _scheduleTimer?.cancel();
    if (state.strategy != AppThemeStrategy.scheduled) return;
    _scheduleTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      reevaluateSchedule();
    });
  }

  /// Zamanlanmış modda saat sınırını geçince veya uygulama öne gelince çağrılır.
  void reevaluateSchedule() {
    final r = resolveThemeMode(state);
    if (r != state.resolvedThemeMode) {
      emit(state.copyWith(resolvedThemeMode: r));
    }
  }

  Future<void> _persist(ThemeCubitState s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _kStrategyKey,
      switch (s.strategy) {
        AppThemeStrategy.system => 'system',
        AppThemeStrategy.scheduled => 'scheduled',
        AppThemeStrategy.manual => 'manual',
      },
    );
    await p.setString(
      _kThemeModeKey,
      s.manualMode == ThemeMode.dark ? 'night' : 'day',
    );
    await p.setInt(_kNightStartKey, s.nightStartMinutes);
    await p.setInt(_kNightEndKey, s.nightEndMinutes);
  }

  Future<void> _emitAndPersist(ThemeCubitState next) async {
    final resolved = resolveThemeMode(next);
    final out = next.copyWith(resolvedThemeMode: resolved);
    emit(out);
    await _persist(out);
    _startScheduleTimerIfNeeded();
  }

  Future<void> setStrategy(AppThemeStrategy strategy) async {
    await _emitAndPersist(state.copyWith(strategy: strategy));
  }

  Future<void> setManualMode(ThemeMode mode) async {
    assert(mode == ThemeMode.light || mode == ThemeMode.dark);
    await _emitAndPersist(state.copyWith(manualMode: mode));
  }

  Future<void> setNightWindow({
    required int nightStartMinutes,
    required int nightEndMinutes,
  }) async {
    await _emitAndPersist(
      state.copyWith(
        nightStartMinutes: nightStartMinutes.clamp(0, 1439),
        nightEndMinutes: nightEndMinutes.clamp(0, 1439),
      ),
    );
  }

  /// Harita güneş/ay: her zaman manuel moda geçer, görünür temayı tersine çevirir.
  Future<void> toggle() async {
    final Brightness eff = _effectiveBrightness();
    final ThemeMode next =
        eff == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    await _emitAndPersist(
      state.copyWith(
        strategy: AppThemeStrategy.manual,
        manualMode: next,
      ),
    );
  }

  Brightness _effectiveBrightness() {
    if (state.resolvedThemeMode == ThemeMode.system) {
      return SchedulerBinding.instance.platformDispatcher.platformBrightness;
    }
    return state.resolvedThemeMode == ThemeMode.dark
        ? Brightness.dark
        : Brightness.light;
  }

  @override
  Future<void> close() {
    _scheduleTimer?.cancel();
    return super.close();
  }
}
