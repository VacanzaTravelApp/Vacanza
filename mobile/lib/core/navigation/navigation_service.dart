import 'package:flutter/material.dart';

import 'package:mobile/features/auth/presentation/screens/login_screen.dart';

/// Global navigation helper.
///
/// Neden var?
/// - Interceptor gibi "UI context"i olmayan yerlerden yönlendirme yapabilmek.
/// - 401 geldiğinde stack'i temizleyip Login'e dönebilmek.
///
/// Kullanım:
/// - main.dart içinde MaterialApp(navigatorKey: NavigationService.navigatorKey)
/// - Interceptor içinde NavigationService.resetToLogin(...)
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  /// Uygulamada o an aktif context (varsa).
  static BuildContext? get _context => navigatorKey.currentContext;

  /// Session expired tarzı bir mesaj göstermek için.
  static void showSnackBar(String message) {
    final ctx = _context;
    if (ctx == null) return;

    ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Login ekranına stack temizleyerek gider.
  /// Kullanıcı back'e basınca geri dönememeli.
  static void resetToLogin() {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }
}