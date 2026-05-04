import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

/// Instagram-style avatar with optional gradient story ring,
/// online dot, and smooth hero-animation support.
class AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final double radius;
  final Color? borderColor;
  final bool showOnline;
  final bool showStoryRing; // gradient ring like IG stories
  final bool hasNewStory; // ring active/inactive state
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    this.avatarUrl,
    required this.username,
    this.radius = 24,
    this.borderColor,
    this.showOnline = false,
    this.showStoryRing = false,
    this.hasNewStory = true,
    this.onTap,
  });

  Color _avatarColor(String name) {
    const palette = [
      Color(0xFF6C47FF),
      Color(0xFFFF4D6D),
      Color(0xFF00C9A7),
      Color(0xFFFFBE0B),
      Color(0xFF4CC9F0),
      Color(0xFFFF7043),
    ];
    return palette[name.isEmpty ? 0 : name.codeUnitAt(0) % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final color = _avatarColor(username);

    // Core avatar circle
    Widget avatar = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null && avatarUrl!.isNotEmpty
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initials(initial, color),
            )
          : _initials(initial, color),
    );

    // White padding ring (between photo and gradient ring)
    if (showStoryRing) {
      avatar = Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
        ),
        child: avatar,
      );

      // Gradient story ring
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasNewStory ? AppColors.storyGradient : null,
          color: hasNewStory ? null : AppColors.border,
        ),
        padding: const EdgeInsets.all(2),
        child: avatar,
      );
    } else if (borderColor != null) {
      avatar = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, color: borderColor),
        child: avatar,
      );
    }

    // Online indicator dot
    if (showOnline) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: showStoryRing ? 4 : 0,
            bottom: showStoryRing ? 4 : 0,
            child: Container(
              width: (radius * 0.38).clamp(8, 14),
              height: (radius * 0.38).clamp(8, 14),
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }

  Widget _initials(String initial, Color color) {
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.dmSans(
          color: color,
          fontSize: radius * 0.58,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}