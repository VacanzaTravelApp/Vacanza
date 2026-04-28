import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/badge_dto.dart';
import '../../data/repositories/gamification_repository.dart';
import 'gamification_state.dart';

class GamificationCubit extends Cubit<GamificationState> {
  final GamificationRepository _repository;

  DateTime? _lastFetchTime;
  int _requestCounter = 0;

  /// Badge IDs the user already had at the start of the session.
  /// Populated on the first successful fetch; used to diff subsequent refreshes.
  Set<int>? _knownEarnedIds;

  static const _cooldown = Duration(seconds: 15);

  GamificationCubit({required GamificationRepository repository})
      : _repository = repository,
        super(const GamificationInitial());

  Future<void> fetchProfile() async {
    final reqId = ++_requestCounter;
    final stateName = state.runtimeType.toString();

    if (state is GamificationLoading) {
      log('[GAM_CUBIT] #$reqId SKIPPED_LOADING state=$stateName');
      return;
    }

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

      // First fetch: record baseline earned IDs, no newly-earned notification.
      final isFirstFetch = _knownEarnedIds == null;
      final earnedIds =
          profile.badges.where((b) => b.earned).map((b) => b.id).toSet();

      List<BadgeDto> newlyEarned = const [];
      if (!isFirstFetch) {
        newlyEarned = profile.badges
            .where((b) => b.earned && !_knownEarnedIds!.contains(b.id))
            .toList();
      }
      _knownEarnedIds = earnedIds;

      log('[GAM_CUBIT] #$reqId LOADED '
          'role=${profile.roleText} level=${profile.levelText} '
          'xp=${profile.totalXp} newBadges=${newlyEarned.length}');
      emit(GamificationLoaded(profile, newlyEarnedBadges: newlyEarned));
    } on GamificationException catch (e) {
      log('[GAM_CUBIT] #$reqId ERROR ${e.message}');
      emit(GamificationError(e.message));
    }
  }

  /// Force re-fetch bypassing cooldown. Used after check-in (MOB-12).
  Future<void> refresh() async {
    _lastFetchTime = null;
    return fetchProfile();
  }
}
