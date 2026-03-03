import 'package:dio/dio.dart';

import '../models/chat_models.dart';

/// HTTP client for the chat API.
///
/// Uses the shared [Dio] instance (JwtInterceptor handles Bearer token).
/// Backend proxies to AI service at /chat/*.
class ChatApiClient {
  final Dio _dio;

  ChatApiClient(this._dio);

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
        .map((e) =>
            ConversationListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /chat/conversations — Create a new conversation.
  Future<ConversationCreateResponse> createConversation() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/chat/conversations',
      options: Options(
        receiveTimeout: const Duration(seconds: 30),
      ),
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
      options: Options(
        receiveTimeout: const Duration(seconds: 90),
      ),
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
