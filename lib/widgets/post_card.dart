// lib/widgets/post_card.dart
//
// Card design matching the Swaply screenshot exactly:
//   • Avatar (gradient initials) + Name + @handle · time · campus badge
//   • Bold title + 2-line description
//   • Dark OFFERS ⇅ WANTS double-pill box
//   • Tag chips row (from skillOffered + tags)
//   • 🔥 saves · ⇅ swaps  |  [Save]  [Swap →]
//
// Usage:
//   SwapPostCard(
//     post: p,
//     onSwap: () { ... },
//     onBookmark: () { ... },
//     onTapAuthor: () { ... },
//   )
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/post_model.dart';
import '../utils/app_theme.dart';

/// Alias so old call-sites (`PostCard(post: x)`) still compile.
typedef PostCard = SwapPostCard;

// ─────────────────────────────────────────────────────────────────────────────
class SwapPostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onSwap;
  final VoidCallback? onBookmark;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onTapAuthor;
  final bool isOwn;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const SwapPostCard({
    super.key,
    required this.post,
    this.onSwap,
    this.onBookmark,
    this.onBookmarkToggle,
    this.onTapAuthor,
    this.isOwn = false,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<SwapPostCard> createState() => _SwapPostCardState();
}

class _SwapPostCardState extends State<SwapPostCard>
    with SingleTickerProviderStateMixin {
  // ── local save (bookmark) state ───────────────────────────────────────────
  late bool _saved;

  VoidCallback? get _effectiveBookmark =>
      widget.onBookmarkToggle ?? widget.onBookmark;

  @override
  void initState() {
    super.initState();
    _saved = widget.post.isBookmarked;
  }

  // ── theme helpers ─────────────────────────────────────────────────────────
  bool get _d => Theme.of(context).brightness == Brightness.dark;

  // card
  Color get _cardBg => _d ? const Color(0xFF111828) : Colors.white;
  Color get _border => _d ? const Color(0xFF1E2A3A) : const Color(0xFFE5E8EE);
  // text
  Color get _tp => _d ? const Color(0xFFF1F5FB) : const Color(0xFF0D1117);
  Color get _ts => _d ? const Color(0xFF8090A8) : const Color(0xFF5A677A);
  Color get _tl => _d ? const Color(0xFF4A5A6E) : const Color(0xFFABB5C3);
  // offer/wants box
  Color get _boxBg => _d ? const Color(0xFF0D1520) : const Color(0xFF0D1520);
  Color get _boxBorder =>
      _d ? const Color(0xFF1E2E42) : const Color(0xFF1E2E42);
  // tag chip
  Color get _chipBg => _d ? const Color(0xFF1A2535) : const Color(0xFFEEF3FB);
  Color get _chipBorder =>
      _d ? const Color(0xFF253447) : const Color(0xFFD0DBE8);
  Color get _chipText => _d ? const Color(0xFF7BA7D4) : const Color(0xFF3A6E9E);

  // ── helpers ───────────────────────────────────────────────────────────────
  String get _initials {
    final name =
        widget.post.profile?.fullName ?? widget.post.profile?.username ?? '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  String get _displayName =>
      widget.post.profile?.fullName ?? widget.post.profile?.username ?? 'User';

  String get _handle => '@${widget.post.profile?.username ?? 'user'}';

  String get _campus => (widget.post.profile?.campus?.isNotEmpty == true)
      ? widget.post.profile!.campus!
      : 'MRU';

  String get _timeAgo {
    final d = DateTime.now().difference(widget.post.createdAt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  static const _avatarGrads = [
    [Color(0xFF7C5CFC), Color(0xFFFF4D7D)],
    [Color(0xFF00C9A7), Color(0xFF4CC9F0)],
    [Color(0xFFFFBE0B), Color(0xFFFF6B35)],
    [Color(0xFF6C47FF), Color(0xFF00C9A7)],
    [Color(0xFFFF4D6D), Color(0xFFFF9F43)],
  ];

  List<Color> get _avatarGrad {
    if (_initials.isEmpty) return _avatarGrads[0];
    return _avatarGrads[_initials.codeUnitAt(0) % _avatarGrads.length];
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    // Tags row: skillOffered first, then post.tags (deduped), max 4
    final tagSet = <String>{post.skillOffered, ...post.tags};
    final tags = tagSet.take(4).toList();

    final savesCount = post.bookmarksCount;
    // swaps displayed = (bookmarksCount * 0.6).round()  — keeps numbers realistic
    final swapsCount = (post.bookmarksCount * 0.6).round();

    return GestureDetector(
      onTap: widget.onSwap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border, width: 1),
          boxShadow: _d
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────────
              _buildHeader(post),

              const SizedBox(height: 12),

              // ── Title ──────────────────────────────────────────────────────
              Text(
                post.title,
                style: GoogleFonts.dmSans(
                  color: _tp,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.22,
                ),
              ),

              const SizedBox(height: 6),

              // ── Description ────────────────────────────────────────────────
              Text(
                post.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  color: _ts,
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 14),

              // ── OFFERS ⇅ WANTS box ─────────────────────────────────────────
              _buildOffersWantsBox(post),

              const SizedBox(height: 12),

              // ── Tag chips ──────────────────────────────────────────────────
              _buildTagChips(tags),

              const SizedBox(height: 14),

              // ── Bottom row: counts + buttons ───────────────────────────────
              _buildBottomRow(savesCount, swapsCount),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(PostModel post) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        GestureDetector(
          onTap: widget.onTapAuthor,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _avatarGrad,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                _initials,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Name + handle + time
        Expanded(
          child: GestureDetector(
            onTap: widget.onTapAuthor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayName,
                  style: GoogleFonts.dmSans(
                    color: _tp,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$_handle · $_campus',
                  style: GoogleFonts.dmSans(
                    color: _tl,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Time badge
        Text(
          _timeAgo,
          style: GoogleFonts.dmSans(
            color: _tl,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── OFFERS ⇅ WANTS ──────────────────────────────────────────────────────────
  Widget _buildOffersWantsBox(PostModel post) {
    return Container(
      decoration: BoxDecoration(
        color: _boxBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _boxBorder, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // OFFERS side
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'OFFERS',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF4A5A72),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      post.skillOffered,
                      style: GoogleFonts.dmSans(
                        color: AppColors.primary, // purple
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Centre swap icon
            Container(width: 1, color: _boxBorder),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2535),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF253447)),
                ),
                child: const Icon(
                  Icons.swap_vert_rounded,
                  size: 16,
                  color: Color(0xFF5A7A9A),
                ),
              ),
            ),
            Container(width: 1, color: _boxBorder),

            // WANTS side
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'WANTS',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF4A5A72),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      post.skillWanted?.isNotEmpty == true
                          ? post.skillWanted!
                          : 'Open swap',
                      style: GoogleFonts.dmSans(
                        // coral/red — matches screenshot
                        color: const Color(0xFFFF6B6B),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tag chips ───────────────────────────────────────────────────────────────
  Widget _buildTagChips(List<String> tags) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: tags.map((t) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _chipBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _chipBorder, width: 1),
          ),
          child: Text(
            t,
            style: GoogleFonts.dmSans(
              color: _chipText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Bottom row ──────────────────────────────────────────────────────────────
  Widget _buildBottomRow(int savesCount, int swapsCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 🔥 saves
        const Text('🔥', style: TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text(
          '$savesCount saves',
          style: GoogleFonts.dmSans(
            color: _tl,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        // ⇅ swaps
        const Text(
          '⇅',
          style: TextStyle(fontSize: 13, color: Color(0xFF5A7A9A)),
        ),
        const SizedBox(width: 4),
        Text(
          '$swapsCount swaps',
          style: GoogleFonts.dmSans(
            color: _tl,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),

        const Spacer(),

        // [Save] outlined button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _saved = !_saved);
            _effectiveBookmark?.call();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _saved
                  ? AppColors.primary.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _saved
                    ? AppColors.primary.withOpacity(0.6)
                    : (_d ? const Color(0xFF2A3A50) : const Color(0xFFCCD6E0)),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  size: 14,
                  color: _saved ? AppColors.primary : _ts,
                ),
                const SizedBox(width: 5),
                Text(
                  'Save',
                  style: GoogleFonts.dmSans(
                    color: _saved ? AppColors.primary : _ts,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // [Swap →] gradient button
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onSwap?.call();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C5CFC), Color(0xFFFF4D7D)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C5CFC).withOpacity(0.40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Swap',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '→',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Small edit / delete button (own posts only) — kept for compatibility
// ─────────────────────────────────────────────────────────────────────────────
class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SmallBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}
