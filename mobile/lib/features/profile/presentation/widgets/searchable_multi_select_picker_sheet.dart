import 'package:flutter/material.dart';

import 'package:mobile/features/booking/presentation/widgets/search/booking_search_field_styles.dart';

import '../../data/profile_preference_options.dart';
import '../styles/profile_sheet_styles.dart';

/// Config for the searchable multi-select picker bottom sheet.
class SearchableMultiSelectPickerConfig {
  final String label;
  final List<String> options;
  final List<String> initialSelected;
  final bool searchable;
  final Color accentColor;
  final void Function(List<String> selected) onDone;

  const SearchableMultiSelectPickerConfig({
    required this.label,
    required this.options,
    required this.initialSelected,
    this.searchable = true,
    required this.accentColor,
    required this.onDone,
  });
}

/// Bottom sheet: multi-select with optional search, checkboxes, and Done.
/// Use via [showSearchableMultiSelectPicker].
/// Returns a [Future] that completes when the sheet is closed.
Future<void> showSearchableMultiSelectPicker(
  BuildContext context, {
  required SearchableMultiSelectPickerConfig config,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _SearchableMultiSelectPickerSheet(config: config),
  ).then((_) {});
}

class _SearchableMultiSelectPickerSheet extends StatefulWidget {
  final SearchableMultiSelectPickerConfig config;

  const _SearchableMultiSelectPickerSheet({required this.config});

  @override
  State<_SearchableMultiSelectPickerSheet> createState() =>
      _SearchableMultiSelectPickerSheetState();
}

class _SearchableMultiSelectPickerSheetState
    extends State<_SearchableMultiSelectPickerSheet> {
  late List<String> _selected;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.config.initialSelected);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredOptions {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.config.options;
    return widget.config.options
        .where((o) => o.toLowerCase().contains(query))
        .toList();
  }

  void _toggle(String option) {
    setState(() {
      if (_selected.contains(option)) {
        _selected.remove(option);
      } else {
        _selected.add(option);
      }
    });
  }

  void _done() {
    widget.config.onDone(List<String>.from(_selected));
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.config.accentColor;
    final options = _filteredOptions;
    final cs = Theme.of(context).colorScheme;

    return ProfileSheetStyles.sheetPanel(
      context: context,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.config.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      '${_selected.length} selected',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (widget.config.searchable) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Search…',
                      hintStyle: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                      ),
                      prefixIcon: Icon(Icons.search, size: 20, color: cs.onSurfaceVariant),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close, size: 20, color: cs.onSurfaceVariant),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: BookingSearchFieldStyles.fieldFill(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: BookingSearchFieldStyles.fieldBorderInactive(context),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: BookingSearchFieldStyles.fieldBorderInactive(context),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: accent,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(
            height: 1,
            color: BookingSearchFieldStyles.fieldBorderInactive(context),
          ),
          // List
          Flexible(
            child: options.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No results',
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final active = _selected.contains(option);
                      return InkWell(
                        onTap: () => _toggle(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: active ? accent : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: active
                                        ? Colors.transparent
                                        : BookingSearchFieldStyles.fieldBorderInactive(
                                            context,
                                          ),
                                    width: 2,
                                  ),
                                ),
                                child: active
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  formatOptionLabel(option),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          // Done
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _done,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text('Done (${_selected.length} selected)'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
