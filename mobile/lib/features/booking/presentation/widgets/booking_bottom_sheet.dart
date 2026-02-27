import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/booking_repository.dart';
import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
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
    return BlocProvider(
      create: (ctx) => BookingCubit(
        repository: ctx.read<BookingRepository>(),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(_sheetRadius),
              ),
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
                          color: Colors.grey.shade300.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ),
                ),

                // ─── Header ──────────────────────────────────────
                _SheetHeader(onClose: () => Navigator.of(context).pop()),

                const Divider(height: 1, thickness: 0.5),

                // ─── State-driven body ───────────────────────────
                Expanded(
                  child: BlocBuilder<BookingCubit, BookingState>(
                    builder: (context, state) {
                      return SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: _buildBody(context, state),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Routes to the correct view based on cubit state.
  ///
  /// MOB6/7/8 will replace these placeholders with real widgets.
  Widget _buildBody(BuildContext context, BookingState state) {
    return switch (state) {
      BookingSearch() => BookingSearchForm(initialType: state.type),
      BookingLoading() => const _LoadingView(),
      BookingHotelResults() => _PlaceholderView(
          icon: Icons.hotel_rounded,
          title: '${state.results.length} Hotels Found',
          subtitle: 'Results list will be wired in MOB7.',
          state: state,
        ),
      BookingFlightResults() => _PlaceholderView(
          icon: Icons.flight_rounded,
          title: '${state.results.length} Flights Found',
          subtitle: 'Results list will be wired in MOB7.',
          state: state,
        ),
      BookingEmpty() => _PlaceholderView(
          icon: Icons.search_off_rounded,
          title: 'No Results',
          subtitle: state.summary,
          state: state,
        ),
      BookingError() => _ErrorView(
          message: state.message,
          onRetry: () => context.read<BookingCubit>().retry(),
        ),
      BookingFilters() => _PlaceholderView(
          icon: Icons.tune_rounded,
          title: 'Filters',
          subtitle: 'Filters view will be wired in MOB8.',
          state: state,
        ),
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
                          color: const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          size: 24,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    _headerTitle(state),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
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
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(
                Icons.close,
                size: 20,
                color: Colors.grey.shade500,
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

/// Placeholder view for states not yet wired (MOB6/7/8).
class _PlaceholderView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final BookingState state;

  const _PlaceholderView({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.state,
  });

  static const _accent = Color(0xFF0096FF);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 32, color: _accent),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Loading placeholder.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        const CircularProgressIndicator(
          color: Color(0xFF0096FF),
          strokeWidth: 3,
        ),
        const SizedBox(height: 20),
        Text(
          'Searching…',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

/// Error view with retry button.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            border: Border.all(color: const Color(0xFFFECACA)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Center(
                  child: Text(
                    '!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unable to load results',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7F1D1D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onRetry,
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626),
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
