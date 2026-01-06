import 'package:flutter/material.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';

class RegisterPasswordSection extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmController;

  final bool up;
  final bool low;
  final bool dig;
  final bool spe;
  final bool len8;
  final bool mismatch;
  final bool confirmGlow;
  final VoidCallback onPasswordChanged;

  const RegisterPasswordSection({
    super.key,
    required this.passwordController,
    required this.confirmController,
    required this.up,
    required this.low,
    required this.dig,
    required this.spe,
    required this.len8,
    required this.mismatch,
    required this.confirmGlow,
    required this.onPasswordChanged,
  });

  @override
  State<RegisterPasswordSection> createState() =>
      _RegisterPasswordSectionState();
}

class _RegisterPasswordSectionState
    extends State<RegisterPasswordSection> {
  bool _passwordVisible = false;
  bool _confirmVisible = false;

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
    final confirmGlow = widget.confirmGlow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: widget.passwordController,
          hintText: "Create a password",
          label: "Password",
          obscureText: !_passwordVisible,
          onChanged: (_) => widget.onPasswordChanged(),
          suffixIcon: IconButton(
            icon: Icon(
              _passwordVisible
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              size: 18,
              color: AppColors.inputPlaceholder,
            ),
            onPressed: () {
              setState(() => _passwordVisible = !_passwordVisible);
            },
          ),
          validator: (v) =>
          (widget.up &&
              widget.low &&
              widget.dig &&
              widget.spe &&
              widget.len8)
              ? null
              : "Invalid password",
        ),

        const SizedBox(height: 6),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rule("1+ uppercase", widget.up),
                _rule("1+ lowercase", widget.low),
                _rule("1 number", widget.dig),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rule("1 special char", widget.spe),
                _rule("8+ characters", widget.len8),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        AppTextField(
          controller: widget.confirmController,
          hintText: "Confirm your password",
          label: "Confirm Password",
          obscureText: !_confirmVisible,
          errorGlow: confirmGlow,
          suffixIcon: IconButton(
            icon: Icon(
              _confirmVisible
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              size: 18,
              color: AppColors.inputPlaceholder,
            ),
            onPressed: () {
              setState(() => _confirmVisible = !_confirmVisible);
            },
          ),
          validator: (v) =>
          widget.mismatch ? "Passwords do not match" : null,
        ),

        if (confirmGlow)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              "Passwords do not match",
              style: TextStyle(
                color: Colors.red.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}