import 'package:flutter/material.dart';
import '../../../../core/widgets/app_text_field.dart';
import 'package:mobile/core/theme/app_theme.dart';

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
    final tokens = context.vacanzaTokens;

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
              color: tokens.textSub.withValues(alpha: 0.70),
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
                _rule(context, "1+ uppercase", widget.up),
                _rule(context, "1+ lowercase", widget.low),
                _rule(context, "1 number", widget.dig),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rule(context, "1 special char", widget.spe),
                _rule(context, "8+ characters", widget.len8),
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
              color: tokens.textSub.withValues(alpha: 0.70),
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
                color: Colors.red.withValues(alpha: 0.90),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}