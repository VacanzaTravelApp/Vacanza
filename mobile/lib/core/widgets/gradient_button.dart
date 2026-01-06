import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  /// true ise gradient görünüm, false ise disabled gri görünüm
  final bool active;

  /// true ise tıklanabilir (onTap çalışır)
  final bool enabled;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.active = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool canTap = enabled && !loading && onPressed != null;
    final BorderRadius radius = BorderRadius.circular(26);

    final Decoration decoration = active
        ? BoxDecoration(
      borderRadius: radius,
      gradient: const LinearGradient(
        colors: [
          AppColors.primary,
          AppColors.accentMint,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.25),
          blurRadius: 14,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
      ],
    )
        : BoxDecoration(
      borderRadius: radius,
      color: AppColors.buttonDisabled,
    );

    return ClipRRect(
      borderRadius: radius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: decoration,
        height: 52,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: canTap ? onPressed : null,
            child: Center(
              child: loading
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
