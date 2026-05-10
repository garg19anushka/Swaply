import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/shimmer_card.dart';
import '../posts/post_detail_screen.dart';
import '../posts/create_post_screen.dart';
import '../profile/user_profile_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  OpenRequestsScreen  –  uses SwapPostCard (feed-identical design)
// ═══════════════════════════════════════════════════════════════════════════
class OpenRequestsScreen extends StatefulWidget {
  const OpenRequestsScreen({super.key});

  @override
  State<OpenRequestsScreen> createState() => _OpenRequestsScreenState();
}

class _OpenRequestsScreenState extends State<OpenRequestsScreen> {
  bool get _d => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _d ? const Color(0xFF0A0A14) : Colors.white;
  Color get _sf => _d ? const Color(0xFF0E0E1C) : Colors.white;
  Color get _bd => _d ? const Color(0xFF1E1E2E) : AppColors.divider;
  Color get _tp => _d ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get _ts => _d ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get _tl => _d ? const Color(0xFF555575) : AppColors.textLight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostService>().fetchOpenRequests();
    });
  }

  void _openDetail(PostModel p) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: p)),
    );
  }

  void _openProfile(String userId) {
    HapticFeedback.selectionClick();
    final myId = context.read<AuthService>().currentUser?.id;
    if (userId == myId) {
      Navigator.pop(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
      );
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete post?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This action cannot be undone.',
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.dmSans(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<PostService>().deletePost(postId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthService>().currentUser?.id;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: _sf,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 4,
                right: 16,
                bottom: 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: _tp,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      Text(
                        'Open Requests',
                        style: GoogleFonts.dmSans(
                          color: _tp,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 1, thickness: 1, color: _bd),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),

          // ── Info banner ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(_d ? 0.10 : 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Students posting requests for help — respond by starting a chat!',
                        style: GoogleFonts.dmSans(
                          color: _ts,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 50.ms),
          ),

          // ── Content ─────────────────────────────────────────────────────
          Consumer<PostService>(
            builder: (_, ps, __) {
              // Loading shimmer
              if (ps.isLoading && ps.openRequests.isEmpty) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const ShimmerCard(),
                      childCount: 4,
                    ),
                  ),
                );
              }

              // Empty state
              if (ps.openRequests.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.help_outline_rounded,
                            size: 44,
                            color: _tl,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No open requests yet',
                          style: GoogleFonts.dmSans(
                            color: _tp,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Be the first to post a help request!',
                          style: GoogleFonts.dmSans(color: _ts, fontSize: 13),
                        ),
                      ],
                    ).animate().fadeIn().scale(begin: const Offset(0.92, 0.92)),
                  ),
                );
              }

              // Requests list — feed-identical SwapPostCard
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final p = ps.openRequests[i];
                    return SwapPostCard(
                          key: ValueKey(p.id),
                          post: p,
                          isOwn: p.userId == myId,
                          onSwap: () => _openDetail(p),
                          onBookmark: () => ps.toggleBookmark(p.id),
                          onTapAuthor: () => _openProfile(p.userId),
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreatePostScreen(post: p),
                            ),
                          ),
                          onDelete: () => _deletePost(p.id),
                        )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: i * 55))
                        .slideY(
                          begin: 0.06,
                          delay: Duration(milliseconds: i * 55),
                          curve: Curves.easeOutCubic,
                        );
                  }, childCount: ps.openRequests.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SwapPostCard  –  feed-identical card, Swap → button removed
// ─────────────────────────────────────────────────────────────────────────────
class SwapPostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback onSwap;
  final VoidCallback onBookmark;
  final VoidCallback onTapAuthor;
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
  late int _likeCount;
  late AnimationController _likeCtrl;
  late Animation<double> _likeScale;

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
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
    _likeCtrl.reverse().then((_) => _likeCtrl.forward());
  }

  bool get _d => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _d ? const Color(0xFF111126) : Colors.white;
  Color get _cardBorder => _d ? const Color(0xFF252540) : AppColors.border;
  Color get _tp => _d ? const Color(0xFFF0F0FF) : AppColors.textPrimary;
  Color get _ts => _d ? const Color(0xFF9090B0) : AppColors.textSecondary;
  Color get _tl => _d ? const Color(0xFF555575) : AppColors.textLight;
  Color get _div => _d ? const Color(0xFF1E1E38) : const Color(0xFFEEEEEE);

  static const _grads = [
    [Color(0xFF7C5CFC), Color(0xFFFF4D7D)],
    [Color(0xFF00C9A7), Color(0xFF4CC9F0)],
    [Color(0xFFFFBE0B), Color(0xFFFF6B35)],
    [Color(0xFF6C47FF), Color(0xFF00C9A7)],
    [Color(0xFFFF4D6D), Color(0xFFFF9F43)],
    [Color(0xFF4CC9F0), Color(0xFF6C47FF)],
  ];

  List<Color> get _avatarGrad {
    final s = _initials;
    if (s.isEmpty) return _grads[0];
    return _grads[s.codeUnitAt(0) % _grads.length];
  }

  String get _initials {
    final name =
        widget.post.profile?.fullName ?? widget.post.profile?.username ?? '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(widget.post.createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  int get _daysLeft {
    final expiry = widget.post.createdAt.add(const Duration(days: 7));
    return expiry.difference(DateTime.now()).inDays.clamp(0, 99);
  }

  bool get _isAvailable =>
      DateTime.now().difference(widget.post.createdAt).inHours < 24;

  String get _availLabel {
    if (_isAvailable) return 'Available now';
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

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final rating = post.profile?.averageRating ?? 0.0;
    final campus = post.profile?.campus?.isNotEmpty == true
        ? post.profile!.campus!
        : 'MRU';
    final swapCount = post.bookmarksCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1),
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(post, rating, campus),
                const SizedBox(height: 14),
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
                Text(
                  post.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: _ts,
                    fontSize: 13.5,
                    height: 1.5,
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
                Divider(height: 1, color: _div),
                const SizedBox(height: 10),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(PostModel post, double rating, String campus) {
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onTapAuthor,
          child: Container(
            width: 46,
            height: 46,
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
        const SizedBox(width: 11),
        Expanded(
          child: GestureDetector(
            onTap: widget.onTapAuthor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.profile?.fullName ?? post.profile?.username ?? 'User',
                  style: GoogleFonts.dmSans(
                    color: _tp,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '@${post.profile?.username ?? 'user'}',
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

  Widget _buildWantsLine(String sw) {
    final parts = sw
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

  Widget _buildStatusRow(int swapCount) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _isAvailable
                ? const Color(0xFF00C9A7).withOpacity(0.12)
                : const Color(0xFFFFBE0B).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isAvailable
                  ? const Color(0xFF00C9A7).withOpacity(0.35)
                  : const Color(0xFFFFBE0B).withOpacity(0.35),
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
                _availLabel,
                style: GoogleFonts.dmSans(
                  color: _isAvailable
                      ? const Color(0xFF00C9A7)
                      : const Color(0xFFFFBE0B),
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

  // ── Actions – Swap → button removed ───────────────────────────────────────
  Widget _buildActions() => Row(
    children: [
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
      GestureDetector(
        onTap: widget.onBookmark,
        child: Icon(
          widget.post.isBookmarked
              ? Icons.bookmark_rounded
              : Icons.bookmark_outline_rounded,
          size: 20,
          color: widget.post.isBookmarked ? AppColors.primary : _tl,
        ),
      ),
      const Spacer(),
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

  Widget _dot() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: Text('·', style: TextStyle(color: _tl, fontSize: 12)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Small helpers
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
