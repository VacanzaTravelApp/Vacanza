import '../../data/models/chat_models.dart';

sealed class ChatState {
  const ChatState();
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;

  /// Sunucu sohbeti; kullanıcı ilk mesajı gönderene kadar null (boş sohbet oluşturulmaz).
  final String? conversationId;
  final MessageSendResponse? lastResponse;
  final bool isSending;
  final String? error;

  /// The text of the last message that failed to send (used for retry).
  final String? lastFailedMessage;

  /// Non-null when a send failed and the user can retry inline.
  /// Distinct from [error] which is used for fatal/conversation-level errors.
  final String? retryableError;

  const ChatLoaded({
    required this.messages,
    this.conversationId,
    this.lastResponse,
    this.isSending = false,
    this.error,
    this.lastFailedMessage,
    this.retryableError,
  });
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});
}
