import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/animated_background.dart';
import 'package:mobile/core/widgets/vacanza_gradient_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final user = fb.FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active session. Please log in again.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final credential = fb.EmailAuthProvider.credential(
        email: email,
        password: _currentPassword.text,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPassword.text);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Password updated successfully.')),
        );
      Navigator.of(context).pop();
    } on fb.FirebaseAuthException catch (e) {
      dev.log('[Auth] change password error code=${e.code} message=${e.message}', name: 'Auth');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(e.message ?? 'Could not update password.')),
        );
    } catch (e) {
      dev.log('[Auth] change password error $e', name: 'Auth');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not update password.')),
        );
    } finally {
      if (mounted) setState(() => _submitting = false);
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

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
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
                      Icon(Icons.lock_rounded, size: 64, color: accent),
                      const SizedBox(height: 16),
                      Text(
                        'Change password',
                        style: titleStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'For security, please enter your current password.',
                        style: body,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _currentPassword,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Current password',
                              ),
                              validator: (v) {
                                if ((v ?? '').isEmpty) return 'Current password is required.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _newPassword,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'New password',
                              ),
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty) return 'New password is required.';
                                if (value.length < 6) return 'Password must be at least 6 characters.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirmPassword,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Confirm new password',
                              ),
                              validator: (v) {
                                if ((v ?? '') != _newPassword.text) return 'Passwords do not match.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 50,
                              child: VacanzaGradientButton(
                                label: 'Update password',
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

