import 'package:equatable/equatable.dart';

class GeoPoint extends Equatable {
  final double lat;
  final double lng;

  const GeoPoint({required this.lat, required this.lng});

  @override
  List<Object?> get props => [lat, lng];
}