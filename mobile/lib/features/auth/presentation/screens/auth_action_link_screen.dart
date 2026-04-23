import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/animated_background.dart';
import 'package:mobile/core/widgets/vacanza_gradient_button.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/screens/auth_gate.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';

class AuthActionLinkScreen extends StatefulWidget {
  const AuthActionLinkScreen({super.key, required this.uri});

  final Uri uri;

  @override
  State<AuthActionLinkScreen> createState() => _AuthActionLinkScreenState();
}

class _AuthActionLinkScreenState extends State<AuthActionLinkScreen> {
  String? _error;
  String _status = 'loading';

  // Reset-password state
  String? _resetEmail;
  bool _resetSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final qp = widget.uri.queryParameters;
    final mode = qp['mode'];
    final oobCode = qp['oobCode'];
    final authRepo = context.read<AuthRepository>();

    if (oobCode == null || oobCode.isEmpty) {
      setState(() {
        _error = 'Invalid link. Missing code.';
        _status = 'error';
      });
      return;
    }

    try {
      if (mode == 'verifyEmail' || mode == 'action') {
        await fb.FirebaseAuth.instance.applyActionCode(oobCode);

        final user = fb.FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.reload();
        }

        // Try to sync backend session, but don’t block success on it.
        try {
          await authRepo.restoreSession();
        } catch (e) {
          dev.log('[Auth] restoreSession failed after verifyEmail: $e', name: 'Auth');
        }

        if (!mounted) return;
        setState(() => _status = 'verifySuccess');

        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (_) => false,
        );
        return;
      }

      if (mode == 'resetPassword') {
        final email =
            await fb.FirebaseAuth.instance.verifyPasswordResetCode(oobCode);
        if (!mounted) return;
        setState(() {
          _resetEmail = email;
          _status = 'resetPassword';
        });
        return;
      }

      setState(() {
        _error = 'Unsupported action.';
        _status = 'error';
      });
    } on fb.FirebaseAuthException catch (e) {
      dev.log('[Auth] action link error code=${e.code} message=${e.message}', name: 'Auth');
      setState(() {
        _error = e.message ?? 'Link is invalid or expired.';
        _status = 'error';
      });
    } catch (e) {
      dev.log('[Auth] action link error $e', name: 'Auth');
      setState(() {
        _error = 'Link is invalid or expired.';
        _status = 'error';
      });
    }
  }

  Future<void> _submitResetPassword() async {
    final oobCode = widget.uri.queryParameters['oobCode'];
    if (oobCode == null || oobCode.isEmpty) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _resetSubmitting = true);
    try {
      final pass = _newPassword.text;
      await fb.FirebaseAuth.instance.confirmPasswordReset(
        code: oobCode,
        newPassword: pass,
      );

      if (!mounted) return;
      setState(() => _status = 'resetSuccess');
    } on fb.FirebaseAuthException catch (e) {
      dev.log('[Auth] confirmPasswordReset error code=${e.code} message=${e.message}', name: 'Auth');
      if (!mounted) return;
      setState(() {
        _error = e.message ?? 'Could not reset password.';
        _status = 'error';
      });
    } catch (e) {
      dev.log('[Auth] confirmPasswordReset error $e', name: 'Auth');
      if (!mounted) return;
      setState(() {
        _error = 'Could not reset password.';
        _status = 'error';
      });
    } finally {
      if (mounted) setState(() => _resetSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.vacanzaTokens;
    final accent = context.authAccent;
    final titleStyle = AppTextStyles.titleLarge(context).copyWith(
      color: tokens.textMain,
    );
    final body = AppTextStyles.bodyMedium(context).copyWith(
      color: tokens.textSub,
    );

    Widget content;

    if (_status == 'loading') {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: accent,
            ),
          ),
          const SizedBox(height: 16),
          Text('Verifying your link...', style: body),
        ],
      );
    } else if (_status == 'verifySuccess') {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 64, color: accent),
          const SizedBox(height: 16),
          Text('Email verified', style: titleStyle, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Redirecting you to the app...', style: body, textAlign: TextAlign.center),
        ],
      );
    } else if (_status == 'resetPassword') {
      final resetEmail = _resetEmail;
      content = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.lock_reset_rounded, size: 64, color: accent),
            const SizedBox(height: 16),
            Text('Reset your password', style: titleStyle, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            if (resetEmail != null)
              Text(
                'Account: $resetEmail',
                style: body,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _newPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Password is required.';
                      if (value.length < 6) return 'Password must be at least 6 characters.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                    ),
                    validator: (v) {
                      if ((v ?? '') != _newPassword.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: VacanzaGradientButton(
                      label: 'Update password',
                      onPressed: _resetSubmitting ? null : _submitResetPassword,
                      enabled: !_resetSubmitting,
                      loading: _resetSubmitting,
                      minHeight: 50,
                      borderRadius: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _resetSubmitting
                        ? null
                        : () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (_) => false,
                            );
                          },
                    child: const Text(
                      'Back to log in',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_status == 'resetSuccess') {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 64, color: accent),
          const SizedBox(height: 16),
          Text('Password updated', style: titleStyle, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('You can now log in with your new password.', style: body, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: VacanzaGradientButton(
              label: 'Back to log in',
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
              enabled: true,
              loading: false,
              minHeight: 48,
              borderRadius: 14,
            ),
          ),
        ],
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text('Something went wrong', style: titleStyle, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(_error ?? 'Link is invalid or expired.', style: body, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: VacanzaGradientButton(
              label: 'Back to log in',
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
              enabled: true,
              loading: false,
              minHeight: 48,
              borderRadius: 14,
            ),
          ),
        ],
      );
    }

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

