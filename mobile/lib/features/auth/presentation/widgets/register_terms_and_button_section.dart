import 'package:flutter/material.dart';
import '../../../../core/widgets/gradient_button.dart';
import 'package:mobile/core/theme/app_theme.dart';

class RegisterTermsAndButtonSection extends StatelessWidget {
  final bool terms;
  final bool loading;
  final bool formValid;
  final ValueChanged<bool?> onTermsChanged;
  final Future<void> Function() onSubmit;

  const RegisterTermsAndButtonSection({
    super.key,
    required this.terms,
    required this.loading,
    required this.formValid,
    required this.onTermsChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.vacanzaTokens;
    final accent = context.authAccent;
    final canSubmit = formValid && terms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Checkbox(
              value: terms,
              onChanged: onTermsChanged,
              activeColor: accent,
              checkColor: Colors.white,
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: tokens.textSub,
                  ),
                  children: [
                    const TextSpan(text: "I agree to the "),
                    TextSpan(
                      text: "Terms & Conditions",
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: " and "),
                    TextSpan(
                      text: "Privacy Policy",
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        GradientButton(
          text: "Sign Up",
          loading: loading,
          active: canSubmit,
          enabled: canSubmit,
          onPressed: canSubmit ? onSubmit : null,
        ),
      ],
    );
  }
}