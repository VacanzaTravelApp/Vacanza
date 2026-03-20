// Profile UI — shared styles matching Figma/React reference.
// Use across profile cards; no BLoC or API logic.

import 'package:flutter/material.dart';

// ─── Colors ─────────────────────────────────────────────────────────────────

abstract final class ProfileUIColors {
  ProfileUIColors._();

  static const profileBlue = Color(0xFF0096FF);
  static const profileBlueLight = Color(0xFF00C6FF);
  static const profileGreen = Color(0xFF2ECC71);
  static const profileGreenDark = Color(0xFF27AE60);
  static const profileAmber = Color(0xFFFFD166);
  static const profileOrange = Color(0xFFF4A261);
  static const profileRed = Color(0xFFEF4444);

  static const profileGray100 = Color(0xFFF3F4F6);
  static const profileGray400 = Color(0xFF9CA3AF);
  static const profileGray500 = Color(0xFF6B7280);
  static const profileGray800 = Color(0xFF1F2937);

  static const profileBg = Color(0xFFFAFAFA);
  static const profileRed50 = Color(0xFFFEF2F2);
}

// ─── Card decoration ─────────────────────────────────────────────────────────

abstract final class ProfileCardDecoration {
  ProfileCardDecoration._();

  static BoxDecoration card() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

// ─── Icon container gradients ────────────────────────────────────────────────

abstract final class ProfileIconGradient {
  ProfileIconGradient._();

  static const gamification = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ProfileUIColors.profileAmber, ProfileUIColors.profileOrange],
  );

  static const travelPrefs = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ProfileUIColors.profileBlue, ProfileUIColors.profileBlueLight],
  );

  static const stats = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ProfileUIColors.profileGreen, ProfileUIColors.profileGreenDark],
  );

  static const checkIn = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ProfileUIColors.profileAmber, ProfileUIColors.profileOrange],
  );
}

/// Icon container 48x48, rounded 16, with gradient and optional icon.
Widget profileIconContainer({
  required LinearGradient gradient,
  required Widget icon,
  List<BoxShadow>? boxShadow,
}) {
  return Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: gradient,
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
    ),
    child: IconTheme(
      data: const IconThemeData(color: Colors.white, size: 24),
      child: icon,
    ),
  );
}

/// Small icon container 36x36, rounded 12, tint background (no gradient).
Widget profileAccountIconContainer({
  required Color backgroundColor,
  required Color iconColor,
  required IconData icon,
}) {
  return Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: backgroundColor,
    ),
    child: Icon(icon, size: 20, color: iconColor),
  );
}

// ─── Chip styles ────────────────────────────────────────────────────────────

abstract final class ProfileChipStyle {
  ProfileChipStyle._();

  static Widget categoryPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ProfileUIColors.profileBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: ProfileUIColors.profileBlue,
        ),
      ),
    );
  }

  static Widget extraPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ProfileUIColors.profileGray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: ProfileUIColors.profileGray500,
        ),
      ),
    );
  }

  static Widget dietaryPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ProfileUIColors.profileRed50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: ProfileUIColors.profileRed,
        ),
      ),
    );
  }
}

// ─── Section label ──────────────────────────────────────────────────────────

const TextStyle profileSectionLabelStyle = TextStyle(
  fontSize: 10,
  fontWeight: FontWeight.w600,
  color: ProfileUIColors.profileGray400,
  letterSpacing: 1.0,
);

// ─── Stat tile ───────────────────────────────────────────────────────────────

const EdgeInsets _statTilePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

Widget profileStatTile({
  required Widget title,
  required String subtitle,
}) {
  return Container(
    padding: _statTilePadding,
    decoration: BoxDecoration(
      color: ProfileUIColors.profileBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: ProfileUIColors.profileGray100),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultTextStyle(
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ProfileUIColors.profileGray800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: title,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: ProfileUIColors.profileGray500,
          ),
        ),
      ],
    ),
  );
}

// ─── Summary row (label + value) ──────────────────────────────────────────────

const double _summaryLabelWidth = 90;

Widget profileSummaryRow({
  required String label,
  required Widget value,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _summaryLabelWidth,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: ProfileUIColors.profileGray400,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: value),
      ],
    ),
  );
}
