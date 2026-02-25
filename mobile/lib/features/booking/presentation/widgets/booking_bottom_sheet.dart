import 'package:flutter/material.dart';

/// UC1.8-MOB1 — Booking bottom-sheet shell.
///
/// Opens as a modal bottom sheet on top of the map.
/// States (Search / Results / Filters) will be wired in MOB2–MOB8.
class BookingBottomSheet extends StatelessWidget {
  const BookingBottomSheet({super.key});

  // ── Design tokens (from Figma) ──────────────────────────────────
  static const _sheetRadius = 32.0;
  static const _handleWidth = 48.0;
  static const _handleHeight = 5.0;
  static const _accent = Color(0xFF0096FF);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
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
              // ─── Handle bar ───────────────────────────────────
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

              // ─── Header row ───────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Book',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    _CloseButton(
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 0.5),

              // ─── Body (placeholder — wired in MOB6/7/8) ──────
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      // Placeholder icon + text
                      const SizedBox(height: 40),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.luggage_rounded,
                          size: 32,
                          color: _accent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Search Hotels & Flights',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find the best deals for your trip.\nSearch form will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Circular close button matching Figma: gray bg, X icon.
class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}
