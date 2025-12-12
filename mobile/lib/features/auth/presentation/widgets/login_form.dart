import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/widgets/gradient_button.dart';

import 'package:mobile/features/auth/presentation/widgets/login_email_section.dart';
import 'package:mobile/features/auth/presentation/widgets/login_password_section.dart';

import 'package:mobile/features/auth/presentation/bloc/login_bloc.dart';
import 'package:mobile/features/auth/presentation/bloc/login_event.dart';
import 'package:mobile/features/auth/presentation/bloc/login_state.dart';

/// Login formunun UI + basit validasyon + BLoC entegrasyonunu yöneten widget.
///
/// Görsel yapı VACANZA-83'teki ile birebir aynı:
///  - Email alanı
///  - Password alanı
///  - "Forgot Password?" linki
///  - Gradient "Log In" butonu
///
/// Farklar:
///  - _submit içindeki sahte delay kaldırıldı, yerine LoginBloc'e event gönderiliyor.
///  - Loading durumu ve hata mesajı artık LoginState üzerinden okunuyor.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _password = TextEditingController();

  /// Local form validasyon flag'i.
  /// Sadece email formatı + password boş mu kontrolü için kullanıyoruz.
  bool _formValid = false;

  /// Email format kontrolü için kullandığımız regex.
  final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');

  @override
  void initState() {
    super.initState();
    // Inputlar değiştikçe formun valid olup olmadığını yeniden hesaplıyoruz.
    _email.addListener(_update);
    _password.addListener(_update);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Email + password alanlarının geçerli olup olmadığını günceller.
  void _update() {
    final emailValid = _emailRegex.hasMatch(_email.text.trim());
    final passValid = _password.text.isNotEmpty;

    setState(() {
      _formValid = emailValid && passValid;
    });
  }

  /// Form submit edildiğinde çağrılır.
  ///
  /// 1) Form validator'ları geçmezse hiçbir şey yapmaz.
  /// 2) Klavyeyi kapatır.
  /// 3) LoginBloc'e LoginSubmitted event'i gönderir.
  ///
  /// Asıl login iş akışı (Firebase + backend + token saklama)
  /// AuthRepository + LoginBloc içinde yönetilir.
  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Klavyeyi kapat
    FocusScope.of(context).unfocus();

    // BLoC'e login event'ini gönder
    context.read<LoginBloc>().add(
      LoginSubmitted(
        email: _email.text.trim(),
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // LoginState'i dinleyerek:
    //  - loading state'i
    //  - hata mesajını
    // UI'a yansıtacağız.
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        final isSubmitting = state.isSubmitting;

        // Butonun aktif olup olmaması:
        //  - Form local olarak valid olmalı (_formValid)
        //  - Şu anda login isteği atılıyor olmamalı (isSubmitting == false)
        final canSubmit = _formValid && !isSubmitting;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // EMAIL
              LoginEmailSection(
                emailController: _email,
                emailRegex: _emailRegex,
              ),

              const SizedBox(height: 16),

              // PASSWORD
              LoginPasswordSection(passwordController: _password),

              const SizedBox(height: 10),

              // FORGOT PASSWORD
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: VACANZA-XX: Forgot Password akışı burada tasarlanacak.
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Eğer login denemesinde hata aldıysak (Firebase/AuthRepository),
              // BLoC failure state'ten gelen errorMessage'ı butonun üstünde gösteriyoruz.
              if (state.isFailure && state.errorMessage != null) ...[
                Text(
                  state.errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // LOGIN BUTTON
              GradientButton(
                text: "Log In",
                // Loading spinner artık BLoC'teki status'e bağlı.
                loading: isSubmitting,
                active: canSubmit,
                enabled: canSubmit,
                onPressed: canSubmit ? () => _submit(context) : null,
              ),
            ],
          ),
        );
      },
    );
  }
}