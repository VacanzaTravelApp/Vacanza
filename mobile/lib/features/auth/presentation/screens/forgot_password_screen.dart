import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/animated_background.dart';
import 'package:mobile/core/widgets/vacanza_gradient_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.prefillEmail});

  final String? prefillEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _submitting = false;

  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');

  @override
  void initState() {
    super.initState();
    if (widget.prefillEmail != null) {
      _email.text = widget.prefillEmail!.trim();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  static String _mapResetError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-email':
        return 'No account found with this email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your connection and try again.';
      default:
        return 'Could not send reset email. Please try again.';
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    try {
      await fb.FirebaseAuth.instance.sendPasswordResetEmail(
        email: _email.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on fb.FirebaseAuthException catch (e) {
      dev.log(
        '[Auth] sendPasswordResetEmail error code=${e.code} message=${e.message}',
        name: 'Auth',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_mapResetError(e.code)),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      dev.log('[Auth] sendPasswordResetEmail error $e', name: 'Auth');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not send reset email. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.vacanzaTokens;
    final accent = context.authAccent;
    final titleStyle = AppTextStyles.titleLarge(
      context,
    ).copyWith(color: tokens.textMain);
    final body = AppTextStyles.bodyMedium(
      context,
    ).copyWith(color: tokens.textSub);

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.lock_reset_rounded, size: 64, color: accent),
                      const SizedBox(height: 16),
                      Text(
                        'Forgot your password?',
                        style: titleStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your email and we’ll send you a reset link.',
                        style: body,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Email is required.';
                            if (!_emailRegex.hasMatch(value))
                              return 'Enter a valid email.';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 50,
                        child: VacanzaGradientButton(
                          label: 'Send reset link',
                          onPressed: _submitting ? null : _submit,
                          enabled: !_submitting,
                          loading: _submitting,
                          minHeight: 50,
                          borderRadius: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
