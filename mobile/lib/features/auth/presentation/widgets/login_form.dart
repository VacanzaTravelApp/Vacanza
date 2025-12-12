import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/gradient_button.dart';

import 'package:mobile/features/auth/presentation/widgets/login_email_section.dart';
import 'package:mobile/features/auth/presentation/widgets/login_password_section.dart';

import 'package:mobile/features/auth/presentation/bloc/login_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/login_event.dart';
import 'package:mobile/features/auth/presentation/bloc/login_state.dart';

/// Login form widget that manages:
/// - UI (email + password fields, forgot password link, button)
/// - basic validation (email format + password not empty)
/// - BLoC integration (dispatch LoginSubmitted, read loading/error from state)
///
/// IMPORTANT:
/// - No artificial delay.
/// - Loading spinner is driven by LoginState.status (submitting).
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _password = TextEditingController();

  /// Local validation flag (only for enabling/disabling the button).
  bool _formValid = false;

  /// Email regex used both in real-time rules and validator.
  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');

  @override
  void initState() {
    super.initState();
    _email.addListener(_update);
    _password.addListener(_update);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Re-compute whether the form is eligible to submit.
  void _update() {
    final emailValid = _emailRegex.hasMatch(_email.text.trim());
    final passValid = _password.text.isNotEmpty;

    setState(() {
      _formValid = emailValid && passValid;
    });
  }

  /// Submit handler:
  /// - runs validators
  /// - closes keyboard
  /// - dispatches LoginSubmitted to LoginBloc
  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    context.read<LoginBloc>().add(
      LoginSubmitted(
        email: _email.text.trim(),
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        final isSubmitting = state.isSubmitting;

        /// Button is enabled when:
        /// - local form is valid
        /// - not currently submitting
        final canSubmit = _formValid && !isSubmitting;

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
                  onPressed: () {
                    // TODO: Implement forgot password flow later.
                  },
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

              // Inline error (from BLoC / repository)
              if (state.isFailure && state.errorMessage != null) ...[
                Text(
                  state.errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // LOGIN BUTTON
              GradientButton(
                text: "Log In",
                loading: isSubmitting,
                active: canSubmit,
                enabled: canSubmit,
                onPressed: canSubmit ? () => _submit(context) : null,
              ),
            ],
          ),
        );
      },
    );
  }
}