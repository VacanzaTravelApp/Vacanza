import 'package:dio/dio.dart';

/// Viator / tour pricing row from GET /routes/{id}/pricing.
class WaypointPricingRow {
  final String waypointName;
  final int day;
  final int order;
  final double? minPriceUsd;
  final String currency;
  final String? bookingUrl;
  final String? productTitle;
  final bool found;
  final String? status;
  final String? message;

  const WaypointPricingRow({
    required this.waypointName,
    required this.day,
    required this.order,
    this.minPriceUsd,
    this.currency = 'USD',
    this.bookingUrl,
    this.productTitle,
    this.found = false,
    this.status,
    this.message,
  });

  factory WaypointPricingRow.fromJson(Map<String, dynamic> json) {
    num? n(dynamic v) => v is num ? v : (v is String ? num.tryParse(v) : null);
    return WaypointPricingRow(
      waypointName:
          (json['waypointName'] ?? json['waypoint_name'] ?? '').toString(),
      day: (json['day'] is num) ? (json['day'] as num).toInt() : 0,
      order: (json['order'] is num) ? (json['order'] as num).toInt() : 0,
      minPriceUsd: n(json['minPriceUsd'] ?? json['min_price_usd'])?.toDouble(),
      currency: (json['currency'] ?? 'USD').toString(),
      bookingUrl: (json['bookingUrl'] ?? json['booking_url'])?.toString(),
      productTitle: (json['productTitle'] ?? json['product_title'])?.toString(),
      found: json['found'] == true,
      status: json['status']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

/// API client for saved route viewing and directions geometry.
///
/// Uses the shared Dio instance (JwtInterceptor attaches Firebase Bearer token).
class AiRouteApiClient {
  final Dio _dio;

  AiRouteApiClient(this._dio);

  /// GET /routes/{routeId}/pricing — Viator museum/tour prices per waypoint.
  Future<List<WaypointPricingRow>> getRoutePricing(String routeId) async {
    final response = await _dio.get<dynamic>(
      '/routes/$routeId/pricing',
      options: Options(receiveTimeout: const Duration(seconds: 45)),
    );
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => WaypointPricingRow.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// POST /api/routes/{routeId}/adjust — adaptive replan (e.g. user-reported closed POI).
  Future<Map<String, dynamic>> adjustRoute({
    required String routeId,
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/routes/$routeId/adjust',
      data: body,
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty response from adjustRoute');
    }
    return data;
  }

  /// GET /routes/{routeId}
  Future<Map<String, dynamic>> getRoute(String routeId) async {
    final response = await _dio.get<Map<String, dynamic>>('/routes/$routeId');
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty response from getRoute');
    }
    return data;
  }

  /// GET /routes/conversation/{conversationId} — saved routes for this chat (oldest first).
  /// Matches web [aiApi.getRoutesForConversation]; used to restore route cards in history.
  Future<List<Map<String, dynamic>>> getRoutesForConversation(
    String conversationId,
  ) async {
    final response = await _dio.get<dynamic>(
      '/routes/conversation/$conversationId',
      options: Options(receiveTimeout: const Duration(seconds: 45)),
    );
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// POST /routes/directions
  ///
  /// Body matches backend record: { waypoints: [{ latitude, longitude, name? ... }] }
  Future<Map<String, dynamic>> getDirectionsGeometry({
    required List<Map<String, dynamic>> waypoints,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/routes/directions',
      data: {'waypoints': waypoints},
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty response from directions');
    }
    return data;
  }

  /// GET /routes/{routeId}/event-recommendations?day=
  Future<Map<String, dynamic>> getEventRecommendations(
    String routeId, {
    int? day,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/routes/$routeId/event-recommendations',
      queryParameters: {if (day != null) 'day': day},
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty response from event recommendations');
    }
    return data;
  }
}
