import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mobile/core/navigation/navigation_service.dart';
import 'package:mobile/features/trip_calendar/data/api/trip_calendar_api_client.dart';

class IcsExportService {
  final TripCalendarApiClient _api;

  IcsExportService(this._api);

  static String formatIsoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static DateTime? tryParseIsoDate(String? s) {
    if (s == null) return null;
    final t = s.trim();
    if (t.isEmpty) return null;
    return DateTime.tryParse(t);
  }

  Future<void> registerAndOpenRouteIcs({
    required String routeId,
    required DateTime eventDate,
  }) async {
    final iso = formatIsoDate(eventDate);

    // Endpoint 1 must not be skipped.
    try {
      await _api.registerRouteToCalendar(routeId: routeId, eventDate: iso);
    } catch (e) {
      // If it's already registered for that day, proceed to export anyway.
      if (!isConflict409(e)) rethrow;
    }

    // Immediately download ICS.
    final Uint8List bytes = await _api.exportRouteIcsBytes(routeId: routeId);
    final file = await _writeTempIcs(bytes, filename: 'vacanza-trip.ics');

    final result = await OpenFilex.open(
      file.path,
      type: 'text/calendar',
    );

    if (result.type == ResultType.done) {
      NavigationService.showSnackBar(
        "Added to Trip Agenda. To add it to your phone calendar, tap Add/Save in your calendar app.",
      );
      return;
    }

    // If OS cannot handle ICS, surface a clear message.
    final msg = result.message;
    NavigationService.showSnackBar(
      msg.trim().isNotEmpty
          ? msg.trim()
          : 'Could not open calendar file on this device.',
    );
  }

  Future<File> _writeTempIcs(Uint8List bytes, {required String filename}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static bool isConflict409(Object e) {
    if (e is DioException) {
      return e.response?.statusCode == 409;
    }
    return false;
  }
}

