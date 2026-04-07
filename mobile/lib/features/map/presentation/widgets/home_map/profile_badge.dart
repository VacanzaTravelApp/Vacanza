import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// Profile chip/badge (map top-left). Avatar from [profilePhotoBytes], then [imageUrl], [imagePath], or placeholder.
class ProfileBadge extends StatelessWidget {
  final String name;
  final String subtitle;

  /// Binary photo from [GET /users/me/profile/photo] when [UserProfile.hasProfilePhoto].
  final Uint8List? profilePhotoBytes;

  /// Network URL for profile image (from profile.profileImageUrl).
  final String? imageUrl;

  /// Optional asset path (e.g. for local placeholder).
  final String? imagePath;

  final VoidCallback? onTap;

  const ProfileBadge({
    super.key,
    required this.name,
    required this.subtitle,
    this.profilePhotoBytes,
    this.imageUrl,
    this.imagePath,
    this.onTap,
  });

  static const double _avatarSize = 38;

  Widget _buildAvatar(BuildContext context) {
    final hasBytes =
        profilePhotoBytes != null && profilePhotoBytes!.isNotEmpty;
    if (hasBytes) {
      return ClipOval(
        child: SizedBox(
          width: _avatarSize,
          height: _avatarSize,
          child: Image.memory(
            profilePhotoBytes!,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            errorBuilder: (ctx, __, ___) => _placeholderAvatar(ctx),
          ),
        ),
      );
    }
    final hasNetworkUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final hasAssetPath = imagePath != null && imagePath!.isNotEmpty;
    if (hasNetworkUrl) {
      return ClipOval(
        child: SizedBox(
          width: _avatarSize,
          height: _avatarSize,
          child: Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            loadingBuilder: (ctx, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _placeholderAvatar(ctx);
            },
            errorBuilder: (ctx, __, ___) => _placeholderAvatar(ctx),
          ),
        ),
      );
    }
    if (hasAssetPath) {
      return ClipOval(
        child: SizedBox(
          width: _avatarSize,
          height: _avatarSize,
          child: Image.asset(
            imagePath!,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
      );
    }
    return _placeholderAvatar(context);
  }

  Widget _placeholderAvatar(BuildContext context) {
    final colors = context.mapControlActiveGradientColors;
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final child = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: t.pillSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.pillBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatar(context),
          const SizedBox(width: 10),

          // Texts
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.mapControlAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: child);
    }
    return child;
  }
}