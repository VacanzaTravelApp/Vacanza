import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';

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
    final canSubmit = formValid && terms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Checkbox(
              value: terms,
              onChanged: onTermsChanged,
              activeColor: AppColors.primary,
              checkColor: Colors.white,
            ),
            Expanded(
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  children: [
                    TextSpan(text: "I agree to the "),
                    TextSpan(
                      text: "Terms & Conditions",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: " and "),
                    TextSpan(
                      text: "Privacy Policy",
                      style: TextStyle(
                        color: AppColors.primary,
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
    )
      ],
    );
  }
}