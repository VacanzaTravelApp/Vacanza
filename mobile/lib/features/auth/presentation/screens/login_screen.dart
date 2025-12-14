import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/widgets/animated_background.dart';

import 'package:mobile/features/auth/presentation/widgets/login_form.dart';
import 'package:mobile/features/auth/presentation/screens/register_screen.dart';

// Login BLoC importları
import 'package:mobile/features/auth/presentation/bloc/login_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/login_state.dart';
import 'package:mobile/features/map/presentation/screens/home_map_screen.dart';

// Login başarıya ulaştığında yönleneceğimiz ana ekran (şimdilik mock map)
import 'package:mobile/features/map/presentation/screens/map_screen.dart';

/// Login ekranı UI + BLoC entegrasyonu - VACANZA-83/84
///
/// VACANZA-83:
///   - Tamamen UI + basit validasyon (LoginForm içinde) vardı.
///
/// VACANZA-84:
///   - LoginForm artık LoginBloc ile konuşuyor (LoginSubmitted event).
///   - Bu ekran da BlocListener<LoginBloc, LoginState> ile
///     login success durumunu dinleyip MapScreen'e yönlendiriyor.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  /// Login başarılı olduğunda yapılacak işlemleri tek yerde topladık:
  ///  - Kısa bir snackbar ile kullanıcıya feedback ver
  ///  - Navigation stack'i temizleyerek MapScreen'e git
  void _onLoginSuccess(BuildContext context) {
    // Her ihtimale karşı önce aktif snackbari kapatıyoruz.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Login successful, redirecting to map...'),
        ),
      );

    // Login olduktan sonra geri tuşu ile login ekranına dönmesini
    // istemediğimiz için pushAndRemoveUntil kullanıyoruz.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomeMapScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTextStyles.titleLarge(context).copyWith(
      color: AppColors.textHeading,
    );
    final bodyMedium = AppTextStyles.bodyMedium(context);
    final subtitleColor = AppColors.textMuted;

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
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.accentMint,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.flight_takeoff_rounded,
                            color: Colors.white,
                            size: 28,
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
                                    ..shader = const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.accentMint,
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
                              children: const [
                                TextSpan(text: "Don't have an account? "),
                                TextSpan(
                                  text: 'Sign Up',
                                  style: TextStyle(
                                    color: AppColors.primary,
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