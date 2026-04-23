import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/vacanza_gradient_button.dart';

import '../../../data/models/sort_criteria.dart';
import '../../cubit/booking_cubit.dart';
import '../../cubit/booking_state.dart';
import '../search/booking_field_scroll_padding.dart';
import '../search/booking_search_field_styles.dart';

/// UC1.8-MOB8 — Filters view for budget + sort adjustment.
class BookingFiltersView extends StatefulWidget {
  final BookingFilters filters;

  const BookingFiltersView({super.key, required this.filters});

  @override
  State<BookingFiltersView> createState() => _BookingFiltersViewState();
}

class _BookingFiltersViewState extends State<BookingFiltersView> {
  late final TextEditingController _budgetCtrl;
  late SortCriteria? _sort;

  @override
  void initState() {
    super.initState();
    _budgetCtrl = TextEditingController(
      text: widget.filters.currentBudget?.toString() ?? '',
    );
    _sort = widget.filters.currentSort;
  }

  @override
  void dispose() {
    _budgetCtrl.dispose();
    super.dispose();
  }

  List<SortCriteria> get _options =>
      widget.filters.type == BookingType.hotels
          ? SortCriteria.values
          : [SortCriteria.priceAsc, SortCriteria.priceDesc];

  double? get _parsedBudget {
    if (_budgetCtrl.text.trim().isEmpty) return null;
    final v = double.tryParse(_budgetCtrl.text.trim());
    if (v == null || v <= 0) return null;
    return v;
  }

  void _apply() {
    context.read<BookingCubit>().applyFilters(
          budget: _parsedBudget,
          sortBy: _sort,
        );
  }

  void _reset() {
    context.read<BookingCubit>().resetFilters();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final neutralFieldFill = isLight
        ? context.lightGlassFieldFill
        : cs.surfaceContainerHighest.withValues(alpha: 0.65);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Filters',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            GestureDetector(
              onTap: () => context.read<BookingCubit>().backToResults(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: neutralFieldFill,
                  border: Border.all(
                    color: isLight
                        ? accent.withValues(alpha: 0.22)
                        : cs.outline.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          widget.filters.summary,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),

        const SizedBox(height: 24),

        // Budget field
        _sectionLabel(
          context,
          widget.filters.type == BookingType.hotels
              ? 'Budget per night'
              : 'Budget',
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _budgetCtrl,
          scrollPadding: bookingFieldScrollPadding(context),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'No limit',
            hintStyle: TextStyle(
              color: cs.onSurfaceVariant.withValues(alpha: 0.85),
              fontSize: 13,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 4),
              child: Text(
                '\$',
                style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'USD',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: neutralFieldFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Sort chips
        _sectionLabel(context, 'Sort by'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _options.map((s) => _sortChip(context, s)).toList(),
        ),

        const SizedBox(height: 32),

        // Apply button
        VacanzaGradientButton(
          label: 'Apply Filters',
          icon: Icons.check_rounded,
          onPressed: _apply,
          enabled: true,
          minHeight: 52,
          borderRadius: 20,
        ),

        const SizedBox(height: 12),

        // Reset button
        GestureDetector(
          onTap: _reset,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: neutralFieldFill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded,
                    size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Reset Filters',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _sortChip(BuildContext context, SortCriteria criteria) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = context.mapControlAccent;
    final selected = _sort == criteria;
    final label = switch (criteria) {
      SortCriteria.priceAsc => 'Price ↑',
      SortCriteria.priceDesc => 'Price ↓',
      SortCriteria.ratingDesc => 'Rating ↓',
    };

    return GestureDetector(
      onTap: () => setState(() => _sort = criteria),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? accent
              : (isLight
                  ? context.lightGlassFieldFill
                  : cs.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? accent
                : BookingSearchFieldStyles.fieldBorderInactive(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
