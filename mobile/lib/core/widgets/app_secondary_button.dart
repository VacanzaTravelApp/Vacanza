import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Secondary button (Cancel) consistent with Auth theme.
/// Same height and corner radius as [GradientButton]; outline style.
class AppSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const AppSecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
  });

  static const _height = 52.0;
  static final _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(26),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textHeading,
          side: const BorderSide(color: AppColors.inputBorder),
          shape: _shape,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
