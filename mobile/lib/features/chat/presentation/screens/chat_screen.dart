import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import 'package:mobile/core/widgets/vacanza_gradient_button.dart';
import '../../data/api/chat_api_client.dart';
import '../../data/models/chat_models.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/chat_empty_state.dart';
import '../widgets/chat_error_banner.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_route_card.dart';
import '../widgets/chat_typing_indicator.dart';
import '../widgets/past_conversations_sheet.dart';
import '../../data/loading_tips.dart';

/// Result when closing the chat after a route action (maps to web navigation).
class ChatScreenNavResult {
  final MessageSendResponse response;
  final bool openEventsInitially;
  final bool startDrawAreaOnMap;

  const ChatScreenNavResult({
    required this.response,
    this.openEventsInitially = false,
    this.startDrawAreaOnMap = false,
  });
}

/// Returns the last element matching [test], or null.
T? _lastWhere<T>(List<T> list, bool Function(T) test) {
  for (var i = list.length - 1; i >= 0; i--) {
    if (test(list[i])) return list[i];
  }
  return null;
}

/// Chatbot screen — AI travel assistant.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ChatScreenView();
  }
}

class _ChatScreenView extends StatefulWidget {
  const _ChatScreenView();

  @override
  State<_ChatScreenView> createState() => _ChatScreenViewState();
}

