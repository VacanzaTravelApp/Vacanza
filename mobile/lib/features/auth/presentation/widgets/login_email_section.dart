import 'package:flutter/material.dart';
import 'package:mobile/core/widgets/app_text_field.dart';
import 'package:mobile/core/theme/app_colors.dart';

class LoginEmailSection extends StatelessWidget {
  final TextEditingController emailController;
  final RegExp emailRegex;

  const LoginEmailSection({
    super.key,
    required this.emailController,
    required this.emailRegex,
  });

  @override
  Widget build(BuildContext context) {
    final email = emailController.text.trim();
    final ok = emailRegex.hasMatch(email);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: emailController,
          label: "Email",
          hintText: "Enter your email",
          validator: (v) {
            final val = v?.trim() ?? "";
            if (val.isEmpty) return "Email is required";
            if (!emailRegex.hasMatch(val)) return "Invalid email";
            return null;
          },
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.radio_button_unchecked,
              color: ok ? AppColors.accentMint : AppColors.inputBorder,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              "Valid email format",
              style: TextStyle(
                fontSize: 12,
                color: ok ? AppColors.accentMint : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}