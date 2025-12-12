import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
// NOTE: Keeping this import as-is (even if not directly used here),
// to avoid confusion in the existing widget structure.
import '../../../../core/widgets/app_text_field.dart';

import '../bloc/register_bloc.dart';
import '../bloc/register_event.dart';
import '../bloc/register_state.dart';

import 'auth_card_container.dart';
import 'register_name_section.dart';
import 'register_email_section.dart';
import 'register_password_section.dart';
import 'register_terms_and_button_section.dart';

/// Register form widget.
/// Responsibilities:
/// - holds controllers for all fields
/// - performs live validation and business rules (preferred name, password rules, etc.)
/// - dispatches RegisterSubmitted to RegisterBloc
/// - reads loading/error states from RegisterState
///
/// IMPORTANT:
/// - No artificial delay.
/// - Loading spinner is driven by RegisterState.status (submitting).
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

  bool _formValid = false;
  bool _terms = false;

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

  /// Updates live validation flags and business rules.
  void _updateForm() {
    final pass = _password.text.trim();
    final conf = _confirm.text.trim();

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

  /// Submit:
  /// - validator check
  /// - business rule check (terms + _formValid)
  /// - close keyboard
  /// - dispatch RegisterSubmitted
  Future<void> _submit(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_terms || !_formValid) return;

    FocusScope.of(context).unfocus();

    final preferredNames = <String>[];
    if (_preferredFirst) preferredNames.add(_firstName.text.trim());
    if (_preferredMiddle) preferredNames.add(_middleName.text.trim());

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
  }

  @override
  Widget build(BuildContext context) {
    final hasBothNames =
        _firstName.text.trim().isNotEmpty &&
            _middleName.text.trim().isNotEmpty;

    final preferredMissing =
        hasBothNames && !_preferredFirst && !_preferredMiddle;

    final confirmGlow = mismatch;

    return BlocConsumer<RegisterBloc, RegisterState>(
      listener: (context, state) {
        if (state.isSuccess) {
          // VACANZA-82/85 side effects can live here:
          // snackbar + navigation
        }
      },
      builder: (context, state) {
        final isSubmitting = state.isSubmitting;
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
                  // Global error (Firebase / backend)
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
                    loading: isSubmitting,
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