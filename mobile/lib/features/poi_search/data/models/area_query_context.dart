import 'package:equatable/equatable.dart';
import 'area_source.dart';
import 'selected_area.dart';

/// UC1.2'nin tek "state modeli":
/// - alanın kaynağı (viewport vs user selection)
/// - alanın tipi (bbox/polygon/none)
///
/// UI + BLoC + API request'ler bunun üzerinden beslenecek.
class AreaQueryContext extends Equatable {
  final AreaSource areaSource;
  final SelectedArea area;

  const AreaQueryContext({
    required this.areaSource,
    required this.area,
  });

  /// İlk açılış: henüz viewport bbox hesaplanmamış olabilir.
  factory AreaQueryContext.initial() => const AreaQueryContext(
    areaSource: AreaSource.viewport,
    area: NoArea(),
  );

  bool get hasUsableArea => area.isUsable;

  AreaQueryContext copyWith({
    AreaSource? areaSource,
    SelectedArea? area,
  }) {
    return AreaQueryContext(
      areaSource: areaSource ?? this.areaSource,
      area: area ?? this.area,
    );
  }

  @override
  List<Object?> get props => [areaSource, area];
}