import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Returns true if [url] is non-empty and parseable with a scheme (e.g. https).
bool isValidBookingUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;
  final uri = Uri.tryParse(trimmed);
  return uri != null && uri.hasScheme;
}

/// Opens [url] in external browser. Shows SnackBar on invalid/missing URL or when launch fails.
/// Does not gate on canLaunchUrl (unreliable on Android/emulators); always attempts launch.
Future<void> openBookingUrl(BuildContext context, String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking link unavailable')),
      );
    }
    return;
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking link unavailable')),
      );
    }
    return;
  }

  final platform = context.mounted ? Theme.of(context).platform : null;
  final canLaunch = await canLaunchUrl(uri);
  if (kDebugMode) {
    debugPrint(
      '[URL_DEBUG] uri=$uri platform=$platform canLaunch=$canLaunch',
    );
  }
  if (!context.mounted) return;

  bool launchResult = false;
  try {
    launchResult = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (kDebugMode) {
      debugPrint('[URL_DEBUG] launchResult=$launchResult');
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[URL_DEBUG] launchResult=exception $e $st');
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open booking link')),
      );
    }
    return;
  }
  if (!launchResult && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cannot open booking link')),
    );
  }
}
