import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/animated_background.dart';
import 'package:mobile/core/theme/theme_cubit.dart';

import 'package:mobile/features/auth/presentation/widgets/login_form.dart';
import 'package:mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:mobile/features/auth/presentation/screens/auth_gate.dart';

// Login BLoC importları
import 'package:mobile/features/auth/presentation/bloc/login_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/login_state.dart';

/// Login ekranı UI + BLoC entegrasyonu - VACANZA-83/84
///
/// VACANZA-83:
///   - Tamamen UI + basit validasyon (LoginForm içinde) vardı.
///
/// VACANZA-84:
///   - LoginForm artık LoginBloc ile konuşuyor (LoginSubmitted event).
///   - Bu ekran da `BlocListener<LoginBloc, LoginState>` ile
///     login success durumunu dinleyip AuthGate'e yönlendiriyor.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  /// Login başarılı olduğunda: snackbar + stack temizleyerek [AuthGate].
  /// AuthGate `emailVerified` ile VerifyEmail veya haritaya yönlendirir.
  void _onLoginSuccess(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Login successful, redirecting...'),
        ),
      );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.vacanzaTokens;
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final accent = context.authAccent;

    final titleStyle = AppTextStyles.titleLarge(context).copyWith(
      color: tokens.textMain,
    );
    final bodyMedium = AppTextStyles.bodyMedium(context);
    final subtitleColor = tokens.textSub;

    return BlocListener<LoginBloc, LoginState>(
      // Status değişmediği sürece listener tetiklenmesin (gereksiz çalışmayı engeller).
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        // Sadece login başarı durumunda navigation yapıyoruz.
        if (state.isSuccess) {
          _onLoginSuccess(context);
        }
        // Failure durumunda navigation yok; hata mesajı LoginForm içinde inline gösteriliyor.
      },
      // UI: VACANZA-83'teki görünüm aynen korunuyor.
      child: AnimatedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      children: [
                        const SizedBox(height: 55),

                        // ---------- LOGO ----------
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => context.read<ThemeCubit>().toggle(),
                          child: Container(
                            height: 56,
                            width: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: context.authAccentGradientColors,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.22),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              isLight
                                  ? Icons.nightlight_round
                                  : Icons.wb_sunny_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ---------- HEADER ----------
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: titleStyle,
                            children: [
                              const TextSpan(text: 'Welcome Back to '),
                              TextSpan(
                                text: 'Vacanza',
                                style: TextStyle(
                                  foreground: Paint()
                                    ..shader = LinearGradient(
                                      colors: [
                                        accent,
                                        Color.lerp(
                                              accent,
                                              Colors.white,
                                              isLight ? 0.08 : 0.18,
                                            ) ??
                                            accent,
                                      ],
                                    ).createShader(
                                      const Rect.fromLTWH(0, 0, 160, 32),
                                    ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Sign in to continue your journey',
                          style: bodyMedium.copyWith(color: subtitleColor),
                        ),

                        const SizedBox(height: 32),

                        // ---------- LOGIN FORM ----------
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: LoginForm(),
                        ),

                        const SizedBox(height: 24),

                        // ---------- SIGN UP CTA ----------
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Text.rich(
                            TextSpan(
                              style:
                              bodyMedium.copyWith(color: subtitleColor),
                              children: [
                                const TextSpan(text: "Don't have an account? "),
                                TextSpan(
                                  text: 'Sign Up',
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
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