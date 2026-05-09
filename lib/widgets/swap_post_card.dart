// lib/widgets/swap_post_card.dart
//
// ─── STEP-BY-STEP SETUP ────────────────────────────────────────────────────
//
// 1. Save this file as:  lib/widgets/swap_post_card.dart
//
// 2. Open lib/screens/feed/feed_screen.dart and DELETE the entire bodies of:
//      class SwapPostCard ...  (and its State class _SwapPostCardState)
//      class _SkillPill ...
//      class _SmallBtn  ...
//    Then add at the top of feed_screen.dart:
//      import 'package:Swaply/widgets/swap_post_card.dart';
//
// 3. Add the same import to:
//      lib/screens/profile/profile_screen.dart
//      lib/screens/profile/user_profile_screen.dart
//      lib/screens/posts/open_requests_screen.dart
//
// No other changes needed anywhere.  PostCard / SwapPostCard both work.
// ───────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Swaply/models/post_model.dart';
import 'package:Swaply/utils/app_theme.dart';
import 'package:Swaply/widgets/avatar_widget.dart'; // real profile photo

/// [PostCard] is an alias so old call-sites like `PostCard(post: x)` compile.
typedef PostCard = SwapPostCard;

// ─────────────────────────────────────────────────────────────────────────────
//  SwapPostCard
// ─────────────────────────────────────────────────────────────────────────────
class SwapPostCard extends StatefulWidget {
  final PostModel post;

  /// Opens the post detail. Tapping the card body also triggers this.
  final VoidCallback? onSwap;

  /// Bookmark icon tapped.
  final VoidCallback? onBookmark;

  /// Alias used by open_requests_screen — wins over [onBookmark] if both set.
  final VoidCallback? onBookmarkToggle;

  /// Author avatar / name tapped.
  final VoidCallback? onTapAuthor;

  /// Shows edit + delete buttons when the current user owns this post.
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
  bool _liked = false;
  late int _likeCount;
  late AnimationController _likeCtrl;
  late Animation<double> _likeScale;

