import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/services/location_service.dart';
import 'location_event.dart';
import 'location_state.dart';

/// Manages foreground GPS tracking lifecycle.
///
/// - [StartTracking]: checks permission, subscribes to position stream.
/// - [StopTracking]: cancels stream subscription.
/// - [LocationUpdated]: internal — updates state with new coordinates.
///
/// The bloc does **not** handle background tracking.
/// Stream is cancelled on [StopTracking] and in [close].
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationService _locationService;
  StreamSubscription<Position>? _positionSubscription;

  LocationBloc({required LocationService locationService})
      : _locationService = locationService,
        super(LocationState.initial()) {
    on<StartTracking>(_onStartTracking);
    on<StopTracking>(_onStopTracking);
    on<LocationUpdated>(_onLocationUpdated);
  }

  Future<void> _onStartTracking(
    StartTracking event,
    Emitter<LocationState> emit,
  ) async {
    // Already tracking — avoid duplicate subscriptions
    if (_positionSubscription != null) return;

    log('[LocationBloc] StartTracking requested');

    // 1) Check & request permission via geolocator
    final permission = await _locationService.checkAndRequestPermission();

    if (permission == LocationPermission.denied) {
      log('[LocationBloc] Permission denied');
      emit(state.copyWith(status: LocationStatus.permissionDenied));
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      log('[LocationBloc] Permission permanently denied');
      emit(state.copyWith(status: LocationStatus.permissionDeniedForever));
      return;
    }

    // 2) Permission granted — subscribe to position stream
    log('[LocationBloc] Permission granted, starting position stream');

    _positionSubscription = _locationService.positionStream().listen(
      (position) {
        log('[LocationBloc] stream position lat=${position.latitude}, lng=${position.longitude}');
        add(LocationUpdated(position.latitude, position.longitude));
      },
      onError: (Object error) {
        log('[LocationBloc] Position stream error: $error');
        add(const StopTracking());
      },
    );

    // 3) Emit tracking state (coordinates will come via LocationUpdated)
    emit(state.copyWith(status: LocationStatus.tracking));
  }

  void _onStopTracking(
    StopTracking event,
    Emitter<LocationState> emit,
  ) {
    _cancelSubscription();
    log('[LocationBloc] StopTracking — stream cancelled');

    // Keep last known coordinates but go back to initial status
    emit(state.copyWith(status: LocationStatus.initial));
  }

  void _onLocationUpdated(
    LocationUpdated event,
    Emitter<LocationState> emit,
  ) {
    // First valid GPS fix — notify listeners (camera center, etc.)
    final firstFix = state.latitude == null && state.longitude == null;
    if (firstFix) {
      log('[LocationBloc] ★ first GPS fix lat=${event.latitude} lng=${event.longitude}');
    } else {
      log('[LocationBloc] LocationUpdated lat=${event.latitude} lng=${event.longitude}');
    }

    emit(state.copyWith(
      status: LocationStatus.tracking,
      latitude: event.latitude,
      longitude: event.longitude,
      isFirstFix: firstFix,
    ));
  }

  void _cancelSubscription() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  Future<void> close() {
    _cancelSubscription();
    return super.close();
  }
}
