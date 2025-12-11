import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/animated_background.dart';

import '../bloc/register_bloc.dart';
import '../bloc/register_state.dart';
import '../bloc/register_event.dart';
import '../widgets/register_form.dart';
import 'package:mobile/features/map/presentation/screens/map_screen.dart'; // path'i projene göre ayarla
import 'login_screen.dart';

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

        /// Burada RegisterBloc'i dinleyip:
        ///  - success olduğunda snackbar + MapScreen navigation
        ///  - success sonrası RegisterReset event'i ile state'i temizleme
        /// işlerini yapıyoruz.
        body: BlocListener<RegisterBloc, RegisterState>(
          // Sadece status değiştiğinde tetiklenmesi için.
          listenWhen: (previous, current) =>
          previous.status != current.status,
          listener: (context, state) {
            if (state.isSuccess) {
              // 1) Kullanıcıya başarı mesajını göster.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Registration successful! Welcome to Vacanza.',
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );

              // 2) Success state'i tek seferlik tüketmek için
              //    RegisterReset event'ini dispatch ediyoruz.
              //
              //    Böylece:
              //      - BLoC state'i tekrar initial'e döner,
              //      - ileride rebuild olduğunda aynı success state
              //        tekrar tetiklenmez.
              context.read<RegisterBloc>().add(const RegisterReset());

              // 3) Küçük bir gecikme ile MapScreen'e yönlendir.
              //    pushReplacement:
              //      - Back tuşunda RegisterScreen'e dönmeyi engeller.
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
            //  - failure durumunda navigation yapmıyoruz.
            //  - Hata mesajı zaten RegisterForm içinde inline olarak gösteriliyor.
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
                      // ... (senin mevcut logo + title + form + "Already have an account?" kısmın)
                      // Burayı kendi halinle bırakabilirsin;
                      // kritik olan kısım yukarıdaki BlocListener logic'i.
                      const Flexible(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: RegisterForm(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: () {
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