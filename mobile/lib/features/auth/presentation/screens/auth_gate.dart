import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:mobile/core/widgets/animated_background.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/theme/app_theme.dart';

import 'package:mobile/features/auth/data/storage/secure_storage_service.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile/features/auth/presentation/screens/verify_email_screen.dart';
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
  bool _needsEmailVerification = false;

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
  /// 3) Varsa -> emailVerified + token refresh
  /// 4) Token geldiyse -> SecureStorage'a yaz
  /// 5) emailVerified ise -> HOME MAP, değilse -> VerifyEmail
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

      // 2️⃣ Kullanıcı bilgisini tazele ve emailVerified durumunu oku
      await firebaseUser.reload();
      final refreshed = fb.FirebaseAuth.instance.currentUser;
      if (refreshed == null) {
        _goUnauthenticated();
        return;
      }

      final isVerified = refreshed.emailVerified;

      // 3️⃣ TOKEN'I ZORLA YENİDEN AL
      final idToken = await refreshed.getIdToken(true);

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Firebase ID Token alınamadı');
      }

      // 4️⃣ TOKEN'I STORAGE'A YAZ
      await _storage.writeAccessToken(idToken);

      // 5️⃣ AUTH / VERIFY KARARI
      setState(() {
        _checking = false;
        _authenticated = isVerified;
        _needsEmailVerification = !isVerified;
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
      final tokens = context.vacanzaTokens;
      final accent = context.authAccent;

      return AnimatedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparing your journey...',
                  style: bodyMedium.copyWith(color: tokens.textSub),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ NET KARAR
    if (_needsEmailVerification) {
      return const VerifyEmailScreen();
    }

    return _authenticated
        ? const HomeMapScreen()
        : const LoginScreen();
  }
}