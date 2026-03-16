import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/widgets/animated_background.dart';
import 'package:mobile/core/navigation/navigation_service.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:mobile/features/map/presentation/screens/home_map_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _sending = false;
  bool _checking = false;
  bool _initialTriggered = false;

  @override
  void initState() {
    super.initState();
    // İlk açılışta bir kez otomatik verification maili dene (spam engellemek için flag ile korundu).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialTriggered) {
        _initialTriggered = true;
        _resendVerification(silent: true);
      }
    });
  }

  Future<void> _resendVerification({bool silent = false}) async {
    if (!mounted) return;
    setState(() => _sending = true);
    try {
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!silent) {
          _showSnackBar('No active session. Please log in again.');
        }
        return;
      }
      dev.log('[Auth] sendEmailVerification: start', name: 'Auth');
      await user.sendEmailVerification();
      dev.log(
        '[Auth] sendEmailVerification: success email=${user.email}',
        name: 'Auth',
      );
      if (!silent) {
        _showSnackBar('Verification email sent. Please check your inbox.');
      }
    } on fb.FirebaseAuthException catch (e) {
      dev.log(
        '[Auth] sendEmailVerification: error code=${e.code} message=${e.message}',
        name: 'Auth',
      );
      if (!silent) {
        _showSnackBar('Could not send verification email. Please try again.');
      }
    } catch (e) {
      dev.log(
        '[Auth] sendEmailVerification: error (non-Firebase) $e',
        name: 'Auth',
      );
      if (!silent) {
        _showSnackBar('Could not send verification email. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _iVerified() async {
    if (!mounted) return;
    setState(() => _checking = true);
    try {
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('No active session. Please log in again.');
        return;
      }
      await user.reload();
      final refreshed = fb.FirebaseAuth.instance.currentUser;
      dev.log(
        '[Auth] reload -> emailVerified=${refreshed?.emailVerified} email=${refreshed?.email}',
        name: 'Auth',
      );
      if (refreshed == null || !(refreshed.emailVerified)) {
        _showSnackBar('Email not verified yet. Please click the link in your email.');
        return;
      }

      // Force-refresh Firebase ID token and sync backend session (GET /auth/login).
      try {
        await context.read<AuthRepository>().restoreSession();
      } catch (e) {
        // If backend session cannot be synced, keep user informed and let AuthGate
        // handle clean session resolution on next app start.
        _showSnackBar('Session could not be synchronized. Please try again or restart the app.');
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeMapScreen()),
          (_) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout() async {
    if (!mounted) return;
    final repo = context.read<AuthRepository>();
    try {
      await repo.logout();
    } finally {
      NavigationService.resetToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTextStyles.titleLarge(context).copyWith(
      color: AppColors.textHeading,
    );
    final bodyMedium = AppTextStyles.bodyMedium(context);

    final isBusy = _sending || _checking;

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.mark_email_read_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Verify your email',
                        textAlign: TextAlign.center,
                        style: titleStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a verification link to your email address. '
                        'Please verify your email to continue to Vacanza.',
                        textAlign: TextAlign.center,
                        style: bodyMedium.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isBusy ? null : _resendVerification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Resend verification email',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: isBusy ? null : _iVerified,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _checking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(
                                  'I verified',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      TextButton(
                        onPressed: isBusy ? null : _logout,
                        child: const Text(
                          'Logout instead',
                          style: TextStyle(
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
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

