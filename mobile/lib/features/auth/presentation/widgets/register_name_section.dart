import 'package:flutter/material.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';

class RegisterNameSection extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController middleNameController;
  final TextEditingController lastNameController;

  final bool hasBothNames;
  final bool preferredFirst;
  final bool preferredMiddle;
  final bool preferredMissing;

  final ValueChanged<bool> onPreferredFirstChanged;
  final ValueChanged<bool> onPreferredMiddleChanged;

  const RegisterNameSection({
    super.key,
    required this.firstNameController,
    required this.middleNameController,
    required this.lastNameController,
    required this.hasBothNames,
    required this.preferredFirst,
    required this.preferredMiddle,
    required this.preferredMissing,
    required this.onPreferredFirstChanged,
    required this.onPreferredMiddleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final first = firstNameController.text.trim();
    final middle = middleNameController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: firstNameController,
          label: "First Name",
          hintText: "Enter your first name",
          validator: (v) => v!.isEmpty ? "Required" : null,
        ),

        const SizedBox(height: 16),

        AppTextField(
          controller: middleNameController,
          label: "Middle Name",
          hintText: "Enter your middle name",
          validator: (v) => v!.isEmpty ? "Required" : null,
        ),

        const SizedBox(height: 16),

        AppTextField(
          controller: lastNameController,
          label: "Last Name",
          hintText: "Enter your last name",
          validator: (v) => v!.isEmpty ? "Required" : null,
        ),

        if (hasBothNames) ...[
          const SizedBox(height: 12),

          const Text(
            "Preferred Name",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: FilterChip(
                  label: Text(first.isEmpty ? "First name" : first),
                  selected: preferredFirst,
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  onSelected: onPreferredFirstChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilterChip(
                  label: Text(middle.isEmpty ? "Middle name" : middle),
                  selected: preferredMiddle,
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  onSelected: onPreferredMiddleChanged,
                ),
              ),
            ],
          ),

          if (preferredMissing)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                "Please choose at least one preferred name",
                style: TextStyle(color: Colors.red, fontSize: 11),
              ),
            ),
        ]
      ],
    );
  }
}