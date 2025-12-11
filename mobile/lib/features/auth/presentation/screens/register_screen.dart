import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/animated_background.dart';
import '../bloc/register_bloc.dart';
import '../bloc/register_state.dart';
import '../widgets/register_form.dart';
import 'login_screen.dart';     // "Already have an account? Log In" için.
import '../../../map/presentation/screens/map_screen.dart'; // ⭐ Yeni import (path'i projene göre ayarla)

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTextStyles.titleLarge(context).copyWith(
      color: AppColors.textHeading,
    );
    final bodyMedium = AppTextStyles.bodyMedium(context);

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,

        /// VACANZA-82 genişletilmiş versiyon:
        ///
        /// RegisterBloc'u dinleyerek:
        ///  - success olduğunda snackbar gösteriyoruz,
        ///  - sonrasında kullanıcıyı ana MapScreen'e yönlendiriyoruz.
        ///
        /// Navigation mantığını UI katmanında tutuyoruz,
        /// BLoC içinden push/pop yapılmıyor (clean architecture).
        body: BlocListener<RegisterBloc, RegisterState>(
          // Sadece status değiştiğinde çalışsın; gereksiz tetiklenmeyi engeller.
          listenWhen: (previous, current) =>
          previous.status != current.status,
          listener: (context, state) {
            if (state.isSuccess) {
              // 1) Kullanıcıya başarı mesajını göster.
              //    Mesaj kısa ve net tutuluyor.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Registration successful! Welcome to Vacanza.'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );

              // 2) Çok küçük bir gecikme ile MapScreen'e yönlendir.
              //    Bu gecikme, snackbar'ın ilk frame'inin çizilmesini garantiler.
              //    pushReplacement kullanmamızın sebebi:
              //      - Kullanıcı back tuşuna bastığında Register'a dönemesin.
              Future.delayed(const Duration(milliseconds: 300), () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MapScreen(),
                  ),
                );
              });
            }

            // Not:
            //  - failure state'te burada navigation yok.
            //  - Hata mesajı zaten RegisterForm içinde
            //    BLoC'tan gelen errorMessage ile gösteriliyor.
          },

          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const SizedBox(height: 24),

                      // Logo
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
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
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

                      const SizedBox(height: 16),

                      // Başlık
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: titleStyle,
                          children: [
                            const TextSpan(text: 'Create Your '),
                            TextSpan(
                              text: 'Vacanza ',
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
                            const TextSpan(text: 'Account'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Start your personalized journey today',
                        textAlign: TextAlign.center,
                        style: bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Register form
                      const Flexible(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: RegisterForm(),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Login CTA: "Already have an account? Log In"
                      GestureDetector(
                        onTap: () {
                          // Burada LoginScreen'e replacement yapıyoruz ki,
                          // kullanıcı Login → Map akışına geçtiğinde
                          // back stack daha temiz olsun.
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            style: bodyMedium.copyWith(
                              color: AppColors.textMuted,
                            ),
                            children: const [
                              TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Log In',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
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