class _ChatScreenViewState extends State<_ChatScreenView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasDraft = false;
  bool _showJumpToLatest = false;

  // ── Loading tip state (mirrors web 9-second rotation) ──
  TravelTip? _currentTip;
  List<TravelTip> _tipPool = [];
  int _tipIndex = 0;
  Timer? _tipTimer;
  String? _lastSentText;

  String _formatTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    // If user navigates away and comes back while a request is still in-flight,
    // ChatCubit may already be in `isSending=true` without triggering listenWhen.
    // Ensure tips appear immediately in that case.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = context.read<ChatCubit>().state;
      if (s is ChatLoaded && s.isSending) {
        _startTipRotation(_lastSentText ?? '');
      }
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final distanceFromBottom = (pos.maxScrollExtent - pos.pixels).abs();
    final shouldShow = distanceFromBottom > 420;
    if (shouldShow != _showJumpToLatest && mounted) {
      setState(() => _showJumpToLatest = shouldShow);
    }
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _scrollController.removeListener(_handleScroll);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startTipRotation(String cityHint) {
    _tipTimer?.cancel();
    _tipPool = getTipsForCity(cityHint);
    _tipIndex = 0;
    if (_tipPool.isNotEmpty) {
      setState(() => _currentTip = _tipPool[0]);
    }
    _tipTimer = Timer.periodic(const Duration(seconds: 9), (_) {
      if (_tipPool.isEmpty || !mounted) return;
      _tipIndex = (_tipIndex + 1) % _tipPool.length;
      setState(() => _currentTip = _tipPool[_tipIndex]);
    });
  }

  void _stopTipRotation() {
    _tipTimer?.cancel();
    _tipTimer = null;
    if (mounted) setState(() => _currentTip = null);
  }

  void _advanceTip() {
    if (_tipPool.isEmpty) return;
    _tipIndex = (_tipIndex + 1) % _tipPool.length;
    setState(() => _currentTip = _tipPool[_tipIndex]);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showPastConversations(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final s = context.read<ChatCubit>().state;
        final selectedId = s is ChatLoaded ? s.conversationId : null;
        return PastConversationsSheet(
          apiClient: ctx.read<ChatApiClient>(),
          selectedConversationId: selectedId,
          onSelect: (conversationId) {
            Navigator.of(ctx).pop();
            context.read<ChatCubit>().loadConversation(conversationId);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: t.bgMain,
      appBar: AppBar(
        title: BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            final String title;
            if (state is ChatLoaded &&
                (state.conversationId ?? '').isNotEmpty) {
              // v1: backend doesn't expose titles on mobile yet.
              title = 'Vacanza AI';
            } else {
              title = 'Vacanza AI';
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: t.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).brightness == Brightness.light
                                ? const Color(0xFF2DD4A8)
                                : const Color(0xFF34D399),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (Theme.of(context).brightness ==
                                        Brightness.light
                                    ? const Color(0xFF2DD4A8)
                                    : const Color(0xFF34D399))
                                .withValues(alpha: 0.55),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Travel assistant',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: t.textSub.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        backgroundColor:
            Theme.of(context).brightness == Brightness.light
                ? context.lightGlassPanelColor
                : cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: t.accentGradient),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () async {
            if (!_hasDraft) {
              Navigator.of(context).pop();
              return;
            }
            final shouldClose = await showDialog<bool>(
              context: context,
              builder: (ctx) {
                final t = ctx.vacanzaTokens;
                return AlertDialog(
                  title: const Text('Discard message?'),
                  content: const Text('You have a draft message.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text('Keep', style: TextStyle(color: t.vividBlue)),
                    ),
                    VacanzaGradientButton(
                      label: 'Discard',
                      onPressed: () => Navigator.of(ctx).pop(true),
                      enabled: true,
                      minHeight: 44,
                      borderRadius: 14,
                      horizontalPadding: 16,
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                );
              },
            );
            if (shouldClose == true && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          color: t.textMain,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Past conversations',
            onPressed: () => _showPastConversations(context),
            color: t.textMain,
          ),
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              if (state is ChatLoaded && state.messages.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'New conversation',
                  onPressed: () => context.read<ChatCubit>().newConversation(),
                  color: t.vividBlue,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatCubit, ChatState>(
              listenWhen: (prev, next) {
                if (next is ChatLoaded && prev is ChatLoaded) {
                  if (next.messages.length > prev.messages.length) return true;
                  if (next.error != null && next.error != prev.error) {
                    return true;
                  }
                  if (next.isSending != prev.isSending) return true;
                }
                return false;
              },
              listener: (context, state) {
                if (state is ChatLoaded) {
                  if (state.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error!),
                        duration: const Duration(seconds: 8),
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'OK',
                          onPressed: () {
                            context.read<ChatCubit>().clearLastError();
                          },
                        ),
                      ),
                    );
                  }
                  if (state.retryableError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.retryableError!),
                        duration: const Duration(seconds: 6),
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'Retry',
                          onPressed: () {
                            context.read<ChatCubit>().retryLastMessage();
                          },
                        ),
                      ),
                    );
                  }
                  // Start / stop tip rotation based on sending state
                  if (state.isSending) {
                    _startTipRotation(_lastSentText ?? '');
                  } else {
                    _stopTipRotation();
                  }
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                if (state is ChatLoading) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: t.vividBlue),
                        const SizedBox(height: 16),
                        const Text(
                          'Starting conversation...',
                          style: TextStyle(),
                        ),
                      ],
                    ),
                  );
                }
                if (state is ChatError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: t.textSub),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed:
                                () =>
                                    context
                                        .read<ChatCubit>()
                                        .startConversation(),
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            label: const Text('Retry'),
                            style: FilledButton.styleFrom(
                              backgroundColor: t.vividBlue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (state is ChatLoaded) {
                  if (state.messages.isEmpty) {
                    return ChatEmptyState(
                      onSendExample:
                          () => context.read<ChatCubit>().sendMessage(
                            'I\'m planning a trip to Istanbul. '
                            'What are some must-see places?',
                          ),
                    );
                  }
                  final showTyping = state.isSending;
                  return Column(
                    children: [
                      if (state.error != null)
                        ChatErrorBanner(
                          error: state.error!,
                          onDismiss:
                              () => context.read<ChatCubit>().clearLastError(),
                        ),
                      if (state.retryableError != null && !state.isSending)
                        _ChatRetryBar(
                          message: state.retryableError!,
                          onRetry:
                              () =>
                                  context.read<ChatCubit>().retryLastMessage(),
                          onDismiss:
                              () =>
                                  context
                                      .read<ChatCubit>()
                                      .clearRetryableError(),
                        ),
                      Expanded(
                        child: Stack(
                          children: [
                            ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              itemCount:
                                  state.messages.length + (showTyping ? 1 : 0),
                              itemBuilder: (context, i) {
                                if (showTyping && i == state.messages.length) {
                                  return ChatTypingIndicator(
                                    currentTip: _currentTip,
                                    onNextTip: _advanceTip,
                                  );
                                }
                                final message = state.messages[i];
                                final isAssistant = !message.isUser;
                                final canShowRouteCard =
                                    isAssistant && message.routeData != null;
                                // Has a previous route card? → This one is an edit.
                                final isRouteEdit =
                                    canShowRouteCard &&
                                    state.messages
                                        .take(i)
                                        .any((m) => m.routeData != null);

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ChatMessageBubble(
                                      message: message,
                                      timestampLabel: _formatTime(
                                        message.createdAt,
                                      ),
                                    ),
                                    if (canShowRouteCard)
                                      ChatRouteCard(
                                        route: message.routeData!,
                                        summary: message.routeSummaryMessage,
                                        routeId: message.routeId,
                                        isRouteEdit: isRouteEdit,
                                        onDrawAreaOnMap: () {
                                          Navigator.of(context).pop(
                                            const ChatScreenNavResult(
                                              response: MessageSendResponse(
                                                content: '',
                                              ),
                                              startDrawAreaOnMap: true,
                                            ),
                                          );
                                        },
                                        onShowOnMap: () {
                                          final convId = state.conversationId;
                                          final res = MessageSendResponse(
                                            content: '',
                                            routeData: message.routeData,
                                            routeSummaryMessage:
                                                message.routeSummaryMessage,
                                            routeId: message.routeId,
                                            conversationId: convId,
                                          );
                                          Navigator.of(context).pop(
                                            ChatScreenNavResult(
                                              response: res,
                                              openEventsInitially: false,
                                            ),
                                          );
                                        },
                                        onViewEvents: () {
                                          final convId = state.conversationId;
                                          final res = MessageSendResponse(
                                            content: '',
                                            routeData: message.routeData,
                                            routeSummaryMessage:
                                                message.routeSummaryMessage,
                                            routeId: message.routeId,
                                            conversationId: convId,
                                          );
                                          Navigator.of(context).pop(
                                            ChatScreenNavResult(
                                              response: res,
                                              openEventsInitially: true,
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                );
                              },
                            ),
                            Positioned(
                              right: 16,
                              bottom: 16,
                              child: IgnorePointer(
                                ignoring: !_showJumpToLatest,
                                child: AnimatedOpacity(
                                  opacity: _showJumpToLatest ? 1 : 0,
                                  duration: const Duration(milliseconds: 180),
                                  child: AnimatedScale(
                                    scale: _showJumpToLatest ? 1 : 0.96,
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOut,
                                    child: _JumpToLatestButton(
                                      visible: _showJumpToLatest,
                                      onTap: _scrollToBottom,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              final canSend = state is ChatLoaded && !state.isSending;
              // Check whether any route exists to switch between plan / edit chips
              final hasExistingRoute =
                  state is ChatLoaded &&
                  state.messages.any((m) => m.routeData != null);
              final lastRouteMsg =
                  state is ChatLoaded
                      ? _lastWhere(state.messages, (m) => m.routeData != null)
                      : null;
              final totalDays =
                  lastRouteMsg?.routeData?.totalDays ??
                  lastRouteMsg?.routeData?.days.length ??
                  0;

              final List<ChatQuickAction> quickActions;
              if (hasExistingRoute) {
                quickActions = [
                  if (totalDays >= 1)
                    ChatQuickAction(
                      label: 'Day 1: more museums',
                      onTap: () {
                        if (!canSend) return;
                        _lastSentText = 'Make day 1 more museum-focused';
                        context.read<ChatCubit>().sendMessage(_lastSentText!);
                      },
                    ),
                  if (totalDays >= 2)
                    ChatQuickAction(
                      label: 'Slow down day 2',
                      onTap: () {
                        if (!canSend) return;
                        _lastSentText = 'Slow down day 2';
                        context.read<ChatCubit>().sendMessage(_lastSentText!);
                      },
                    ),
                  if (totalDays >= 3)
                    ChatQuickAction(
                      label: 'Day 3: more dining',
                      onTap: () {
                        if (!canSend) return;
                        _lastSentText = 'Add more dining options to day 3';
                        context.read<ChatCubit>().sendMessage(_lastSentText!);
                      },
                    ),
                  ChatQuickAction(
                    label: 'Slower pace',
                    onTap: () {
                      if (!canSend) return;
                      _lastSentText =
                          'Change the pace to slow for the whole trip';
                      context.read<ChatCubit>().sendMessage(_lastSentText!);
                    },
                  ),
                ];
              } else {
                quickActions = [
                  ChatQuickAction(
                    label: '3-day Istanbul',
                    onTap: () {
                      if (!canSend) return;
                      _lastSentText = 'Plan a 3-day trip to Istanbul.';
                      context.read<ChatCubit>().sendMessage(_lastSentText!);
                    },
                  ),
                  ChatQuickAction(
                    label: '2-day Rome',
                    onTap: () {
                      if (!canSend) return;
                      _lastSentText = 'Plan a 2-day trip to Rome.';
                      context.read<ChatCubit>().sendMessage(_lastSentText!);
                    },
                  ),
                  ChatQuickAction(
                    label: '4-day Antalya',
                    onTap: () {
                      if (!canSend) return;
                      _lastSentText =
                          'Create a 4-day Antalya vacation plan for me.';
                      context.read<ChatCubit>().sendMessage(_lastSentText!);
                    },
                  ),
                ];
              }

              return ChatInputBar(
                controller: _controller,
                enabled: canSend,
                isSending: state is ChatLoaded && state.isSending,
                onStop: () => context.read<ChatCubit>().stopSending(),
                quickActions: quickActions,
                quickActionsLabel:
                    hasExistingRoute ? 'Edit route:' : 'Plan a route:',
                onSend: () {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  _lastSentText = text;
                  context.read<ChatCubit>().sendMessage(text);
                  _controller.clear();
                  setState(() => _hasDraft = false);
                },
                onDraftChanged: (has) {
                  if (_hasDraft == has) return;
                  setState(() => _hasDraft = has);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _JumpToLatestButton extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;

  const _JumpToLatestButton({required this.visible, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: context.mapControlActiveGradientColors,
    );
    final radius = BorderRadius.circular(999);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: visible ? onTap : null,
        borderRadius: radius,
        splashColor: Colors.white.withValues(alpha: 0.14),
        highlightColor: Colors.white.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: gradient,
            border: Border.all(
              color: Colors.white.withValues(alpha: isLight ? 0.22 : 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: t.vividBlue.withValues(alpha: isLight ? 0.20 : 0.26),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.10 : 0.35),
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.arrow_downward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  'Latest',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatRetryBar extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const _ChatRetryBar({
    required this.message,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:
            isLight
                ? const Color(0xFFFFFBEB)
                : cs.surfaceContainerHighest.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isLight
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                  : t.cardBorder.withValues(alpha: 0.70),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: isLight ? const Color(0xFFD97706) : t.vividBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: t.textMain,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: t.vividBlue,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: t.textSub,
            visualDensity: VisualDensity.compact,
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}
