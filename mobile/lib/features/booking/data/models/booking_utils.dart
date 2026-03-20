const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Parses ISO 8601 duration "PT3H15M" → "3h 15m". Returns raw string if parsing fails.
String formatDuration(String isoDuration) {
  final match = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?').firstMatch(isoDuration);
  if (match == null) return isoDuration;
  final hours = match.group(1);
  final minutes = match.group(2);
  final parts = <String>[];
  if (hours != null && hours != '0') parts.add('${hours}h');
  if (minutes != null && minutes != '0') parts.add('${minutes}m');
  return parts.isEmpty ? '0m' : parts.join(' ');
}

/// Formats "2025-07-01" → "Jul 1, 2025". Returns raw string if parsing fails.
String formatDate(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
  } catch (_) {
    return isoDate;
  }
}

/// Formats "2025-07-01T08:30:00" → "08:30". Returns raw string if parsing fails.
String formatTime(String isoDateTime) {
  try {
    final dt = DateTime.parse(isoDateTime);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return isoDateTime;
  }
}

/// Null-safe rating display. Returns null when [rating] is null.
String? formatRating(double? rating) {
  if (rating == null) return null;
  return rating.toStringAsFixed(1);
}

/// Stops label: 0 → "Direct", 1 → "1 stop", N → "N stops".
String formatStops(int stops) {
  if (stops == 0) return 'Direct';
  if (stops == 1) return '1 stop';
  return '$stops stops';
}
