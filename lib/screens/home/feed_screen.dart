import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/post_card.dart';
import '../../widgets/shimmer_card.dart';
import '../notifications/notifications_screen.dart';
import '../posts/post_detail_screen.dart';
import '../posts/open_requests_screen.dart';
import '../posts/create_post_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/user_profile_screen.dart';
import '../../widgets/chatbot_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Callback type so FeedScreen can ask MainNavScreen to switch tabs
// ─────────────────────────────────────────────────────────────────────────────
typedef TabSwitchCallback = void Function(int index);

// ─────────────────────────────────────────────────────────────────────────────
//  Category data – 13 chips
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
//  Pastel palettes – deterministic from skillOffered.length
// ─────────────────────────────────────────────────────────────────────────────
const _pastels = [
  [Color(0xFFD1FAE5), Color(0xFF34D399)], // mint
  [Color(0xFFFFE4CC), Color(0xFFFF9F43)], // peach
  [Color(0xFFFFD6E0), Color(0xFFFF4D6D)], // pink
  [Color(0xFFCFE8FF), Color(0xFF4CC9F0)], // sky
  [Color(0xFFE8D5FF), Color(0xFF6C47FF)], // violet
  [Color(0xFFFFF9C4), Color(0xFFE0C200)], // yellow
];

List<Color> _palFor(PostModel p) =>
    _pastels[p.skillOffered.length % _pastels.length];

// ─────────────────────────────────────────────────────────────────────────────
//  FeedScreen
// ─────────────────────────────────────────────────────────────────────────────
class FeedScreen extends StatefulWidget {
  /// Called when "See All" (Recent Skills) is tapped – switches to Explore tab.
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

  // ── theme helpers ─────────────────────────────────────────────
  bool get _d => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _d ? Colors.black : Colors.white;
  Color get _sf => _d ? AppColors.darkSurface : Colors.white;
  Color get _tp => _d ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get _ts => _d ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get _bd => _d ? AppColors.darkDivider : AppColors.divider;
  Color get _sv => _d ? AppColors.darkSurfaceVariant : const Color(0xFFF2F2F4);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<PostService>().fetchPosts(),
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Search ────────────────────────────────────────────────────
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

