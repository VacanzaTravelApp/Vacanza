import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/api/chat_api_client.dart';
import '../../data/models/chat_models.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';

/// Chatbot screen — AI travel assistant.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ChatCubit(ctx.read<ChatApiClient>())..startConversation(),
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
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              if (state is ChatLoaded && state.messages.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'New conversation',
                  onPressed: () =>
                      context.read<ChatCubit>().newConversation(),
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
                  if (next.error != null && next.error != prev.error) return true;
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
                            onPressed: () =>
                                context.read<ChatCubit>().startConversation(),
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
                      onSendExample: () => context.read<ChatCubit>().sendMessage(
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
                          onDismiss: () =>
                              context.read<ChatCubit>().clearLastError(),
                        ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          itemCount: state.messages.length +
                              (showTyping ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (showTyping && i == state.messages.length) {
                              return const _TypingIndicator();
                            }
                            return _MessageBubble(
                                message: state.messages[i]);
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
              style: const TextStyle(
                color: AppColors.textMuted,
                height: 1.4,
              ),
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
                  onTap: () => context.read<ChatCubit>().sendMessage(
                        'What are some budget-friendly travel tips?',
                      ),
                ),
                _SuggestionChip(
                  label: 'Weekend getaway ideas',
                  onTap: () => context.read<ChatCubit>().sendMessage(
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
                    final offset = (phase < 0.5
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
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red.shade900,
              ),
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
      labelStyle: const TextStyle(
        fontSize: 13,
        color: AppColors.textHeading,
      ),
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
                color: isUser
                    ? AppColors.primary
                    : Colors.white,
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
