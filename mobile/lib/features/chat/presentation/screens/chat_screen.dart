import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/ai/data/api/ai_route_api_client.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/api/chat_api_client.dart';
import '../../data/models/chat_models.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';

/// Result when closing the chat after a route action (maps to web navigation).
class ChatScreenNavResult {
  final MessageSendResponse response;
  final bool openEventsInitially;

  const ChatScreenNavResult({
    required this.response,
    this.openEventsInitially = false,
  });
}

/// Chatbot screen — AI travel assistant.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (ctx) => ChatCubit(
            ctx.read<ChatApiClient>(),
            ctx.read<AiRouteApiClient>(),
          )..startConversation(),
      child: const _ChatScreenView(),
    );
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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
      builder:
          (ctx) => _PastConversationsSheet(
            apiClient: ctx.read<ChatApiClient>(),
            onSelect: (conversationId) {
              Navigator.of(ctx).pop();
              context.read<ChatCubit>().loadConversation(conversationId);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgFrom,
      appBar: AppBar(
        title: const Text(
          'Travel Assistant',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textHeading,
          ),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.textHeading,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Past conversations',
            onPressed: () => _showPastConversations(context),
            color: AppColors.textHeading,
          ),
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              if (state is ChatLoaded && state.messages.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'New conversation',
                  onPressed: () => context.read<ChatCubit>().newConversation(),
                  color: AppColors.primary,
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
                  if (next.error != null && next.error != prev.error)
                    return true;
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
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 16),
                        Text(
                          'Starting conversation...',
                          style: TextStyle(color: AppColors.textMuted),
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
                            style: const TextStyle(color: AppColors.textMuted),
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
                              backgroundColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (state is ChatLoaded) {
                  if (state.messages.isEmpty) {
                    return _EmptyState(
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
                        _ErrorBanner(
                          error: state.error!,
                          onDismiss:
                              () => context.read<ChatCubit>().clearLastError(),
                        ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          itemCount:
                              state.messages.length + (showTyping ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (showTyping && i == state.messages.length) {
                              return const _TypingIndicator();
                            }
                            final message = state.messages[i];
                            final isAssistant = !message.isUser;
                            final canShowRouteCard =
                                isAssistant && message.routeData != null;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _MessageBubble(message: message),
                                if (canShowRouteCard)
                                  _RouteCard(
                                    route: message.routeData!,
                                    summary: message.routeSummaryMessage,
                                    routeId: message.routeId,
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
              return _ChatInput(
                controller: _controller,
                enabled: canSend,
                onSend: () {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  context.read<ChatCubit>().sendMessage(text);
                  _controller.clear();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onSendExample;

  const _EmptyState({required this.onSendExample});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.travel_explore_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your AI Travel Assistant',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask about destinations, activities, or get personalized recommendations.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _SuggestionChip(
                  label: 'Best places in Istanbul',
                  onTap: () => onSendExample(),
                ),
                _SuggestionChip(
                  label: 'Budget-friendly tips',
                  onTap:
                      () => context.read<ChatCubit>().sendMessage(
                        'What are some budget-friendly travel tips?',
                      ),
                ),
                _SuggestionChip(
                  label: 'Weekend getaway ideas',
                  onTap:
                      () => context.read<ChatCubit>().sendMessage(
                        'Suggest a weekend getaway from my city.',
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final phase = (_controller.value + i * 0.2) % 1.0;
                    final offset =
                        (phase < 0.5
                            ? Curves.easeOut.transform(phase * 2)
                            : Curves.easeIn.transform(2 - phase * 2)) *
                        5;
                    return Padding(
                      padding: EdgeInsets.only(left: i > 0 ? 5 : 0),
                      child: Transform.translate(
                        offset: Offset(0, -offset),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.error, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade700,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: TextStyle(fontSize: 13, color: Colors.red.shade900),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onDismiss,
            color: Colors.red.shade700,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class _PastConversationsSheet extends StatefulWidget {
  final ChatApiClient apiClient;
  final void Function(String conversationId) onSelect;

  const _PastConversationsSheet({
    required this.apiClient,
    required this.onSelect,
  });

  @override
  State<_PastConversationsSheet> createState() =>
      _PastConversationsSheetState();
}

class _PastConversationsSheetState extends State<_PastConversationsSheet> {
  List<ConversationListItem> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.apiClient.listConversations();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (mounted) {
        setState(() {
          _conversations = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder:
          (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'Past Conversations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHeading,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child:
                      _loading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                          : _error != null
                          ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _load,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                          : _conversations.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 48,
                                  color: AppColors.textMuted.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No past conversations',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _conversations.length,
                            itemBuilder: (context, i) {
                              final c = _conversations[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  child: const Icon(
                                    Icons.chat_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  'Conversation',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textHeading,
                                  ),
                                ),
                                subtitle: Text(
                                  _formatDate(c.updatedAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                onTap: () => widget.onSelect(c.id),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: BorderSide(color: AppColors.inputBorder),
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.textHeading),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: isUser ? Colors.white : AppColors.textHeading,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.accentMint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatefulWidget {
  final ChatRouteData route;
  final String? summary;
  final String? routeId;
  final VoidCallback onShowOnMap;
  final VoidCallback onViewEvents;

  const _RouteCard({
    required this.route,
    required this.summary,
    required this.routeId,
    required this.onShowOnMap,
    required this.onViewEvents,
  });

  @override
  State<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<_RouteCard> {
  bool _loadingPrices = false;
  String? _pricingError;
  List<WaypointPricingRow>? _pricingRows;

  Future<void> _loadPrices() async {
    final id = widget.routeId;
    if (id == null) return;
    setState(() {
      _loadingPrices = true;
      _pricingError = null;
    });
    try {
      final rows = await context.read<AiRouteApiClient>().getRoutePricing(id);
      if (!mounted) return;
      setState(() {
        _loadingPrices = false;
        _pricingRows = rows;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPrices = false;
        _pricingError = 'Could not load prices.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final days = route.totalDays > 0 ? route.totalDays : route.days.length;
    final stops = route.days.fold<int>(0, (acc, d) => acc + d.waypoints.length);

    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 56, bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              route.title?.trim().isNotEmpty == true
                  ? route.title!
                  : 'AI Route',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${route.destination ?? 'Destination'} • $days day${days == 1 ? '' : 's'} • $stops stop${stops == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
            if (route.tripStartDate != null &&
                route.tripStartDate!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Trip starts: ${route.tripStartDate}',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            if (widget.summary != null &&
                widget.summary!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                widget.summary!,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: AppColors.textHeading,
                ),
              ),
            ],
            if (route.weatherForecast.isNotEmpty) ...[
              const SizedBox(height: 10),
              _RouteWeatherStrip(route: route),
            ],
            if (widget.routeId != null) ...[
              const SizedBox(height: 10),
              Text(
                'Events',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeading.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 10),
              _ChatEventsPreview(routeId: widget.routeId!),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.onViewEvents,
                  icon: const Icon(Icons.event_rounded, size: 18),
                  label: const Text('View all events'),
                ),
              ),
            ],
            if (widget.routeId != null) ...[
              const SizedBox(height: 4),
              Text(
                'Museum & tour prices',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeading.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Viator — products matched to your route stops (saved routes only).',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _loadingPrices ? null : _loadPrices,
                  child:
                      _loadingPrices
                          ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Show prices'),
                ),
              ),
              if (_pricingError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _pricingError!,
                    style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                  ),
                ),
              if (_pricingRows != null && _pricingRows!.isNotEmpty) ...[
                const SizedBox(height: 8),
                ..._pricingRows!
                    .take(4)
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          r.found && r.minPriceUsd != null
                              ? '${r.waypointName}: from \$${r.minPriceUsd!.toStringAsFixed(0)} ${r.currency}'
                              : '${r.waypointName}: ${r.message ?? '—'}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.25,
                            color: AppColors.textHeading,
                          ),
                        ),
                      ),
                    ),
              ],
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onShowOnMap,
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('Show on map'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteWeatherStrip extends StatelessWidget {
  final ChatRouteData route;

  const _RouteWeatherStrip({required this.route});

  String _shortDate(String? d) {
    if (d == null || d.length < 10) return d ?? '';
    return d.substring(5).replaceFirst('-', '/');
  }

  @override
  Widget build(BuildContext context) {
    final wf = route.weatherForecast;
    if (wf.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: wf.length.clamp(0, 5),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final row = wf[i];
          final tMax = row.tempMaxCelsius;
          final tMin = row.tempMinCelsius;
          final precip = row.precipitationProbabilityMaxPercent;
          return Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _shortDate(row.date),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                if (tMax != null && tMin != null)
                  Text(
                    '${tMax.round()}° / ${tMin.round()}°',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                if (precip != null)
                  Text(
                    'Rain ${precip.round()}%',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChatEventsPreview extends StatelessWidget {
  final String routeId;

  const _ChatEventsPreview({required this.routeId});

  @override
  Widget build(BuildContext context) {
    final api = context.read<AiRouteApiClient>();
    return FutureBuilder<Map<String, dynamic>>(
      future: api.getEventRecommendations(routeId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final data = snap.data;
        if (data == null) {
          return const Text(
            'No events preview.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          );
        }
        final list = data['events'];
        final events = list is List ? list : const [];
        final has = data['hasRecommendations'] == true;
        if (!has || events.isEmpty) {
          return const Text(
            'No events found for this window.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final e in events.take(2))
              if (e is Map)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${e['name'] ?? 'Event'} • ${e['startTime'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.25,
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Ask about travel...',
                  hintStyle: const TextStyle(color: AppColors.inputPlaceholder),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: enabled ? AppColors.primary : AppColors.buttonDisabled,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: enabled ? onSend : null,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
