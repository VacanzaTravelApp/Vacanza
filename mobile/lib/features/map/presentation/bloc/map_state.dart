import 'package:equatable/equatable.dart';

enum MapViewMode { twoD, threeD }

/// Harita ekranı state'i.
///
/// isMapReady:
/// - Controller setlenmeden true olmaz.
/// lastErrorMessage:
/// - Map init / controller işlemleri gibi kritik noktalarda hata gösterimi için.
class MapState extends Equatable {
  final MapViewMode viewMode;
  final bool isMapReady;

  /// Recenter gibi "one-shot" tetikleyiciler için.
  /// Her basışta artar, UI tarafı bu tick değişimini dinler.
  final int recenterTick;

  final String? lastErrorMessage;

  const MapState({
    required this.viewMode,
    required this.isMapReady,
    required this.recenterTick,
    required this.lastErrorMessage,
  });

  factory MapState.initial() => const MapState(
    viewMode: MapViewMode.twoD,
    isMapReady: false,
    recenterTick: 0,
    lastErrorMessage: null,
  );

  MapState copyWith({
    MapViewMode? viewMode,
    bool? isMapReady,
    int? recenterTick,
    String? lastErrorMessage,
  }) {
    return MapState(
      viewMode: viewMode ?? this.viewMode,
      isMapReady: isMapReady ?? this.isMapReady,
      recenterTick: recenterTick ?? this.recenterTick,
      lastErrorMessage: lastErrorMessage,
    );
  }

  @override
  List<Object?> get props => [viewMode, isMapReady, recenterTick, lastErrorMessage];
}