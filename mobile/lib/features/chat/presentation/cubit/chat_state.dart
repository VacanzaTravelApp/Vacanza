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
  final String conversationId;
  final bool isSending;
  final String? error;

  const ChatLoaded({
    required this.messages,
    required this.conversationId,
    this.isSending = false,
    this.error,
  });
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});
}
