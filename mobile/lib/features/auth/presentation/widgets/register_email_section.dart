import 'package:flutter/material.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'package:mobile/core/theme/app_theme.dart';

class RegisterEmailSection extends StatelessWidget {
  final TextEditingController emailController;
  final RegExp emailRegex;

  const RegisterEmailSection({
    super.key,
    required this.emailController,
    required this.emailRegex,
  });

  Widget _rule(BuildContext context, String text, bool ok) {
    final tokens = context.vacanzaTokens;
    final accent = context.authAccent;
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: ok ? accent : tokens.cardBorder,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: ok ? accent : tokens.textSub,
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
        _rule(context, "Valid email format", emailValid),
      ],
    );
  }
}