import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/animated_background.dart';
import '../widgets/register_form.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const SizedBox(height: 24),
                    // logo
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
                    // heading
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
                      style: bodyMedium.copyWith(color: subtitleColor),
                    ),
                    const SizedBox(height: 24),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const RegisterForm(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text.rich(
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
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
