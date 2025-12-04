import 'package:flutter/material.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';

class RegisterEmailSection extends StatelessWidget {
  final TextEditingController emailController;
  final RegExp emailRegex;

  const RegisterEmailSection({
    super.key,
    required this.emailController,
    required this.emailRegex,
  });

  Widget _rule(String text, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: ok ? AppColors.accentMint : AppColors.inputBorder,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: ok ? AppColors.accentMint : AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailValid =
    emailRegex.hasMatch(emailController.text.trim());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: emailController,
          hintText: "Enter your email",
          label: "Email",
          keyboardType: TextInputType.emailAddress,
          validator: (v) => emailRegex.hasMatch(v!.trim())
              ? null
              : "Enter a valid email",
        ),
        const SizedBox(height: 6),
        _rule("Valid email format", emailValid),
      ],
    );
  }
}