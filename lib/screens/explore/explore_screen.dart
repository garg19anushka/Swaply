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
import '../posts/post_detail_screen.dart';
import '../posts/create_post_screen.dart';
import '../profile/user_profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Category chip data  (12 items matching Home Page)
// ─────────────────────────────────────────────────────────────────────────────
class _Cat {
  final String label;
  final IconData icon;
  const _Cat(this.label, this.icon);
}

const _cats = [
  _Cat('Design',   Icons.palette_outlined),
  _Cat('Coding',   Icons.code_rounded),
  _Cat('Music',    Icons.music_note_rounded),
  _Cat('Writing',  Icons.edit_note_rounded),
  _Cat('Math',     Icons.calculate_outlined),
  _Cat('Language', Icons.translate_rounded),
  _Cat('Photo',    Icons.camera_alt_outlined),
  _Cat('Cooking',  Icons.restaurant_outlined),
  _Cat('Fitness',  Icons.fitness_center_rounded),
  _Cat('Finance',  Icons.attach_money_rounded),
  _Cat('Business', Icons.business_center_outlined),
  _Cat('DIY',      Icons.handyman_outlined),
];

// ─────────────────────────────────────────────────────────────────────────────
//  Deterministic pastel card gradients
// ─────────────────────────────────────────────────────────────────────────────
const _cardGrads = [
  [Color(0xFFBBDEFB), Color(0xFF90CAF9)],
  [Color(0xFFF8BBD0), Color(0xFFF48FB1)],
  [Color(0xFFB2EBF2), Color(0xFF80DEEA)],
  [Color(0xFFDCEDC8), Color(0xFFC5E1A5)],
  [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
  [Color(0xFFE1BEE7), Color(0xFFCE93D8)],
];

List<Color> _gradFor(PostModel p) =>
    _cardGrads[p.skillOffered.length % _cardGrads.length];

// ═══════════════════════════════════════════════════════════════════════════
//  ExploreScreen
//  • Neutral header with "Explore" + gradient accent underline
//  • Search bar matching Home Page
//  • Filter: All · Barter · Custom chips
//  • Popular Skills: 12 neutral icon+label chips
//  • 2-column grid  (16px corners, gradient headers)
//  • Own posts → Edit + Delete icons inside card
// ═══════════════════════════════════════════════════════════════════════════
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchCtrl = TextEditingController();
  String _query       = '';
  String _exchange    = 'all'; // 'all' | 'barter' | 'custom'
  String? _activeCat;
  final Set<String> _activeFilters = {};

  // ── theme shortcuts ─────────────────────────────────────────────────────
  bool  get _d  => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _d ? const Color(0xFF111318) : Colors.white;
  Color get _sf => _d ? const Color(0xFF1A1D24) : Colors.white;
  Color get _sv => _d ? const Color(0xFF22252E) : const Color(0xFFF2F2F4);
  Color get _bd => _d ? const Color(0xFF2A2D36) : const Color(0xFFEFEFEF);
  Color get _tp => _d ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A0A);
  Color get _ts => _d ? const Color(0xFF8E9099) : const Color(0xFF6E6E6E);
  Color get _tl => _d ? const Color(0xFF555862) : const Color(0xFFAAAAAA);
  Color get _cb => _d ? const Color(0xFF22252E) : const Color(0xFFF2F2F4); // chip bg
  Color get _ce => _d ? const Color(0xFF32363F) : const Color(0xFFE0E0E0); // chip border

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<PostService>().fetchPosts());
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _search(String q) {
    setState(() => _query = q);
    context.read<PostService>().fetchPosts(
      searchQuery: q.isEmpty ? null : q,
      exchangeType: _exchange == 'all' ? null : _exchange,
    );
  }

  void _setExchange(String v) {
    setState(() => _exchange = v);
    context.read<PostService>().fetchPosts(
      searchQuery: _query.isEmpty ? null : _query,
      exchangeType: v == 'all' ? null : v,
    );
  }

  void _pickCat(String cat) {
    final next = _activeCat == cat ? null : cat;
    setState(() { _activeCat = next; });
    final kw = next ?? '';
    _searchCtrl.text = kw;
    _search(kw);
  }

  void _toggleFilter(String f) =>
      setState(() => _activeFilters.contains(f)
          ? _activeFilters.remove(f)
          : _activeFilters.add(f));

  Future<void> _delete(String postId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete post?', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text('This cannot be undone.', style: GoogleFonts.dmSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.dmSans(color: _ts))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: GoogleFonts.dmSans(
                  color: AppColors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true && mounted) {
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

          // ── Sticky neutral header ─────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: _sf,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            centerTitle: false,
            toolbarHeight: 56,
            title: Text('Explore',
                style: GoogleFonts.dmSans(
                  color: _tp, fontSize: 22,
                  fontWeight: FontWeight.w800, letterSpacing: -0.5,
                )),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: _bd),
            ),
          ),

          // ── Search bar ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 46,
                decoration: BoxDecoration(
                  color: _sv,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _query.isNotEmpty ? AppColors.primary : _ce,
                    width: _query.isNotEmpty ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 13),
                    Icon(Icons.search_rounded, color: _ts, size: 18),
                    const SizedBox(width: 9),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _search,
                        style: GoogleFonts.dmSans(color: _tp, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search skills, people...',
                          hintStyle: GoogleFonts.dmSans(color: _ts, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear(); _search('');
                          setState(() => _activeCat = null);
                        },
                        child: Padding(padding: const EdgeInsets.all(11),
                            child: Icon(Icons.close_rounded, color: _ts, size: 16)),
                      )
                    else
                      const SizedBox(width: 13),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 40.ms),
          ),

          // ── Popular Skills heading + chips ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Text('Popular Skills',
                  style: GoogleFonts.dmSans(
                      color: _tp, fontSize: 14.5,
                      fontWeight: FontWeight.w700, letterSpacing: -0.1)),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                itemCount: _cats.length,
                itemBuilder: (_, i) {
                  final c = _cats[i];
                  final active = _activeCat == c.label;
                  return GestureDetector(
                    onTap: () => _pickCat(c.label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 170),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : _cb,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active ? AppColors.primary : _ce, width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(c.icon, size: 13,
                              color: active ? Colors.white : _ts),
                          const SizedBox(width: 5),
                          Text(c.label,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                color: active ? Colors.white : _ts,
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ).animate().fadeIn(delay: 70.ms),
          ),

          // ── Filter row: All · Barter · Custom + 10 advanced chips ──────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter:',
                      style: GoogleFonts.dmSans(
                          color: _tp, fontSize: 13.5,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      // ── Primary exchange filters ──────────────────────
                      ...[
                        ('all',    'All'),
                        ('barter', 'Barter'),
                        ('custom', 'Custom'),
                      ].map(((String, String) rec) {
                        final v      = rec.$1;
                        final label  = rec.$2;
                        final active = _exchange == v;
                        return GestureDetector(
                          onTap: () => _setExchange(v),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 7),
                            decoration: BoxDecoration(
                              color: active ? AppColors.primary : _cb,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active ? AppColors.primary : _ce,
                                width: active ? 1.5 : 1,
                              ),
                            ),
                            child: Text(label,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12.5,
                                  fontWeight:
                                      active ? FontWeight.w700 : FontWeight.w500,
                                  color: active ? Colors.white : _ts,
                                )),
                          ),
                        );
                      }).toList(),

                      // ── Advanced filters ──────────────────────────────
                      ...[
                        'Trending', 'New', 'Top Rated', 'Urgent',
                        'Quick', 'Long term', 'Online', 'In person',
                        'Flexible', 'Beginner friendly',
                      ].map((f) {
                        final on = _activeFilters.contains(f);
                        return GestureDetector(
                          onTap: () => _toggleFilter(f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 7),
                            decoration: BoxDecoration(
                              color: on
                                  ? AppColors.primary.withOpacity(0.1)
                                  : _cb,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: on ? AppColors.primary : _ce,
                                width: on ? 1.5 : 1,
                              ),
                            ),
                            child: Text(f,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12.5,
                                  fontWeight:
                                      on ? FontWeight.w700 : FontWeight.w500,
                                  color: on ? AppColors.primary : _ts,
                                )),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 55.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // ── 2-column grid ─────────────────────────────────────────────────
          Consumer<PostService>(
            builder: (_, ps, __) {
              if (ps.isLoading && ps.posts.isEmpty) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                        (_, __) => _ShimmerCard(d: _d), childCount: 6),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 10,
                      crossAxisSpacing: 10, childAspectRatio: 0.88,
                    ),
                  ),
                );
              }

              if (ps.posts.isEmpty) return SliverFillRemaining(child: _empty());

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final p = ps.posts[i];
                      return _ExploreCard(
                        key: ValueKey(p.id),
                        post: p,
                        gradient: _gradFor(p),
                        isOwn: p.userId == myId,
                        d: _d, tp: _tp, ts: _ts, tl: _tl,
                        cardSurface: _d ? const Color(0xFF1A1D24) : Colors.white,
                        cardBorder: _bd,
                        stripBg: _d ? const Color(0xFF22252E) : const Color(0xFFF6F6F8),
                        stripDivider: _d ? const Color(0xFF32363F) : const Color(0xFFE5E5E5),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => PostDetailScreen(post: p)));
                        },
                        onAuthorTap: () {
                          if (p.profile?.id != null) {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) =>
                                    UserProfileScreen(userId: p.profile!.id)));
                          }
                        },
                        onBookmark: () => ps.toggleBookmark(p.id),
                        onEdit: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => CreatePostScreen(post: p))),
                        onDelete: () => _delete(p.id),
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: i * 40))
                          .slideY(begin: 0.07,
                              delay: Duration(milliseconds: i * 40),
                              curve: Curves.easeOutCubic);
                    },
                    childCount: ps.posts.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 10,
                    crossAxisSpacing: 10, childAspectRatio: 0.88,
                  ),
                ),
              );
            },
          ),
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
                  color: AppColors.primary.withOpacity(0.07),
                  shape: BoxShape.circle),
              child: const Icon(Icons.search_off_rounded,
                  size: 42, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text('No results found',
                style: GoogleFonts.dmSans(
                    color: _tp, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text('Try a different search or filter',
                style: GoogleFonts.dmSans(color: _ts, fontSize: 13)),
          ],
        ).animate().fadeIn(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  ExploreCard  –  2-col grid card with gradient header
// ─────────────────────────────────────────────────────────────────────────────
class _ExploreCard extends StatelessWidget {
  final PostModel post;
  final List<Color> gradient;
  final bool isOwn, d;
  final Color tp, ts, tl, cardSurface, cardBorder, stripBg, stripDivider;
  final VoidCallback onTap, onAuthorTap, onBookmark, onEdit, onDelete;

  const _ExploreCard({
    super.key,
    required this.post, required this.gradient,
    required this.isOwn, required this.d,
    required this.tp, required this.ts, required this.tl,
    required this.cardSurface, required this.cardBorder,
    required this.stripBg, required this.stripDivider,
    required this.onTap, required this.onAuthorTap,
    required this.onBookmark, required this.onEdit, required this.onDelete,
  });

  String get _catLabel {
    final s = post.skillOffered.toLowerCase();
    if (s.contains('design') || s.contains('figma') || s.contains('canva')) return 'Design';
    if (s.contains('code') || s.contains('flutter') || s.contains('python') ||
        s.contains('java') || s.contains('react') || s.contains('dev')) return 'Dev';
    if (s.contains('music') || s.contains('guitar') || s.contains('piano')) return 'Music';
    if (s.contains('math')) return 'Math';
    if (post.isOpenRequest) return 'Help';
    return 'Skill';
  }

  @override
  Widget build(BuildContext context) {
    final isBarter = post.exchangeType == 'barter';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(d ? 0.20 : 0.05),
              blurRadius: 10, offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Gradient header ──────────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circle
                    Positioned(
                      right: -14, top: -14,
                      child: Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Category label (top-left)
                    Positioned(
                      left: 8, top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.82),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_catLabel,
                            style: GoogleFonts.dmSans(
                              fontSize: 9, fontWeight: FontWeight.w700,
                              color: gradient[1],
                            )),
                      ),
                    ),
                    // Own: Edit + Delete (top-right)
                    if (isOwn)
                      Positioned(
                        right: 7, top: 7,
                        child: Row(children: [
                          _MiniBtn(icon: Icons.edit_outlined,
                              color: AppColors.primary, onTap: onEdit),
                          const SizedBox(width: 5),
                          _MiniBtn(icon: Icons.delete_outline_rounded,
                              color: AppColors.error, onTap: onDelete),
                        ]),
                      )
                    else
                      Positioned(
                        right: 7, top: 7,
                        child: GestureDetector(
                          onTap: onBookmark,
                          child: Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              post.isBookmarked
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_outline_rounded,
                              size: 14,
                              color: post.isBookmarked
                                  ? AppColors.primary : gradient[1],
                            ),
                          ),
                        ),
                      ),
                    // My Swap badge + exchange badge (bottom)
                    if (isOwn)
                      Positioned(
                        left: 8, bottom: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: gradient[1].withOpacity(0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('My Swap',
                              style: GoogleFonts.dmSans(
                                  fontSize: 8, fontWeight: FontWeight.w700,
                                  color: gradient[1])),
                        ),
                      ),
                    Positioned(
                      right: 8, bottom: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.82),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(isBarter ? 'Barter' : 'Custom',
                            style: GoogleFonts.dmSans(
                              fontSize: 8, fontWeight: FontWeight.w700,
                              color: isBarter
                                  ? AppColors.primary : AppColors.accentTeal,
                            )),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Author ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 0),
              child: GestureDetector(
                onTap: onAuthorTap,
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
                        post.profile?.fullName?.split(' ').first
                            ?? post.profile?.username ?? 'User',
                        style: GoogleFonts.dmSans(
                            color: ts, fontSize: 10.5,
                            fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if ((post.profile?.averageRating ?? 0) > 0) ...[
                      Icon(Icons.star_rounded,
                          size: 11, color: Colors.amber.shade500),
                      const SizedBox(width: 2),
                      Text(post.profile!.averageRating.toStringAsFixed(1),
                          style: GoogleFonts.dmSans(
                              color: ts, fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            ),

            // ── Title ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 5, 9, 0),
              child: Text(post.title,
                  style: GoogleFonts.dmSans(
                    color: tp, fontSize: 12,
                    fontWeight: FontWeight.w700, height: 1.3,
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),

            const Spacer(),

            // ── Offering / Wants strip ────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: stripBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('OFFERING',
                            style: GoogleFonts.dmSans(
                                fontSize: 7.5, color: tl,
                                fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Row(children: [
                          Icon(Icons.star_rounded, size: 9, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(post.skillOffered,
                                style: GoogleFonts.dmSans(
                                    fontSize: 10, color: AppColors.primary,
                                    fontWeight: FontWeight.w700),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                      ],
                    ),
                  ),
                  Container(
                    width: 1, height: 26,
                    color: stripDivider,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(isBarter ? 'WANTS' : 'OFFERS',
                            style: GoogleFonts.dmSans(
                                fontSize: 7.5, color: tl,
                                fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                isBarter
                                    ? (post.skillWanted ?? 'Open')
                                    : (post.customOffer ?? 'Custom'),
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: isBarter
                                      ? AppColors.secondary
                                      : AppColors.accentTeal,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              isBarter
                                  ? Icons.sync_alt_rounded
                                  : Icons.card_giftcard_rounded,
                              size: 9,
                              color: isBarter
                                  ? AppColors.secondary : AppColors.accentTeal,
                            ),
                          ],
                        ),
                      ],
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

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MiniBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
        ),
        child: Icon(icon, size: 13, color: color),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final bool d;
  const _ShimmerCard({required this.d});
  @override
  Widget build(BuildContext context) {
    final base = d ? const Color(0xFF22252E) : const Color(0xFFEEEEEE);
    final high = d ? const Color(0xFF2A2D36) : const Color(0xFFF8F8F8);
    return Container(
      decoration: BoxDecoration(
          color: base, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: high,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 20, height: 20,
                    decoration: BoxDecoration(color: high, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Container(width: 55, height: 8,
                    decoration: BoxDecoration(color: high,
                        borderRadius: BorderRadius.circular(4))),
              ]),
              const SizedBox(height: 8),
              Container(width: double.infinity, height: 9,
                  decoration: BoxDecoration(color: high,
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 5),
              Container(width: 70, height: 9,
                  decoration: BoxDecoration(color: high,
                      borderRadius: BorderRadius.circular(4))),
            ]),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String capitalize() => isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
}