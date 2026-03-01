import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Returns true if [url] is non-empty and parseable with a scheme (e.g. https).
bool isValidBookingUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;
  final uri = Uri.tryParse(trimmed);
  return uri != null && uri.hasScheme;
}

/// Opens [url] in external browser. Shows SnackBar on invalid/missing URL or when launch fails.
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
  final canLaunch = await canLaunchUrl(uri);
  if (!context.mounted) return;
  if (!canLaunch) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cannot open booking link')),
    );
    return;
  }
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot open booking link')),
      );
    }
  }
}
