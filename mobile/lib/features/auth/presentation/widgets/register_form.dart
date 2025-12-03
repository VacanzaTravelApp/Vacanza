import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/theme/app_colors.dart';

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

  // Password visibility
  bool _passwordVisible = false;
  bool _confirmVisible = false;

  // Preferred name (multi-select: first, middle, or both)
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
      _confirm
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
      _confirm
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _updateForm() {
    final pass = _password.text.trim();
    final conf = _confirm.text.trim();

    // Password kuralları
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

    // Eğer isimlerden biri boşsa preferred seçimlerini sıfırla
    if (!f || !m) {
      _preferredFirst = false;
      _preferredMiddle = false;
    }

    final prefOk = f && m ? (_preferredFirst || _preferredMiddle) : false;

    setState(() {
      _formValid = f && m && l && e && p && c && prefOk;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_terms) return;

    setState(() => _loading = true);

    // TODO(VACANZA-81): Replace with repository / BLoC call to /auth/register
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _loading = false);
  }

  Widget _rule(String text, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: ok ? AppColors.accentMint : AppColors.inputBorder,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: ok ? AppColors.accentMint : AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final confirmGlow = mismatch;
    final emailValid = _emailRegex.hasMatch(_email.text.trim());
    final hasBothNames =
        _firstName.text.trim().isNotEmpty && _middleName.text.trim().isNotEmpty;

    final bool preferredMissing =
        hasBothNames && !_preferredFirst && !_preferredMiddle;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
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
              // FIRST NAME
              AppTextField(
                controller: _firstName,
                hintText: "Enter your first name",
                label: "First Name",
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // MIDDLE NAME
              AppTextField(
                controller: _middleName,
                hintText: "Enter your middle name",
                label: "Middle Name",
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              if (hasBothNames) ...[
                const SizedBox(height: 12),
                const Text(
                  "Preferred name",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeading,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: Text(
                          _firstName.text.trim().isEmpty
                              ? "First name"
                              : _firstName.text.trim(),
                        ),
                        selected: _preferredFirst,
                        selectedColor:
                        AppColors.primary.withOpacity(0.15),
                        onSelected: (selected) {
                          setState(() {
                            _preferredFirst = selected;
                          });
                          _updateForm();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: Text(
                          _middleName.text.trim().isEmpty
                              ? "Middle name"
                              : _middleName.text.trim(),
                        ),
                        selected: _preferredMiddle,
                        selectedColor:
                        AppColors.primary.withOpacity(0.15),
                        onSelected: (selected) {
                          setState(() {
                            _preferredMiddle = selected;
                          });
                          _updateForm();
                        },
                      ),
                    ),
                  ],
                ),
                if (preferredMissing)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "Please choose at least one preferred name",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 16),

              // LAST NAME
              AppTextField(
                controller: _lastName,
                hintText: "Enter your last name",
                label: "Last Name",
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // EMAIL
              AppTextField(
                controller: _email,
                hintText: "Enter your email",
                label: "Email",
                keyboardType: TextInputType.emailAddress,
                validator: (v) => _emailRegex.hasMatch(v!.trim())
                    ? null
                    : "Enter a valid email",
              ),
              const SizedBox(height: 6),
              _rule("Valid email format", emailValid),
              const SizedBox(height: 16),

              // PASSWORD
              AppTextField(
                controller: _password,
                hintText: "Create a password",
                label: "Password",
                obscureText: !_passwordVisible,
                onChanged: (_) => _updateForm(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size: 18,
                    color: AppColors.inputPlaceholder,
                  ),
                  onPressed: () {
                    setState(() => _passwordVisible = !_passwordVisible);
                  },
                ),
                validator: (v) =>
                (up && low && dig && spe && len8)
                    ? null
                    : "Invalid password",
              ),

              const SizedBox(height: 6),

              // PASSWORD RULES
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _rule("1+ uppercase", up),
                      _rule("1+ lowercase", low),
                      _rule("1 number", dig),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _rule("1 special char", spe),
                      _rule("8+ characters", len8),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // CONFIRM PASSWORD
              AppTextField(
                controller: _confirm,
                hintText: "Confirm your password",
                label: "Confirm Password",
                obscureText: !_confirmVisible,
                errorGlow: confirmGlow,
                suffixIcon: IconButton(
                  icon: Icon(
                    _confirmVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size: 18,
                    color: AppColors.inputPlaceholder,
                  ),
                  onPressed: () {
                    setState(() => _confirmVisible = !_confirmVisible);
                  },
                ),
                validator: (v) =>
                mismatch ? "Passwords do not match" : null,
              ),

              if (confirmGlow)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    "Passwords do not match",
                    style: TextStyle(
                      color: Colors.red.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // TERMS
              Row(
                children: [
                  Checkbox(
                    value: _terms,
                    onChanged: (v) =>
                        setState(() => _terms = v ?? false),
                    activeColor: AppColors.primary,
                    checkColor: Colors.white,
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                        children: [
                          const TextSpan(text: "I agree to the "),
                          TextSpan(
                            text: "Terms & Conditions",
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {},
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy",
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              GradientButton(
                text: "Sign Up",
                loading: _loading,
                active: _formValid && _terms,          // 🔥 burada checkbox koşulu da var
                enabled: _formValid && _terms,
                onPressed: _formValid && _terms ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
