import 'package:equatable/equatable.dart';
import 'geo_point.dart';

abstract class SelectedArea extends Equatable {
  const SelectedArea();
  bool get isUsable;
}

class NoArea extends SelectedArea {
  const NoArea();

  @override
  bool get isUsable => false;

  @override
  List<Object?> get props => [];
}

class BboxArea extends SelectedArea {
  final double minLat;
  final double minLng;
  final double maxLat;
  final double maxLng;

  const BboxArea._({
    required this.minLat,
    required this.minLng,
    required this.maxLat,
    required this.maxLng,
  });

  factory BboxArea({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
  }) {
    final nMinLat = (minLat <= maxLat) ? minLat : maxLat;
    final nMaxLat = (minLat <= maxLat) ? maxLat : minLat;
    final nMinLng = (minLng <= maxLng) ? minLng : maxLng;
    final nMaxLng = (minLng <= maxLng) ? maxLng : minLng;

    return BboxArea._(
      minLat: nMinLat,
      minLng: nMinLng,
      maxLat: nMaxLat,
      maxLng: nMaxLng,
    );
  }

  @override
  bool get isUsable => true;

  @override
  List<Object?> get props => [minLat, minLng, maxLat, maxLng];
}

class PolygonArea extends SelectedArea {
  final List<GeoPoint> points;

  const PolygonArea._(this.points);

  factory PolygonArea(List<GeoPoint> points) {
    if (points.length < 3) {
      throw ArgumentError('Polygon requires at least 3 points.');
    }
    if (points.length > 200) {
      throw ArgumentError('Polygon supports max 200 points.');
    }
    return PolygonArea._(List.unmodifiable(points));
  }

  @override
  bool get isUsable => points.length >= 3 && points.length <= 200;

  @override
  List<Object?> get props => [points];
}