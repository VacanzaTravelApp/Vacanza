import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
// Aslında burada AppTextField kullanılmıyor ama
// RegisterNameSection / PasswordSection içinde kullanıldığı için
// o widget'lerin import düzeninde bir sorun olmaması adına bırakıyoruz.
import '../../../../core/widgets/app_text_field.dart';

import '../bloc/register_bloc.dart';
import '../bloc/register_event.dart';
import '../bloc/register_state.dart';

import 'auth_card_container.dart';
import 'register_name_section.dart';
import 'register_email_section.dart';
import 'register_password_section.dart';
import 'register_terms_and_button_section.dart';

/// Register ekranının ana form widget'ı.
/// Burada:
///  - TextEditingController'lar tutuluyor
///  - Form validation kuralları çalışıyor
///  - Preferred name seçimi kontrol ediliyor
///  - Terms & Conditions onayı takip ediliyor
///  - Submit olduğunda BLoC'e RegisterSubmitted event'i gönderiliyor
class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  /// Flutter form'unu kontrol etmek için GlobalKey.
  /// _formKey.currentState!.validate() ile
  /// tüm TextFormField validator'larını tetikliyoruz.
  final _formKey = GlobalKey<FormState>();

  // ----------------------------------------------------------
  // ✏️ TextEditingController'lar
  // ----------------------------------------------------------
  //
  // Bu controller'lar input'lardaki text'e hem erişmemizi
  // hem de değişiklikleri dinleyip
  // form durumunu (_updateForm) güncellememizi sağlıyor.
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  /// Formun genel olarak valid olup olmadığı.
  /// Burada sadece tek tek TextField'lerin valid olması değil,
  /// aynı zamanda:
  ///   - Preferred name seçili mi
  ///   - Password kuralları sağlanıyor mu
  /// gibi "business rule" seviyesini de işin içine katıyoruz.
  bool _formValid = false;

  /// Kullanıcı Terms & Conditions kutusunu işaretledi mi?
  /// Checkbox bu boolean'a bağlı.
  bool _terms = false;

  // ----------------------------------------------------------
  // 📧 Email Regex
  // ----------------------------------------------------------
  //
  // Email input’unu hem real-time hem de validator içinde
  // kontrol ederken kullanıyoruz.
  final RegExp _emailRegex =
  RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');

  // ----------------------------------------------------------
  // 🔐 Şifre kuralları
  // ----------------------------------------------------------
  //
  // up  -> En az 1 büyük harf var mı?
  // low -> En az 1 küçük harf var mı?
  // dig -> En az 1 rakam var mı?
  // spe -> En az 1 özel karakter var mı?
  // len8 -> En az 8 karakter mi?
  bool up = false, low = false, dig = false, spe = false, len8 = false;

  /// Confirm password ile password eşleşiyor mu?
  /// mismatch = true → "Passwords do not match" hata mesajı gösterilecek.
  bool mismatch = false;

  // ----------------------------------------------------------
  // ⭐ Preferred name seçimleri
  // ----------------------------------------------------------
  //
  // Kullanıcının hem first hem middle name'i varsa,
  // bu iki isimden hangisi (veya hangileri) "preferred name"
  // olarak kullanılacak, onu işaretliyor.
  bool _preferredFirst = false;
  bool _preferredMiddle = false;

  @override
  void initState() {
    super.initState();

    // Tüm controller'lara listener ekliyoruz.
    // Böylece kullanıcı her yazdığında _updateForm çağrılıyor,
    // form validasyon state'i canlı olarak güncelleniyor.
    for (final c in [
      _firstName,
      _middleName,
      _lastName,
      _email,
      _password,
      _confirm,
    ]) {
      c.addListener(_updateForm);
    }
  }

  @override
  void dispose() {
    // Memory leak olmaması için tüm controller'ları dispose ediyoruz.
    for (final c in [
      _firstName,
      _middleName,
      _lastName,
      _email,
      _password,
      _confirm,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ----------------------------------------------------------
  // 🧠 _updateForm
  // ----------------------------------------------------------
  //
  // Bu fonksiyon:
  //  - Password kurallarını günceller
  //  - Confirm password eşleşmesini kontrol eder
  //  - First/middle/last name, email, password geçerliliklerini kontrol eder
  //  - Preferred name seçim durumuna bakar
  //  - Sonuçta _formValid'i set eder
  void _updateForm() {
    final pass = _password.text.trim();
    final conf = _confirm.text.trim();

    // 1) Şifre kurallarını güncelle
    up = RegExp(r'[A-Z]').hasMatch(pass); // büyük harf
    low = RegExp(r'[a-z]').hasMatch(pass); // küçük harf
    dig = RegExp(r'[0-9]').hasMatch(pass); // rakam
    spe = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pass); // özel karakter
    len8 = pass.length >= 8; // en az 8 karakter

    // 2) Confirm password eşleşme durumu
    mismatch = conf.isNotEmpty && conf != pass;

    // 3) Diğer alanların doluluk ve format kontrolü
    final f = _firstName.text.trim().isNotEmpty;
    final m = _middleName.text.trim().isNotEmpty;
    final l = _lastName.text.trim().isNotEmpty;
    final e = _emailRegex.hasMatch(_email.text.trim());
    final p = up && low && dig && spe && len8; // tüm password kuralları
    final c = conf == pass && conf.isNotEmpty;

    // 4) Preferred name kuralı:
    //    Kullanıcının hem first hem middle name'i varsa,
    //    bunlardan en az birini preferred olarak seçmiş olmalı.
    final prefOk = f && m ? (_preferredFirst || _preferredMiddle) : false;

    // 5) Tüm kurallar sağlanıyorsa form valid kabul edilir.
    setState(() {
      _formValid = f && m && l && e && p && c && prefOk;
    });
  }

  // ----------------------------------------------------------
  // 🚀 _submit
  // ----------------------------------------------------------
  //
  // Bu fonksiyon UI tarafındaki son adım:
  //  - Flutter form validator'larını çalıştırır.
  //  - Terms işaretli mi ve _formValid true mu kontrol eder.
  //  - Tüm check'ler geçtiyse RegisterBloc'e RegisterSubmitted event'i yollar.
  //
  // DİKKAT:
  //  - Firebase ve backend çağrısı burada direkt yapılmıyor.
  //  - Sadece BLoC'e event gönderiliyor.
  //  - Asıl iş mantığı RegisterBloc + AuthRepository tarafında.
  Future<void> _submit(BuildContext context) async {
    // Tüm TextFormField'lerin validator'larını tetikle.
    // Eğer herhangi biri hata dönerse form invalid kabul edilir.
    if (!_formKey.currentState!.validate()) return;

    // Terms işaretli değilse veya formValid değilse hiçbir çağrı göndermiyoruz.
    // Bu kuralla:
    //   - Firebase'e gereksiz istek gitmiyor
    //   - Acceptance Criteria: "Form invalidken hiçbir çağrı yapılmamalı" sağlanıyor.
    if (!_terms || !_formValid) return;

    // Preferred names listesini hazırla.
    final preferredNames = <String>[];
    if (_preferredFirst) {
      preferredNames.add(_firstName.text.trim());
    }
    if (_preferredMiddle) {
      preferredNames.add(_middleName.text.trim());
    }

    // BLoC'e event gönder:
    //   - Firebase register
    //   - (Backend hazır olduğunda) /auth/register
    // çağrıları RegisterBloc -> AuthRepository içinde yapılacak.
    context.read<RegisterBloc>().add(
      RegisterSubmitted(
        firstName: _firstName.text.trim(),
        middleName: _middleName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        preferredNames: preferredNames,
      ),
    );

    // VACANZA-82:
    //   RegisterStatus.success durumunu dinleyip:
    //   - Snackbar göster
    //   - Bir sonraki ekrana (ör: onboarding / home / map) yönlendir
    // işlemlerini burada yapan bir listener ekleyeceğiz.
  }

  @override
  Widget build(BuildContext context) {
    // Kullanıcının hem first hem middle name'i dolu mu?
    // Eğer ikisi de doluysa Preferred Name alanı görünecek.
    final hasBothNames = _firstName.text.trim().isNotEmpty &&
        _middleName.text.trim().isNotEmpty;

    // Preferred name seçimi zorunlu mu ve şu an seçilmemiş mi?
    final preferredMissing =
        hasBothNames && !_preferredFirst && !_preferredMiddle;

    // Confirm password textfield'ında kırmızı glow gösterilsin mi?
    final confirmGlow = mismatch;

    // BlocConsumer:
    //  - builder: UI'yı state'e göre yeniden çizer.
    //  - listener: One-shot side effect (snackbar, navigation vs.) için kullanılır.
    return BlocConsumer<RegisterBloc, RegisterState>(
      listener: (context, state) {
        // Şimdilik sadece success state’ini not ediyoruz.
        // VACANZA-82'de:
        //   if (state.isSuccess) {
        //     -> snackbar + navigation
        //   }
        if (state.isSuccess) {
          // debugPrint('Register success!');
        }
      },
      builder: (context, state) {
        // Şu an submit işlemi devam ediyor mu? (Firebase + backend)
        final isSubmitting = state.isSubmitting;

        // Butonun aktif olabilmesi için:
        //  - Form valid olmalı
        //  - Terms işaretli olmalı
        //  - Şu an submit işlemi devam etmiyor olmalı
        final canSubmit = _formValid && _terms && !isSubmitting;

        return AuthCardContainer(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --------------------------------------------------
                  // 🔴 BLoC'tan gelen global error mesajı (Firebase / Backend)
                  // --------------------------------------------------
                  //
                  // Eğer RegisterStatus.failure ise ve errorMessage dolu ise,
                  // kartın en üstünde kırmızı bir uyarı kutusu gösteriyoruz.
                  // Örnek senaryolar:
                  //  - Firebase: email-already-in-use, weak-password vs.
                  //  - Backend: 409 duplicate email, 500 server error vs.
                  if (state.isFailure && state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.7),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // --------------------------------------------------
                  // 👤 İsim Alanları (First / Middle / Last + Preferred)
                  // --------------------------------------------------
                  RegisterNameSection(
                    firstNameController: _firstName,
                    middleNameController: _middleName,
                    lastNameController: _lastName,
                    hasBothNames: hasBothNames,
                    preferredFirst: _preferredFirst,
                    preferredMiddle: _preferredMiddle,
                    preferredMissing: preferredMissing,
                    onPreferredFirstChanged: (v) {
                      setState(() => _preferredFirst = v);
                      _updateForm();
                    },
                    onPreferredMiddleChanged: (v) {
                      setState(() => _preferredMiddle = v);
                      _updateForm();
                    },
                  ),

                  const SizedBox(height: 16),

                  // --------------------------------------------------
                  // 📧 Email Alanı
                  // --------------------------------------------------
                  RegisterEmailSection(
                    emailController: _email,
                    emailRegex: _emailRegex,
                  ),

                  const SizedBox(height: 16),

                  // --------------------------------------------------
                  // 🔐 Password + Confirm Password Alanları
                  // --------------------------------------------------
                  RegisterPasswordSection(
                    passwordController: _password,
                    confirmController: _confirm,
                    up: up,
                    low: low,
                    dig: dig,
                    spe: spe,
                    len8: len8,
                    mismatch: mismatch,
                    confirmGlow: confirmGlow,
                    onPasswordChanged: () => _updateForm(),
                  ),

                  const SizedBox(height: 20),

                  // --------------------------------------------------
                  // ✅ Terms & Conditions + "Sign Up" Button
                  // --------------------------------------------------
                  RegisterTermsAndButtonSection(
                    terms: _terms,
                    loading: isSubmitting, // BLoC submitting state
                    formValid: _formValid,
                    onTermsChanged: (v) {
                      setState(() => _terms = v ?? false);
                    },
                    onSubmit: () => _submit(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}