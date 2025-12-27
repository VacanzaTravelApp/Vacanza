// Flutter UI
import 'package:flutter/material.dart';

// BLoC yönetimi için gerekli importlar
import 'package:flutter_bloc/flutter_bloc.dart';

// Tema dosyaları (renkler, text stilleri, arkaplan animasyonu)
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/widgets/animated_background.dart';

// Register form widget'ı (isim, email, password alanları burada)
import 'package:mobile/features/auth/presentation/widgets/register_form.dart';

// Register BLoC (event + state + bloc logic)
import 'package:mobile/features/auth/presentation/bloc/register_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/register_state.dart';
import 'package:mobile/features/auth/presentation/bloc/register_event.dart';

// Login ekranı (altta “Already have an account?” yazısı için)
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile/features/map/presentation/screens/home_map_screen.dart';

// Register sonrası yönleneceğimiz ana map ekranı (şimdilik mock)


/// ------------------------------------------------------------
///                      REGISTER SCREEN
/// ------------------------------------------------------------
/// Bu ekran Vacanza'nın register UI’sini gösterir.
/// İçinde:
///   - Logo
///   - Başlık
///   - Açıklama
///   - RegisterForm (isim, email, password)
///   - Log In CTA
///
/// Ayrıca RegisterBloc'i dinleyerek:
///   ✔ Register başarılı → snackbar + MapScreen yönlendirme
///   ✔ Hata → Form içinde kırmızı mesaj (navigation yok)
///
/// VACANZA-82 gereksinimleri eksiksiz karşılanır.
/// ------------------------------------------------------------
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Başlık yazısı stilini temadan çekiyoruz.
    final titleStyle = AppTextStyles.titleLarge(context).copyWith(
      color: AppColors.textHeading,
    );

    // Orta boyutlu metin stilleri (açıklama ve CTA için)
    final bodyMedium = AppTextStyles.bodyMedium(context);

    // Açık gri metin rengi
    final subtitleColor = AppColors.textMuted;

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,

        /// -------------------------------------------------------------------
        ///  BLoC LISTENER → RegisterBloc değişikliklerini dinliyoruz.
        ///
        ///  Burada UI mantığı var:
        ///    - SUCCESS olduğunda snackbar + MapScreen yönlendirme
        ///    - FAILURE olduğunda navigation yapılmaz (form kendi hata gösterir)
        ///
        ///  NOT: BLoC içinde navigation YAPMIYORUZ → UI katmanı sorumludur.
        /// -------------------------------------------------------------------
        body: BlocListener<RegisterBloc, RegisterState>(
          // Aynı state tekrar build edildiğinde tetiklemesin diye:
          listenWhen: (prev, curr) => prev.status != curr.status,

          listener: (context, state) {
            // -------------------------------------------
            // SUCCESS DURUMU
            // -------------------------------------------
            if (state.isSuccess) {
              // 1) Kullanıcıya başarı mesajı
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Registration successful! Welcome to Vacanza.'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );

              // 2) SUCCESS state sadece bir kez çalışsın diye
              //    RegisterReset event'i gönderiyoruz.
              context.read<RegisterBloc>().add(const RegisterReset());

              // 3) Snackbar görünür olsun diye küçük gecikme
              Future.delayed(const Duration(milliseconds: 300), () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeMapScreen()),
                );
              });
            }

            // FAILURE durumda burada bir şey yapmıyoruz.
            // Hata mesajı RegisterForm içinde inline gösteriliyor.
          },

          /// -------------------------------------------------------------------
          ///  AŞAĞISI TAMAMEN SENİN ORİJİNAL UI KODUN
          ///  (Logo, başlık, açıklama, form, CTA)
          ///
          ///  Biz sadece bunu BlocListener içine sardık.
          /// -------------------------------------------------------------------
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(), // klavye kapatma

            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),

                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const SizedBox(height: 24),

                      /// --------------------------------------------------
                      /// ✈️ Sol üstteki Vacanza LOGO baloncuğu
                      /// --------------------------------------------------
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

                      /// --------------------------------------------------
                      /// 📝 Register Başlık (Create Your Vacanza Account)
                      /// --------------------------------------------------
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

                      /// --------------------------------------------------
                      /// 📄 Açıklama (subheading)
                      /// --------------------------------------------------
                      Text(
                        'Start your personalized journey today',
                        textAlign: TextAlign.center,
                        style: bodyMedium.copyWith(color: subtitleColor),
                      ),

                      const SizedBox(height: 24),

                      /// --------------------------------------------------
                      /// 📌 Kayıt formu (isim + email + şifre)
                      /// --------------------------------------------------
                      const Flexible(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: RegisterForm(),
                        ),
                      ),

                      const SizedBox(height: 18),

                      /// --------------------------------------------------
                      /// 🔐 LOGIN CTA (zaten hesabı olan kullanıcılar için)
                      /// --------------------------------------------------
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
                            style: bodyMedium.copyWith(color: subtitleColor),
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