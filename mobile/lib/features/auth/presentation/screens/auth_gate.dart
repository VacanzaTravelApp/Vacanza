import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:mobile/core/widgets/animated_background.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';

import 'package:mobile/features/auth/data/storage/secure_storage_service.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile/features/map/presentation/screens/home_map_screen.dart';

/// AuthGate
///
/// TEK VE NET KURAL:
/// Bir kullanıcı authenticated sayılabilmesi için:
///   1) FirebaseAuth.currentUser != null
///   2) Firebase ID Token başarıyla alınabilmeli
///
/// Token her app açılışında yeniden alınır ve SecureStorage'a yazılır.
/// Böylece:
/// - Logout sonrası map ASLA açılmaz
/// - App restart'ta session deterministik olur
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final SecureStorageService _storage = SecureStorageService();

  bool _checking = true;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _resolveSession();
  }

  /// 🔐 SESSION RESOLVE (TEK GERÇEK SOURCE)
  ///
  /// Akış:
  /// 1) Firebase currentUser var mı?
  /// 2) Yoksa -> LOGIN
  /// 3) Varsa -> getIdToken(forceRefresh: true)
  /// 4) Token geldiyse -> SecureStorage'a yaz
  /// 5) -> HOME MAP
  ///
  /// HATA OLURSA:
  /// - Firebase signOut
  /// - SecureStorage temizle
  /// - LOGIN
  Future<void> _resolveSession() async {
    try {
      final firebaseUser = fb.FirebaseAuth.instance.currentUser;

      // 1️⃣ Firebase session yok → LOGIN
      if (firebaseUser == null) {
        _goUnauthenticated();
        return;
      }

      // 2️⃣ TOKEN'I ZORLA YENİDEN AL
      final idToken = await firebaseUser.getIdToken(true);

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Firebase ID Token alınamadı');
      }

      // 3️⃣ TOKEN'I STORAGE'A YAZ
      await _storage.writeAccessToken(idToken);

      // 4️⃣ AUTH OK
      setState(() {
        _authenticated = true;
        _checking = false;
      });
    } catch (e) {
      // ❌ HER TÜRLÜ FAIL → HARD LOGOUT
      await _hardLogout();
      _goUnauthenticated();
    }
  }

  Future<void> _hardLogout() async {
    try {
      await _storage.clearSession();
      await fb.FirebaseAuth.instance.signOut();
    } catch (_) {
      // ignore
    }
  }

  void _goUnauthenticated() {
    setState(() {
      _authenticated = false;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ⏳ Loading
    if (_checking) {
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

    // ✅ NET KARAR
    return _authenticated
        ? const HomeMapScreen()
        : const LoginScreen();
  }
}