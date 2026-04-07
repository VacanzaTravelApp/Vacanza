// Profile UI — shared styles matching Figma/React reference.
// Use across profile cards; no BLoC or API logic.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

// ─── Colors ─────────────────────────────────────────────────────────────────

abstract final class ProfileUIColors {
  ProfileUIColors._();

  static const profileGreen = Color(0xFF2ECC71);
  static const profileGreenDark = Color(0xFF27AE60);
  static const profileAmber = Color(0xFFFFD166);
  static const profileOrange = Color(0xFFF4A261);
  static const profileRed = Color(0xFFEF4444);

  static const profileGray400 = Color(0xFF9CA3AF);
  static const profileGray500 = Color(0xFF6B7280);
  static const profileGray800 = Color(0xFF1F2937);
}

// ─── Card decoration ─────────────────────────────────────────────────────────

abstract final class ProfileCardDecoration {
  ProfileCardDecoration._();

  static BoxDecoration card(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.mapControlAccent;
    return BoxDecoration(
      color: isDark
          ? cs.surface.withValues(alpha: 0.92)
          : context.lightGlassPanelColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        // Frame should match "Ask Vacanza" accent family.
        color: accent.withValues(alpha: isDark ? 0.28 : 0.22),
      ),
      boxShadow: [
        BoxShadow(
          color: cs.shadow.withValues(alpha: isDark ? 0.20 : 0.06),
          blurRadius: isDark ? 18 : 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

/// Menu row cards: frosted glass in light mode, solid in dark.
Widget profileGlassMenuCard({
  required BuildContext context,
  required Widget child,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final decoration = ProfileCardDecoration.card(context);
  if (isDark) {
    return Container(decoration: decoration, child: child);
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        decoration: decoration,
        child: child,
      ),
    ),
  );
}

// ─── Icon container gradients ────────────────────────────────────────────────

abstract final class ProfileIconGradient {
  ProfileIconGradient._();

  static LinearGradient stats = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ProfileUIColors.profileGreen, ProfileUIColors.profileGreenDark],
  );

  static LinearGradient checkIn(BuildContext context) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [context.vacanzaTokens.vividCoral, context.mapControlAccent],
  );

  static LinearGradient editProfile(BuildContext context) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: context.mapControlActiveGradientColors,
  );

  static LinearGradient achievements(BuildContext context) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [context.vacanzaTokens.vividAmber, context.vacanzaTokens.vividCoral],
  );
}

/// Icon container 48x48, rounded 16.
///
/// No colored background (requested): uses neutral surface + accent border/ring.
Widget profileIconContainer({
  required BuildContext context,
  required Color accentColor,
  required IconData icon,
}) {
  final cs = Theme.of(context).colorScheme;
  final isLight = Theme.of(context).brightness == Brightness.light;
  return Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: isLight ? context.lightGlassFieldFill : cs.surface.withValues(alpha: 0.6),
      border: Border.all(color: accentColor.withValues(alpha: 0.55), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.10),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Icon(icon, size: 22, color: accentColor),
  );
}

/// Small icon container 36x36, rounded 12, tint background (no gradient).
Widget profileAccountIconContainer({
  required BuildContext context,
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

  static Widget categoryPill(BuildContext context, String label) {
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        ),
      ),
    );
  }

  static Widget extraPill(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }

  static Widget dietaryPill(BuildContext context, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: cs.onErrorContainer,
        ),
      ),
    );
  }
}

// ─── Section label ──────────────────────────────────────────────────────────

TextStyle profileSectionLabelStyle(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: cs.onSurfaceVariant,
    letterSpacing: 1.0,
  );
}

// ─── Stat tile ───────────────────────────────────────────────────────────────

const EdgeInsets _statTilePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

Widget profileStatTile({
  required BuildContext context,
  required Widget title,
  required String subtitle,
}) {
  final cs = Theme.of(context).colorScheme;
  final isLight = Theme.of(context).brightness == Brightness.light;
  return Container(
    padding: _statTilePadding,
    decoration: BoxDecoration(
      color: isLight
          ? context.lightGlassFieldFill
          : cs.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: isLight
            ? context.mapControlAccent.withValues(alpha: 0.14)
            : cs.outline.withValues(alpha: 0.2),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultTextStyle(
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: title,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant,
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
