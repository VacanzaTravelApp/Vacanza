import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/checkin_repository.dart';
import 'checkin_event.dart';
import 'checkin_state.dart';

/// Handles auto check-in API calls with throttling and empty-candidates guard.
///
/// Listens for [TriggerAutoCheckin] events dispatched from the
/// LocationBloc listener in HomeMapScreen.
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

    log('[CheckinBloc] calling POST /checkins/auto');

    try {
      final response = await _repository.autoCheckin(
        latitude: event.latitude,
        longitude: event.longitude,
        candidatePoiIds: event.candidatePoiIds,
      );

      log('[CheckinBloc] success checkInId=${response.checkInId} '
          'poiName=${response.poiName} '
          'gamificationTriggered=${response.gamificationTriggered}');

      emit(state.copyWith(
        status: CheckinStatus.success,
        response: response,
      ));
    } on CheckinException catch (e) {
      log('[CheckinBloc] failure: ${e.message}');
      emit(state.copyWith(
        status: CheckinStatus.failure,
        errorMessage: e.message,
      ));
    }
  }
}
