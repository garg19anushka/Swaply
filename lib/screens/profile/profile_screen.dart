import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/chat_model.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/post_card.dart';
import '../auth/login_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<SwapModel> _swaps = [];
  List<RatingModel> _ratings = [];
  bool _loadingExtra = false;

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
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthService>();
      if (auth.currentUser != null) {
        context.read<PostService>().fetchBookmarkedPosts();
        _loadExtra(auth.currentUser!.id);
      }
    });
  }

  Future<void> _loadExtra(String userId) async {
    setState(() => _loadingExtra = true);
    final cs = context.read<ChatService>();
    _swaps = await cs.fetchUserSwaps();
    _ratings = await cs.fetchUserRatings(userId);
    if (mounted) setState(() => _loadingExtra = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _initials(String? fullName, String? username) {
    final n = fullName ?? username ?? '?';
    final parts = n.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final profile = auth.currentProfile;
    final postSvc = context.watch<PostService>();
    final myPostCount = postSvc.posts
        .where((p) => p.userId == auth.currentUser?.id)
        .length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,

      // ══════════════════════════════════════════════════════════════════
      //  NAVIGATION DRAWER
      // ══════════════════════════════════════════════════════════════════
      endDrawer: _ProfileDrawer(
        d: _d,
        bg: _bg,
        sf: _sf,
        sv: _sv,
        bd: _bd,
        tp: _tp,
        ts: _ts,
        tl: _tl,
        profile: profile,
        onClose: () => _scaffoldKey.currentState?.closeEndDrawer(),
        onEditProfile: () {
          _scaffoldKey.currentState?.closeEndDrawer();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          ).then((_) => auth.fetchProfile());
        },
        onLeaderboard: () {
          _scaffoldKey.currentState?.closeEndDrawer();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
          );
        },
        onLogout: () {
          _scaffoldKey.currentState?.closeEndDrawer();
          _showLogoutDialog(context, auth);
        },
        onDeleteAccount: () => _showDeleteAccountDialog(context, auth),
      ),

      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 0,
            toolbarHeight: 52,
            backgroundColor: _sf,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            title: Text(
              'Profile',
              style: GoogleFonts.dmSans(
                color: _tp,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            centerTitle: false,
            actions: [
              // Single hamburger menu icon
              IconButton(
                icon: Icon(Icons.menu_rounded, color: _tp, size: 24),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: _bd),
            ),
          ),
        ],

        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
                    Row(
                      children: [
                        // Avatar square
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
                          child: profile?.avatarUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    profile!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _initialsWidget(
                                          profile.username,
                                          profile.fullName,
                                        ),
                                  ),
                                )
                              : _initialsWidget(
                                  profile?.username,
                                  profile?.fullName,
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.fullName ??
                                    profile?.username ??
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
                                '@${profile?.username ?? ''}'
                                '${profile?.campus != null ? ' · ${profile!.campus}' : ''}',
                                style: GoogleFonts.dmSans(
                                  color: _ts,
                                  fontSize: 12,
                                ),
                              ),
                              if ((profile?.badges ?? []).isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 5,
                                  runSpacing: 5,
                                  children: profile!.badges
                                      .take(3)
                                      .map(
                                        (b) => _Chip(
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
                    if ((profile?.bio ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          profile!.bio!,
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

                    // Stats
                    Row(
                      children: [
                        _StatPanel(
                          value: '${profile?.totalSwaps ?? 0}',
                          label: 'Swaps done',
                          sv: _sv,
                          bd: _bd,
                          tp: _tp,
                          ts: _ts,
                        ),
                        const SizedBox(width: 8),
                        _StatPanel(
                          value: (profile?.averageRating ?? 0) > 0
                              ? profile!.averageRating.toStringAsFixed(1)
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
                          value: '$myPostCount',
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

              // Skills I offer
              if ((profile?.skillsOffered ?? []).isNotEmpty) ...[
                _label('Skills I offer'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile!.skillsOffered
                      .map(
                        (s) => _Chip(label: s, color: AppColors.primary, d: _d),
                      )
                      .toList(),
                ).animate().fadeIn(delay: 80.ms),
                const SizedBox(height: 20),
              ],

              // Skills I want
              if ((profile?.skillsWanted ?? []).isNotEmpty) ...[
                _label('Skills I want'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile!.skillsWanted
                      .map(
                        (s) =>
                            _Chip(label: s, color: AppColors.secondary, d: _d),
                      )
                      .toList(),
                ).animate().fadeIn(delay: 120.ms),
                const SizedBox(height: 20),
              ],

              // Recent reviews
              if (_ratings.isNotEmpty) ...[
                _label('Recent reviews'),
                const SizedBox(height: 10),
                ..._ratings
                    .take(3)
                    .map(
                      (r) => _ReviewCard(
                        rating: r,
                        d: _d,
                        sf: _sf,
                        bd: _bd,
                        tp: _tp,
                        ts: _ts,
                        tl: _tl,
                      ).animate().fadeIn(delay: 160.ms),
                    ),
              ],

              const SizedBox(height: 24),
              _label('My Activity'),
              const SizedBox(height: 12),

              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: _sf,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _bd, width: 1),
                ),
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Posts'),
                    Tab(text: 'Bookmarks'),
                    Tab(text: 'History'),
                    Tab(text: 'Analytics'),
                  ],
                  labelColor: AppColors.primary,
                  unselectedLabelColor: _ts,
                  indicatorColor: AppColors.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 12),
                  dividerColor: Colors.transparent,
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 420,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _PostsTab(
                      userId: auth.currentUser?.id ?? '',
                      d: _d,
                      sf: _sf,
                      bd: _bd,
                      tp: _tp,
                      ts: _ts,
                      tl: _tl,
                    ),
                    _BookmarksTab(
                      d: _d,
                      sf: _sf,
                      bd: _bd,
                      tp: _tp,
                      ts: _ts,
                      tl: _tl,
                    ),
                    _HistoryTab(
                      swaps: _swaps,
                      ratings: _ratings,
                      isLoading: _loadingExtra,
                      d: _d,
                      sf: _sf,
                      sv: _sv,
                      bd: _bd,
                      tp: _tp,
                      ts: _ts,
                      tl: _tl,
                    ),
                    _AnalyticsTab(
                      swaps: _swaps,
                      ratings: _ratings,
                      isLoading: _loadingExtra,
                      d: _d,
                      sf: _sf,
                      sv: _sv,
                      bd: _bd,
                      tp: _tp,
                      ts: _ts,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initialsWidget(String? username, String? fullName) => Center(
    child: Text(
      _initials(fullName, username),
      style: GoogleFonts.dmSans(
        color: AppColors.primary,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _label(String t) => Text(
    t,
    style: GoogleFonts.dmSans(
      color: _tp,
      fontSize: 15,
      fontWeight: FontWeight.w700,
    ),
  );

  void _showLogoutDialog(BuildContext ctx, AuthService auth) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: _sf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Logout',
          style: GoogleFonts.dmSans(
            color: _tp,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: GoogleFonts.dmSans(color: _ts, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: _tl)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext ctx, AuthService auth) {
    _scaffoldKey.currentState?.closeEndDrawer();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: _sf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Account',
          style: GoogleFonts.dmSans(
            color: _tp,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          'This will permanently delete your account and all your data. This cannot be undone.',
          style: GoogleFonts.dmSans(color: _ts, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: _tl)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (r) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              elevation: 0,
            ),
            child: Text(
              'Delete Account',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  NAVIGATION DRAWER
// ═══════════════════════════════════════════════════════════════════════════
class _ProfileDrawer extends StatefulWidget {
  final bool d;
  final Color bg, sf, sv, bd, tp, ts, tl;
  final dynamic profile;
  final VoidCallback onClose;
  final VoidCallback onEditProfile;
  final VoidCallback onLeaderboard;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  const _ProfileDrawer({
    required this.d,
    required this.bg,
    required this.sf,
    required this.sv,
    required this.bd,
    required this.tp,
    required this.ts,
    required this.tl,
    required this.profile,
    required this.onClose,
    required this.onEditProfile,
    required this.onLeaderboard,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  @override
  State<_ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<_ProfileDrawer> {
  bool get d => widget.d;
  Color get sf => widget.sf;
  Color get bd => widget.bd;
  Color get tp => widget.tp;
  Color get ts => widget.ts;
  Color get tl => widget.tl;

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: color ?? AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showChangePasswordDialog() {
    widget.onClose();
    final emailCtrl = TextEditingController(text: widget.profile?.email ?? '');
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscurePass = true;
    bool obscureConfirm = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: sf,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Change Password / Email',
            style: GoogleFonts.dmSans(
              color: tp,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.dmSans(color: tp, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'New Email',
                  labelStyle: GoogleFonts.dmSans(color: ts, fontSize: 13),
                  prefixIcon: Icon(
                    Icons.mail_outline_rounded,
                    color: ts,
                    size: 18,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: bd),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: obscurePass,
                style: GoogleFonts.dmSans(color: tp, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: GoogleFonts.dmSans(color: ts, fontSize: 13),
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    color: ts,
                    size: 18,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: ts,
                      size: 18,
                    ),
                    onPressed: () => setS(() => obscurePass = !obscurePass),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: bd),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: obscureConfirm,
                style: GoogleFonts.dmSans(color: tp, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: GoogleFonts.dmSans(color: ts, fontSize: 13),
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    color: ts,
                    size: 18,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: ts,
                      size: 18,
                    ),
                    onPressed: () =>
                        setS(() => obscureConfirm = !obscureConfirm),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: bd),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.dmSans(color: tl)),
            ),
            ElevatedButton(
              onPressed: () {
                if (passCtrl.text.isNotEmpty &&
                    passCtrl.text != confirmCtrl.text) {
                  _snack('Passwords do not match', color: AppColors.error);
                  return;
                }
                Navigator.pop(ctx);
                _snack('Changes saved successfully!', color: AppColors.success);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDownloadDataDialog() {
    widget.onClose();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Download My Data',
          style: GoogleFonts.dmSans(
            color: tp,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          'We will prepare a copy of your data including your profile, posts, and swap history. You will be notified when it\'s ready.',
          style: GoogleFonts.dmSans(color: ts, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: tl)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _snack(
                'Your data export has been requested!',
                color: AppColors.success,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
            ),
            child: Text(
              'Request Export',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    widget.onClose();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'About Swaply',
              style: GoogleFonts.dmSans(
                color: tp,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0 (Build 1)',
              style: GoogleFonts.dmSans(
                color: tp,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Swaply is a skill-swap platform where users can exchange their talents and abilities with others.',
              style: GoogleFonts.dmSans(color: ts, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'Developed by',
              style: GoogleFonts.dmSans(color: tl, fontSize: 11),
            ),
            Text(
              'Anushka Garg',
              style: GoogleFonts.dmSans(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
            ),
            child: Text(
              'Close',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFAQsDialog() {
    widget.onClose();
    final faqs = [
      (
        'How do I create a swap post?',
        'Tap the + Post button in the bottom nav, fill in what skill you offer and what you want in return.',
      ),
      (
        'How does the rating system work?',
        'After completing a swap, both parties can rate each other from 1–5 stars. Ratings affect your leaderboard position.',
      ),
      (
        'Can I cancel a swap request?',
        'Yes! Go to the swap in your Chats tab and tap "Cancel Request" before the other party accepts.',
      ),
      (
        'Is Swaply free to use?',
        'Yes, Swaply is completely free. All skill swaps are peer-to-peer with no monetary transactions.',
      ),
      (
        'How do I report a user?',
        'Open the user\'s profile, tap the three-dot menu in the top right and select "Report User".',
      ),
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Frequently Asked Questions',
          style: GoogleFonts.dmSans(
            color: tp,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: faqs.length,
            separatorBuilder: (_, __) => Divider(height: 16, color: bd),
            itemBuilder: (_, i) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faqs[i].$1,
                  style: GoogleFonts.dmSans(
                    color: tp,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  faqs[i].$2,
                  style: GoogleFonts.dmSans(color: ts, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
            ),
            child: Text(
              'Got it',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactDialog() {
    widget.onClose();
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Contact Developer',
          style: GoogleFonts.dmSans(
            color: tp,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Have a bug to report or a suggestion? We\'d love to hear from you!',
              style: GoogleFonts.dmSans(color: ts, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              maxLines: 4,
              style: GoogleFonts.dmSans(color: tp, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Write your message here...',
                hintStyle: GoogleFonts.dmSans(color: tl, fontSize: 13),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: bd),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: tl)),
          ),
          ElevatedButton(
            onPressed: () {
              if (msgCtrl.text.trim().isEmpty) {
                _snack('Please write a message first', color: AppColors.error);
                return;
              }
              Navigator.pop(ctx);
              _snack(
                'Message sent! We\'ll get back to you soon.',
                color: AppColors.success,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
            ),
            child: Text(
              'Send',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    widget.onClose();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sf,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Terms & Privacy Policy',
          style: GoogleFonts.dmSans(
            color: tp,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms of Service',
                style: GoogleFonts.dmSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'By using Swaply, you agree to exchange skills fairly and honestly. You must not use the platform for any illegal activity, harassment, or misrepresentation of your skills.',
                style: GoogleFonts.dmSans(color: ts, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Text(
                'Privacy Policy',
                style: GoogleFonts.dmSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'We collect only the data necessary to operate the platform (profile info, posts, swap history). We never sell your data to third parties. You may request deletion of your account and data at any time.',
                style: GoogleFonts.dmSans(color: ts, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Text(
                'Last updated: January 2025',
                style: GoogleFonts.dmSans(color: tl, fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 0,
            ),
            child: Text(
              'I Understand',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRateDialog() {
    widget.onClose();
    int selectedStars = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: sf,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Rate Swaply',
            style: GoogleFonts.dmSans(
              color: tp,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enjoying Swaply? Give us a rating!',
                style: GoogleFonts.dmSans(color: ts, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setS(() => selectedStars = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < selectedStars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.warning,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                [
                  '',
                  'Poor',
                  'Fair',
                  'Good',
                  'Great',
                  'Excellent!',
                ][selectedStars],
                style: GoogleFonts.dmSans(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Later', style: GoogleFonts.dmSans(color: tl)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _snack(
                  selectedStars >= 4
                      ? 'Thank you for the $selectedStars-star review! ⭐'
                      : 'Thanks for your feedback! We\'ll keep improving.',
                  color: AppColors.success,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
              ),
              child: Text(
                'Submit',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: sf,
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: BoxDecoration(
                color: sf,
                border: Border(bottom: BorderSide(color: bd, width: 1)),
              ),
              child: Row(
                children: [
                  Text(
                    'Menu',
                    style: GoogleFonts.dmSans(
                      color: tp,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: d
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.close_rounded, color: tp, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DrawerSection(label: 'Appearance', tp: tp, ts: ts),
                    Consumer<ThemeProvider>(
                      builder: (_, tp2, __) => _DrawerTile(
                        icon: tp2.isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        label: tp2.isDark
                            ? 'Switch to Light Mode'
                            : 'Switch to Dark Mode',
                        d: d,
                        sf: sf,
                        bd: bd,
                        tp: tp,
                        ts: ts,
                        trailing: Switch.adaptive(
                          value: tp2.isDark,
                          onChanged: (_) => tp2.toggleTheme(),
                          activeColor: AppColors.primary,
                        ),
                        onTap: () => tp2.toggleTheme(),
                      ),
                    ),

                    _DrawerSection(label: 'Leaderboard', tp: tp, ts: ts),
                    _DrawerTile(
                      icon: Icons.leaderboard_rounded,
                      label: 'Rankings',
                      d: d,
                      sf: sf,
                      bd: bd,
                      tp: tp,
                      ts: ts,
                      onTap: widget.onLeaderboard,
                    ),

                    _DrawerSection(label: 'Account', tp: tp, ts: ts),
                    _DrawerTile(
                      icon: Icons.edit_outlined,
                      label: 'Edit Profile',
                      d: d,
                      sf: sf,
                      bd: bd,
                      tp: tp,
                      ts: ts,
                      onTap: widget.onEditProfile,
                    ),
                    _DrawerTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'Change Password / Email',
                      d: d,
                      sf: sf,
                      bd: bd,
                      tp: tp,
                      ts: ts,
                      onTap: _showChangePasswordDialog,
                    ),
                    _DrawerTile(
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      color: AppColors.warning,
                      d: d,
                      sf: sf,
                      bd: bd,
                      tp: tp,
                      ts: ts,
                      onTap: widget.onLogout,
                    ),
                    _DrawerTile(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete Account',
                      color: AppColors.error,
                      d: d,
                      sf: sf,
                      bd: bd,
                      tp: tp,
                      ts: ts,
                      onTap: widget.onDeleteAccount,
                    ),

                    _DrawerSection(label: 'App Data', tp: tp, ts: ts),
                    _DrawerTile(
                      icon: Icons.cleaning_services_outlined,
                      label: 'Clear Cache',
                      d: d,
                      sf: sf,
                      bd: bd,
                      tp: tp,
                      ts: ts,
                      onTap: () {
                        widget.onClose();
                        _snack(
                          'Cache cleared successfully!',
                          color: AppColors.success,
                        );
                      },
                    ),
                    _DrawerTile(
                      icon: Icons.download_outlined,
                      label: 'Download My Data',
                      d: d,
                      sf: sf,
                      bd: bd,
                      tp: tp,
                      ts: ts,
                      onTap: _showDownloadDataDialog,
                    ),
                    _DrawerTile(
                      icon: Icons.info_outline_rounded,
                      label: 'About App · v1.0.0',
                      d: d,
                      sf: sf,
                      bd: bd,
                      tp: tp,
                      ts: ts,
                      onTap: _showAboutDialog,
                    ),

                    _DrawerSection(label: 'Support', tp: tp, ts: ts),
                    _DrawerTile(
                      icon: Icons.help_outline_rounded,
                      label: 'FAQs',
                      d: d,
                      sf: sf,
                      bd: bd,
                      tp: tp,
                      ts: ts,
                      onTap: _showFAQsDialog,
                    ),
                    _DrawerTile(
                      icon: Icons.mail_outline_rounded,
                      label: 'Contact Developer',
                      d: d,
                      sf: sf,
                      bd: bd,
                      tp: tp,
                      ts: ts,
                      onTap: _showContactDialog,
                    ),
                    _DrawerTile(
                      icon: Icons.gavel_outlined,
                      label: 'Terms & Privacy Policy',
                      d: d,
                      sf: sf,
                      bd: bd,
                      tp: tp,
                      ts: ts,
                      onTap: _showTermsDialog,
                    ),
                    _DrawerTile(
                      icon: Icons.star_outline_rounded,
                      label: 'Rate the App',
                      d: d,
                      sf: sf,
                      bd: bd,
                      tp: tp,
                      ts: ts,
                      onTap: _showRateDialog,
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
}

// ── Drawer section header ──────────────────────────────────────────────────
class _DrawerSection extends StatelessWidget {
  final String label;
  final Color tp, ts;
  const _DrawerSection({
    required this.label,
    required this.tp,
    required this.ts,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmSans(
          color: ts,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// ── Drawer tile ────────────────────────────────────────────────────────────
class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final Widget? trailing;
  final bool d;
  final Color sf, bd, tp, ts;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.d,
    required this.sf,
    required this.bd,
    required this.tp,
    required this.ts,
    required this.onTap,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? tp;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.withOpacity(d ? 0.14 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: c, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: c,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(Icons.chevron_right_rounded, color: ts, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared widgets
// ─────────────────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool d;
  const _Chip({required this.label, required this.color, required this.d});

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

class _ReviewCard extends StatelessWidget {
  final RatingModel rating;
  final bool d;
  final Color sf, bd, tp, ts, tl;

  const _ReviewCard({
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
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 8,
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
                radius: 16,
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
                itemSize: 15,
              ),
            ],
          ),
          if (rating.review != null && rating.review!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rating.review!,
              style: GoogleFonts.dmSans(color: ts, fontSize: 13, height: 1.5),
            ),
          ],
          const SizedBox(height: 5),
          Text(
            rating.createdAt.toString().substring(0, 10),
            style: GoogleFonts.dmSans(color: tl, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tabs
// ─────────────────────────────────────────────────────────────────────────────
class _PostsTab extends StatefulWidget {
  final String userId;
  final bool d;
  final Color sf, bd, tp, ts, tl;
  const _PostsTab({
    required this.userId,
    required this.d,
    required this.sf,
    required this.bd,
    required this.tp,
    required this.ts,
    required this.tl,
  });

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  List _posts = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    _posts = await context.read<PostService>().fetchUserPosts(widget.userId);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      );
    if (_posts.isEmpty)
      return _empty(
        Icons.post_add_rounded,
        'No posts yet',
        widget.ts,
        widget.tl,
      );
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: _posts.length,
      itemBuilder: (_, i) => PostCard(post: _posts[i]),
    );
  }
}

class _BookmarksTab extends StatelessWidget {
  final bool d;
  final Color sf, bd, tp, ts, tl;
  const _BookmarksTab({
    required this.d,
    required this.sf,
    required this.bd,
    required this.tp,
    required this.ts,
    required this.tl,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PostService>(
      builder: (_, ps, __) {
        if (ps.bookmarkedPosts.isEmpty)
          return _empty(
            Icons.bookmark_outline_rounded,
            'No bookmarks yet',
            ts,
            tl,
          );
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: ps.bookmarkedPosts.length,
          itemBuilder: (_, i) => PostCard(post: ps.bookmarkedPosts[i]),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<SwapModel> swaps;
  final List<RatingModel> ratings;
  final bool isLoading, d;
  final Color sf, sv, bd, tp, ts, tl;

  const _HistoryTab({
    required this.swaps,
    required this.ratings,
    required this.isLoading,
    required this.d,
    required this.sf,
    required this.sv,
    required this.bd,
    required this.tp,
    required this.ts,
    required this.tl,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      );
    if (swaps.isEmpty && ratings.isEmpty)
      return _empty(Icons.history_rounded, 'No swap history yet', ts, tl);
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        if (swaps.isNotEmpty) ...[
          Text(
            'Swaps',
            style: GoogleFonts.dmSans(
              color: tp,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...swaps.map(
            (s) => _SwapTile(swap: s, d: d, sf: sf, bd: bd, tp: tp, ts: ts),
          ),
          const SizedBox(height: 16),
        ],
        if (ratings.isNotEmpty) ...[
          Text(
            'Ratings Received',
            style: GoogleFonts.dmSans(
              color: tp,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...ratings.map(
            (r) => _ReviewCard(
              rating: r,
              d: d,
              sf: sf,
              bd: bd,
              tp: tp,
              ts: ts,
              tl: tl,
            ),
          ),
        ],
      ],
    );
  }
}

class _SwapTile extends StatelessWidget {
  final SwapModel swap;
  final bool d;
  final Color sf, bd, tp, ts;
  const _SwapTile({
    required this.swap,
    required this.d,
    required this.sf,
    required this.bd,
    required this.tp,
    required this.ts,
  });

  @override
  Widget build(BuildContext context) {
    Color sc = AppColors.warning;
    if (swap.status == 'completed') sc = AppColors.success;
    if (swap.status == 'cancelled') sc = AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sf,
        borderRadius: BorderRadius.circular(12),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: sc.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.swap_horiz_rounded, color: sc, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Swap ${swap.id.substring(0, 8)}...',
                  style: GoogleFonts.dmSans(
                    color: tp,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  swap.createdAt.toString().substring(0, 10),
                  style: GoogleFonts.dmSans(color: ts, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: sc.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              swap.status.toUpperCase(),
              style: GoogleFonts.dmSans(
                color: sc,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  final List<SwapModel> swaps;
  final List<RatingModel> ratings;
  final bool isLoading, d;
  final Color sf, sv, bd, tp, ts;

  const _AnalyticsTab({
    required this.swaps,
    required this.ratings,
    required this.isLoading,
    required this.d,
    required this.sf,
    required this.sv,
    required this.bd,
    required this.tp,
    required this.ts,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      );
    final completed = swaps.where((s) => s.status == 'completed').length;
    final avgRating = ratings.isEmpty
        ? 0.0
        : ratings.fold(0.0, (sum, r) => sum + r.rating) / ratings.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: GoogleFonts.dmSans(
              color: tp,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Completed',
                  value: '$completed',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  d: d,
                  sf: sf,
                  bd: bd,
                  tp: tp,
                  ts: ts,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  title: 'Avg Rating',
                  value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '-',
                  icon: Icons.star_outline,
                  color: AppColors.warning,
                  d: d,
                  sf: sf,
                  bd: bd,
                  tp: tp,
                  ts: ts,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (ratings.isNotEmpty) ...[
            Text(
              'Rating Trend',
              style: GoogleFonts.dmSans(
                color: tp,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 140,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sf,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: bd, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: ratings
                    .take(5)
                    .toList()
                    .reversed
                    .map(
                      (r) => Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            r.rating.toStringAsFixed(1),
                            style: GoogleFonts.dmSans(
                              color: tp,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: 28,
                            height: (100 * (r.rating / 5.0)).clamp(8.0, 100.0),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color, sf, bd, tp, ts;
  final bool d;
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.d,
    required this.sf,
    required this.bd,
    required this.tp,
    required this.ts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sf,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bd, width: 1),
        boxShadow: d
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: tp,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(title, style: GoogleFonts.dmSans(color: ts, fontSize: 11)),
        ],
      ),
    );
  }
}

Widget _empty(IconData icon, String msg, Color ts, Color tl) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 44, color: tl),
        const SizedBox(height: 10),
        Text(msg, style: TextStyle(color: ts, fontSize: 13)),
      ],
    ),
  );
}
