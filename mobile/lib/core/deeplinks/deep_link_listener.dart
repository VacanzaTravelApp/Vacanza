import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'package:mobile/core/navigation/navigation_service.dart';
import 'package:mobile/features/auth/presentation/screens/auth_action_link_screen.dart';

/// Listens for incoming app/universal links and routes them to the proper UI.
///
/// Supported links (prod):
/// - https://production.vacanza.app/confirm-email?mode=verifyEmail&oobCode=...
/// - https://production.vacanza.app/confirm-email?mode=resetPassword&oobCode=...
class DeepLinkListener extends StatefulWidget {
  const DeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  Uri? _lastHandled;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // Ensure navigator is ready before we try to route.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);

      _sub = _appLinks.uriLinkStream.listen(_handle);
    });
  }

  void _handle(Uri uri) {
    if (!mounted) return;

    // Avoid double-handling (can happen with redirects / repeated emits).
    if (_lastHandled?.toString() == uri.toString()) return;
    _lastHandled = uri;

    if (uri.host != 'production.vacanza.app') return;
    if (uri.path != '/confirm-email') return;

    final nav = NavigationService.navigatorKey.currentState;
    if (nav == null) return;

    nav.push(
      MaterialPageRoute(
        builder: (_) => AuthActionLinkScreen(uri: uri),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

