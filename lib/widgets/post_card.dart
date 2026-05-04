import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import '../utils/app_theme.dart';
import '../screens/posts/post_detail_screen.dart';
import 'avatar_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PostCard  –  rich card matching the reference design:
//
//  ┌──────────────────────────────────────────────────────┐
//  │  [Avatar]  Name · timeago                 [Bookmark] │
//  │  [Urgent] [Quick Help] ...  tag pills                 │
//  │                                                       │
//  │  ████ Title (bold)                                    │
//  │  Description text (2 lines, muted)                    │
//  │                                                       │
//  │  ┌─────────────── exchange strip ──────────────────┐ │
//  │  │  OFFERING           ⇌/🎁           WANTS/OFFERS │ │
//  │  │  ★ Skill name     (badge)       Skill/Amount ↗  │ │
//  │  └─────────────────────────────────────────────────┘ │
//  └──────────────────────────────────────────────────────┘
// ─────────────────────────────────────────────────────────────────────────────

// Thumbnail palette – deterministic from skill name
const List<List<Color>> _thumbPalettes = [
  [Color(0xFFB5F0C8), Color(0xFF4CAF7D)], // mint
  [Color(0xFFFFD6A5), Color(0xFFFF9F43)], // amber
  [Color(0xFFD0BFFF), Color(0xFF6C47FF)], // violet
  [Color(0xFFFFC8DD), Color(0xFFFF4D6D)], // pink
  [Color(0xFFA0E7FF), Color(0xFF4CC9F0)], // sky
  [Color(0xFFF9F871), Color(0xFFE0C200)], // yellow
];

List<Color> _paletteFor(String s) =>
    _thumbPalettes[s.length % _thumbPalettes.length];

// Category label + icon derived from skill string
String _categoryLabel(PostModel post) {
  if (post.isOpenRequest) return 'Help';
  final skill = post.skillOffered.toLowerCase();
  if (skill.contains('design') || skill.contains('figma') || skill.contains('graphic'))
    return 'Design';
  if (skill.contains('code') ||
      skill.contains('flutter') ||
      skill.contains('python') ||
      skill.contains('react') ||
      skill.contains('dev') ||
      skill.contains('js'))
    return 'Dev';
  if (skill.contains('music') || skill.contains('guitar') || skill.contains('piano'))
    return 'Music';
  if (skill.contains('teach') || skill.contains('tutor') || skill.contains('help'))
    return 'Teach';
  return 'Skill';
}

IconData _categoryIcon(String label) {
  switch (label) {
    case 'Design':
      return Icons.palette_outlined;
    case 'Dev':
      return Icons.code_rounded;
    case 'Music':
      return Icons.music_note_rounded;
    case 'Teach':
      return Icons.school_outlined;
    case 'Help':
      return Icons.handshake_outlined;
    default:
      return Icons.star_outline_rounded;
  }
}

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onBookmarkToggle;

  const PostCard({super.key, required this.post, this.onBookmarkToggle});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 220),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _navigate() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => PostDetailScreen(post: widget.post),
        transitionsBuilder: (_, a1, a2, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkDivider : const Color(0xFFEEEEEE);
    final stripBg = isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF6F6F8);
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final textLight = isDark ? AppColors.darkTextLight : AppColors.textLight;

    final isBarter = widget.post.exchangeType == 'barter';
    final category = _categoryLabel(widget.post);
    final palette = _paletteFor(widget.post.skillOffered);

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.reverse(),
      onTapUp: (_) {
        _pressCtrl.forward();
        _navigate();
      },
      onTapCancel: () => _pressCtrl.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail / Media area ───────────────
              _Thumbnail(
                palette: palette,
                category: category,
                icon: _categoryIcon(category),
                isOpenRequest: widget.post.isOpenRequest,
                isBarter: isBarter,
              ),

              // ── Header row  (avatar + name + bookmark) ─
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Row(
                  children: [
                    AvatarWidget(
                      avatarUrl: widget.post.profile?.avatarUrl,
                      username: widget.post.profile?.username ?? '',
                      radius: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.profile?.fullName ??
                                widget.post.profile?.username ??
                                'Unknown',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            timeago.format(widget.post.createdAt),
                            style: GoogleFonts.dmSans(
                              color: textLight,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (widget.post.isOpenRequest)
                      _Pill(
                        label: 'Request',
                        color: AppColors.warning,
                        bg: AppColors.warning.withOpacity(0.12),
                      ),

                    const SizedBox(width: 4),

                    if (widget.onBookmarkToggle != null)
                      _BookmarkButton(
                        saved: widget.post.isBookmarked,
                        onTap: widget.onBookmarkToggle!,
                        isDark: isDark,
                      ),
                  ],
                ),
              ),

              // ── Tags ────────────────────────────────
              if (widget.post.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: widget.post.tags.map(_buildTag).toList(),
                  ),
                ),

              // ── Title ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Text(
                  widget.post.title,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // ── Description ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Text(
                  widget.post.description,
                  style: GoogleFonts.dmSans(
                    color: textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // ── Exchange strip ───────────────────────
              _ExchangeStrip(
                post: widget.post,
                isBarter: isBarter,
                stripBg: stripBg,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String tag) {
    Color c = AppColors.primary;
    Color bg = AppColors.primary.withOpacity(0.09);
    if (tag == 'Urgent') {
      c = AppColors.error;
      bg = AppColors.error.withOpacity(0.09);
    } else if (tag == 'Quick Help') {
      c = AppColors.warning;
      bg = AppColors.warning.withOpacity(0.09);
    } else if (tag == 'Online') {
      c = AppColors.accentTeal;
      bg = AppColors.accentTeal.withOpacity(0.09);
    } else if (tag == 'Beginner-friendly') {
      c = const Color(0xFF4CAF7D);
      bg = const Color(0xFF4CAF7D).withOpacity(0.09);
    } else if (tag == 'Flexible') {
      c = AppColors.secondary;
      bg = AppColors.secondary.withOpacity(0.09);
    }
    return _Pill(label: tag, color: c, bg: bg);
  }
}

