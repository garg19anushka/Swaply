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
import '../../widgets/shimmer_card.dart';
import '../../widgets/home_hero_card.dart';
import '../notifications/notifications_screen.dart';
import '../posts/post_detail_screen.dart';
import '../posts/open_requests_screen.dart';
import '../posts/create_post_screen.dart';
import '../profile/user_profile_screen.dart';
import '../../widgets/chatbot_widget.dart';
import 'package:Swaply/widgets/swap_post_card.dart';
typedef TabSwitchCallback = void Function(int index);

// ─────────────────────────────────────────────────────────────────────────────
//  Category data
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
              // ── Pinned header shell ──────────────────────────────────
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

              // ── Non-sticky header ────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: _sf,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
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
                              GestureDetector(
                                onTap: () => widget.onSwitchTab?.call(4),
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

                        const SizedBox(height: 14),
                        Divider(height: 1, thickness: 1, color: _bd),
                        const SizedBox(height: 14),

                        // Search bar
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

                        // Categories heading
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

                        // Category chips
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

                        // ── HERO CARD ──────────────────────────────────
                        const SizedBox(height: 12),
                        HomeHeroCard(
                          onBrowse: () => widget.onSwitchTab?.call(1),
                          onPostSkill: () => widget.onSwitchTab?.call(2),
                          matchCount: 3,
                          activeSwaps: 24,
                        ),

                        // ──────────────────────────────────────────────
                        const SizedBox(height: 8),
                        Divider(height: 1, thickness: 1, color: _bd),
                      ],
                    ),
                  ),
                ),
              ),

              // ══════════════════════════════════════════════════════════
              //  MAIN FEED — real Supabase data, new card design
              //  Featured swap section REMOVED as requested
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

                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section heading
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Recent Skills',
                                  style: GoogleFonts.dmSans(
                                    color: _tp,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
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
                        ).animate().fadeIn(),

                        // All posts using new SwapPostCard
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
                                              milliseconds: e.key * 60,
                                            ),
                                          )
                                          .slideY(
                                            begin: 0.06,
                                            delay: Duration(
                                              milliseconds: e.key * 60,
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
//  SwapPostCard  –  matches screenshot exactly, uses real PostModel fields
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

  // ── Theme ──────────────────────────────────────────────────
  bool get _d => Theme.of(context).brightness == Brightness.dark;
  Color get _cardBg => _d ? const Color(0xFF111126) : Colors.white;
  Color get _cardBorder => _d ? const Color(0xFF252540) : AppColors.border;
  Color get _tp => _d ? const Color(0xFFF0F0FF) : AppColors.textPrimary;
  Color get _ts => _d ? const Color(0xFF9090B0) : AppColors.textSecondary;
  Color get _tl => _d ? const Color(0xFF555575) : AppColors.textLight;
  Color get _divider => _d ? const Color(0xFF1E1E38) : const Color(0xFFEEEEEE);

  // ── Avatar gradient, deterministic per first initial ───────
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

  // Post expires 7 days after creation
  int get _daysLeft {
    final expiry = widget.post.createdAt.add(const Duration(days: 7));
    return expiry.difference(DateTime.now()).inDays.clamp(0, 99);
  }

  // "Available now" if posted within last 24 h
  bool get _isAvailableNow =>
      DateTime.now().difference(widget.post.createdAt).inHours < 24;

  String get _availLabel {
    if (_isAvailableNow) return 'Available now';
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final next = DateTime.now().add(const Duration(days: 2));
    return 'Busy till ${days[next.weekday - 1]}';
  }

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
          highlightColor: AppColors.primary.withOpacity(0.03),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER ──────────────────────────────────────────
                _buildHeader(post, rating, campus),
                const SizedBox(height: 14),

                // ── TITLE ────────────────────────────────────────────
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

                // ── DESCRIPTION ──────────────────────────────────────
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

                // ── SKILL PILLS (coral) ───────────────────────────────
                _buildSkillPills(post),
                const SizedBox(height: 11),

                // ── WANTS LINE ────────────────────────────────────────
                if (post.skillWanted != null &&
                    post.skillWanted!.trim().isNotEmpty) ...[
                  _buildWantsLine(post.skillWanted!),
                  const SizedBox(height: 11),
                ],

                // ── STATUS ROW ────────────────────────────────────────
                _buildStatusRow(swapCount),

                // ── EXPIRY ────────────────────────────────────────────
                if (_daysLeft <= 7) ...[
                  const SizedBox(height: 9),
                  _buildExpiry(),
                ],

                const SizedBox(height: 12),
                Divider(height: 1, color: _divider),
                const SizedBox(height: 10),

                // ── ACTIONS ───────────────────────────────────────────
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
      crossAxisAlignment: CrossAxisAlignment.center,
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
                    letterSpacing: -0.1,
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
        // Campus badge – grey pill
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
              color: const Color(0xFF4CC9F0), // cyan, matches screenshot
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
            color: _isAvailableNow
                ? const Color(0xFF00C9A7).withOpacity(0.12)
                : const Color(0xFFFFBE0B).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isAvailableNow
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
                  color: _isAvailableNow
                      ? const Color(0xFF00C9A7)
                      : const Color(0xFFFFBE0B),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _availLabel,
                style: GoogleFonts.dmSans(
                  color: _isAvailableNow
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

  Widget _buildExpiry() {
    return Row(
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
  }

  Widget _buildActions() {
    return Row(
      children: [
        // Like button with bounce animation
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

        // Comment
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

        // Own post: edit + delete buttons
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
          const SizedBox(width: 10),
        ],

        // Swap → gradient pill
        GestureDetector(
          onTap: widget.onSwap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C5CFC), Color(0xFFFF4D7D)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C5CFC).withOpacity(0.38),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              'Swap →',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
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
//  Small edit / delete button for own posts
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

// ─────────────────────────────────────────────────────────────────────────────
//  Category chip
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
//  Header icon button
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
