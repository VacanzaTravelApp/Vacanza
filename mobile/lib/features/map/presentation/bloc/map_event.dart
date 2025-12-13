import 'package:equatable/equatable.dart';

/// Harita ekranında kullanıcı aksiyonlarını temsil eden event'ler.
///
/// NOT:
/// - 137'de Mapbox controller gelince bu controller gerçek tipine çevrilecek.
/// - Şimdilik Mapbox bağımlılığı yaratmamak için Object? kullanıyoruz.
abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

/// Harita/controller hazır olduğunda tetiklenir.
///
/// controller:
/// - Şimdilik Object? (Mapbox yokken bile event contract hazır olsun diye)
/// - 137'de MapboxMapController gibi gerçek tipe çekilecek.
class MapInitialized extends MapEvent {
  final Object? controller;

  const MapInitialized({required this.controller});

  @override
  List<Object?> get props => [controller];
}

class MapToggleViewModePressed extends MapEvent {
  const MapToggleViewModePressed();
}

class MapRecenterPressed extends MapEvent {
  const MapRecenterPressed();
}