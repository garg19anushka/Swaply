import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../models/swap_model.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/swap_service.dart';
import '../../services/leaderboard_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/shimmer_card.dart';
import '../notifications/notifications_screen.dart';
import '../posts/post_detail_screen.dart';
import '../posts/create_post_screen.dart';
import '../profile/user_profile_screen.dart';
import '../swaps/all_swaps_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../../widgets/chatbot_widget.dart';
import '../../widgets/swap_post_card.dart';

typedef TabSwitchCallback = void Function(int index);

// ─────────────────────────────────────────────────────────────────────────────
//  Categories
// ─────────────────────────────────────────────────────────────────────────────
class _Cat {
  final String label;
  final IconData icon;
  final String q;
  const _Cat(this.label, this.icon, this.q);
}

const _cats = [
  _Cat('All', Icons.grid_view_rounded, 'all'),
  _Cat('Coding', Icons.code_rounded, 'coding'),
  _Cat('Design', Icons.palette_outlined, 'design'),
  _Cat('Music', Icons.music_note_rounded, 'music'),
  _Cat('Writing', Icons.edit_note_rounded, 'writing'),
  _Cat('Math', Icons.calculate_outlined, 'math'),
  _Cat('Language', Icons.translate_rounded, 'language'),
  _Cat('Photo', Icons.camera_alt_outlined, 'photo'),
  _Cat('Cooking', Icons.restaurant_outlined, 'cooking'),
  _Cat('Fitness', Icons.fitness_center_rounded, 'fitness'),
  _Cat('Finance', Icons.attach_money_rounded, 'finance'),
  _Cat('Business', Icons.business_center_outlined, 'business'),
  _Cat('DIY', Icons.handyman_outlined, 'diy'),
];

// ─────────────────────────────────────────────────────────────────────────────
//  FeedScreen
// ─────────────────────────────────────────────────────────────────────────────
class FeedScreen extends StatefulWidget {
  final TabSwitchCallback? onSwitchTab;
  const FeedScreen({super.key, this.onSwitchTab});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _cat = 'all';
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  bool _searchActive = false;

