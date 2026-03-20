import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable flight text field styled like other inputs.
class IataTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final IconData icon;

  const IataTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.placeholder,
    this.icon = Icons.search_rounded,
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
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              color: Color(0xFFBBBBBB),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFFAAAAAA)),
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
      ],
    );
  }
}
