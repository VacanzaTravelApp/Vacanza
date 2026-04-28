import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile/features/auth/presentation/screens/verify_email_screen.dart';

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

    final theme = Theme.of(ctx);
    final cs = theme.colorScheme;
    final tokens = ctx.vacanzaTokens;
    final isLight = theme.brightness == Brightness.light;

    ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor: isLight
            ? tokens.cardBg.withValues(alpha: 0.96)
            : cs.surface.withValues(alpha: 0.94),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: tokens.cardBorder.withValues(alpha: isLight ? 0.22 : 0.55),
            width: 1.0,
          ),
        ),
        elevation: 10,
        content: Text(
          message,
          style: TextStyle(
            color: tokens.textMain,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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

  /// Email verify ekranına stack temizleyerek gider.
  static void goToVerifyEmail() {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
      (_) => false,
    );
  }
}