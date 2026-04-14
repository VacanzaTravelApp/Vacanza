import 'dart:convert';

/// Chat API models.
///
/// Backend returns snake_case (from AI service).

/// Internal POI tool round-trip rows (saved for LLM context; hide in UI).
bool isSearchPoisPipelineMessage(String content) {
  if (content.contains('__TOOL_RESULT__search_pois__')) return true;
  final t = content.trim();
  if (!t.startsWith('{')) return false;
  try {
    final dynamic j = jsonDecode(t);
    if (j is Map && j['tool'] == 'search_pois') return true;
  } catch (_) {}
  return false;
}

List<ChatMessage> filterVisibleChatMessages(List<ChatMessage> messages) =>
    messages.where((m) => !isSearchPoisPipelineMessage(m.content)).toList();

class ChatMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;
  final ChatRouteData? routeData;
  final String? routeSummaryMessage;
  final String? routeId;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.routeData,
    this.routeSummaryMessage,
    this.routeId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'] ?? json['createdAt'];
    final routeDataMap = _routeDataMapFromJson(json);
    final routeData =
        routeDataMap != null ? ChatRouteData.fromJson(routeDataMap) : null;
    final rsmRaw = json['route_summary_message'] ?? json['routeSummaryMessage'];
    final routeSummaryMessage =
        (rsmRaw ?? '').toString().trim().isEmpty
            ? null
            : rsmRaw.toString();
    final ridRaw = json['route_id'] ?? json['routeId'];
    final routeId =
        (ridRaw ?? '').toString().trim().isEmpty
            ? null
            : ridRaw.toString();
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt:
          createdAt is String
              ? DateTime.tryParse(createdAt) ?? DateTime.now()
              : DateTime.now(),
      routeData: routeData,
      routeSummaryMessage: routeSummaryMessage,
      routeId: routeId,
    );
  }

  bool get isUser => role == 'user';
}

Map<String, dynamic>? _routeDataMapFromJson(Map<String, dynamic> json) {
  final m = json['route_data'] ?? json['routeData'];
  if (m is Map<String, dynamic>) {
    return m;
  }
  if (m is Map) {
    return Map<String, dynamic>.from(m);
  }
  return null;
}

class ConversationCreateResponse {
  final String id;

  const ConversationCreateResponse({required this.id});

  factory ConversationCreateResponse.fromJson(Map<String, dynamic> json) {
    return ConversationCreateResponse(id: (json['id'] ?? '').toString());
  }
}

class ConversationListItem {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConversationListItem({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationListItem.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'];
    final updatedAt = json['updated_at'];
    return ConversationListItem(
      id: (json['id'] ?? '').toString(),
      createdAt:
          createdAt is String
              ? DateTime.tryParse(createdAt) ?? DateTime.now()
              : DateTime.now(),
      updatedAt:
          updatedAt is String
              ? DateTime.tryParse(updatedAt) ?? DateTime.now()
              : DateTime.now(),
    );
  }
}

class MessageSendResponse {
  final String content;
  final List<ExtractedPreference> extractedPreferences;
  final ChatRouteData? routeData;
  final String? routeSummaryMessage;
  final String? routeId;
  final String? conversationId;

  const MessageSendResponse({
    required this.content,
    this.extractedPreferences = const [],
    this.routeData,
    this.routeSummaryMessage,
    this.routeId,
    this.conversationId,
  });

  factory MessageSendResponse.fromJson(Map<String, dynamic> json) {
    final prefs = json['extracted_preferences'] ?? json['extractedPreferences'];
    final routeDataMap = _routeDataMapFromJson(json);
    final rsmRaw = json['route_summary_message'] ?? json['routeSummaryMessage'];
    final ridRaw = json['route_id'] ?? json['routeId'];
    final cidRaw = json['conversation_id'] ?? json['conversationId'];
    return MessageSendResponse(
      content: (json['content'] ?? '').toString(),
      extractedPreferences:
          prefs is List
              ? (prefs)
                  .map(
                    (e) =>
                        ExtractedPreference.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
              : const [],
      routeData:
          routeDataMap != null ? ChatRouteData.fromJson(routeDataMap) : null,
      routeSummaryMessage:
          (rsmRaw ?? '').toString().trim().isEmpty
              ? null
              : rsmRaw.toString(),
      routeId:
          (ridRaw ?? '').toString().trim().isEmpty
              ? null
              : ridRaw.toString(),
      conversationId:
          (cidRaw ?? '').toString().trim().isEmpty
              ? null
              : cidRaw.toString(),
    );
  }
}

/// Minimal route payload returned inside chat message response (snake_case).
class ChatRouteData {
  final String? title;
  final String? destination;
  final int totalDays;
  final List<ChatDayPlan> days;
  final String? notes;

  /// When true, event search uses the trip date range from the route (narrow window).
  final bool? tripDatesUserSpecified;

  /// First calendar day of the trip (YYYY-MM-DD) when user stated dates.
  final String? tripStartDate;

  /// Open-Meteo daily summaries (backend-enriched).
  final List<DailyWeatherSummary> weatherForecast;

