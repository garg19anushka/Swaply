import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

/// Rounded-square avatar: dark background, purple border, purple bold
/// initials — shows the real profile photo (avatarUrl) when present,
/// falling back to initials otherwise. Used everywhere a person's
/// avatar appears, so the look stays consistent across the whole app.
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

  static const _purple = Color(0xFF8C7CFF);

  @override
  Widget build(BuildContext context) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final side = radius * 2;
    final cornerRadius = side * 0.32;

    // Core avatar square
    Widget avatar = Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cornerRadius),
        color: const Color(0xFF1A1A2C),
        border: Border.all(color: borderColor ?? _purple, width: 1.4),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null && avatarUrl!.isNotEmpty
          ? Image.network(
              avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initials(initial),
            )
          : _initials(initial),
    );

    // White padding ring (between photo and gradient ring)
    if (showStoryRing) {
      avatar = Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cornerRadius + 3),
          color: AppColors.surface,
        ),
        child: avatar,
      );

      // Gradient story ring
      avatar = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cornerRadius + 5),
          gradient: hasNewStory ? AppColors.storyGradient : null,
          color: hasNewStory ? null : AppColors.border,
        ),
        padding: const EdgeInsets.all(2),
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
            right: showStoryRing ? 4 : -1,
            bottom: showStoryRing ? 4 : -1,
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

  Widget _initials(String initial) {
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.dmSans(
          color: _purple,
          fontSize: radius * 0.58,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
