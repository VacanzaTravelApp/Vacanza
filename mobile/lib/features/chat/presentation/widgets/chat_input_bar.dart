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

    // ── Send button colours ──────────────────────────────────────────────────
    final sendHi = Color.lerp(accent, Colors.white, isLight ? 0.20 : 0.14)!;

    // ── Stop button colours — glass surface, coral icon, no heavy gradient ──
    final coral = t.vividCoral;
    final stopBg = isLight
        ? context.lightGlassPanelColor
        : cs.surface.withValues(alpha: 0.92);
    final stopBorder = coral.withValues(alpha: isLight ? 0.45 : 0.38);
    final stopIconColor = coral;

    // ── Disabled colours ────────────────────────────────────────────────────
    final bgDisabled = isLight
        ? context.lightGlassFieldFill
        : cs.surfaceContainerHighest.withValues(alpha: 0.46);
    final iconDisabled = t.textSub.withValues(alpha: isLight ? 0.50 : 0.60);

    final bool isActive = isSending || enabled;

    BoxDecoration buildDecoration() {
      if (isSending) {
        return BoxDecoration(
          borderRadius: radius,
          color: stopBg,
          border: Border.all(color: stopBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: coral.withValues(alpha: isLight ? 0.14 : 0.10),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.06 : 0.28),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        );
      }
      if (enabled) {
        return BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent, sendHi],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: isLight ? 0.18 : 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isLight ? 0.22 : 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.10 : 0.32),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        );
      }
      return BoxDecoration(
        borderRadius: radius,
        color: bgDisabled,
        border: Border.all(
          color: t.cardBorder.withValues(alpha: isLight ? 0.50 : 0.38),
        ),
      );
    }

    return Tooltip(
      message: isSending ? 'Stop generating' : 'Send message',
      child: AnimatedOpacity(
        opacity: isActive ? 1 : 0.65,
        duration: const Duration(milliseconds: 150),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: radius,
            onTap: isSending ? onStop : (enabled ? onTap : null),
            splashColor: (isSending ? coral : accent).withValues(alpha: 0.14),
            highlightColor: (isSending ? coral : accent).withValues(alpha: 0.06),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: size,
              height: size,
              decoration: buildDecoration(),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: isSending
                      ? _StopGlyph(
                          key: const ValueKey('stop'),
                          color: stopIconColor,
                        )
                      : Icon(
                          Icons.send_rounded,
                          key: const ValueKey('send'),
                          color: enabled ? Colors.white : iconDisabled,
                          size: 20,
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
      width: 11,
      height: 11,
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
