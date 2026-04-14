import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;
  final ValueChanged<bool> onDraftChanged;
  final List<ChatQuickAction> quickActions;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSend,
    required this.onDraftChanged,
    this.quickActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final sendAccent = context.mapControlAccent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? context.lightGlassPanelColor
            : cs.surface,
        border: Border(
          top: BorderSide(color: t.cardBorder.withValues(alpha: 0.75)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.light
                  ? 0.06
                  : 0.30,
            ),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final showQuickActions =
                quickActions.isNotEmpty && value.text.trim().isEmpty;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showQuickActions) ...[
                  _ChatQuickActionsRow(actions: quickActions),
                  const SizedBox(height: 12),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        enabled: enabled,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Ask about travel...',
                          hintStyle: TextStyle(
                            color: t.textSub.withValues(alpha: 0.85),
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.light
                                  ? context.lightGlassFieldFill
                                  : cs.surfaceContainerHighest.withValues(
                                    alpha: 0.55,
                                  ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: t.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: t.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: sendAccent, width: 1.6),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (v) => onDraftChanged(v.trim().isNotEmpty),
                        onSubmitted: (_) => onSend(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _SendButton(
                      enabled: enabled,
                      onTap: onSend,
                      accent: sendAccent,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ChatQuickAction {
  final String label;
  final VoidCallback onTap;

  const ChatQuickAction({required this.label, required this.onTap});
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  final Color accent;

  const _SendButton({
    required this.enabled,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final radius = BorderRadius.circular(18);

    final Color bgDisabled =
        isLight ? Colors.black.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.08);
    final Color iconDisabled =
        isLight ? t.textSub.withValues(alpha: 0.55) : t.textSub.withValues(alpha: 0.65);

    final Color border =
        enabled ? Colors.white.withValues(alpha: isLight ? 0.18 : 0.10) : Colors.transparent;

    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.72,
      duration: const Duration(milliseconds: 140),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? onTap : null,
          splashColor: Colors.white.withValues(alpha: 0.14),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: enabled ? null : bgDisabled,
              gradient:
                  enabled
                      ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent,
                          Color.lerp(accent, Colors.white, isLight ? 0.20 : 0.14) ?? accent,
                        ],
                      )
                      : null,
              border: Border.all(color: border),
              boxShadow:
                  enabled
                      ? [
                        BoxShadow(
                          color: accent.withValues(alpha: isLight ? 0.22 : 0.28),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isLight ? 0.10 : 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ]
                      : null,
            ),
            child: Icon(
              Icons.send_rounded,
              color: enabled ? Colors.white : iconDisabled,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatQuickActionsRow extends StatelessWidget {
  final List<ChatQuickAction> actions;

  const _ChatQuickActionsRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final a = actions[i];
          final bg =
              Theme.of(context).brightness == Brightness.light
                  ? context.lightGlassFieldFill
                  : cs.surfaceContainerHighest.withValues(alpha: 0.35);
          return Material(
            color: bg,
            shape: StadiumBorder(
              side: BorderSide(color: t.cardBorder.withValues(alpha: 0.55)),
            ),
            child: InkWell(
              onTap: a.onTap,
              customBorder: const StadiumBorder(),
              splashColor: accent.withValues(alpha: 0.16),
              highlightColor: accent.withValues(alpha: 0.10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Text(
                  '+ ${a.label}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: t.textMain,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

