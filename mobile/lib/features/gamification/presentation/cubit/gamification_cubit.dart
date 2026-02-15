import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/gamification_repository.dart';
import 'gamification_state.dart';

/// Manages the gamification profile state.
///
/// - [fetchProfile] — initial fetch (Loading → Loaded/Error).
/// - [refresh] — re-fetch alias for MOB-12 post-check-in.
class GamificationCubit extends Cubit<GamificationState> {
  final GamificationRepository _repository;

  GamificationCubit({required GamificationRepository repository})
      : _repository = repository,
        super(const GamificationInitial());

  /// Fetches the gamification profile from the backend.
  /// Skips if already loading to prevent concurrent fetches.
  ///
  /// On 404, receives mock data from repository with `isMock: true`.
  Future<void> fetchProfile() async {
    if (state is GamificationLoading) return;

    log('[GamificationCubit] fetchProfile');
    emit(const GamificationLoading());

    try {
      final result = await _repository.getProfile();

      if (result.isMock) {
        log('[GamificationCubit] loaded MOCK — '
            'role=${result.profile.roleText}');
      } else {
        log('[GamificationCubit] loaded — '
            'role=${result.profile.roleText} level=${result.profile.levelText} '
            'xp=${result.profile.totalXp}');
      }

      emit(GamificationLoaded(result.profile, isMock: result.isMock));
    } on GamificationException catch (e) {
      log('[GamificationCubit] error: ${e.message}');
      emit(GamificationError(e.message));
    }
  }

  /// Re-fetch the profile (e.g., after a new check-in in MOB-12).
  Future<void> refresh() => fetchProfile();
}
