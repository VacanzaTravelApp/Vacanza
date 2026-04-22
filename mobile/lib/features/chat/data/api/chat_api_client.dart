import 'package:dio/dio.dart';

import '../models/chat_models.dart';

/// HTTP client for the chat API.
///
/// Uses the shared [Dio] instance (JwtInterceptor handles Bearer token).
/// Backend proxies to AI service at /chat/*.
class ChatApiClient {
  final Dio _dio;

  ChatApiClient(this._dio);

  /// POST /chat/routes/from-polygon — Create a multi-day itinerary from a drawn polygon.
  Future<MessageSendResponse> createRouteFromPolygon({
    required List<List<double>> coordinates,
    int? totalDays,
    String? travelStyle,
    List<String>? categories,
    bool? includeFavorites,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/chat/routes/from-polygon',
      data: {
        'coordinates': coordinates,
        if (totalDays != null) 'totalDays': totalDays,
        if (travelStyle != null) 'travelStyle': travelStyle,
        if (categories != null) 'categories': categories,
        if (includeFavorites != null) 'includeFavorites': includeFavorites,
      },
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    final data = response.data;
    if (data == null) {
      throw FormatException('Empty response from createRouteFromPolygon');
    }
    return MessageSendResponse.fromJson(data);
  }

  /// POST /chat/routes/replan-day-from-polygon — Replan a single day of the latest saved route.
  Future<MessageSendResponse> replanDayFromPolygon({
    required String conversationId,
    required int day,
    required List<List<double>> coordinates,
    String? travelStyle,
    List<String>? categories,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/chat/routes/replan-day-from-polygon',
      data: {
        'conversationId': conversationId,
        'day': day,
        'coordinates': coordinates,
        if (travelStyle != null) 'travelStyle': travelStyle,
        if (categories != null) 'categories': categories,
      },
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    final data = response.data;
    if (data == null) {
      throw FormatException('Empty response from replanDayFromPolygon');
    }
    return MessageSendResponse.fromJson(data);
  }

  /// GET /chat/conversations — List user's conversations.
  Future<List<ConversationListItem>> listConversations({
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _dio.get<dynamic>(
      '/chat/conversations',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final data = response.data;
    if (data is! List) return [];
    return data
        .map((e) => ConversationListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /chat/conversations — Create a new conversation.
  Future<ConversationCreateResponse> createConversation() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/chat/conversations',
      options: Options(receiveTimeout: const Duration(seconds: 30)),
    );
    final data = response.data;
    if (data == null) {
      throw FormatException('Empty response from create conversation');
    }
    return ConversationCreateResponse.fromJson(data);
  }

  /// POST /chat/conversations/{id}/messages — Send message, get AI response.
  /// AI can take 30–60s; use longer receiveTimeout.
  Future<MessageSendResponse> sendMessage(
    String conversationId,
    String content,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/chat/conversations/$conversationId/messages',
      data: {'content': content},
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    final data = response.data;
    if (data == null) {
      throw FormatException('Empty response from send message');
    }
    return MessageSendResponse.fromJson(data);
  }

  /// GET /chat/conversations/{id}/messages — Get conversation history.
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _dio.get<dynamic>(
      '/chat/conversations/$conversationId/messages',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final data = response.data;
    if (data is! List) {
      return [];
    }
    return data
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
