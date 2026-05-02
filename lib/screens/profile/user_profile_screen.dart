import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/chat_model.dart';
import '../../models/profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/post_card.dart';
import '../../main.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  ProfileModel? _profile;
  List _posts = [];
  List<RatingModel> _ratings = [];
  bool _loading = true;
  late TabController _tabCtrl;

  // ── theme shortcuts ──────────────────────────────────────────────────────
  bool get _d => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _d ? const Color(0xFF111318) : Colors.white;
  Color get _sf => _d ? const Color(0xFF1A1D24) : Colors.white;
  Color get _sv => _d ? const Color(0xFF22252E) : const Color(0xFFF2F2F4);
  Color get _bd => _d ? const Color(0xFF2A2D36) : const Color(0xFFEFEFEF);
  Color get _tp => _d ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A0A);
  Color get _ts => _d ? const Color(0xFF8E9099) : const Color(0xFF6E6E6E);
  Color get _tl => _d ? const Color(0xFF555862) : const Color(0xFFAAAAAA);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    final chatSvc = context.read<ChatService>();
    final postSvc = context.read<PostService>();
    _profile = await auth.getProfileById(widget.userId);
    _posts = await postSvc.fetchUserPosts(widget.userId);
    _ratings = await chatSvc.fetchUserRatings(widget.userId);
    if (mounted) setState(() => _loading = false);
  }

  String _initials() {
    final n = _profile?.fullName ?? _profile?.username ?? '?';
    final parts = n.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthService>().currentUser?.id;
    final isOwn = myId == widget.userId;

    if (_loading) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Sticky app bar ───────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: _sf,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _tp,
                size: 19,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _profile?.fullName ?? _profile?.username ?? 'Profile',
              style: GoogleFonts.dmSans(
                color: _tp,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: false,
            actions: [
              if (!isOwn)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: _tp),
                  color: _sf,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (v) {
                    if (v == 'report') _showReportDialog(context);
                    if (v == 'block') _showBlockDialog(context);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.flag_outlined,
                            size: 18,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Report User',
                            style: GoogleFonts.dmSans(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.block_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Block User',
                            style: GoogleFonts.dmSans(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: _bd),
            ),
          ),

          // ── Scrollable body ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Profile card ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _sf,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: _bd, width: 1),
                      boxShadow: _d
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : AppShadows.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar + name row
                        Row(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: _sv,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: _profile?.avatarUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        _profile!.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _initialsBox(),
                                      ),
                                    )
                                  : _initialsBox(),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _profile?.fullName ??
                                        _profile?.username ??
                                        'User',
                                    style: GoogleFonts.dmSans(
                                      color: _tp,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '@${_profile?.username ?? ''}'
                                    '${_profile?.campus != null ? ' · ${_profile!.campus}' : ''}',
                                    style: GoogleFonts.dmSans(
                                      color: _ts,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if ((_profile?.badges ?? []).isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 5,
                                      runSpacing: 5,
                                      children: _profile!.badges
                                          .take(3)
                                          .map(
                                            (b) => _SkillChip(
                                              label: b,
                                              color: Colors.amber,
                                              d: _d,
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),

                        // ── Bio – LEFT aligned ──────────────────────────────
                        if ((_profile?.bio ?? '').isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _profile!.bio!,
                              style: GoogleFonts.dmSans(
                                color: _ts,
                                fontSize: 13,
                                height: 1.5,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),
                        Divider(color: _bd, height: 1),
                        const SizedBox(height: 14),

                        // ── 3 stat panels ────────────────────────────────────
                        Row(
                          children: [
                            _StatPanel(
                              value: '${_profile?.totalSwaps ?? 0}',
                              label: 'Swaps done',
                              sv: _sv,
                              bd: _bd,
                              tp: _tp,
                              ts: _ts,
                            ),
                            const SizedBox(width: 8),
                            _StatPanel(
                              value: (_profile?.averageRating ?? 0) > 0
                                  ? _profile!.averageRating.toStringAsFixed(1)
                                  : '-',
                              label: 'Avg rating',
                              icon: Icons.star_rounded,
                              iconColor: Colors.amber,
                              sv: _sv,
                              bd: _bd,
                              tp: _tp,
                              ts: _ts,
                            ),
                            const SizedBox(width: 8),
                            _StatPanel(
                              value: '${_posts.length}',
                              label: 'Active posts',
                              sv: _sv,
                              bd: _bd,
                              tp: _tp,
                              ts: _ts,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 350.ms),

                  const SizedBox(height: 20),

                  // ── Skills I offer ──────────────────────────────────────
                  if ((_profile?.skillsOffered ?? []).isNotEmpty) ...[
                    _sectionLabel('Skills I offer'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _profile!.skillsOffered
                          .map(
                            (s) => _SkillChip(
                              label: s,
                              color: AppColors.primary,
                              d: _d,
                            ),
                          )
                          .toList(),
                    ).animate().fadeIn(delay: 80.ms),
                    const SizedBox(height: 20),
                  ],

                  // ── Skills I want ───────────────────────────────────────
                  if ((_profile?.skillsWanted ?? []).isNotEmpty) ...[
                    _sectionLabel('Skills I want'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _profile!.skillsWanted
                          .map(
                            (s) => _SkillChip(
                              label: s,
                              color: AppColors.secondary,
                              d: _d,
                            ),
                          )
                          .toList(),
                    ).animate().fadeIn(delay: 120.ms),
                    const SizedBox(height: 20),
                  ],

                  // ── Recent Reviews ──────────────────────────────────────
                  if (_ratings.isNotEmpty) ...[
                    _sectionLabel('Recent reviews'),
                    const SizedBox(height: 10),
                    ..._ratings
                        .take(3)
                        .map(
                          (r) => _ReviewTile(
                            rating: r,
                            d: _d,
                            sf: _sf,
                            bd: _bd,
                            tp: _tp,
                            ts: _ts,
                            tl: _tl,
                          ).animate().fadeIn(delay: 160.ms),
                        ),
                    const SizedBox(height: 20),
                  ],

                  // ── Activity tabs ───────────────────────────────────────
                  _sectionLabel('Activity'),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: _sf,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _bd, width: 1),
                    ),
                    child: TabBar(
                      controller: _tabCtrl,
                      tabs: const [
                        Tab(text: 'Posts'),
                        Tab(text: 'Reviews'),
                      ],
                      labelColor: AppColors.primary,
                      unselectedLabelColor: _ts,
                      indicatorColor: AppColors.primary,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 13),
                      dividerColor: Colors.transparent,
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    height: 360,
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        // Posts tab
                        _posts.isEmpty
                            ? _emptyState(
                                Icons.post_add_rounded,
                                'No posts yet',
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(top: 4),
                                itemCount: _posts.length,
                                itemBuilder: (_, i) =>
                                    PostCard(post: _posts[i]),
                              ),

                        // Reviews tab
                        _ratings.isEmpty
                            ? _emptyState(
                                Icons.star_outline_rounded,
                                'No reviews yet',
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(top: 4),
                                itemCount: _ratings.length,
                                itemBuilder: (_, i) => _ReviewTile(
                                  rating: _ratings[i],
                                  d: _d,
                                  sf: _sf,
                                  bd: _bd,
                                  tp: _tp,
                                  ts: _ts,
                                  tl: _tl,
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialsBox() => Center(
    child: Text(
      _initials(),
      style: GoogleFonts.dmSans(
        color: AppColors.primary,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _sectionLabel(String t) => Text(
    t,
    style: GoogleFonts.dmSans(
      color: _tp,
      fontSize: 15,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _emptyState(IconData icon, String msg) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: _tl),
        const SizedBox(height: 10),
        Text(msg, style: GoogleFonts.dmSans(color: _ts, fontSize: 13)),
      ],
    ),
  );

  void _showReportDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _sf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Report User',
          style: GoogleFonts.dmSans(color: _tp, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please provide a reason for reporting this user.',
              style: GoogleFonts.dmSans(color: _ts),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              style: GoogleFonts.dmSans(color: _tp),
              decoration: InputDecoration(
                hintText: 'Reason...',
                hintStyle: GoogleFonts.dmSans(color: _tl),
                filled: true,
                fillColor: _sv,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _bd),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _bd),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: _tl)),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = ctrl.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(context);
              final uid = context.read<AuthService>().currentUser?.id;
              if (uid == null) return;
              try {
                await supabase.from('user_reports').insert({
                  'reporter_id': uid,
                  'reported_id': widget.userId,
                  'reason': reason,
                });
                if (mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User reported.')),
                  );
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'Report',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _sf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Block User',
          style: GoogleFonts.dmSans(color: _tp, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to block this user?',
          style: GoogleFonts.dmSans(color: _ts),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: _tl)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final uid = context.read<AuthService>().currentUser?.id;
              if (uid == null) return;
              try {
                await supabase.from('user_blocks').insert({
                  'blocker_id': uid,
                  'blocked_id': widget.userId,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User blocked.')),
                  );
                  Navigator.pop(context);
                }
              } catch (_) {}
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'Block',
              style: GoogleFonts.dmSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Stat Panel
// ─────────────────────────────────────────────────────────────────────────────
class _StatPanel extends StatelessWidget {
  final String value, label;
  final IconData? icon;
  final Color? iconColor;
  final Color sv, bd, tp, ts;

  const _StatPanel({
    required this.value,
    required this.label,
    required this.sv,
    required this.bd,
    required this.tp,
    required this.ts,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: sv,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bd, width: 1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: iconColor ?? AppColors.primary),
                  const SizedBox(width: 3),
                ],
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    color: tp,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: ts,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Skill Chip
// ─────────────────────────────────────────────────────────────────────────────
class _SkillChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool d;
  const _SkillChip({required this.label, required this.color, required this.d});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(d ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: color,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Review Tile
// ─────────────────────────────────────────────────────────────────────────────
class _ReviewTile extends StatelessWidget {
  final RatingModel rating;
  final bool d;
  final Color sf, bd, tp, ts, tl;

  const _ReviewTile({
    required this.rating,
    required this.d,
    required this.sf,
    required this.bd,
    required this.tp,
    required this.ts,
    required this.tl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sf,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bd, width: 1),
        boxShadow: d
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(
                avatarUrl: rating.rater?.avatarUrl,
                username: rating.rater?.username ?? '',
                radius: 15,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rating.rater?.fullName ?? rating.rater?.username ?? 'User',
                  style: GoogleFonts.dmSans(
                    color: tp,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              RatingBarIndicator(
                rating: rating.rating.toDouble(),
                itemBuilder: (_, __) =>
                    const Icon(Icons.star_rounded, color: AppColors.warning),
                itemCount: 5,
                itemSize: 14,
              ),
            ],
          ),
          if (rating.review != null && rating.review!.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              rating.review!,
              style: GoogleFonts.dmSans(color: ts, fontSize: 13, height: 1.5),
            ),
          ],
          const SizedBox(height: 5),
          Text(
            rating.createdAt.toString().substring(0, 10),
            style: GoogleFonts.dmSans(color: tl, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}
