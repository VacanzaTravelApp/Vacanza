import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/theme/app_theme.dart';

import '../../data/repositories/booking_repository.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import 'filters/booking_filters_view.dart';
import 'results/booking_empty_state.dart';
import 'results/booking_loading_skeleton.dart';
import 'results/booking_results_view.dart';
import 'search/booking_search_form.dart';

/// UC1.8-MOB1/MOB2 — Booking bottom-sheet shell.
///
/// Opens as a modal bottom sheet on top of the map.
/// Routes content based on [BookingCubit] state.
class BookingBottomSheet extends StatelessWidget {
  const BookingBottomSheet({super.key});

  // ── Design tokens (from Figma) ──────────────────────────────────
  static const _sheetRadius = 32.0;
  static const _handleWidth = 48.0;
  static const _handleHeight = 5.0;

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return BlocProvider(
      create: (ctx) => BookingCubit(
        repository: ctx.read<BookingRepository>(),
      ),
      // Lifts the whole sheet above the keyboard so flight/hotel autocomplete
      // dropdowns stay visible (inner scroll padding alone is not enough).
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          final t = context.vacanzaTokens;
          final cs = Theme.of(context).colorScheme;
          return Container(
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.98),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(_sheetRadius),
              ),
              border: Border.all(color: t.cardBorder.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 32,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                // ─── Handle bar ──────────────────────────────────
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Center(
                      child: Container(
                        width: _handleWidth,
                        height: _handleHeight,
                        decoration: BoxDecoration(
                          color: cs.outline.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ),
                ),

                // ─── Header ──────────────────────────────────────
                _SheetHeader(onClose: () => Navigator.of(context).pop()),

                Divider(height: 1, thickness: 0.5, color: cs.outline.withValues(alpha: 0.35)),

                // ─── State-driven body ───────────────────────────
                Expanded(
                  child: BlocBuilder<BookingCubit, BookingState>(
                    builder: (context, state) {
                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => FocusScope.of(context).unfocus(),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          // Bottom inset handled by [AnimatedPadding] above.
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                          child: _buildBody(context, state),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        ),
      ),
    );
  }

  /// Routes to the correct view based on cubit state.
  Widget _buildBody(BuildContext context, BookingState state) {
    return switch (state) {
      BookingSearch() => BookingSearchForm(initialType: state.type),
      BookingLoading() => const BookingLoadingSkeleton(),
      BookingHotelResults() => BookingResultsView(
          results: state.results,
          type: BookingType.hotels,
          summary: state.summary,
        ),
      BookingFlightResults() => BookingResultsView(
          results: state.results,
          type: BookingType.flights,
          summary: state.summary,
        ),
      BookingEmpty() => BookingEmptyState(
          onModifySearch: () => context.read<BookingCubit>().backToSearch(),
        ),
      BookingError() => _ErrorView(
          message: state.message,
          onRetry: () => context.read<BookingCubit>().retry(),
        ),
      BookingFilters() => BookingFiltersView(filters: state),
    };
  }
}

// ─── Private sub-widgets ────────────────────────────────────────────

/// Header row with title + close button.
class _SheetHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _SheetHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BlocBuilder<BookingCubit, BookingState>(
            buildWhen: (prev, next) =>
                prev.runtimeType != next.runtimeType,
            builder: (context, state) {
              final showBack = state is! BookingSearch;
              return Row(
                children: [
                  if (showBack) ...[
                    GestureDetector(
                      onTap: () {
                        final cubit = context.read<BookingCubit>();
                        if (state is BookingFilters) {
                          cubit.backToResults();
                        } else {
                          cubit.backToSearch();
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 24,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    _headerTitle(state),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              );
            },
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                Icons.close,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _headerTitle(BookingState state) {
    return switch (state) {
      BookingSearch() => 'Book',
      BookingLoading() => 'Searching…',
      BookingHotelResults() => 'Hotels',
      BookingFlightResults() => 'Flights',
      BookingEmpty() => 'No Results',
      BookingError() => 'Error',
      BookingFilters() => 'Filters',
    };
  }
}


/// Error view with retry button.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.errorContainer.withValues(alpha: 0.65),
            border: Border.all(color: cs.error.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Center(
                  child: Text(
                    '!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unable to load results',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onErrorContainer.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onRetry,
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
