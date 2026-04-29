import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/checkin_repository.dart';
import 'checkin_event.dart';
import 'checkin_state.dart';

/// Handles auto check-in API calls with throttling and empty-candidates guard.
///
/// After the API responds (HTTP 200), branches into three outcomes:
/// - [CheckinStatus.newCreated] — checkInId != null → new check-in
/// - [CheckinStatus.duplicate]  — success && checkInId == null
/// - [CheckinStatus.noMatch]    — !success (no POI within range)
///
/// Only [newCreated] should trigger local state updates.
class CheckinBloc extends Bloc<CheckinEvent, CheckinState> {
  final CheckinRepository _repository;

  /// Minimum interval between API calls.
  static const Duration _throttleDuration = Duration(seconds: 10);

  /// Timestamp of the last successful API dispatch (not response).
  DateTime? _lastCallTime;

  CheckinBloc({required CheckinRepository repository})
      : _repository = repository,
        super(CheckinState.initial()) {
    on<TriggerAutoCheckin>(_onTriggerAutoCheckin);
  }

  Future<void> _onTriggerAutoCheckin(
    TriggerAutoCheckin event,
    Emitter<CheckinState> emit,
  ) async {
    // Guard: skip if no candidate POIs
    if (event.candidatePoiIds.isEmpty) {
      log('[CheckinBloc] skipped — empty candidates');
      return;
    }

    // Throttle: skip if last call was too recent
    final now = DateTime.now();
    if (_lastCallTime != null) {
      final elapsed = now.difference(_lastCallTime!);
      if (elapsed < _throttleDuration) {
        log('[CheckinBloc] throttled — skipping '
            '(last call ${elapsed.inSeconds}s ago)');
        return;
      }
    }

    log('[CheckinBloc] TriggerAutoCheckin '
        'lat=${event.latitude} lng=${event.longitude} '
        'candidates=${event.candidatePoiIds.length}');

    _lastCallTime = now;
    emit(state.copyWith(status: CheckinStatus.loading));

    log('[CheckinBloc] calling POST /users/me/checkins/auto');

    try {
      final response = await _repository.autoCheckin(
        latitude: event.latitude,
        longitude: event.longitude,
        candidatePoiIds: event.candidatePoiIds,
      );

      // ── MOB-4: Branch into 3 response outcomes ──

      // 1) New check-in created (primary signal: checkInId != null)
      if (response.checkInId != null) {
        log('[CheckinBloc] newCreated '
            'checkInId=${response.checkInId} '
            'poiName=${response.poiName} '
            'gamificationTriggered=${response.gamificationTriggered}');

        emit(state.copyWith(
          status: CheckinStatus.newCreated,
          response: response,
          gamificationTriggered: response.gamificationTriggered,
        ));
        return;
      }

      // 2) Duplicate — already checked in (success==true, no checkInId)
      if (response.success) {
        log('[CheckinBloc] duplicate '
            'poiId=${response.poiId} '
            'poiName=${response.poiName} '
            'message=${response.message}');

        emit(state.copyWith(
          status: CheckinStatus.duplicate,
          response: response,
        ));
        return;
      }

      // 3) No matching POI in range (success==false)
      log('[CheckinBloc] noMatch message=${response.message}');

      emit(state.copyWith(
        status: CheckinStatus.noMatch,
        response: response,
      ));
    } on CheckinException catch (e) {
      log('[CheckinBloc] failure: ${e.message}');
      emit(state.copyWith(
        status: CheckinStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e, st) {
      log('[CheckinBloc] unexpected error: $e\n$st');
      emit(state.copyWith(
        status: CheckinStatus.failure,
        errorMessage: 'Something went wrong. Please try again.',
      ));
    }
  }
}
