import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/api/chat_api_client.dart';
import '../../data/models/chat_models.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatApiClient _apiClient;

  ChatCubit(this._apiClient) : super(const ChatInitial());

  String? _conversationId;

  static final ChatMessage _greeting = ChatMessage(
    id: 'greeting',
    role: 'assistant',
    content: 'Merhaba, ben Vacanza AI. Bugün nereyi keşfetmek istersin?',
    createdAt: DateTime.now(),
  );

  /// Yerel karşılama; sunucuda conversation yaratılmaz ta ki ilk mesaj gönderilene kadar.
  Future<void> startConversation() async {
    try {
      if (_conversationId == null) {
        emit(ChatLoaded(
          messages: [_greeting],
          conversationId: null,
        ));
        return;
      }
      emit(const ChatLoading());
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
    final current = state;
    if (current is! ChatLoaded) return;

    late final String activeConvId;
    try {
      if (_conversationId != null) {
        activeConvId = _conversationId!;
      } else {
        final res = await _apiClient.createConversation();
        activeConvId = res.id;
        _conversationId = activeConvId;
      }
    } catch (e, st) {
      developer.log('Chat createConversation error: $e', name: 'ChatCubit', stackTrace: st);
      emit(ChatLoaded(
        messages: current.messages,
        conversationId: current.conversationId,
        isSending: false,
        error: e.toString(),
      ));
      return;
    }

    final userMsg = ChatMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: content.trim(),
      createdAt: DateTime.now(),
    );
    emit(ChatLoaded(
      messages: [...current.messages, userMsg],
      conversationId: activeConvId,
      isSending: true,
    ));

    try {
      final res = await _apiClient.sendMessage(
        activeConvId,
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
        conversationId: activeConvId,
        isSending: false,
      ));
    } catch (e, st) {
      developer.log('Chat API error: $e', name: 'ChatCubit', stackTrace: st);
      emit(ChatLoaded(
        messages: [...current.messages, userMsg],
        conversationId: activeConvId,
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

  /// Yeni sohbet (sunucuda henüz kayıt yok).
  void newConversation() {
    _conversationId = null;
    emit(ChatLoaded(
      messages: [_greeting],
      conversationId: null,
    ));
  }
}
