import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Optional budget input with $ prefix and USD badge.
class BudgetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? helperText;

  const BudgetField({
    super.key,
    required this.controller,
    this.label = 'Budget (Optional)',
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF999999),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
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
            hintText: 'Max price',
            hintStyle: const TextStyle(
              color: Color(0xFFBBBBBB),
              fontWeight: FontWeight.w400,
              fontSize: 13,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 4),
              child: Text(
                '\$',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFFAAAAAA),
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
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
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
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
              borderSide: const BorderSide(
                color: Color(0xFF0096FF),
                width: 1.5,
              ),
            ),
          ),
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              helperText!,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFFAAAAAA),
              ),
            ),
          ),
      ],
    );
  }

  /// Parses the budget text. Returns null for empty, zero, or invalid values.
  static double? parse(String text) {
    if (text.trim().isEmpty) return null;
    final value = double.tryParse(text.trim());
    if (value == null || value <= 0) return null;
    return value;
  }
}
