import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A reusable avatar widget that:
/// - Tries to load [photoUrl] via network with graceful error fallback
/// - Falls back to a gender-appropriate icon (male/female) or initials (other/null)
class UserAvatarWidget extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final String? gender; // 'male' | 'female' | 'other' | null
  final double radius;

  const UserAvatarWidget({
    super.key,
    required this.displayName,
    this.photoUrl,
    this.gender,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Widget fallback;

    final g = gender?.toLowerCase();
    if (g == 'male') {
      bg = AppTheme.maleBlueBg;
      fallback = Icon(
        Icons.face_rounded,
        size: radius * 1.1,
        color: AppTheme.maleBlue,
      );
    } else if (g == 'female') {
      bg = AppTheme.femalePinkBg;
      fallback = Icon(
        Icons.face_3_rounded,
        size: radius * 1.1,
        color: AppTheme.femalePink,
      );
    } else {
      bg = AppTheme.primaryPurple.withValues(alpha: 0.14);
      fallback = Text(
        _initials(displayName),
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryPurple,
        ),
      );
    }

    if (photoUrl == null || photoUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: fallback,
      );
    }

    // Network image with error fallback
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.network(
          photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CircleAvatar(
            radius: radius,
            backgroundColor: bg,
            child: fallback,
          ),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return CircleAvatar(
              radius: radius,
              backgroundColor: bg,
              child: SizedBox(
                width: radius * 0.6,
                height: radius * 0.6,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}