// ── Thumbnail / Media area ────────────────────────────────
class _Thumbnail extends StatelessWidget {
  final List<Color> palette;
  final String category;
  final IconData icon;
  final bool isOpenRequest;
  final bool isBarter;

  const _Thumbnail({
    required this.palette,
    required this.category,
    required this.icon,
    required this.isOpenRequest,
    required this.isBarter,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette[0], palette[0].withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette[1].withOpacity(0.18),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -30,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette[1].withOpacity(0.12),
                ),
              ),
            ),
            // Category badge (top-left)
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette[1],
                  ),
                ),
              ),
            ),
            // Exchange type badge (top-right)
            Positioned(
              right: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  isOpenRequest
                      ? 'Open Request'
                      : isBarter
                          ? 'Barter'
                          : 'Custom',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isOpenRequest
                        ? AppColors.warning
                        : isBarter
                            ? AppColors.primary
                            : AppColors.accentTeal,
                  ),
                ),
              ),
            ),
            // Center icon
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette[1].withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: palette[1], size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exchange strip ────────────────────────────────────────
class _ExchangeStrip extends StatelessWidget {
  final PostModel post;
  final bool isBarter;
  final Color stripBg;
  final bool isDark;

  const _ExchangeStrip({
    required this.post,
    required this.isBarter,
    required this.stripBg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final leftColor = AppColors.primary;
    final rightColor = isBarter ? AppColors.secondary : AppColors.accentTeal;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: stripBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          // Offering
          Expanded(
            child: _SkillChip(
              label: post.skillOffered,
              tag: 'OFFERING',
              color: leftColor,
              icon: Icons.star_rounded,
              align: CrossAxisAlignment.start,
              isDark: isDark,
            ),
          ),

          // Centre badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient:
                    isBarter ? AppColors.primaryGradient : AppColors.mintGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isBarter ? AppColors.primary : AppColors.accentTeal)
                        .withOpacity(0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isBarter ? '⇌' : '🎁',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),

          // Wanting / offering
          Expanded(
            child: _SkillChip(
              label: isBarter
                  ? (post.skillWanted ?? 'Open')
                  : (post.customOffer ?? 'Custom'),
              tag: isBarter ? 'WANTS' : 'OFFERS',
              color: rightColor,
              icon: isBarter
                  ? Icons.sync_alt_rounded
                  : Icons.card_giftcard_rounded,
              align: CrossAxisAlignment.end,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final String tag;
  final Color color;
  final IconData icon;
  final CrossAxisAlignment align;
  final bool isDark;

  const _SkillChip({
    required this.label,
    required this.tag,
    required this.color,
    required this.icon,
    required this.align,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tagColor = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final isRight = align == CrossAxisAlignment.end;
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          tag,
          style: GoogleFonts.dmSans(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: tagColor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: isRight
              ? [
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(icon, color: color, size: 13),
                ]
              : [
                  Icon(icon, color: color, size: 13),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
        ),
      ],
    );
  }
}

// ── Bookmark button with pop animation ───────────────────
class _BookmarkButton extends StatefulWidget {
  final bool saved;
  final VoidCallback onTap;
  final bool isDark;
  const _BookmarkButton(
      {required this.saved, required this.onTap, required this.isDark});

  @override
  State<_BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends State<_BookmarkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _tap() {
    HapticFeedback.lightImpact();
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final inactiveColor =
        widget.isDark ? AppColors.darkTextLight : AppColors.textLight;
    return GestureDetector(
      onTap: _tap,
      child: ScaleTransition(
        scale: _scale,
        child: Icon(
          widget.saved
              ? Icons.bookmark_rounded
              : Icons.bookmark_outline_rounded,
          color: widget.saved ? AppColors.primary : inactiveColor,
          size: 22,
        ),
      ),
    );
  }
}

// ── Reusable pill label ───────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Pill({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}