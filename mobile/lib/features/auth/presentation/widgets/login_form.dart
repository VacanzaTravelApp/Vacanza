import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/gradient_button.dart';

import 'package:mobile/features/auth/presentation/widgets/login_email_section.dart';
import 'package:mobile/features/auth/presentation/widgets/login_password_section.dart';

/// Login formunun UI yapısı.
/// - Email
/// - Password
/// - Forgot Password
/// - Log In butonu
///
/// VACANZA-83 → sadece UI + validasyon
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _formValid = false;

  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');

  @override
  void initState() {
    super.initState();
    _email.addListener(_update);
    _password.addListener(_update);
  }

  void _update() {
    final emailValid = _emailRegex.hasMatch(_email.text.trim());
    final passValid = _password.text.isNotEmpty;

    setState(() {
      _formValid = emailValid && passValid;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _loading = false);

    // VACANZA-84'te buraya Firebase login gelecek
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // EMAIL
          LoginEmailSection(
            emailController: _email,
            emailRegex: _emailRegex,
          ),

          const SizedBox(height: 16),

          // PASSWORD
          LoginPasswordSection(passwordController: _password),

          const SizedBox(height: 10),

          // FORGOT PASSWORD
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // LOGIN BUTTON
          GradientButton(
            text: "Log In",
            loading: _loading,
            active: _formValid,
            enabled: _formValid,
            onPressed: _formValid ? _submit : null,
          ),
        ],
      ),
    );
  }
}