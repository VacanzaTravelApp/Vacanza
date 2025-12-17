import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:mobile/core/widgets/animated_background.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';

import 'package:mobile/features/auth/data/storage/secure_storage_service.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile/features/map/presentation/screens/home_map_screen.dart';

/// Uygulama açıldığında ilk çalışan "gate" ekranı.
///
/// Yeni Mantık:
///  - Backend token üretmiyor.
///  - Biz "authenticated" saymak için:
///      1) SecureStorage'da token var mı?  (Bearer olarak gidecek Firebase ID Token)
///      2) Firebase tarafında currentUser var mı? (Firebase session açık mı?)
///    ikisini birlikte kontrol ediyoruz.
///
/// Bu sprint için:
///  - Token'ın expire olup olmadığı gibi derin kontrol YOK.
///  - Full guard / refresh / 401 handling işleri ileride (VACANZA-88 vb.).
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final SecureStorageService _storage = SecureStorageService();

  bool _isChecking = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  /// Basit auth kontrolü:
  ///  - Storage token var mı?
  ///  - Firebase currentUser var mı?
  ///
  /// İkisi de varsa kullanıcıyı MapScreen'e alıyoruz.
  Future<void> _checkAuthStatus() async {
    try {
      final token = await _storage.readAccessToken();
      final firebaseUser = fb.FirebaseAuth.instance.currentUser;

      final hasToken = token != null && token.isNotEmpty;
      final hasFirebaseSession = firebaseUser != null;

      setState(() {
        _isAuthenticated = hasToken && hasFirebaseSession;
        _isChecking = false;
      });
    } catch (_) {
      setState(() {
        _isAuthenticated = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      final bodyMedium = AppTextStyles.bodyMedium(context);

      return AnimatedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparing your journey...',
                  style: bodyMedium.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _isAuthenticated ? const HomeMapScreen() : const LoginScreen();
  }
}