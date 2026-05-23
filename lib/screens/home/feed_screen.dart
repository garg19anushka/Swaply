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
import '../../services/ai_match_service.dart';
import '../../services/leaderboard_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/shimmer_card.dart';
import '../../widgets/home_hero_card.dart';
import '../notifications/notifications_screen.dart';
import '../posts/post_detail_screen.dart';
import '../posts/open_requests_screen.dart';
import '../posts/create_post_screen.dart';
import '../profile/user_profile_screen.dart';
import '../swaps/all_swaps_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../../widgets/chatbot_widget.dart';

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
      _triggerAiMatches();
    });
  }

  // ── AI match: derive skills from user's OWN posts, not ProfileModel ───────
  void _triggerAiMatches() {
    final auth = context.read<AuthService>();
    final allPosts = context.read<PostService>().posts;
    final myId = auth.currentUser?.id ?? '';
    final campus = auth.currentProfile?.campus ?? 'Campus';
    if (allPosts.isEmpty) return;

    // Find what the current user offers/wants from their own posts
    final myPosts = allPosts.where((p) => p.userId == myId).toList();
    final mySkillOffered = myPosts.isNotEmpty
        ? myPosts.first.skillOffered
        : auth.currentProfile?.username ?? 'General';
    final mySkillWanted = myPosts.isNotEmpty
        ? (myPosts.first.skillWanted ?? 'Any skill')
        : 'Any skill';

    context.read<AiMatchService>().fetchMatches(
      mySkillOffered: mySkillOffered,
      mySkillWanted: mySkillWanted,
      myCampus: campus,
      myUserId: myId,
      allPosts: allPosts,
      maxResults: 5,
    );
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
                        const SizedBox(height: 12),
                        HomeHeroCard(
                          onBrowse: () => widget.onSwitchTab?.call(1),
                          onPostSkill: () => widget.onSwitchTab?.call(2),
                          matchCount: 3,
                          activeSwaps: 24,
                        ),
                        const SizedBox(height: 8),
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
              //  AI SMART MATCHES  – real AiMatchService data
              // ══════════════════════════════════════════════════════
              SliverToBoxAdapter(
                child: Consumer<AiMatchService>(
                  builder: (_, ai, __) {
                    if (ai.isLoading) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            title: '✨  Smart Matches',
                            actionLabel: 'See all',
                            onAction: () => widget.onSwitchTab?.call(1),
                            dark: _d,
                            tp: _tp,
                          ),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                              itemCount: 3,
                              itemBuilder: (_, __) =>
                                  _MatchCardSkeleton(dark: _d),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }
                    if (!ai.hasMatches) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: '✨  Smart Matches',
                          actionLabel: 'See all',
                          onAction: () => widget.onSwitchTab?.call(1),
                          dark: _d,
                          tp: _tp,
                        ),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            itemCount: ai.matches.length,
                            itemBuilder: (_, i) =>
                                _MatchCard(
                                      result: ai.matches[i],
                                      dark: _d,
                                      onTap: () =>
                                          _openPostDetail(ai.matches[i].post),
                                    )
                                    .animate()
                                    .fadeIn(
                                      delay: Duration(milliseconds: i * 80),
                                    )
                                    .slideX(begin: 0.1),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),

              // ══════════════════════════════════════════════════════
              //  LEADERBOARD PREVIEW  – top 3 from LeaderboardService
              // ══════════════════════════════════════════════════════
              SliverToBoxAdapter(
                child: _LeaderboardPreviewSection(
                  dark: _d,
                  tp: _tp,
                  ts: _ts,
                  bd: _bd,
                  sv: _sv,
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
//  AI Match Card
// ─────────────────────────────────────────────────────────────────────────────
class _MatchCard extends StatelessWidget {
  final AiMatchResult result;
  final bool dark;
  final VoidCallback onTap;
  const _MatchCard({
    required this.result,
    required this.dark,
    required this.onTap,
  });

  static const _grads = [
    [Color(0xFF7C5CFC), Color(0xFFFF4D7D)],
    [Color(0xFF00C9A7), Color(0xFF4CC9F0)],
    [Color(0xFFFFBE0B), Color(0xFFFF6B35)],
    [Color(0xFF6C47FF), Color(0xFF00C9A7)],
    [Color(0xFFFF4D6D), Color(0xFFFF9F43)],
  ];

  String get _initials {
    final name =
        result.post.profile?.fullName ?? result.post.profile?.username ?? '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  List<Color> get _grad =>
      _grads[_initials.isEmpty ? 0 : _initials.codeUnitAt(0) % _grads.length];

  Color get _cardBg => dark ? const Color(0xFF111126) : Colors.white;
  Color get _border => dark ? const Color(0xFF252540) : AppColors.border;
  Color get _tp => dark ? const Color(0xFFF0F0FF) : AppColors.textPrimary;
  Color get _ts => dark ? const Color(0xFF9090B0) : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final post = result.post;
    final campus = post.profile?.campus ?? 'Campus';
    final partnerName =
        post.profile?.fullName?.split(' ').first ??
        post.profile?.username ??
        'User';
    final score = result.matchScore;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: dark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _grad,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                partnerName,
                style: GoogleFonts.dmSans(
                  color: _tp,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),

              Text(
                campus,
                style: GoogleFonts.dmSans(color: _ts, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Skill pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D6D).withOpacity(0.13),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFFFF4D6D).withOpacity(0.35),
                  ),
                ),
                child: Text(
                  post.skillOffered.length > 12
                      ? '${post.skillOffered.substring(0, 12)}…'
                      : post.skillOffered,
                  style: GoogleFonts.dmSans(
                    color: dark
                        ? const Color(0xFFFF7A9A)
                        : const Color(0xFFCC2244),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Match score
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 12,
                    color: Color(0xFF00C9A7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$score% match',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF00C9A7),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Match bar
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0xFF2A2A3E)
                      : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: score / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF7C5CFC)],
                      ),
                      borderRadius: BorderRadius.circular(2),
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
//  SwapPostCard – full post card
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
//  Small reusable widgets
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

class _CatChip extends StatelessWidget {
  final _Cat cat;
  final bool active;
  final bool d;
  final VoidCallback onTap;
  const _CatChip({
    required this.cat,
    required this.active,
    required this.d,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = d ? Colors.white : AppColors.primary;
    final activeIcon = d ? AppColors.primary : Colors.white;
    final activeLabel = d ? AppColors.primary : Colors.white;
    final inactiveBg = d
        ? AppColors.darkSurfaceVariant
        : const Color(0xFFF2F2F4);
    final inactiveClr = d
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final inactiveBdr = d ? AppColors.darkBorder : const Color(0xFFE5E5E5);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 68,
        height: 80,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: active ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(14),
          border: active ? null : Border.all(color: inactiveBdr, width: 1),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: (d ? Colors.white : AppColors.primary).withOpacity(
                      0.18,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(cat.icon, size: 22, color: active ? activeIcon : inactiveClr),
            const SizedBox(height: 5),
            Text(
              cat.label,
              style: GoogleFonts.dmSans(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? activeLabel : inactiveClr,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Leaderboard Preview Section  (home feed inline widget)
// ─────────────────────────────────────────────────────────────────────────────
class _LeaderboardPreviewSection extends StatefulWidget {
  final bool dark;
  final Color tp, ts, bd, sv;
  const _LeaderboardPreviewSection({
    required this.dark,
    required this.tp,
    required this.ts,
    required this.bd,
    required this.sv,
  });

  @override
  State<_LeaderboardPreviewSection> createState() =>
      _LeaderboardPreviewSectionState();
}

class _LeaderboardPreviewSectionState
    extends State<_LeaderboardPreviewSection> {
  final _svc = LeaderboardService();

  @override
  void initState() {
    super.initState();
    _svc.fetchLeaderboard();
  }

  @override
  void dispose() {
    _svc.dispose();
    super.dispose();
  }

  Color get _sf => widget.dark ? const Color(0xFF161824) : Colors.white;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _svc,
      child: Consumer<LeaderboardService>(
        builder: (_, svc, __) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Section header ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 15)),
                        const SizedBox(width: 6),
                        Text(
                          'Top Swappers',
                          style: GoogleFonts.dmSans(
                            color: widget.tp,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LeaderboardScreen(),
                        ),
                      ),
                      child: Text(
                        'See all',
                        style: GoogleFonts.dmSans(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Loading shimmer ─────────────────────────────
                if (svc.isLoading)
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: widget.sv,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),

                // ── Top 3 row ───────────────────────────────────
                if (!svc.isLoading && svc.filteredEntries.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _sf,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: widget.bd, width: 1),
                    ),
                    child: Row(
                      children: svc.filteredEntries
                          .take(3)
                          .toList()
                          .asMap()
                          .entries
                          .map((e) {
                            final idx = e.key;
                            final entry = e.value;
                            final medals = [
                              const Color(0xFFFFD700),
                              const Color(0xFFC0C0C0),
                              const Color(0xFFCD7F32),
                            ];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        UserProfileScreen(userId: entry.id),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        AvatarWidget(
                                          avatarUrl: entry.avatarUrl,
                                          username: entry.username,
                                          radius: 24,
                                          borderColor: medals[idx],
                                        ),
                                        Positioned(
                                          bottom: -4,
                                          right: 0,
                                          left: 0,
                                          child: Center(
                                            child: Container(
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: medals[idx],
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: _sf,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${idx + 1}',
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w800,
                                                    color: idx == 0
                                                        ? Colors.black87
                                                        : Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      entry.username,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: widget.tp,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${entry.totalSwaps} swaps',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 10,
                                        color: widget.ts,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),

                // ── Empty state ─────────────────────────────────
                if (!svc.isLoading && svc.filteredEntries.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _sf,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: widget.bd, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        'No swappers yet — be the first! 🚀',
                        style: GoogleFonts.dmSans(
                          color: widget.ts,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

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
