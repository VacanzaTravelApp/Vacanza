import 'package:flutter/widgets.dart';

/// Whether to show imperial units (ft / mi) for AR UI based on locale.
bool localeUsesImperial(BuildContext context) {
  final code = Localizations.localeOf(context).countryCode?.toUpperCase();
  return code == 'US' || code == 'LR' || code == 'MM';
}

/// Formats [meters] for AR chips and sheets (metric or imperial).
String formatArDistanceMeters(double meters, {required bool useImperial}) {
  if (useImperial) {
    if (meters < 1609.344) {
      final ft = (meters * 3.28084).round();
      return '$ft ft';
    }
    final mi = meters / 1609.344;
    return '${mi.toStringAsFixed(mi >= 10 ? 0 : 1)} mi';
  }
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  return '${(meters / 1000).toStringAsFixed(1)} km';
}
