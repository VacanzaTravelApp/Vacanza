import 'package:equatable/equatable.dart';

/// Map ekranında kullanıcı aksiyonlarını ve lifecycle olaylarını temsil eden event'ler.
///
/// Bu task (156) Mapbox şart değil.
/// O yüzden controller tipi şimdilik `Object` olarak tutulur.
/// 137'de Mapbox controller geldiğinde bu Object yerine gerçek tipi koyacağız.
abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

/// Harita controller'ı hazır olduğunda dispatch edilir.
/// (Mapbox 137'de gelince gerçek controller burada gelecek.)
class MapInitialized extends MapEvent {
  final Object controller;

  const MapInitialized({required this.controller});

  @override
  List<Object?> get props => [controller];
}

/// Sağdaki "2D/3D/SAT" butonuna basıldı.
class ToggleViewModePressed extends MapEvent {
  const ToggleViewModePressed();
}

/// Sağdaki "Recenter" butonuna basıldı.
class RecenterPressed extends MapEvent {
  const RecenterPressed();
}