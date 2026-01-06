import 'package:flutter/material.dart';

/// Sol üstte görünen profil chip/badge.
/// Şimdilik mock data ile çalışır.
/// Backend user info geldiğinde buraya bağlanacak.
class ProfileBadge extends StatelessWidget {
  final String name;
  final String subtitle;

  /// ✅ opsiyonel: asset path (örn: assets/core/theme/profile/serhat.jpg)
  final String? imagePath;

  const ProfileBadge({
    super.key,
    required this.name,
    required this.subtitle,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = (imagePath != null && imagePath!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasImage
                  ? null
                  : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0096FF),
                  Color(0xFF2ECC71),
                ],
              ),
              image: hasImage
                  ? DecorationImage(
                image: AssetImage(imagePath!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: hasImage
                ? null
                : const Icon(Icons.person, color: Colors.white, size: 20),
          ),

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
  }
}