  // ── Navigation helpers ────────────────────────────────────────
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
      // Own profile – navigate to the Profile tab
      widget.onSwitchTab?.call(4);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId)),
      );
    }
  }

  void _openOwnProfile() {
    widget.onSwitchTab?.call(4);
  }

  // ── Delete post ───────────────────────────────────────────────
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
              // ══════════════════════════════════════════════════════════
              //  STICKY HEADER
              // ══════════════════════════════════════════════════════════
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: 0,
                toolbarHeight: 0,
                backgroundColor: _sf,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
              ),

              // ══════════════════════════════════════════════════════════
              //  NON-STICKY HEADER CONTENT
              // ══════════════════════════════════════════════════════════
              SliverToBoxAdapter(
                child: Container(
                  color: _sf,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Top bar: Logo | Greeting + Avatar + Notif + OpenReq ─
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left: SkillSwap logo + tagline
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

                              // Right: Hey greeting + avatar (taps → profile)
                              GestureDetector(
                                onTap: _openOwnProfile,
                                child: Row(
                                  children: [
                                    Text(
                                      'Hey, $name',
                                      style: GoogleFonts.dmSans(
                                        color: _tp,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AvatarWidget(
                                      avatarUrl: auth.currentProfile?.avatarUrl,
                                      username:
                                          auth.currentProfile?.username ?? name,
                                      radius: 16,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Bell → Notifications
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

                              const SizedBox(width: 6),

                              // Open Requests button
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OpenRequestsScreen(),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.warning.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.help_outline_rounded,
                                        size: 15,
                                        color: AppColors.warning,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Open\nRequests',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.dmSans(
                                          color: AppColors.warning,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 320.ms),

                        // ── Divider ───────────────────────────────────
                        const SizedBox(height: 14),
                        Divider(height: 1, thickness: 1, color: _bd),
                        const SizedBox(height: 14),

                        // ── Search bar ────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 46,
                            decoration: BoxDecoration(
                              color: _sv,
                              borderRadius: BorderRadius.circular(13),
                              border: _searchActive
                                  ? Border.all(
                                      color: AppColors.primary,
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 13),
                                Icon(
                                  Icons.search_rounded,
                                  color: _ts,
                                  size: 19,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: TextField(
                                    controller: _searchCtrl,
                                    onChanged: _search,
                                    style: GoogleFonts.dmSans(
                                      color: _tp,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Search skills, people...',
                                      hintStyle: GoogleFonts.dmSans(
                                        color: _ts,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                if (_searchActive)
                                  GestureDetector(
                                    onTap: () {
                                      _searchCtrl.clear();
                                      _search('');
                                      setState(() => _cat = 'all');
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(11),
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: _ts,
                                        size: 17,
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(width: 13),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 50.ms),

                        const SizedBox(height: 18),

                        // ── Categories heading ────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Categories',
                            style: GoogleFonts.dmSans(
                              color: _tp,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Category chips row ────────────────────────
                        SizedBox(
                          height: 86,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            itemCount: _cats.length,
                            itemBuilder: (_, i) {
                              final c = _cats[i];
                              return _CatChip(
                                cat: c,
                                active: _cat == c.q,
                                d: _d,
                                onTap: () => _pickCat(c.q),
                              );
                            },
                          ),
                        ).animate().fadeIn(delay: 80.ms),

                        const SizedBox(height: 8),
                        Divider(height: 1, thickness: 1, color: _bd),
                      ],
                    ),
                  ),
                ),
              ),

              // ══════════════════════════════════════════════════════════
              //  MAIN CONTENT – pulls from real PostService
              // ══════════════════════════════════════════════════════════
              Consumer<PostService>(
                builder: (_, ps, __) {
                  if (ps.isLoading && ps.posts.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
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

                  final featured = ps.posts.first;
                  final recent = ps.posts.skip(1).take(4).toList();
                  final rest = ps.posts.skip(5).toList();

                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─────────────────────────────────────────────
                        //  FEATURED SWAP
                        // ─────────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                          child: Text(
                            'Featured swap',
                            style: GoogleFonts.dmSans(
                              color: _tp,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ).animate().fadeIn(),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _FeaturedCard(
                            post: featured,
                            d: _d,
                            isOwn: featured.userId == myId,
                            onTapCard: () => _openPostDetail(featured),
                            onTapAuthor: () =>
                                _openUserProfile(featured.userId),
                            onSwap: () => _openPostDetail(featured),
                            onBookmark: () => ps.toggleBookmark(featured.id),
                            onDelete: () => _deletePost(featured.id),
                          ),
                        ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.06),

                        // ─────────────────────────────────────────────
                        //  RECENT SKILLS
                        // ─────────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Recent skills',
                                  style: GoogleFonts.dmSans(
                                    color: _tp,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              // See all → navigates to Explore tab
                              GestureDetector(
                                onTap: () => widget.onSwitchTab?.call(1),
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
                        ),

                        if (recent.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _RecentGrid(
                              posts: recent,
                              d: _d,
                              myId: myId,
                              onTapCard: _openPostDetail,
                              onTapAuthor: (p) => _openUserProfile(p.userId),
                              onSwap: _openPostDetail,
                              onDelete: (p) => _deletePost(p.id),
                              onBookmark: (p) => ps.toggleBookmark(p.id),
                              onEdit: (p) => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreatePostScreen(post: p),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 80.ms),

                        // ─────────────────────────────────────────────
                        //  MORE SKILLS (all remaining posts)
                        // ─────────────────────────────────────────────
                        if (rest.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                            child: Text(
                              'More skills',
                              style: GoogleFonts.dmSans(
                                color: _tp,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: rest
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) =>
                                        PostCard(
                                              post: e.value,
                                              onBookmarkToggle: () =>
                                                  ps.toggleBookmark(e.value.id),
                                            )
                                            .animate()
                                            .fadeIn(
                                              delay: Duration(
                                                milliseconds: e.key * 55,
                                              ),
                                            )
                                            .slideY(
                                              begin: 0.08,
                                              delay: Duration(
                                                milliseconds: e.key * 55,
                                              ),
                                              curve: Curves.easeOutCubic,
                                            ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],

                        const SizedBox(height: 100),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          // Chatbot FAB
          Positioned(bottom: 20, right: 20, child: const ChatbotFab()),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
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
}

// ─────────────────────────────────────────────────────────────────────────────
//  FeaturedCard  –  large lavender hero card
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final PostModel post;
  final bool d;
  final bool isOwn;
  final VoidCallback onTapCard;
  final VoidCallback onTapAuthor;
  final VoidCallback onSwap;
  final VoidCallback onBookmark;
  final VoidCallback onDelete;

  const _FeaturedCard({
    required this.post,
    required this.d,
    required this.isOwn,
    required this.onTapCard,
    required this.onTapAuthor,
    required this.onSwap,
    required this.onBookmark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tp = d ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final ts = d ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardBg = d ? const Color(0xFF1F1535) : const Color(0xFFF0ECFF);
    final medBg = d ? const Color(0xFF2A1C50) : const Color(0xFFDDD5FF);

    return GestureDetector(
      onTap: onTapCard,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: AppColors.primary.withOpacity(d ? 0.3 : 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(d ? 0.18 : 0.09),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Media area ────────────────────────────────────────────
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: medBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
              ),
              child: Stack(
                children: [
                  // Exchange type label
                  Positioned(
                    left: 14,
                    top: 14,
                    child: _Pill(
                      label: post.exchangeType == 'barter'
                          ? 'Barter'
                          : 'Custom',
                      color: AppColors.primary,
                      bg: AppColors.primary.withOpacity(0.15),
                    ),
                  ),
                  // Own post: edit + delete badges
                  if (isOwn)
                    Positioned(
                      right: 14,
                      top: 14,
                      child: Row(
                        children: [
                          _MediaActionBtn(
                            icon: Icons.edit_outlined,
                            color: AppColors.primary,
                            onTap: onTapCard, // edit navigates to detail
                          ),
                          const SizedBox(width: 6),
                          _MediaActionBtn(
                            icon: Icons.delete_outline_rounded,
                            color: AppColors.error,
                            onTap: onDelete,
                          ),
                        ],
                      ),
                    )
                  else
                    Positioned(
                      right: 14,
                      top: 14,
                      child: GestureDetector(
                        onTap: onBookmark,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            post.isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_outline_rounded,
                            color: post.isBookmarked
                                ? AppColors.primary
                                : Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ),

                  // Ownership badge for own posts
                  if (isOwn)
                    Positioned(
                      left: 14,
                      bottom: 10,
                      child: _Pill(
                        label: '✏️  My Swap',
                        color: AppColors.primary,
                        bg: AppColors.primary.withOpacity(0.18),
                      ),
                    ),

                  Center(
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author row – tappable, leads to profile
                  GestureDetector(
                    onTap: onTapAuthor,
                    child: Row(
                      children: [
                        AvatarWidget(
                          avatarUrl: post.profile?.avatarUrl,
                          username: post.profile?.username ?? '',
                          radius: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            post.profile?.fullName ??
                                post.profile?.username ??
                                'User',
                            style: GoogleFonts.dmSans(
                              color: tp,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if ((post.profile?.averageRating ?? 0) > 0) ...[
                          Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            post.profile!.averageRating.toStringAsFixed(1),
                            style: GoogleFonts.dmSans(
                              color: ts,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    post.title,
                    style: GoogleFonts.dmSans(
                      color: tp,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.description,
                    style: GoogleFonts.dmSans(
                      color: ts,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Tag pills
                  if (post.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: post.tags
                          .take(3)
                          .map(
                            (t) => _Pill(
                              label: t,
                              color: AppColors.primary,
                              bg: AppColors.primary.withOpacity(0.1),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Skill offered + Swap Now
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          post.skillOffered,
                          style: GoogleFonts.dmSans(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onSwap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: d ? AppColors.primaryGradient : null,
                            color: d ? null : AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            boxShadow: AppShadows.button,
                          ),
                          child: Text(
                            'Swap Now',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 13,
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
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Recent Skills grid  –  2-column pastel cards
// ─────────────────────────────────────────────────────────────────────────────
class _RecentGrid extends StatelessWidget {
  final List<PostModel> posts;
  final bool d;
  final String? myId;
  final ValueChanged<PostModel> onTapCard;
  final ValueChanged<PostModel> onTapAuthor;
  final ValueChanged<PostModel> onSwap;
  final ValueChanged<PostModel> onDelete;
  final ValueChanged<PostModel> onBookmark;
  final ValueChanged<PostModel> onEdit;

  const _RecentGrid({
    required this.posts,
    required this.d,
    required this.myId,
    required this.onTapCard,
    required this.onTapAuthor,
    required this.onSwap,
    required this.onDelete,
    required this.onBookmark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <List<PostModel>>[];
    for (var i = 0; i < posts.length; i += 2) {
      rows.add(posts.sublist(i, (i + 2).clamp(0, posts.length)));
    }
    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: row
                    .asMap()
                    .entries
                    .map(
                      (e) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: e.key == 1 ? 6 : 0,
                            right: e.key == 0 ? 6 : 0,
                          ),
                          child: _RecentCard(
                            post: e.value,
                            d: d,
                            palette: _palFor(e.value),
                            isOwn: e.value.userId == myId,
                            onTapCard: () => onTapCard(e.value),
                            onTapAuthor: () => onTapAuthor(e.value),
                            onSwap: () => onSwap(e.value),
                            onDelete: () => onDelete(e.value),
                            onBookmark: () => onBookmark(e.value),
                            onEdit: () => onEdit(e.value),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  RecentCard  –  individual pastel card with conditional edit/delete
// ─────────────────────────────────────────────────────────────────────────────
class _RecentCard extends StatelessWidget {
  final PostModel post;
  final bool d;
  final List<Color> palette;
  final bool isOwn;
  final VoidCallback onTapCard;
  final VoidCallback onTapAuthor;
  final VoidCallback onSwap;
  final VoidCallback onDelete;
  final VoidCallback onBookmark;
  final VoidCallback onEdit;

  const _RecentCard({
    required this.post,
    required this.d,
    required this.palette,
    required this.isOwn,
    required this.onTapCard,
    required this.onTapAuthor,
    required this.onSwap,
    required this.onDelete,
    required this.onBookmark,
    required this.onEdit,
  });

  String get _catLabel {
    if (post.isOpenRequest) return 'Help';
    final s = post.skillOffered.toLowerCase();
    if (s.contains('design') || s.contains('figma') || s.contains('canva'))
      return 'Design';
    if (s.contains('flutter') ||
        s.contains('code') ||
        s.contains('python') ||
        s.contains('java') ||
        s.contains('react') ||
        s.contains('dev'))
      return 'Dev';
    if (s.contains('music') || s.contains('guitar') || s.contains('piano'))
      return 'Music';
    if (s.contains('teach') || s.contains('tutor')) return 'Teach';
    if (s.contains('math')) return 'Math';
    return 'Skill';
  }

  IconData get _catIcon {
    switch (_catLabel) {
      case 'Design':
        return Icons.palette_outlined;
      case 'Dev':
        return Icons.code_rounded;
      case 'Music':
        return Icons.music_note_rounded;
      case 'Teach':
        return Icons.school_outlined;
      case 'Math':
        return Icons.calculate_outlined;
      case 'Help':
        return Icons.handshake_outlined;
      default:
        return Icons.star_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = d ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final ts = d ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardBg = d ? AppColors.darkSurface : Colors.white;
    final border = d ? AppColors.darkDivider : const Color(0xFFEEEEEE);

    return GestureDetector(
      onTap: onTapCard,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: border, width: 1),
          boxShadow: d
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Pastel media area ─────────────────────────────────────
            Container(
              height: 76,
              decoration: BoxDecoration(
                color: palette[0],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
              ),
              child: Stack(
                children: [
                  // Category label
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        _catLabel,
                        style: GoogleFonts.dmSans(
                          color: palette[1],
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  // Own post: edit + delete icons top-right
                  if (isOwn)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Row(
                        children: [
                          _MediaActionBtn(
                            icon: Icons.edit_outlined,
                            color: palette[1],
                            onTap:
                                onEdit, // ← navigates to CreatePostScreen(post:)
                          ),
                          const SizedBox(width: 5),
                          _MediaActionBtn(
                            icon: Icons.delete_outline_rounded,
                            color: AppColors.error,
                            onTap: onDelete,
                          ),
                        ],
                      ),
                    )
                  else
                    // Bookmark for community posts
                    Positioned(
                      right: 8,
                      top: 8,
                      child: GestureDetector(
                        onTap: onBookmark,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            post.isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_outline_rounded,
                            size: 14,
                            color: post.isBookmarked
                                ? AppColors.primary
                                : palette[1],
                          ),
                        ),
                      ),
                    ),

                  // "My Swap" chip for own posts
                  if (isOwn)
                    Positioned(
                      left: 10,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: palette[1].withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          'My Swap',
                          style: GoogleFonts.dmSans(
                            color: palette[1],
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                  Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: palette[1].withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_catIcon, color: palette[1], size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author – tappable, leads to profile
                  GestureDetector(
                    onTap: onTapAuthor,
                    child: Row(
                      children: [
                        AvatarWidget(
                          avatarUrl: post.profile?.avatarUrl,
                          username: post.profile?.username ?? '',
                          radius: 10,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            post.profile?.fullName?.split(' ').first ??
                                post.profile?.username ??
                                'User',
                            style: GoogleFonts.dmSans(
                              color: ts,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Title
                  Text(
                    post.title,
                    style: GoogleFonts.dmSans(
                      color: tp,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),

                  // Rating + exchange type
                  Row(
                    children: [
                      if ((post.profile?.averageRating ?? 0) > 0) ...[
                        Icon(
                          Icons.star_rounded,
                          size: 11,
                          color: Colors.amber.shade500,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          post.profile!.averageRating.toStringAsFixed(1),
                          style: GoogleFonts.dmSans(
                            color: ts,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: post.exchangeType == 'barter'
                              ? AppColors.primary.withOpacity(0.1)
                              : AppColors.accentTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          post.exchangeType == 'barter' ? 'Barter' : 'Custom',
                          style: GoogleFonts.dmSans(
                            color: post.exchangeType == 'barter'
                                ? AppColors.primary
                                : AppColors.accentTeal,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),

                  // Swap Now button – full width, theme-aware
                  GestureDetector(
                    onTap: onSwap,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: d ? AppColors.primaryGradient : null,
                        color: d ? null : AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(
                              d ? 0.22 : 0.16,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        'Swap Now',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Media-area floating action button (edit / delete)
// ─────────────────────────────────────────────────────────────────────────────
class _MediaActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MediaActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
          ],
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Category Chip  –  icon + label, animated active state
// ─────────────────────────────────────────────────────────────────────────────
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
//  Header icon button (rounded square)
// ─────────────────────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool d;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.d, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = d ? AppColors.darkSurfaceVariant : const Color(0xFFF2F2F4);
    final c = d ? AppColors.darkTextPrimary : AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 19, color: c),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reusable pill badge
// ─────────────────────────────────────────────────────────────────────────────
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
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
