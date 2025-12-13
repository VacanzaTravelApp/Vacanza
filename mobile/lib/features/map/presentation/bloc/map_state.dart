import 'package:equatable/equatable.dart';

import '../../data/models/map_view_mode.dart';

/// Map ekranının state'i.
///
/// Minimum istenenler:
/// - MapViewMode (twoD/threeD/sat)
/// - isMapReady (controller hazır mı)
/// - lastErrorMessage? (opsiyonel)
///
/// Ek olarak:
/// - recenterTick: "one-shot" UI aksiyonu tetiklemek için kullanıyoruz.
///   Recenter basılınca +1 olur. Mapbox geldiğinde bu tick'i dinleyip kamerayı resetleyeceğiz.
class MapState extends Equatable {
  final MapViewMode viewMode;
  final bool isMapReady;
  final String? lastErrorMessage;

  /// Recenter için one-shot tetikleyici.
  final int recenterTick;

  /// Controller'ı state'e koyuyoruz çünkü:
  /// - 137'de Mapbox controller üzerinden kamera/tilt işlemleri yapacağız.
  /// - Bu taskta Mapbox olmadığı için `Object?` olarak saklıyoruz.
  final Object? controller;

  const MapState({
    required this.viewMode,
    required this.isMapReady,
    required this.recenterTick,
    this.lastErrorMessage,
    this.controller,
  });

  factory MapState.initial() => const MapState(
    viewMode: MapViewMode.mode2D,
    isMapReady: false,
    recenterTick: 0,
    lastErrorMessage: null,
    controller: null,
  );

  MapState copyWith({
    MapViewMode? viewMode,
    bool? isMapReady,
    int? recenterTick,
    String? lastErrorMessage,
    Object? controller,
    bool clearError = false,
  }) {
    return MapState(
      viewMode: viewMode ?? this.viewMode,
      isMapReady: isMapReady ?? this.isMapReady,
      recenterTick: recenterTick ?? this.recenterTick,
      lastErrorMessage: clearError ? null : (lastErrorMessage ?? this.lastErrorMessage),
      controller: controller ?? this.controller,
    );
  }

  @override
  List<Object?> get props => [
    viewMode,
    isMapReady,
    lastErrorMessage,
    recenterTick,
    controller,
  ];
}