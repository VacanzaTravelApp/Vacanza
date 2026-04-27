import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback? onStop;
  final ValueChanged<bool> onDraftChanged;
  final List<ChatQuickAction> quickActions;
  final String? quickActionsLabel;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSend,
    required this.onDraftChanged,
    this.isSending = false,
    this.onStop,
    this.quickActions = const [],
    this.quickActionsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final sendAccent = context.mapControlAccent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.light
                ? context.lightGlassPanelColor
                : cs.surface,
        border: Border(
          top: BorderSide(color: t.cardBorder.withValues(alpha: 0.75)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha:
                  Theme.of(context).brightness == Brightness.light
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
                  _ChatQuickActionsRow(
                    actions: quickActions,
                    label: quickActionsLabel,
                  ),
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
                            borderSide: BorderSide(
                              color: sendAccent,
                              width: 1.6,
                            ),
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
                      isSending: isSending,
                      onTap: onSend,
                      onStop: onStop,
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
  final bool isSending;
  final VoidCallback onTap;
  final VoidCallback? onStop;
  final Color accent;

  const _SendButton({
    required this.enabled,
    required this.isSending,
    required this.onTap,
    required this.accent,
    this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    const size = 46.0;
    final radius = BorderRadius.circular(17);

    final bool isActive = isSending || enabled;
    final stopAccent = t.vividCoral;
    final stopAccentHi =
        Color.lerp(
          stopAccent,
          isLight ? t.vividAmber : Colors.white,
          isLight ? 0.18 : 0.12,
        )!;
    final sendAccentHi =
        Color.lerp(accent, Colors.white, isLight ? 0.20 : 0.14)!;

    final Color bgDisabled =
        isLight
            ? context.lightGlassFieldFill
            : cs.surfaceContainerHighest.withValues(alpha: 0.46);
    final Color iconDisabled =
        isLight
            ? t.textSub.withValues(alpha: 0.55)
            : t.textSub.withValues(alpha: 0.65);
    final Color border =
        isActive
            ? Colors.white.withValues(alpha: isLight ? 0.18 : 0.10)
            : t.cardBorder.withValues(alpha: isLight ? 0.55 : 0.42);

    final List<Color>? gradientColors =
        isSending
            ? [stopAccent, stopAccentHi]
            : (enabled ? [accent, sendAccentHi] : null);

    final List<BoxShadow>? shadows =
        isActive
            ? [
              BoxShadow(
                color: (isSending ? stopAccent : accent).withValues(
                  alpha: isLight ? 0.22 : 0.28,
                ),
                blurRadius: isSending ? 18 : 16,
                offset: const Offset(0, 7),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.10 : 0.32),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ]
            : null;

    return Tooltip(
      message: isSending ? 'Stop generating' : 'Send message',
      child: Semantics(
        button: true,
        enabled: isActive,
        label: isSending ? 'Stop generating' : 'Send message',
        child: AnimatedScale(
          scale: isSending ? 1.02 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: isActive ? 1 : 0.72,
            duration: const Duration(milliseconds: 140),
            child: Material(
              color: Colors.transparent,
              borderRadius: radius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: radius,
                onTap: isSending ? onStop : (enabled ? onTap : null),
                splashColor: Colors.white.withValues(alpha: 0.16),
                highlightColor: Colors.white.withValues(alpha: 0.07),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    color: isActive ? null : bgDisabled,
                    gradient:
                        gradientColors != null
                            ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors,
                            )
                            : null,
                    border: Border.all(color: border),
                    boxShadow: shadows,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder:
                          (child, animation) => ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                      child:
                          isSending
                              ? _StopGlyph(
                                key: const ValueKey('stop'),
                                color: Colors.white,
                              )
                              : Icon(
                                Icons.send_rounded,
                                key: const ValueKey('send'),
                                color: isActive ? Colors.white : iconDisabled,
                                size: 20,
                              ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StopGlyph extends StatelessWidget {
  final Color color;

  const _StopGlyph({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _ChatQuickActionsRow extends StatelessWidget {
  final List<ChatQuickAction> actions;
  final String? label;

  const _ChatQuickActionsRow({required this.actions, this.label});

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    final totalItems = actions.length + (label != null ? 1 : 0);
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: totalItems,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          // First item is the label when provided
          if (label != null && i == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Text(
                  label!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: t.textSub.withValues(alpha: 0.65),
                  ),
                ),
              ),
            );
          }
          final actionIndex = label != null ? i - 1 : i;
          final a = actions[actionIndex];
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
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
