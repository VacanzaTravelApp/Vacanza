import 'dart:typed_data';

import 'package:flutter/material.dart';

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

  Widget _buildAvatar() {
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
            errorBuilder: (_, __, ___) => _placeholderAvatar(),
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
            loadingBuilder: (_, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _placeholderAvatar();
            },
            errorBuilder: (_, __, ___) => _placeholderAvatar(),
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
    return _placeholderAvatar();
  }

  Widget _placeholderAvatar() {
    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0096FF), Color(0xFF2ECC71)],
        ),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
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
          _buildAvatar(),
          const SizedBox(width: 10),

          // Texts
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF0096FF)),
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