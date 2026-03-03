import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/api/chat_api_client.dart';
import '../../data/models/chat_models.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatApiClient _apiClient;

  ChatCubit(this._apiClient) : super(const ChatInitial());

  String? _conversationId;

  /// Start or resume a conversation.
  /// Creates new conversation if none exists, then loads history.
  Future<void> startConversation() async {
    emit(const ChatLoading());
    try {
      if (_conversationId == null) {
        final res = await _apiClient.createConversation();
        _conversationId = res.id;
      }
      final messages = await _apiClient.getMessages(_conversationId!);
      emit(ChatLoaded(
        messages: messages,
        conversationId: _conversationId!,
      ));
    } catch (e, st) {
      developer.log('Chat startConversation error: $e', name: 'ChatCubit', stackTrace: st);
      emit(ChatError(message: e.toString()));
    }
  }

  /// Send a user message and get AI response.
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (_conversationId == null) return;

    final current = state;
    if (current is! ChatLoaded) return;

    // Optimistic: add user message
    final userMsg = ChatMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: content.trim(),
      createdAt: DateTime.now(),
    );
    emit(ChatLoaded(
      messages: [...current.messages, userMsg],
      conversationId: current.conversationId,
      isSending: true,
    ));

    try {
      final res = await _apiClient.sendMessage(
        _conversationId!,
        content.trim(),
      );
      final assistantMsg = ChatMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        content: res.content,
        createdAt: DateTime.now(),
      );
      final updated = [...current.messages, userMsg, assistantMsg];
      emit(ChatLoaded(
        messages: updated,
        conversationId: current.conversationId,
        isSending: false,
      ));
    } catch (e, st) {
      developer.log('Chat API error: $e', name: 'ChatCubit', stackTrace: st);
      // Keep user message, show error (don't rollback — user sees their message)
      emit(ChatLoaded(
        messages: [...current.messages, userMsg],
        conversationId: current.conversationId,
        isSending: false,
        error: e.toString(),
      ));
    }
  }

  /// Clear last error (e.g. after showing SnackBar).
  void clearLastError() {
    final s = state;
    if (s is ChatLoaded && s.error != null) {
      emit(ChatLoaded(
        messages: s.messages,
        conversationId: s.conversationId,
        isSending: false,
        error: null,
      ));
    }
  }

  /// Load an existing conversation by ID.
  Future<void> loadConversation(String conversationId) async {
    emit(const ChatLoading());
    try {
      _conversationId = conversationId;
      final messages = await _apiClient.getMessages(conversationId);
      emit(ChatLoaded(
        messages: messages,
        conversationId: conversationId,
      ));
    } catch (e, st) {
      developer.log('Chat loadConversation error: $e', name: 'ChatCubit', stackTrace: st);
      emit(ChatError(message: e.toString()));
    }
  }

  /// Start a new conversation (clears current).
  void newConversation() {
    _conversationId = null;
    emit(const ChatInitial());
    startConversation();
  }
}
