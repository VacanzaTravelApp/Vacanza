import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final bool errorGlow;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.onChanged,
    this.errorGlow = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() {});
        if (_focusNode.hasFocus) {
          // Field fokus olduğunda ekranda görünür yere kaydır
          Future.microtask(() {
            if (!mounted) return;
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: 0.2, // biraz üstlere gelsin
            );
          });
        }
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    final isError = widget.errorGlow;

    // **Mini glow – blur=3, spread=0, offset=(0,1)**
    List<BoxShadow> shadows = [];
    Color borderColor = AppColors.inputBorder;

    if (isError) {
      borderColor = Colors.red;
      shadows = [
        BoxShadow(
          color: Colors.red.withOpacity(0.22),
          blurRadius: 3,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ];
    } else if (isFocused) {
      borderColor = AppColors.primary;
      shadows = [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.20),
          blurRadius: 3,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ];
    }

    OutlineInputBorder br(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(
        color: c,
        width: 1.4,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: shadows,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: AppColors.inputPlaceholder),
              filled: true,
              fillColor: AppColors.inputFill,
              suffixIcon: widget.suffixIcon,
              enabledBorder: br(AppColors.inputBorder),
              focusedBorder: br(borderColor),
              errorBorder: br(borderColor),
              focusedErrorBorder: br(borderColor),
            ),
          ),
        ),
      ],
    );
  }
}
