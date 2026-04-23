import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../cubit/chat_cubit.dart';

class ChatEmptyState extends StatelessWidget {
  final VoidCallback onSendExample;

  const ChatEmptyState({super.key, required this.onSendExample});

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: t.vividBlue.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.travel_explore_rounded,
                size: 56,
                color: t.vividBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your AI Travel Assistant',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: t.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask about destinations, activities, or get personalized recommendations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textSub, height: 1.4),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ChatSuggestionChip(
                  label: 'Best places in Istanbul',
                  onTap: onSendExample,
                ),
                ChatSuggestionChip(
                  label: 'Budget-friendly tips',
                  onTap:
                      () => context.read<ChatCubit>().sendMessage(
                        'What are some budget-friendly travel tips?',
                      ),
                ),
                ChatSuggestionChip(
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

class ChatSuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const ChatSuggestionChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor:
          Theme.of(context).brightness == Brightness.light
              ? context.lightGlassFieldFill
              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
      side: BorderSide(color: t.cardBorder.withValues(alpha: 0.9)),
      labelStyle: TextStyle(fontSize: 13, color: t.textMain),
    );
  }
}

