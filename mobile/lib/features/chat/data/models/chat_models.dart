/// Chat API models.
///
/// Backend returns snake_case (from AI service).
class ChatMessage {
  final String id;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'];
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: createdAt is String
          ? DateTime.tryParse(createdAt) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isUser => role == 'user';
}

class ConversationCreateResponse {
  final String id;

  const ConversationCreateResponse({required this.id});

  factory ConversationCreateResponse.fromJson(Map<String, dynamic> json) {
    return ConversationCreateResponse(
      id: (json['id'] ?? '').toString(),
    );
  }
}

class MessageSendResponse {
  final String content;
  final List<ExtractedPreference> extractedPreferences;

  const MessageSendResponse({
    required this.content,
    this.extractedPreferences = const [],
  });

  factory MessageSendResponse.fromJson(Map<String, dynamic> json) {
    final prefs = json['extracted_preferences'];
    return MessageSendResponse(
      content: (json['content'] ?? '').toString(),
      extractedPreferences: prefs is List
          ? (prefs)
              .map((e) => ExtractedPreference.fromJson(
                  e as Map<String, dynamic>))
              .toList()
          : const [],
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
