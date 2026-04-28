import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/api/chat_api_client.dart';
import '../../data/models/chat_models.dart';

class PastConversationsSheet extends StatefulWidget {
  final ChatApiClient apiClient;
  final void Function(String conversationId) onSelect;
  final String? selectedConversationId;

  const PastConversationsSheet({
    super.key,
    required this.apiClient,
    required this.onSelect,
    this.selectedConversationId,
  });

  @override
  State<PastConversationsSheet> createState() => _PastConversationsSheetState();
}

class _PastConversationsSheetState extends State<PastConversationsSheet> {
  List<ConversationListItem> _conversations = [];
  bool _loading = true;
  String? _error;
  final Map<String, String> _previewByConversationId = {};
  final Set<String> _previewLoading = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _truncate(String s, {int max = 70}) {
    final t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.length <= max) return t;
    return '${t.substring(0, max - 1)}…';
  }

  Future<void> _ensurePreviewLoaded(String conversationId) async {
    if (_previewByConversationId.containsKey(conversationId)) return;
    if (_previewLoading.contains(conversationId)) return;
    _previewLoading.add(conversationId);
    try {
      final msgs = await widget.apiClient.getMessages(
        conversationId,
        limit: 30,
        offset: 0,
      );
      final visible = filterVisibleChatMessages(msgs);
      if (visible.isEmpty) {
        _previewByConversationId[conversationId] = 'No messages yet';
      } else {
        // API ordering can vary; prefer a user message snippet if available.
        final firstUser = visible.cast<ChatMessage?>().firstWhere(
          (m) => m != null && m.role == 'user' && m.content.trim().isNotEmpty,
          orElse: () => null,
        );
        final picked = (firstUser ?? visible.first).content;
        _previewByConversationId[conversationId] = _truncate(picked);
      }
    } catch (_) {
      _previewByConversationId[conversationId] = 'Failed to load preview';
    } finally {
      _previewLoading.remove(conversationId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await widget.apiClient.listConversations();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (!mounted) return;
      setState(() {
        _conversations = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load past conversations. Please try again.';
        _loading = false;
      });
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
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder:
          (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: t.cardBorder.withValues(alpha: 0.85)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: Theme.of(context).brightness == Brightness.light
                        ? 0.12
                        : 0.30,
                  ),
                  blurRadius: 28,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Past Conversations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: t.textMain,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        color: t.textSub,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child:
                      _loading
                          ? Center(
                            child: CircularProgressIndicator(color: accent),
                          )
                          : _error != null
                          ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error!,
                                  style: TextStyle(color: t.textSub),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _load,
                                  child: Text(
                                    'Retry',
                                    style: TextStyle(color: accent),
                                  ),
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
                                  color: t.textSub.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No past conversations',
                                  style: TextStyle(color: t.textSub),
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
                              _ensurePreviewLoaded(c.id);
                              final preview = _previewByConversationId[c.id];
                              final isLoadingPreview =
                                  preview == null && _previewLoading.contains(c.id);
                              final selected = c.id == widget.selectedConversationId;
                              return ListTile(
                                title: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.light
                                            ? Colors.white.withValues(alpha: 0.70)
                                            : cs.surfaceContainerHighest
                                                .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color:
                                          selected
                                              ? accent.withValues(alpha: 0.70)
                                              : t.cardBorder.withValues(
                                                alpha: 0.35,
                                              ),
                                      width: selected ? 1.4 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: accent.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color:
                                                accent.withValues(alpha: 0.30),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.chat_bubble_outline_rounded,
                                          size: 18,
                                          color: accent,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              preview ??
                                                  (isLoadingPreview
                                                      ? 'Loading…'
                                                      : '—'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: t.textMain,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatDate(c.updatedAt),
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: t.textSub.withValues(
                                                  alpha: 0.80,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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

