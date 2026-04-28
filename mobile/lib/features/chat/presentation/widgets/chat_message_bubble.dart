import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/chat_models.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String? timestampLabel;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.timestampLabel,
  });

  List<InlineSpan> _parseBoldSpans(
    String text, {
    required TextStyle style,
    required TextStyle boldStyle,
  }) {
    if (!text.contains('**')) {
      return [TextSpan(text: text, style: style)];
    }
    final spans = <InlineSpan>[];
    final re = RegExp(r'\*\*([^*]+)\*\*');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start), style: style));
      }
      spans.add(TextSpan(text: m.group(1) ?? '', style: boldStyle));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: style));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 7),
      bottomRight: Radius.circular(isUser ? 7 : 18),
    );

    final assistantOutlineGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        t.accentGradient[0].withValues(alpha: isLight ? 0.55 : 0.50),
        t.accentGradient[1].withValues(alpha: isLight ? 0.30 : 0.28),
        t.accentGradient[2].withValues(alpha: isLight ? 0.45 : 0.40),
      ],
    );

    final bubbleColor =
        isUser
            ? null
            : (isLight
                ? context.lightGlassBubbleFill
                : cs.surfaceContainerHighest.withValues(alpha: 0.40));
    final textColor = isUser ? Colors.white : t.textMain;
    final baseTextStyle = TextStyle(
      fontSize: 14.5,
      height: 1.5,
      color: textColor,
    );
    final boldTextStyle = baseTextStyle.copyWith(fontWeight: FontWeight.w800);

    Future<void> copy() async {
      HapticFeedback.selectionClick();
      await Clipboard.setData(ClipboardData(text: message.content));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: InkWell(
            onLongPress: copy,
            borderRadius: bubbleRadius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: bubbleRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isLight ? 0.06 : 0.14,
                    ),
                    blurRadius: isLight ? 14 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                padding: !isUser ? const EdgeInsets.all(1.2) : EdgeInsets.zero,
                decoration: BoxDecoration(
                  borderRadius: bubbleRadius,
                  gradient: !isUser ? assistantOutlineGradient : null,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    gradient:
                        isUser
                            ? LinearGradient(colors: t.userBubbleGradient)
                            : null,
                    borderRadius: bubbleRadius,
                    border:
                        isUser
                            ? Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            )
                            : Border.all(
                              // Inner hairline to keep the outline crisp on both themes.
                              color: Colors.white.withValues(
                                alpha: isLight ? 0.35 : 0.10,
                              ),
                            ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        isUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: _parseBoldSpans(
                            message.content,
                            style: baseTextStyle,
                            boldStyle: boldTextStyle,
                          ),
                        ),
                      ),
                      if ((timestampLabel ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          timestampLabel!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color:
                                isUser
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : t.textSub.withValues(alpha: 0.75),
                            height: 1,
                          ),
                        ),
                      ],
                    ],
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
