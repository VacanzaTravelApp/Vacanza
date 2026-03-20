import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/sort_criteria.dart';
import '../../cubit/booking_cubit.dart';
import '../../cubit/booking_state.dart';

/// UC1.8-MOB8 — Filters view for budget + sort adjustment.
class BookingFiltersView extends StatefulWidget {
  final BookingFilters filters;

  const BookingFiltersView({super.key, required this.filters});

  @override
  State<BookingFiltersView> createState() => _BookingFiltersViewState();
}

class _BookingFiltersViewState extends State<BookingFiltersView> {
  static const _accent = Color(0xFF0096FF);

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            GestureDetector(
              onTap: () => context.read<BookingCubit>().backToResults(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF5F5F5),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Color(0xFF888888),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          widget.filters.summary,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),

        const SizedBox(height: 24),

        // Budget field
        _sectionLabel(widget.filters.type == BookingType.hotels
            ? 'Budget per night'
            : 'Budget'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _budgetCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: 'No limit',
            hintStyle: const TextStyle(
              color: Color(0xFFBBBBBB),
              fontSize: 13,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 4),
              child: Text(
                '\$',
                style: TextStyle(fontSize: 15, color: Color(0xFFAAAAAA)),
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'USD',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _accent, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Sort chips
        _sectionLabel('Sort by'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _options.map((s) => _sortChip(s)).toList(),
        ),

        const SizedBox(height: 32),

        // Apply button
        GestureDetector(
          onTap: _apply,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0096FF), Color(0xFF00C6FF)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_rounded, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Reset button
        GestureDetector(
          onTap: _reset,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded,
                    size: 16, color: Color(0xFF888888)),
                SizedBox(width: 8),
                Text(
                  'Reset Filters',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF999999),
        ),
      ),
    );
  }

  Widget _sortChip(SortCriteria criteria) {
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
          color: selected ? _accent : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _accent : const Color(0xFFE5E5E5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF555555),
          ),
        ),
      ),
    );
  }
}
