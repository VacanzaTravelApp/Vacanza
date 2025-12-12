import 'package:flutter/material.dart';

import 'package:mobile/core/widgets/animated_background.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_text_styles.dart';

import 'package:mobile/features/auth/data/storage/secure_storage_service.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile/features/map/presentation/screens/map_screen.dart';

/// Uygulama açıldığında ilk çalışan "gate" ekranı.
///
/// Amaç:
///  - SecureStorage içindeki access token'a bakmak
///  - Token varsa → kullanıcıyı direkt MapScreen'e göndermek
///  - Token yoksa → LoginScreen açmak
///
/// Bu sprint için:
///  - Sadece "token var mı yok mu" kontrolü yapıyoruz.
///  - Token'ın gerçekten valid / expired olup olmadığını
///    kontrol eden full auth guard mekanizması Sprint 2'ye kalacak.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  /// Secure storage servisi.
  /// Buradan access token'ı okuyacağız.
  final SecureStorageService _storage = SecureStorageService();

  /// Async kontrol devam ediyor mu?
  bool _isChecking = true;

  /// Kullanıcının login olmuş kabul edilip edilmeyeceği.
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  /// Uygulama açıldığında bir kere çalışan kontrol:
  ///  - access_token oku
  ///  - null/boş değilse kullanıcıyı "authenticated" say
  Future<void> _checkAuthStatus() async {
    try {
      final accessToken = await _storage.readAccessToken();

      // Şimdilik çok basit bir kural:
      //  - Token null değil ve boş string değilse login kabul ediyoruz.
      //  - JWT'nin süresi / geçerliliği Sprint 2'de detaylı ele alınacak.
      final loggedIn = accessToken != null && accessToken.isNotEmpty;

      setState(() {
        _isAuthenticated = loggedIn;
        _isChecking = false;
      });
    } catch (_) {
      // Herhangi bir hata olsa bile uygulamanın crash olmasını istemiyoruz.
      // Bu durumda "sanki token yokmuş" gibi login ekranına düşer.
      setState(() {
        _isAuthenticated = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1) Kontrol devam ediyorken basit bir splash-style ekran gösteriyoruz.
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

    // 2) Kontrol bittiğinde:
    //  - _isAuthenticated true ise → MapScreen
    //  - değilse → LoginScreen
    if (_isAuthenticated) {
      return const MapScreen();
    } else {
      return const LoginScreen();
    }
  }
}