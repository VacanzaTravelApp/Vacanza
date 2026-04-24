import 'dart:typed_data';

import 'package:dio/dio.dart';

class TripCalendarEventRow {
  final String eventId;
  final String routeId;
  final String title;
  final String? destination;
  final DateTime eventDate;
  final int totalDays;
  final int itineraryDay;

  const TripCalendarEventRow({
    required this.eventId,
    required this.routeId,
    required this.title,
    required this.destination,
    required this.eventDate,
    required this.totalDays,
    required this.itineraryDay,
  });

  factory TripCalendarEventRow.fromJson(Map<String, dynamic> json) {
    final rawDate = (json['eventDate'] ?? json['event_date'])?.toString();
    final dt = rawDate != null ? DateTime.tryParse(rawDate) : null;
    if (dt == null) {
      throw const FormatException('TripCalendarEventRow: invalid eventDate');
    }
    int toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return TripCalendarEventRow(
      eventId: (json['eventId'] ?? json['event_id']).toString(),
      routeId: (json['routeId'] ?? json['route_id']).toString(),
      title: (json['title'] ?? '').toString(),
      destination: (json['destination'])?.toString(),
      eventDate: dt,
      totalDays: toInt(json['totalDays'] ?? json['total_days']),
      itineraryDay: toInt(json['itineraryDay'] ?? json['itinerary_day']),
    );
  }
}

class TripCalendarApiClient {
  final Dio _dio;

  TripCalendarApiClient(this._dio);

  /// Endpoint 1 (required):
  /// POST /users/me/trip-calendar/events
  ///
  /// Returns number of created rows (one per itinerary day) when backend responds with a list.
  Future<int> registerRouteToCalendar({
    required String routeId,
    required String eventDate,
  }) async {
    final response = await _dio.post<dynamic>(
      '/users/me/trip-calendar/events',
      data: <String, dynamic>{
        'routeId': routeId,
        'eventDate': eventDate,
      },
    );
    final data = response.data;
    if (data is List) return data.length;
    return 1;
  }

  /// GET /users/me/trip-calendar/events?year=&month=
  Future<List<TripCalendarEventRow>> listTripCalendarEvents({
    required int year,
    required int month,
  }) async {
    final response = await _dio.get<dynamic>(
      '/users/me/trip-calendar/events',
      queryParameters: <String, dynamic>{
        'year': year,
        'month': month,
      },
    );
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => TripCalendarEventRow.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// DELETE /users/me/trip-calendar/events/{eventId}
  Future<void> deleteTripCalendarEvent(String eventId) async {
    await _dio.delete<dynamic>('/users/me/trip-calendar/events/$eventId');
  }

  /// DELETE /users/me/trip-calendar/events/by-route/{routeId}
  Future<void> deleteTripCalendarEventsByRoute(String routeId) async {
    await _dio.delete<dynamic>('/users/me/trip-calendar/events/by-route/$routeId');
  }

  /// Endpoint 2:
  /// GET /users/me/trip-calendar/export/route/{routeId}
  ///
  /// Returns raw ICS bytes (RFC-5545), Content-Type: text/calendar.
  Future<Uint8List> exportRouteIcsBytes({required String routeId}) async {
    final response = await _dio.get<List<int>>(
      '/users/me/trip-calendar/export/route/$routeId',
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty ICS response');
    }
    return Uint8List.fromList(data);
  }
}