  VoidCallback? get _effectiveBookmark =>
      widget.onBookmarkToggle ?? widget.onBookmark;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.bookmarksCount;
    _likeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.75,
      upperBound: 1.0,
      value: 1.0,
    );
    _likeScale = CurvedAnimation(parent: _likeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _likeCtrl.dispose();
    super.dispose();
  }

  void _toggleLike() {
    HapticFeedback.lightImpact();
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
    _likeCtrl.reverse().then((_) => _likeCtrl.forward());
  }

  // ── Theme ────────────────────────────────────────────────────────────────
  bool get _d => Theme.of(context).brightness == Brightness.dark;

  Color get _cardBg => _d ? const Color(0xFF111126) : Colors.white;
  Color get _border => _d ? const Color(0xFF252540) : AppColors.border;
  Color get _tp => _d ? const Color(0xFFF0F0FF) : AppColors.textPrimary;
  Color get _ts => _d ? const Color(0xFF9090B0) : AppColors.textSecondary;
  Color get _tl => _d ? const Color(0xFF555575) : AppColors.textLight;
  Color get _divider => _d ? const Color(0xFF1E1E38) : const Color(0xFFEEEEEE);

  // ── Data helpers ─────────────────────────────────────────────────────────
  String get _username => widget.post.profile?.username ?? 'user';
  String get _displayName =>
      widget.post.profile?.fullName ?? widget.post.profile?.username ?? 'User';

  /// Pass null when empty — AvatarWidget shows coloured initials as fallback.
  String? get _avatarUrl {
    final u = widget.post.profile?.avatarUrl ?? '';
    return u.isNotEmpty ? u : null;
  }

  String get _timeAgo {
    final d = DateTime.now().difference(widget.post.createdAt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  int get _daysLeft {
    final expiry = widget.post.createdAt.add(const Duration(days: 7));
    return expiry.difference(DateTime.now()).inDays.clamp(0, 99);
  }

  bool get _isAvailableNow =>
      DateTime.now().difference(widget.post.createdAt).inHours < 24;

  String get _availLabel {
    if (_isAvailableNow) return 'Available now';
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return 'Busy till ${days[DateTime.now().add(const Duration(days: 2)).weekday - 1]}';
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final rating = post.profile?.averageRating ?? 0.0;
    final campus = (post.profile?.campus?.isNotEmpty == true)
        ? post.profile!.campus!
        : 'MRU';
    final swapCount = post.bookmarksCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: 1),
        boxShadow: _d
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 6),
                ),
              ]
            : AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: widget.onSwap,
          borderRadius: BorderRadius.circular(18),
          splashColor: AppColors.primary.withOpacity(0.06),
          highlightColor: AppColors.primary.withOpacity(0.03),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(post, rating, campus),
                const SizedBox(height: 14),

                // ── Title ─────────────────────────────────────────────
                Text(
                  post.title,
                  style: GoogleFonts.dmSans(
                    color: _tp,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 7),

                // ── Description ───────────────────────────────────────
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
                const SizedBox(height: 13),

                _buildSkillPills(post),
                const SizedBox(height: 11),

                if (post.skillWanted != null &&
                    post.skillWanted!.trim().isNotEmpty) ...[
                  _buildWantsLine(post.skillWanted!),
                  const SizedBox(height: 11),
                ],

                _buildStatusRow(swapCount),

                if (_daysLeft <= 7) ...[
                  const SizedBox(height: 9),
                  _buildExpiry(),
                ],

                const SizedBox(height: 12),
                Divider(height: 1, color: _divider),
                const SizedBox(height: 10),

                _buildActions(), // ← no Swap button inside
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Header  — AvatarWidget shows the REAL profile photo from Supabase.
  //  If the user has no photo uploaded, AvatarWidget falls back to
  //  a coloured circle with initials — exactly like the profile screen.
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(PostModel post, double rating, String campus) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Profile photo (real data) ─────────────────────────────────
        GestureDetector(
          onTap: widget.onTapAuthor,
          child: AvatarWidget(
            avatarUrl: _avatarUrl, // null → shows initials fallback
            username: _username, // used for initials + colour seed
            radius: 23, // 46 px total — same size as before
          ),
        ),

        const SizedBox(width: 11),

        // ── Name + meta ───────────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTap: widget.onTapAuthor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: GoogleFonts.dmSans(
                    color: _tp,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '@$_username',
                      style: GoogleFonts.dmSans(color: _tl, fontSize: 11.5),
                    ),
                    _dot(),
                    Text(
                      _timeAgo,
                      style: GoogleFonts.dmSans(color: _tl, fontSize: 11.5),
                    ),
                    if (rating > 0) ...[
                      _dot(),
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Color(0xFFFFBE0B),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: GoogleFonts.dmSans(
                          color: _tl,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Campus badge ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: _d ? const Color(0xFF222240) : const Color(0xFFF0F0F8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _d ? const Color(0xFF333360) : const Color(0xFFDDDDEE),
            ),
          ),
          child: Text(
            campus,
            style: GoogleFonts.dmSans(
              color: _ts,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Skill pills ──────────────────────────────────────────────────────────
  Widget _buildSkillPills(PostModel post) {
    final skills = <String>{post.skillOffered, ...post.tags};
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills
          .take(4)
          .map((s) => _SkillPill(label: s, dark: _d))
          .toList(),
    );
  }

  // ── Wants line ───────────────────────────────────────────────────────────
  Widget _buildWantsLine(String skillWanted) {
    final parts = skillWanted
        .split(RegExp(r'[,/&]|\band\b', caseSensitive: false))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Row(
      children: [
        Text(
          'Wants: ',
          style: GoogleFonts.dmSans(
            color: _tl,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            parts.join(' · '),
            style: GoogleFonts.dmSans(
              color: const Color(0xFF4CC9F0),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Status row ───────────────────────────────────────────────────────────
  Widget _buildStatusRow(int swapCount) {
    final dot = _isAvailableNow
        ? const Color(0xFF00C9A7)
        : const Color(0xFFFFBE0B);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: dot.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: dot.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                _availLabel,
                style: GoogleFonts.dmSans(
                  color: dot,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (swapCount > 0) ...[
          const SizedBox(width: 10),
          const Text('✅', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$swapCount swap${swapCount == 1 ? '' : 's'} completed via this post',
              style: GoogleFonts.dmSans(
                color: const Color(0xFF00C9A7),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  // ── Expiry ───────────────────────────────────────────────────────────────
  Widget _buildExpiry() => Row(
    children: [
      const Text('⏳', style: TextStyle(fontSize: 12)),
      const SizedBox(width: 5),
      Text(
        _daysLeft == 0
            ? 'Expires today!'
            : 'Expires in $_daysLeft day${_daysLeft == 1 ? '' : 's'}',
        style: GoogleFonts.dmSans(
          color: const Color(0xFFFFBE0B),
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  //  Actions row — "Swap →" button is intentionally NOT here
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildActions() {
    return Row(
      children: [
        // Like with bounce
        ScaleTransition(
          scale: _likeScale,
          child: GestureDetector(
            onTap: _toggleLike,
            child: Row(
              children: [
                Icon(
                  _liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  size: 20,
                  color: _liked ? AppColors.secondary : _tl,
                ),
                const SizedBox(width: 4),
                Text(
                  '$_likeCount',
                  style: GoogleFonts.dmSans(
                    color: _liked ? AppColors.secondary : _tl,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Comment count
        GestureDetector(
          onTap: widget.onSwap,
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 19, color: _tl),
              const SizedBox(width: 4),
              Text(
                '${(_likeCount * 0.25).round()}',
                style: GoogleFonts.dmSans(
                  color: _tl,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 14),

        // Bookmark
        GestureDetector(
          onTap: _effectiveBookmark,
          child: Icon(
            widget.post.isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_outline_rounded,
            size: 20,
            color: widget.post.isBookmarked ? AppColors.primary : _tl,
          ),
        ),

        const Spacer(),

        // Own post: edit + delete only — NO Swap button
        if (widget.isOwn) ...[
          _SmallBtn(
            icon: Icons.edit_outlined,
            color: AppColors.primary,
            onTap: widget.onEdit ?? () {},
          ),
          const SizedBox(width: 8),
          _SmallBtn(
            icon: Icons.delete_outline_rounded,
            color: AppColors.error,
            onTap: widget.onDelete ?? () {},
          ),
        ],
      ],
    );
  }

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: Text('·', style: TextStyle(color: _tl, fontSize: 12)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Coral skill pill
// ─────────────────────────────────────────────────────────────────────────────
class _SkillPill extends StatelessWidget {
  final String label;
  final bool dark;
  const _SkillPill({required this.label, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFFFF4D6D).withOpacity(0.13)
            : const Color(0xFFFF4D6D).withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFFF4D6D).withOpacity(dark ? 0.35 : 0.22),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: dark ? const Color(0xFFFF7A9A) : const Color(0xFFCC2244),
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Small edit / delete button (own posts only)
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