  /// Morning / afternoon / evening slots per day.
  final List<DayPartWeatherDay> weatherDayParts;

  const ChatRouteData({
    this.title,
    this.destination,
    required this.totalDays,
    required this.days,
    this.notes,
    this.tripDatesUserSpecified,
    this.tripStartDate,
    this.weatherForecast = const [],
    this.weatherDayParts = const [],
  });

  factory ChatRouteData.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    final days =
        rawDays is List
            ? rawDays
                .whereType<Map>()
                .map((e) => ChatDayPlan.fromJson(e.cast<String, dynamic>()))
                .toList()
            : <ChatDayPlan>[];
    final td = json['total_days'];

    final wf = json['weather_forecast'] ?? json['weatherForecast'];
    final weatherForecast =
        wf is List
            ? wf
                .whereType<Map>()
                .map(
                  (e) =>
                      DailyWeatherSummary.fromJson(e.cast<String, dynamic>()),
                )
                .toList()
            : <DailyWeatherSummary>[];

    final wdp = json['weather_day_parts'] ?? json['weatherDayParts'];
    final weatherDayParts =
        wdp is List
            ? wdp
                .whereType<Map>()
                .map(
                  (e) => DayPartWeatherDay.fromJson(e.cast<String, dynamic>()),
                )
                .toList()
            : <DayPartWeatherDay>[];

    final tdu =
        json['trip_dates_user_specified'] ?? json['tripDatesUserSpecified'];
    final tripDatesUserSpecified = tdu is bool ? tdu : null;

    final ts = json['trip_start_date'] ?? json['tripStartDate'];
    final tripStartDate =
        (ts is String && ts.trim().isNotEmpty) ? ts.trim() : null;

    return ChatRouteData(
      title:
          (json['title'] as String?)?.trim().isEmpty == true
              ? null
              : (json['title'] as String?),
      destination:
          (json['destination'] as String?)?.trim().isEmpty == true
              ? null
              : (json['destination'] as String?),
      totalDays: (td is num) ? td.toInt() : (days.isNotEmpty ? days.length : 0),
      days: days,
      notes:
          (json['notes'] as String?)?.trim().isEmpty == true
              ? null
              : (json['notes'] as String?),
      tripDatesUserSpecified: tripDatesUserSpecified,
      tripStartDate: tripStartDate,
      weatherForecast: weatherForecast,
      weatherDayParts: weatherDayParts,
    );
  }
}

/// One day of forecast (Open-Meteo / backend DTO).
class DailyWeatherSummary {
  final String? date;
  final int? weatherCode;
  final double? tempMaxCelsius;
  final double? tempMinCelsius;
  final double? precipitationProbabilityMaxPercent;

  const DailyWeatherSummary({
    this.date,
    this.weatherCode,
    this.tempMaxCelsius,
    this.tempMinCelsius,
    this.precipitationProbabilityMaxPercent,
  });

  factory DailyWeatherSummary.fromJson(Map<String, dynamic> json) {
    num? n(dynamic v) => v is num ? v : (v is String ? num.tryParse(v) : null);
    return DailyWeatherSummary(
      date:
          (json['date'] ?? '').toString().trim().isEmpty
              ? null
              : (json['date']).toString(),
      weatherCode:
          (json['weather_code'] ?? json['weatherCode']) is num
              ? ((json['weather_code'] ?? json['weatherCode']) as num).toInt()
              : null,
      tempMaxCelsius:
          n(json['temp_max_celsius'] ?? json['tempMaxCelsius'])?.toDouble(),
      tempMinCelsius:
          n(json['temp_min_celsius'] ?? json['tempMinCelsius'])?.toDouble(),
      precipitationProbabilityMaxPercent:
          n(
            json['precipitation_probability_max_percent'] ??
                json['precipitationProbabilityMaxPercent'],
          )?.toDouble(),
    );
  }
}

class DayPartSlot {
  final int? weatherCode;
  final int? precipitationProbabilityMaxPercent;
  final bool avoidOutdoor;

  const DayPartSlot({
    this.weatherCode,
    this.precipitationProbabilityMaxPercent,
    this.avoidOutdoor = false,
  });

  factory DayPartSlot.fromJson(Map<String, dynamic> json) {
    return DayPartSlot(
      weatherCode:
          (json['weather_code'] ?? json['weatherCode']) is num
              ? ((json['weather_code'] ?? json['weatherCode']) as num).toInt()
              : null,
      precipitationProbabilityMaxPercent:
          (json['precipitation_probability_max_percent'] ??
                      json['precipitationProbabilityMaxPercent'])
                  is num
              ? ((json['precipitation_probability_max_percent'] ??
                          json['precipitationProbabilityMaxPercent'])
                      as num)
                  .toInt()
              : null,
      avoidOutdoor:
          json['avoid_outdoor'] == true || json['avoidOutdoor'] == true,
    );
  }
}

class DayPartWeatherDay {
  final String? date;
  final DayPartSlot? morning;
  final DayPartSlot? afternoon;
  final DayPartSlot? evening;

