// ============================================================
//  swap_post_card.dart
//
//  Matches the screenshot exactly:
//  • Avatar (initials) + name + handle + time + star rating + campus badge
//  • Bold title, grey description
//  • Coral/pink skill pills (offered)
//  • "Wants:" line in muted label + coloured skill names
//  • Online now pill + swap-count badge
//  • Expiry warning line
//  • Like / Comment / Bookmark icons at bottom left
//  • Gradient "Swap →" pill button at bottom right
//
//  USAGE — replace PostCard in feed_screen.dart:
//    import '../../widgets/swap_post_card.dart';
//    SwapPostCard(
//      post: p,
//      onSwap: () => _openPostDetail(p),
//      onBookmark: () => ps.toggleBookmark(p.id),
//      onTapAuthor: () => _openUserProfile(p.userId),
//    )
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/post_model.dart';
import '../utils/app_theme.dart';

class SwapPostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback onSwap;
  final VoidCallback onBookmark;
  final VoidCallback onTapAuthor;

  /// If true the card is "own" – shows edit/delete instead of like
  final bool isOwn;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const SwapPostCard({
    super.key,
    required this.post,
    required this.onSwap,
    required this.onBookmark,
    required this.onTapAuthor,
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
  int _likeCount = 0;
  late AnimationController _likeCtrl;
  late Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.bookmarksCount; // reuse bookmarks as like proxy
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
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
    _likeCtrl.reverse().then((_) => _likeCtrl.forward());
  }

  // ── Theme helpers ──────────────────────────────────────────
  bool get _d => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _d ? const Color(0xFF141420) : Colors.white;
  Color get _cardBorder => _d ? const Color(0xFF2A2A3E) : AppColors.border;
  Color get _tp => _d ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get _ts => _d ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get _tl => _d ? AppColors.darkTextLight : AppColors.textLight;

  // ── Days until expiry (mock: posts expire 7 days after creation) ──────────
  int get _daysLeft {
    final expiry = widget.post.createdAt.add(const Duration(days: 7));
    return expiry.difference(DateTime.now()).inDays.clamp(0, 99);
  }

  bool get _isAvailable {
    // Simple heuristic: available if created within 1 day
    return DateTime.now().difference(widget.post.createdAt).inHours < 24;
  }

  // ── Initials from name ────────────────────────────────────
  String get _initials {
    final name =
        widget.post.profile?.fullName ?? widget.post.profile?.username ?? '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  // ── Time ago string ───────────────────────────────────────
  String get _timeAgo {
    final diff = DateTime.now().difference(widget.post.createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── Avatar gradient per initials ──────────────────────────
  static const _avatarGrads = [
    [Color(0xFF7C5CFC), Color(0xFFFF4D7D)], // purple-pink
    [Color(0xFF00C9A7), Color(0xFF4CC9F0)], // teal-cyan
    [Color(0xFFFFBE0B), Color(0xFFFF4D6D)], // amber-coral
    [Color(0xFF6C47FF), Color(0xFF00C9A7)], // violet-mint
    [Color(0xFFFF4D6D), Color(0xFFFF9F43)], // coral-orange
  ];

  List<Color> get _avatarGrad {
    final idx = _initials.codeUnitAt(0) % _avatarGrads.length;
    return _avatarGrads[idx];
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final rating = post.profile?.averageRating ?? 0.0;
    final campus = post.profile?.campus ?? 'MRU';

    return GestureDetector(
      onTap: widget.onSwap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder, width: 1),
          boxShadow: _d
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AppShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── ROW 1: Avatar + Name + Handle + Time + Rating + Campus ──
              _buildHeader(post, rating, campus),

              const SizedBox(height: 14),

              // ── ROW 2: Title ─────────────────────────────────────────────
              Text(
                post.title,
                style: GoogleFonts.dmSans(
                  color: _tp,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 6),

              // ── ROW 3: Description ────────────────────────────────────────
              Text(
                post.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  color: _ts,
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 12),

              // ── ROW 4: Skill pills (offered) ──────────────────────────────
              _buildSkillPills(post),

              const SizedBox(height: 10),

              // ── ROW 5: Wants line ─────────────────────────────────────────
              if (post.skillWanted != null && post.skillWanted!.isNotEmpty)
                _buildWantsLine(post.skillWanted!),

              const SizedBox(height: 10),

              // ── ROW 6: Online badge + swap count ──────────────────────────
              _buildStatusRow(post),

              const SizedBox(height: 8),

              // ── ROW 7: Expiry ─────────────────────────────────────────────
              if (_daysLeft <= 7) _buildExpiry(),

              const SizedBox(height: 10),

              // ── DIVIDER ───────────────────────────────────────────────────
              Divider(
                height: 1,
                color: _d ? const Color(0xFF2A2A3E) : const Color(0xFFEEEEEE),
              ),

              const SizedBox(height: 10),

              // ── ROW 8: Actions ────────────────────────────────────────────
              _buildActions(),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.05, curve: Curves.easeOutCubic),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Header
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeader(PostModel post, double rating, String campus) {
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
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _initials,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Name + handle + time + rating
        Expanded(
          child: GestureDetector(
            onTap: widget.onTapAuthor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name row
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        post.profile?.fullName ??
                            post.profile?.username ??
                            'User',
                        style: GoogleFonts.dmSans(
                          color: _tp,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                // Handle · time · ⭐ rating
                Row(
                  children: [
                    Text(
                      '@${post.profile?.username ?? 'user'}',
                      style: GoogleFonts.dmSans(
                        color: _tl,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    _dot(),
                    Text(
                      _timeAgo,
                      style: GoogleFonts.dmSans(color: _tl, fontSize: 11),
                    ),
                    if (rating > 0) ...[
                      _dot(),
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: Color(0xFFFFBE0B),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: GoogleFonts.dmSans(
                          color: _tl,
                          fontSize: 11,
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

        // Campus badge (top-right, grey pill)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _d ? const Color(0xFF2A2A3E) : const Color(0xFFF0F0F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _d ? const Color(0xFF3A3A55) : const Color(0xFFDDDDEE),
            ),
          ),
          child: Text(
            campus,
            style: GoogleFonts.dmSans(
              color: _ts,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Skill pills (coral / pink – "offering" colour)
  // ─────────────────────────────────────────────────────────────
  Widget _buildSkillPills(PostModel post) {
    // All tags + skillOffered as pills, coral style
    final skills = <String>[post.skillOffered, ...post.tags].toSet().toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills
          .take(4)
          .map((s) => _CoralPill(label: s, dark: _d))
          .toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  "Wants:" line
  // ─────────────────────────────────────────────────────────────
  Widget _buildWantsLine(String skillWanted) {
    // Split on common separators: comma, slash, &, "and"
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
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 0,
            children: parts.asMap().entries.map((e) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.value,
                    style: GoogleFonts.dmSans(
                      color: AppColors.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (e.key < parts.length - 1)
                    Text(
                      ' · ',
                      style: GoogleFonts.dmSans(color: _tl, fontSize: 12.5),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Status row: Online pill + swap count
  // ─────────────────────────────────────────────────────────────
  Widget _buildStatusRow(PostModel post) {
    final swapCount = post.bookmarksCount; // use bookmarks_count as proxy

    return Row(
      children: [
        // Online / offline pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: _isAvailable
                ? const Color(0xFF00C9A7).withOpacity(0.12)
                : const Color(0xFFFFBE0B).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isAvailable
                  ? const Color(0xFF00C9A7).withOpacity(0.3)
                  : const Color(0xFFFFBE0B).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _isAvailable
                      ? const Color(0xFF00C9A7)
                      : const Color(0xFFFFBE0B),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _isAvailable ? 'Online now' : 'Last seen recently',
                style: GoogleFonts.dmSans(
                  color: _isAvailable
                      ? const Color(0xFF00C9A7)
                      : const Color(0xFFFFBE0B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Swap count (only show if > 0)
        if (swapCount > 0) ...[
          const SizedBox(width: 10),
          Row(
            children: [
              const Text('✅', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                '$swapCount swap${swapCount == 1 ? '' : 's'} via this post',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF00C9A7),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Expiry warning
  // ─────────────────────────────────────────────────────────────
  Widget _buildExpiry() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          const Text('⏳', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            _daysLeft == 0
                ? 'Expires today!'
                : 'Expires in $_daysLeft day${_daysLeft == 1 ? '' : 's'}',
            style: GoogleFonts.dmSans(
              color: const Color(0xFFFFBE0B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Bottom actions: Like · Comment · Bookmark  |  Swap →
  // ─────────────────────────────────────────────────────────────
  Widget _buildActions() {
    return Row(
      children: [
        // Like
        _ActionBtn(
          icon: _liked
              ? Icons.favorite_rounded
              : Icons.favorite_outline_rounded,
          label: '$_likeCount',
          color: _liked ? AppColors.secondary : _tl,
          onTap: _toggleLike,
          scale: _likeScale,
        ),

        const SizedBox(width: 4),

        // Comment (decorative)
        _ActionBtn(
          icon: Icons.chat_bubble_outline_rounded,
          label: '${(widget.post.bookmarksCount * 0.4).round()}',
          color: _tl,
          onTap: widget.onSwap,
        ),

        const SizedBox(width: 4),

        // Bookmark
        GestureDetector(
          onTap: widget.onBookmark,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              widget.post.isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_outline_rounded,
              size: 20,
              color: widget.post.isBookmarked ? AppColors.primary : _tl,
            ),
          ),
        ),

        const Spacer(),

        // Swap → gradient pill
        GestureDetector(
          onTap: widget.onSwap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C5CFC), Color(0xFFFF4D7D)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C5CFC).withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              'Swap →',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────────
  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text('·', style: TextStyle(color: _tl, fontSize: 11)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Coral skill pill  (matches the pinkish pills in screenshot)
// ─────────────────────────────────────────────────────────────────────────────
class _CoralPill extends StatelessWidget {
  final String label;
  final bool dark;
  const _CoralPill({required this.label, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        // Matches the screenshot: coral/pink background
        color: dark
            ? const Color(0xFFFF4D6D).withOpacity(0.14)
            : const Color(0xFFFF4D6D).withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFFF4D6D).withOpacity(dark ? 0.35 : 0.25),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: dark ? const Color(0xFFFF7A9A) : const Color(0xFFCC2244),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Action button (like / comment) with optional scale animation
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Animation<double>? scale;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.scale,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    if (scale != null) {
      child = ScaleTransition(scale: scale!, child: child);
    }

    return child;
  }
}
