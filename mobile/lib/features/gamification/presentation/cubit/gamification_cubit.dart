import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/gamification_repository.dart';
import 'gamification_state.dart';

/// Manages the gamification profile state.
///
/// Strict guards:
/// - Loading → skip (no concurrent fetches).
/// - Loaded + last fetch < 15 s → skip (cooldown).
/// - Error → allow retry immediately.
///
/// Logs every decision with [GAM_CUBIT] tag.
class GamificationCubit extends Cubit<GamificationState> {
  final GamificationRepository _repository;

  DateTime? _lastFetchTime;
  int _requestCounter = 0;

  static const _cooldown = Duration(seconds: 15);

  GamificationCubit({required GamificationRepository repository})
      : _repository = repository,
        super(const GamificationInitial());

  /// Fetches the gamification profile with strict guards.
  Future<void> fetchProfile() async {
    final reqId = ++_requestCounter;
    final stateName = state.runtimeType.toString();

    // Guard: already loading
    if (state is GamificationLoading) {
      log('[GAM_CUBIT] #$reqId SKIPPED_LOADING state=$stateName');
      return;
    }

    // Guard: cooldown (Loaded within 15s)
    if (state is GamificationLoaded && _lastFetchTime != null) {
      final elapsed = DateTime.now().difference(_lastFetchTime!);
      if (elapsed < _cooldown) {
        log('[GAM_CUBIT] #$reqId SKIPPED_COOLDOWN '
            'state=$stateName elapsed=${elapsed.inSeconds}s');
        return;
      }
    }

    log('[GAM_CUBIT] #$reqId FETCHING state=$stateName');
    emit(const GamificationLoading());

    try {
      final profile = await _repository.getProfile();
      _lastFetchTime = DateTime.now();
      log('[GAM_CUBIT] #$reqId LOADED '
          'role=${profile.roleText} level=${profile.levelText} '
          'xp=${profile.totalXp}');
      emit(GamificationLoaded(profile));
    } on GamificationException catch (e) {
      log('[GAM_CUBIT] #$reqId ERROR ${e.message}');
      emit(GamificationError(e.message));
    }
  }

  /// Force re-fetch (bypasses cooldown). Used after check-in (MOB-12).
  Future<void> refresh() async {
    _lastFetchTime = null; // reset cooldown
    return fetchProfile();
  }
}
