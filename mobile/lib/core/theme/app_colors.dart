import 'package:flutter/material.dart';

final class AppColors {
  AppColors._();

  // PRIMARY / ACCENT
  static const primary = Color(0xFF1DA1F2); // Figma: #1DA1F2
  static const accentMint = Color(0xFF14B8A6); // Figma: #14B8A6

  // BACKGROUND GRADIENT (Figma: from-[#EAF7FF] via-[#F8FBFF] to-[#DDF3FF])
  static const bgFrom = Color(0xFFEAF7FF);
  static const bgVia = Color(0xFFF8FBFF);
  static const bgTo = Color(0xFFDDF3FF);

  // BLOBS (blurred circles)
  static const blobBlue = Color(0xFF1DA1F2);
  static const blobTeal = Color(0xFF14B8A6);

  // TEXT COLORS
  static const textHeading = Color(0xFF2C3E50); // "Create your Vacanza..."
  static const textMuted = Color(0xFF5F7A8F);   // alt açıklamalar

  // CARD
  // bg-white/40 = white with 0.4 alpha
  static const cardBg = Color(0x66FFFFFF); // 0x66 = ~40% opacity
  static const cardBorder = Color(0x99FFFFFF); // white/60

  // INPUT
  static const inputFill = Colors.white;
  static const inputBorder = Color(0xFFD8E6F0); // #D8E6F0
  static const inputPlaceholder = Color(0xFFA0B3C5); // #A0B3C5

  // BUTTON
  static const buttonDisabled = Color(0xFFDDE7F0); // #DDE7F0
}
