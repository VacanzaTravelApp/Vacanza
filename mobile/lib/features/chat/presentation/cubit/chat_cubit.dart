import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ai/data/api/ai_route_api_client.dart';
import '../../data/api/chat_api_client.dart';
import '../../data/models/chat_models.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatApiClient _apiClient;
  final AiRouteApiClient _routeApi;

  ChatCubit(this._apiClient, this._routeApi) : super(const ChatInitial());

  String? _conversationId;
  CancelToken? _sendCancelToken;

  static final ChatMessage _greeting = ChatMessage(
    id: 'greeting',
    role: 'assistant',
    content: 'Hi, I’m Vacanza AI. Where would you like to explore today?',
    createdAt: DateTime.now(),
  );

  /// Yerel karşılama; sunucuda conversation yaratılmaz ta ki ilk mesaj gönderilene kadar.
  Future<void> startConversation() async {
    try {
      if (_conversationId == null) {
        if (isClosed) return;
        emit(
          ChatLoaded(
            messages: [_greeting],
            conversationId: null,
            lastResponse: null,
          ),
        );
        return;
      }
      if (isClosed) return;
      emit(const ChatLoading());
      final messages = await _loadMessagesWithMergedRoutes(_conversationId!);
      if (isClosed) return;
      emit(
        ChatLoaded(
          messages: messages,
          conversationId: _conversationId!,
          lastResponse: null,
        ),
      );
    } catch (e, st) {
      developer.log(
        'Chat startConversation error: $e',
        name: 'ChatCubit',
        stackTrace: st,
      );
      if (isClosed) return;
      emit(ChatError(message: e.toString()));
    }
  }

  /// Cancel an in-flight [sendMessage] request silently (no error banner/retry bar).
  void stopSending() {
    _sendCancelToken?.cancel('user_cancelled');
    _sendCancelToken = null;
    final s = state;
    if (s is! ChatLoaded) return;
    emit(
      ChatLoaded(
        messages: s.messages,
        conversationId: s.conversationId,
        lastResponse: s.lastResponse,
        isSending: false,
      ),
    );
  }

  /// Remove last failed user message and re-send it.
  Future<void> retryLastMessage() async {
    final s = state;
    if (s is! ChatLoaded) return;
    final text = s.lastFailedMessage;
    if (text == null || text.isEmpty) return;
    final msgs = List<ChatMessage>.from(s.messages);
    for (var i = msgs.length - 1; i >= 0; i--) {
      if (msgs[i].role == 'user' && msgs[i].content == text) {
        msgs.removeAt(i);
        break;
      }
    }
    emit(
      ChatLoaded(
        messages: msgs,
        conversationId: s.conversationId,
        lastResponse: s.lastResponse,
        isSending: false,
      ),
    );
    await sendMessage(text);
  }

  /// Dismiss the inline retry bar without retrying.
  void clearRetryableError() {
    final s = state;
    if (s is! ChatLoaded || s.retryableError == null) return;
    emit(
      ChatLoaded(
        messages: s.messages,
        conversationId: s.conversationId,
        lastResponse: s.lastResponse,
        isSending: s.isSending,
        error: s.error,
        lastFailedMessage: s.lastFailedMessage,
      ),
    );
  }

  /// Send a user message and get AI response.
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    final current = state;
    if (current is! ChatLoaded) return;
    if (current.isSending) return;

    late final String activeConvId;
    try {
      if (_conversationId != null) {
        activeConvId = _conversationId!;
      } else {
        final res = await _apiClient.createConversation();
        if (isClosed) return;
        activeConvId = res.id;
        _conversationId = activeConvId;
      }
    } catch (e, st) {
      developer.log(
        'Chat createConversation error: $e',
        name: 'ChatCubit',
        stackTrace: st,
      );
      if (isClosed) return;
      emit(
        ChatLoaded(
          messages: current.messages,
          conversationId: current.conversationId,
          lastResponse: current.lastResponse,
          isSending: false,
          error: e.toString(),
        ),
      );
      return;
    }

    final trimmed = content.trim();
    final userMsg = ChatMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: trimmed,
      createdAt: DateTime.now(),
    );
    _sendCancelToken = CancelToken();
    emit(
      ChatLoaded(
        messages: [...current.messages, userMsg],
        conversationId: activeConvId,
        lastResponse: current.lastResponse,
        isSending: true,
        lastFailedMessage: trimmed,
      ),
    );

    try {
      final res = await _apiClient.sendMessage(
        activeConvId,
        trimmed,
        cancelToken: _sendCancelToken,
      );
      _sendCancelToken = null;
      if (isClosed) return;
      final assistantMsg = ChatMessage(
        id: 'ai-${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        content: res.content,
        createdAt: DateTime.now(),
        routeData: res.routeData,
        routeSummaryMessage: res.routeSummaryMessage,
        routeId: res.routeId,
      );
      final s = state;
      final prevMsgs =
          s is ChatLoaded ? s.messages : [...current.messages, userMsg];
      emit(
        ChatLoaded(
          messages: [
            ...prevMsgs.where((m) => m.id != userMsg.id),
            userMsg,
            assistantMsg,
          ],
          conversationId: activeConvId,
          lastResponse: res,
          isSending: false,
        ),
      );
    } on DioException catch (e, st) {
      _sendCancelToken = null;
      if (isClosed) return;
      if (e.type == DioExceptionType.cancel) {
        // User tapped stop — stopSending() already updated state; ensure isSending=false.
        final s = state;
        if (s is ChatLoaded && s.isSending) {
          emit(
            ChatLoaded(
              messages: s.messages,
              conversationId: s.conversationId,
              lastResponse: s.lastResponse,
              isSending: false,
            ),
          );
        }
        return;
      }
      developer.log('Chat API error: $e', name: 'ChatCubit', stackTrace: st);
      final s = state;
      if (s is! ChatLoaded) return;
      emit(
        ChatLoaded(
          messages: s.messages,
          conversationId: activeConvId,
          lastResponse: s.lastResponse,
          isSending: false,
          lastFailedMessage: trimmed,
          retryableError: _mapSendError(e),
        ),
      );
    } catch (e, st) {
      _sendCancelToken = null;
      developer.log('Chat API error: $e', name: 'ChatCubit', stackTrace: st);
      if (isClosed) return;
      final s = state;
      if (s is! ChatLoaded) return;
      emit(
        ChatLoaded(
          messages: s.messages,
          conversationId: activeConvId,
          lastResponse: s.lastResponse,
          isSending: false,
          lastFailedMessage: trimmed,
          retryableError: 'Something went wrong. Please try again.',
        ),
      );
    }
  }

  String _mapSendError(DioException e) {
    final status = e.response?.statusCode;
    if (e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionTimeout ||
        status == 500 ||
        status == 502 ||
        status == 503) {
      return 'Vacanza AI is busy. Please try again.';
    }
    if (status == 429) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'] ?? data['error'] ?? data['detail'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return 'Failed to send message. Please try again.';
  }

  Future<List<ChatMessage>> _loadMessagesWithMergedRoutes(
    String conversationId,
  ) async {
    final raw = filterVisibleChatMessages(
      await _apiClient.getMessages(conversationId),
    );
    var merged = raw;
    try {
      final details = await _routeApi.getRoutesForConversation(conversationId);
      merged = _mergeHistoryWithSavedRoutes(raw, details);
    } catch (e, st) {
      developer.log(
        'Chat conversation routes merge skipped: $e',
        name: 'ChatCubit',
        stackTrace: st,
      );
    }
    return _hydrateRouteDataForMessages(merged);
  }

  /// Fills [ChatMessage.routeData] from GET /routes/{id} when the API only sent `route_id`.
  Future<List<ChatMessage>> _hydrateRouteDataForMessages(
    List<ChatMessage> messages,
  ) async {
    final cache = <String, ChatRouteData>{};
    final out = <ChatMessage>[];
    for (final m in messages) {
      final rid = m.routeId;
      if (rid != null && m.routeData == null) {
        if (!cache.containsKey(rid)) {
          try {
            final json = await _routeApi.getRoute(rid);
            final raw = json['routeData'] ?? json['route_data'];
            if (raw is Map<String, dynamic>) {
              cache[rid] = ChatRouteData.fromJson(raw);
            } else if (raw is Map) {
              cache[rid] = ChatRouteData.fromJson(
                Map<String, dynamic>.from(raw),
              );
            }
          } catch (e, st) {
            developer.log(
              'Chat route hydrate failed for $rid: $e',
              name: 'ChatCubit',
              stackTrace: st,
            );
          }
        }
        final data = cache[rid];
        if (data != null) {
          out.add(
            ChatMessage(
              id: m.id,
              role: m.role,
              content: m.content,
              createdAt: m.createdAt,
              routeData: data,
              routeSummaryMessage: m.routeSummaryMessage,
              routeId: m.routeId,
            ),
          );
          continue;
        }
      }
      out.add(m);
    }
    return out;
  }

  /// Aligns with web [mergeHistoryWithSavedRoutes]: attach saved route payloads to the
  /// best-matching assistant bubbles (message list API does not include route JSON).
  List<ChatMessage> _mergeHistoryWithSavedRoutes(
    List<ChatMessage> messages,
    List<Map<String, dynamic>> routeDetails,
  ) {
    if (routeDetails.isEmpty) return messages;

    final routes =
        routeDetails
            .map(
              (d) => (
                data: _chatRouteDataFromSavedDetail(d),
                routeId: _routeIdFromDetail(d),
                t: _routeGeneratedAtMs(d),
              ),
            )
            .where((r) => r.data != null)
            .toList()
          ..sort((a, b) => a.t.compareTo(b.t));

    if (routes.isEmpty) return messages;

    final assistantMsgs =
        messages.where((m) => m.role != 'user').toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    var assistantPool =
        assistantMsgs
            .where((m) => _looksLikeRouteRelatedReply(m.content))
            .toList();
    if (assistantPool.isEmpty) {
      assistantPool = assistantMsgs;
    }

    final byMessageId =
        <String, ({List<ChatRouteData> datas, List<String?> ids})>{};
    final usedAssistantIds = <String>{};

    ChatMessage? pickAssistantForRoute(
      ({ChatRouteData? data, String? routeId, int t}) rr,
    ) {
      final candidates =
          assistantPool.where((m) => !usedAssistantIds.contains(m.id)).toList();
      if (candidates.isEmpty) return null;
      ChatMessage? best;
      var bestScore = double.infinity;
      for (final msg in candidates) {
        final msgMs = msg.createdAt.millisecondsSinceEpoch;
        final dt = (msgMs - rr.t).abs().toDouble();
        final latePenalty = msgMs + 1500 < rr.t ? 60000.0 : 0.0;
        final score = dt + latePenalty;
        if (score < bestScore) {
          bestScore = score;
          best = msg;
        }
      }
      return best;
    }

    for (final rr in routes) {
      var best = pickAssistantForRoute(rr);
      if (best == null && assistantPool.isNotEmpty) {
        best = assistantPool.last;
      }
      if (best != null) {
        usedAssistantIds.add(best.id);
        final prev = byMessageId[best.id];
        final datas = [...?prev?.datas, rr.data!];
        final ids = [...?prev?.ids, rr.routeId];
        byMessageId[best.id] = (datas: datas, ids: ids);
      }
    }

    return messages.map((m) {
      final bundle = byMessageId[m.id];
      if (bundle == null || bundle.datas.isEmpty) return m;
      final last = bundle.datas.last;
      final lastId = bundle.ids.isNotEmpty ? bundle.ids.last : m.routeId;
      return ChatMessage(
        id: m.id,
        role: m.role,
        content: m.content,
        createdAt: m.createdAt,
        routeData: last,
        routeSummaryMessage: m.routeSummaryMessage,
        routeId: lastId ?? m.routeId,
      );
    }).toList();
  }

  ChatRouteData? _chatRouteDataFromSavedDetail(Map<String, dynamic> d) {
    final raw = d['routeData'] ?? d['route_data'];
    if (raw == null) return null;
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return ChatRouteData.fromJson(decoded);
        }
      } catch (_) {}
      return null;
    }
    if (raw is Map<String, dynamic>) {
      return ChatRouteData.fromJson(raw);
    }
    if (raw is Map) {
      return ChatRouteData.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  String? _routeIdFromDetail(Map<String, dynamic> d) {
    final raw = d['routeId'] ?? d['route_id'];
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  int _routeGeneratedAtMs(Map<String, dynamic> d) {
    final raw = d['generatedAt'] ?? d['generated_at'];
    if (raw is String) {
      return DateTime.tryParse(raw)?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
  }

  bool _looksLikeRouteRelatedReply(String text) {
    final s = text.trim();
    if (s.isEmpty) return false;
    final lower = s.toLowerCase();
    if (RegExp(
      r"i['']?m here to help with travel",
      caseSensitive: false,
    ).hasMatch(lower)) {
      return false;
    }
    if (RegExp(
      r"^i['']?m here to help\b",
      caseSensitive: false,
    ).hasMatch(lower)) {
      return false;
    }
    if (RegExp(
      r'here is your .+ itinerary\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return true;
    }
    if (lower.contains('itinerary') && lower.contains('here is')) return true;
    if (RegExp(r'day\s+\d+\s+is\s+updated', caseSensitive: false).hasMatch(s)) {
      return true;
    }
    if (lower.contains('updated for your map area')) return true;
    if (RegExp(r'---\s*route_json\s*---', caseSensitive: false).hasMatch(s)) {
      return true;
    }
    // Turkish route replies (Vacanza default locale)
    if (lower.contains('rotanız') || lower.contains('rotan')) return true;
    if (lower.contains('güzergah') || lower.contains('guzergah')) return true;
    if (lower.contains('planladım') || lower.contains('hazırladım')) {
      return true;
    }
    return false;
  }

  /// Clear last error (e.g. after showing SnackBar).
  void clearLastError() {
    final s = state;
    if (s is ChatLoaded && s.error != null) {
      if (isClosed) return;
      emit(
        ChatLoaded(
          messages: s.messages,
          conversationId: s.conversationId,
          lastResponse: s.lastResponse,
          isSending: false,
          error: null,
          lastFailedMessage: s.lastFailedMessage,
          retryableError: s.retryableError,
        ),
      );
    }
  }

  /// Load an existing conversation by ID.
  Future<void> loadConversation(String conversationId) async {
    if (isClosed) return;
    emit(const ChatLoading());
    try {
      _conversationId = conversationId;
      final messages = await _loadMessagesWithMergedRoutes(conversationId);
      if (isClosed) return;
      emit(
        ChatLoaded(
          messages: messages,
          conversationId: conversationId,
          lastResponse: null,
        ),
      );
    } catch (e, st) {
      developer.log(
        'Chat loadConversation error: $e',
        name: 'ChatCubit',
        stackTrace: st,
      );
      if (isClosed) return;
      emit(ChatError(message: e.toString()));
    }
  }

  /// Yeni taslak: API çağrısı yok; kullanıcı mesaj gönderene kadar conversation oluşturulmaz.
  void newConversation() {
    _conversationId = null;
    _sendCancelToken?.cancel('new_conversation');
    _sendCancelToken = null;
    if (isClosed) return;
    emit(
      ChatLoaded(
        messages: [_greeting],
        conversationId: null,
        lastResponse: null,
      ),
    );
  }

  @override
  Future<void> close() {
    _sendCancelToken?.cancel('cubit_closed');
    _sendCancelToken = null;
    return super.close();
  }
}
