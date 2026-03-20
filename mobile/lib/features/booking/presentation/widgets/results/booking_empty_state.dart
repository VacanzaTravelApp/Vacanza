import 'package:flutter/material.dart';

/// Empty state shown when search returns zero results.
class BookingEmptyState extends StatelessWidget {
  final VoidCallback onModifySearch;

  const BookingEmptyState({super.key, required this.onModifySearch});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Icon(
            Icons.search_off_rounded,
            size: 32,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No results found',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Try adjusting your filters or search criteria.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onModifySearch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Modify Search',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF555555),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