  const DayPartWeatherDay({
    this.date,
    this.morning,
    this.afternoon,
    this.evening,
  });

  factory DayPartWeatherDay.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? m(dynamic v) =>
        v is Map ? v.cast<String, dynamic>() : null;
    return DayPartWeatherDay(
      date:
          (json['date'] ?? '').toString().trim().isEmpty
              ? null
              : (json['date']).toString(),
      morning:
          m(json['morning']) != null
              ? DayPartSlot.fromJson(m(json['morning'])!)
              : null,
      afternoon:
          m(json['afternoon']) != null
              ? DayPartSlot.fromJson(m(json['afternoon'])!)
              : null,
      evening:
          m(json['evening']) != null
              ? DayPartSlot.fromJson(m(json['evening'])!)
              : null,
    );
  }
}

class ChatDayPlan {
  final int day;
  final String? title;
  final List<ChatRouteWaypoint> waypoints;
  final String? dayStartLocal;
  final String? dayEndLocal;

  const ChatDayPlan({
    required this.day,
    this.title,
    required this.waypoints,
    this.dayStartLocal,
    this.dayEndLocal,
  });

  factory ChatDayPlan.fromJson(Map<String, dynamic> json) {
    final rawWps = json['waypoints'];
    final wps =
        rawWps is List
            ? rawWps
                .whereType<Map>()
                .map(
                  (e) => ChatRouteWaypoint.fromJson(e.cast<String, dynamic>()),
                )
                .toList()
            : <ChatRouteWaypoint>[];
    final d = json['day'];
    return ChatDayPlan(
      day: (d is num) ? d.toInt() : 0,
      title:
          (json['title'] as String?)?.trim().isEmpty == true
              ? null
              : (json['title'] as String?),
      waypoints: wps,
      dayStartLocal:
          (json['day_start_local'] as String?)?.trim().isEmpty == true
              ? null
              : (json['day_start_local'] as String?),
      dayEndLocal:
          (json['day_end_local'] as String?)?.trim().isEmpty == true
              ? null
              : (json['day_end_local'] as String?),
    );
  }
}

class ChatRouteWaypoint {
  final String name;
  final String? description;
  final String? category;
  final int day;
  final int order;
  final double? latitude;
  final double? longitude;
  final int? estimatedDurationMin;
  final String? timeSlot;
  final int? travelFromPreviousMin;
  final String? arrivalTimeLocal;
  final String? departureTimeLocal;
  final bool unavailable;

  const ChatRouteWaypoint({
    required this.name,
    this.description,
    this.category,
    required this.day,
    required this.order,
    this.latitude,
    this.longitude,
    this.estimatedDurationMin,
    this.timeSlot,
    this.travelFromPreviousMin,
    this.arrivalTimeLocal,
    this.departureTimeLocal,
    required this.unavailable,
  });

  factory ChatRouteWaypoint.fromJson(Map<String, dynamic> json) {
    num? asNum(dynamic v) =>
        v is num ? v : (v is String ? num.tryParse(v) : null);
    final lat = asNum(json['latitude']) ?? asNum(json['lat']);
    final lon =
        asNum(json['longitude']) ?? asNum(json['lon']) ?? asNum(json['lng']);
    return ChatRouteWaypoint(
      name: (json['name'] ?? '').toString(),
      description:
          (json['description'] as String?)?.trim().isEmpty == true
              ? null
              : (json['description'] as String?),
      category:
          (json['category'] as String?)?.trim().isEmpty == true
              ? null
              : (json['category'] as String?),
      day: (json['day'] is num) ? (json['day'] as num).toInt() : 0,
      order: (json['order'] is num) ? (json['order'] as num).toInt() : 0,
      latitude: lat?.toDouble(),
      longitude: lon?.toDouble(),
      estimatedDurationMin:
          (json['estimated_duration_min'] is num)
              ? (json['estimated_duration_min'] as num).toInt()
              : null,
      timeSlot:
          (json['time_slot'] as String?)?.trim().isEmpty == true
              ? null
              : (json['time_slot'] as String?),
      travelFromPreviousMin:
          (json['travel_from_previous_min'] is num)
              ? (json['travel_from_previous_min'] as num).toInt()
              : null,
      arrivalTimeLocal:
          (json['arrival_time_local'] as String?)?.trim().isEmpty == true
              ? null
              : (json['arrival_time_local'] as String?),
      departureTimeLocal:
          (json['departure_time_local'] as String?)?.trim().isEmpty == true
              ? null
              : (json['departure_time_local'] as String?),
      unavailable: json['unavailable'] == true,
    );
  }
}

class ExtractedPreference {
  final String preferenceKey;
  final String preferenceValue;
  final double? confidence;

  const ExtractedPreference({
    required this.preferenceKey,
    required this.preferenceValue,
    this.confidence,
  });

  factory ExtractedPreference.fromJson(Map<String, dynamic> json) {
    return ExtractedPreference(
      preferenceKey: (json['preference_key'] ?? '').toString(),
      preferenceValue: (json['preference_value'] ?? '').toString(),
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}
