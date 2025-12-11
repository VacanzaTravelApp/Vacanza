import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/widgets/animated_background.dart';

import 'package:mobile/features/auth/presentation/widgets/login_form.dart';
import 'package:mobile/features/auth/presentation/screens/register_screen.dart';

/// Login ekranı UI - VACANZA-83
/// Bu ekranda yalnızca UI vardır.
/// Firebase + backend login VACANZA-84 ile gelecektir.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTextStyles.titleLarge(context).copyWith(
      color: AppColors.textHeading,
    );
    final bodyMedium = AppTextStyles.bodyMedium(context);
    final subtitleColor = AppColors.textMuted;

    return AnimatedBackground(
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
                            style: bodyMedium.copyWith(color: subtitleColor),
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
    );
  }
}