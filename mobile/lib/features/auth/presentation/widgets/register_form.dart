import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

import 'auth_card_container.dart';
import 'register_name_section.dart';
import 'register_email_section.dart';
import 'register_password_section.dart';
import 'register_terms_and_button_section.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  bool _formValid = false;
  bool _terms = false;

  // Email regex
  final RegExp _emailRegex =
  RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');

  // Password rules
  bool up = false, low = false, dig = false, spe = false, len8 = false;
  bool mismatch = false;

  // Preferred name selections
  bool _preferredFirst = false;
  bool _preferredMiddle = false;

  @override
  void initState() {
    super.initState();

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

  void _updateForm() {
    final pass = _password.text.trim();
    final conf = _confirm.text.trim();

    // Şifre kuralları
    up = RegExp(r'[A-Z]').hasMatch(pass);
    low = RegExp(r'[a-z]').hasMatch(pass);
    dig = RegExp(r'[0-9]').hasMatch(pass);
    spe = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pass);
    len8 = pass.length >= 8;

    mismatch = conf.isNotEmpty && conf != pass;

    final f = _firstName.text.trim().isNotEmpty;
    final m = _middleName.text.trim().isNotEmpty;
    final l = _lastName.text.trim().isNotEmpty;
    final e = _emailRegex.hasMatch(_email.text.trim());
    final p = up && low && dig && spe && len8;
    final c = conf == pass && conf.isNotEmpty;

    final prefOk = f && m ? (_preferredFirst || _preferredMiddle) : false;

    setState(() {
      _formValid = f && m && l && e && p && c && prefOk;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_terms) return;

    setState(() => _loading = true);

    // TODO: backend register request
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasBothNames =
        _firstName.text.trim().isNotEmpty &&
            _middleName.text.trim().isNotEmpty;

    final preferredMissing =
        hasBothNames && !_preferredFirst && !_preferredMiddle;

    final confirmGlow = mismatch;

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
              // NAME SECTION
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

              // EMAIL SECTION
              RegisterEmailSection(
                emailController: _email,
                emailRegex: _emailRegex,
              ),

              const SizedBox(height: 16),

              // PASSWORD SECTION
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

              // TERMS + BUTTON SECTION
              RegisterTermsAndButtonSection(
                terms: _terms,
                loading: _loading,
                formValid: _formValid,
                onTermsChanged: (v) =>
                    setState(() => _terms = v ?? false),
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}