  bool get _d => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _d ? const Color(0xFF0A0A14) : Colors.white;
  Color get _sf => _d ? const Color(0xFF0E0E1C) : Colors.white;
  Color get _tp => _d ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get _ts => _d ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get _bd => _d ? const Color(0xFF1E1E2E) : AppColors.divider;
  Color get _sv => _d ? const Color(0xFF1A1A2E) : const Color(0xFFF2F2F4);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PostService>().fetchPosts();
      await context.read<SwapService>().fetchActiveSwaps();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String q) {
    setState(() => _searchActive = q.isNotEmpty);
    context.read<PostService>().fetchPosts(searchQuery: q.isEmpty ? null : q);
  }

  void _pickCat(String q) {
    setState(() => _cat = q);
    final kw = q == 'all' ? '' : q;
    _searchCtrl.text = kw;
    _search(kw);
  }

  void _openPostDetail(PostModel p) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: p)),
    );
  }

  void _openUserProfile(String userId) {
    HapticFeedback.selectionClick();
    final myId = context.read<AuthService>().currentUser?.id;
    if (userId == myId) {
      widget.onSwitchTab?.call(4);
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
    final auth = context.watch<AuthService>();
    final myId = auth.currentUser?.id;
    final name =
        auth.currentProfile?.fullName?.split(' ').first ??
        auth.currentProfile?.username ??
        'there';

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Pinned header shell ──────────────────────────────
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: 0,
                toolbarHeight: 0,
                backgroundColor: _bg,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
              ),

              // ── Non-sticky header ────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: _bg,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Swaply',
                                      style: GoogleFonts.dmSans(
                                        color: _tp,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.6,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'Find your next swap',
                                      style: GoogleFonts.dmSans(
                                        color: _ts,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _IconBtn(
                                icon: Icons.emoji_events_outlined,
                                d: _d,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LeaderboardScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _IconBtn(
                                icon: Icons.notifications_outlined,
                                d: _d,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 320.ms),

                        const SizedBox(height: 10),
                        Divider(height: 1, thickness: 1, color: _bd),
                      ],
                    ),
                  ),
                ),
              ),

              // ══════════════════════════════════════════════════════
              //  ACTIVE SWAP  – real SwapService data
              // ══════════════════════════════════════════════════════
              SliverToBoxAdapter(
                child: Consumer<SwapService>(
                  builder: (_, ss, __) {
                    if (ss.activeSwaps.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final swap = ss.activeSwaps.first;
                    return Column(
                      children: [
                        _SectionHeader(
                          title: '🔄  Active Swap',
                          actionLabel: 'View all',
                          onAction: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AllSwapsScreen(),
                            ),
                          ),
                          dark: _d,
                          tp: _tp,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _ActiveSwapCard(swap: swap, dark: _d),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.05);
                  },
                ),
              ),

              // ══════════════════════════════════════════════════════
              //  RECENT SKILLS  – real PostService data
              // ══════════════════════════════════════════════════════
              Consumer<PostService>(
                builder: (_, ps, __) {
                  if (ps.isLoading && ps.posts.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Column(
                          children: List.generate(
                            3,
                            (_) => const ShimmerCard(),
                          ),
                        ),
                      ),
                    );
                  }
                  if (ps.posts.isEmpty) {
                    return SliverFillRemaining(child: _empty());
                  }

                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: 'Recent Skills',
                          actionLabel: 'See all',
                          onAction: () => widget.onSwitchTab?.call(1),
                          dark: _d,
                          tp: _tp,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Column(
                            children: ps.posts
                                .asMap()
                                .entries
                                .map(
                                  (e) =>
                                      SwapPostCard(
                                            post: e.value,
                                            isOwn: e.value.userId == myId,
                                            onSwap: () =>
                                                _openPostDetail(e.value),
                                            onBookmark: () =>
                                                ps.toggleBookmark(e.value.id),
                                            onTapAuthor: () => _openUserProfile(
                                              e.value.userId,
                                            ),
                                            onEdit: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CreatePostScreen(
                                                      post: e.value,
                                                    ),
                                              ),
                                            ),
                                            onDelete: () =>
                                                _deletePost(e.value.id),
                                          )
                                          .animate()
                                          .fadeIn(
                                            delay: Duration(
                                              milliseconds: e.key * 55,
                                            ),
                                          )
                                          .slideY(
                                            begin: 0.06,
                                            delay: Duration(
                                              milliseconds: e.key * 55,
                                            ),
                                            curve: Curves.easeOutCubic,
                                          ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          Positioned(bottom: 20, right: 20, child: const ChatbotFab()),
        ],
      ),
    );
  }

  Widget _empty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.swap_horiz_rounded,
            size: 44,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'No posts yet',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _tp,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Be the first to post a skill swap!',
          style: GoogleFonts.dmSans(color: _ts, fontSize: 14),
        ),
      ],
    ).animate().fadeIn(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Active Swap Card
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveSwapCard extends StatelessWidget {
  final SwapModel swap;
  final bool dark;
  const _ActiveSwapCard({required this.swap, required this.dark});

  Color get _cardBg => dark ? const Color(0xFF111126) : Colors.white;
  Color get _cardBorder => dark ? const Color(0xFF252540) : AppColors.border;
  Color get _tp => dark ? const Color(0xFFF0F0FF) : AppColors.textPrimary;
  Color get _ts => dark ? const Color(0xFF9090B0) : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final pct = (swap.progress * 100).round();
    final partnerFirst =
        swap.partnerName?.split(' ').first ?? swap.partnerUsername ?? 'Partner';

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: dark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ]
            : AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              swap.swapTitle,
              style: GoogleFonts.dmSans(
                color: _tp,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Text(
                    swap.progressLabel,
                    style: GoogleFonts.dmSans(color: _ts, fontSize: 12),
                  ),
                ),
                Text(
                  '$pct%',
                  style: GoogleFonts.dmSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),

            // Gradient progress bar
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF2A2A3E) : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: swap.progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF7C5CFC)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Session dots
            Row(
              children: List.generate(swap.totalSessions, (i) {
                final done = i < swap.doneSessions;
                final active = i == swap.doneSessions;
                Color c;
                if (done)
                  c = AppColors.accentTeal;
                else if (active)
                  c = AppColors.primary;
                else
                  c = dark ? const Color(0xFF2A2A3E) : const Color(0xFFEEEEEE);
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: i < swap.totalSessions - 1 ? 5 : 0,
                    ),
                    height: 4,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    swap.nextSessionLabel,
                    style: GoogleFonts.dmSans(color: _ts, fontSize: 12),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showRateSheet(context, partnerFirst),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.accentTeal.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.accentTeal.withOpacity(0.08),
                    ),
                    child: Text(
                      'Rate $partnerFirst ★',
                      style: GoogleFonts.dmSans(
                        color: AppColors.accentTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRateSheet(BuildContext context, String name) {
    int stars = 0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Container(
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF111126) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Rate $name',
                style: GoogleFonts.dmSans(
                  color: dark ? Colors.white : AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'How was your session?',
                style: GoogleFonts.dmSans(
                  color: dark ? Colors.white54 : AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setSt(() => stars = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        i < stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 36,
                        color: i < stars
                            ? const Color(0xFFFFBE0B)
                            : Colors.grey.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Rating submitted! ⭐',
                        style: GoogleFonts.dmSans(),
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C5CFC), Color(0xFFFF4D7D)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Submit Rating',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Skeleton while AI loads
// ─────────────────────────────────────────────────────────────────────────────
class _MatchCardSkeleton extends StatelessWidget {
  final bool dark;
  const _MatchCardSkeleton({required this.dark});

  @override
  Widget build(BuildContext context) {
    final c = dark ? const Color(0xFF1E1E38) : const Color(0xFFEEEEEE);
    return Container(
          width: 148,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF111126) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: dark ? const Color(0xFF252540) : AppColors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: 90,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  height: 10,
                  width: 60,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 24,
                  width: 70,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1200.ms,
          color: dark ? Colors.white10 : Colors.black12,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final bool dark;
  final Color tp;
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.dark,
    required this.tp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.dmSans(
                color: tp,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: GoogleFonts.dmSans(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool d;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.d, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: d ? AppColors.darkSurfaceVariant : const Color(0xFFF2F2F4),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          size: 19,
          color: d ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
    );
  }
}
