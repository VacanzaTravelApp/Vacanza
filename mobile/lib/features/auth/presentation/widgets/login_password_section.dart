import 'package:flutter/material.dart';
import 'package:mobile/core/widgets/app_text_field.dart';
import 'package:mobile/core/theme/app_theme.dart';

class LoginPasswordSection extends StatefulWidget {
  final TextEditingController passwordController;

  const LoginPasswordSection({
    super.key,
    required this.passwordController,
  });

  @override
  State<LoginPasswordSection> createState() => _LoginPasswordSectionState();
}

class _LoginPasswordSectionState extends State<LoginPasswordSection> {
  bool visible = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.vacanzaTokens;

    return AppTextField(
      controller: widget.passwordController,
      label: "Password",
      hintText: "Enter your password",
      obscureText: !visible,
      validator: (v) {
        if ((v ?? "").isEmpty) return "Password required";
        return null;
      },
      suffixIcon: IconButton(
        icon: Icon(
          visible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          size: 18,
          color: tokens.textSub.withValues(alpha: 0.70),
        ),
        onPressed: () => setState(() => visible = !visible),
      ),
    );
  }
}