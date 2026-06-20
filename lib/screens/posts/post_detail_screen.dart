// lib/screens/posts/post_detail_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
//  PostDetailScreen — supports LIGHT + DARK theme
//  Bookmark icon moved to the top-right corner of the app bar.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/post_service.dart';
import '../../services/swap_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../chat/chat_screen.dart';
import '../profile/user_profile_screen.dart';
import '../swaps/all_swaps_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _starting = false;
  bool _requesting = false;
  bool _swapDone = false;

  PostModel get post => widget.post;

  // ── theme-aware palette ───────────────────────────────────────────────────
  bool get _d => Theme.of(context).brightness == Brightness.dark;

  Color get _bg => _d ? const Color(0xFF0A0815) : const Color(0xFFF7F6FF);
  Color get _surface => _d ? const Color(0xFF15122B) : const Color(0xFFFFFFFF);
  Color get _border => _d ? const Color(0xFF272247) : const Color(0xFFECEAF9);
  Color get _tp => _d ? const Color(0xFFF3F1FF) : const Color(0xFF110D2E);
  Color get _ts => _d ? const Color(0xFFA9A5C9) : const Color(0xFF6B688E);
  Color get _tl => _d ? const Color(0xFF6C6790) : const Color(0xFFAAA8C4);
  Color get _purple => const Color(0xFF6C47FF);
  Color get _coral => const Color(0xFFFF4D6D);
  Color get _amber => const Color(0xFFFFBE0B);
  Color get _teal => const Color(0xFF00C9A7);
  Color get _green => const Color(0xFF4CAF7D);

  Color get _offBoxBg => _d ? const Color(0xFF211C46) : const Color(0xFFF0EDFF);
  Color get _offBoxBd => _d ? const Color(0xFF3C3470) : const Color(0xFFD4CCFF);

  Color get _wantBoxBg =>
      _d ? const Color(0xFF36172A) : const Color(0xFFFFF0F3);
  Color get _wantBoxBd =>
      _d ? const Color(0xFF5A2640) : const Color(0xFFFFCDD5);

  Color get _cardBg => _surface;
  Color get _cardBd => _border;

  // ── Navigation helpers ────────────────────────────────────────────────────
  Future<void> _startSwap() async {
    if (_starting) return;
    setState(() => _starting = true);
    HapticFeedback.mediumImpact();
    try {
      final chat = await context.read<ChatService>().getOrCreateChat(
        otherUserId: post.userId,
        postId: post.id,
      );
      if (!mounted) return;
      if (chat != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(chat: chat, sourcePost: post),
          ),
        );
      } else {
        _snack('Could not start chat. Please try again.');
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _requestSwap() async {
    if (_requesting) return;
    final myId = context.read<AuthService>().currentUser?.id;
    if (myId == post.userId) {
      _snack('You can\'t swap with yourself!');
      return;
    }
    setState(() => _requesting = true);
    HapticFeedback.mediumImpact();
    try {
      final offeredSkill =
          (post.skillWanted != null && post.skillWanted!.isNotEmpty)
          ? post.skillWanted!
          : null;
      final swapId = await context.read<SwapService>().requestSwap(
        responderId: post.userId,
        offeredSkill: offeredSkill,
        wantedSkill: post.skillOffered,
        postId: post.id,
      );
      if (!mounted) return;
      if (swapId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Swap request sent! They\'ll be notified.',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: _teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllSwapsScreen()),
              ),
            ),
          ),
        );
      } else {
        final err = context.read<SwapService>().error;
        _snack(err ?? 'Could not send request. Please try again.');
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _toggleSave() async {
    HapticFeedback.lightImpact();
    await context.read<PostService>().toggleBookmark(post.id);
  }

  void _markSwapDone() {
    HapticFeedback.mediumImpact();
    setState(() => _swapDone = !_swapDone);
    if (!_swapDone) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Swap marked as done!',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isOwn = auth.currentUser?.id == post.userId;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: _border,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: Icon(Icons.chevron_left_rounded, color: _tp, size: 22),
            ),
          ),
        ),
        title: Text(
          'Skill Details',
          style: GoogleFonts.dmSans(
            color: _tp,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        // ── Bookmark moved here, top-right corner ───────────────────────────
        actions: [
          GestureDetector(
            onTap: _toggleSave,
            child: Padding(
              padding: const EdgeInsets.only(right: 14, left: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: post.isBookmarked ? _purple.withOpacity(0.10) : _bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: post.isBookmarked
                        ? _purple.withOpacity(0.45)
                        : _border,
                    width: post.isBookmarked ? 1.5 : 1,
                  ),
                ),
                child: Icon(
                  post.isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  color: post.isBookmarked ? _purple : _ts,
                  size: 19,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _border),
        ),
      ),

      bottomNavigationBar: isOwn
          ? null
          : _BottomBar(
              post: post,
              swapDone: _swapDone,
              starting: _starting,
              requesting: _requesting,
              onMarkDone: _markSwapDone,
              onRequestSwap: _requestSwap,
              onStartChat: _startSwap,
              surface: _surface,
              border: _border,
              purple: _purple,
              ts: _ts,
              tl: _tl,
              green: _green,
              cardBg: _cardBg,
              cardBd: _cardBd,
              isDark: _d,
            ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero header — gradient banner ─────────────────────────────
            _HeroBanner(
              post: post,
              isDark: _d,
              border: _border,
              tp: _tp,
              tl: _tl,
              amber: _amber,
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tags ─────────────────────────────────────────────
                  if (post.tags.isNotEmpty) ...[
                    _TagRow(
                      post: post,
                      purple: _purple,
                      amber: _amber,
                      teal: _teal,
                      green: _green,
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── Skill exchange card ───────────────────────────────
                  _ExchangeCard(
                        post: post,
                        surface: _surface,
                        border: _border,
                        bg: _bg,
                        tl: _tl,
                        purple: _purple,
                        coral: _coral,
                        offBoxBg: _offBoxBg,
                        offBoxBd: _offBoxBd,
                        wantBoxBg: _wantBoxBg,
                        wantBoxBd: _wantBoxBd,
                      )
                      .animate()
                      .fadeIn(delay: 80.ms)
                      .slideY(begin: 0.04, delay: 80.ms),
                  const SizedBox(height: 20),

                  // ── Author card ───────────────────────────────────────
                  _AuthorCard(
                    post: post,
                    surface: _surface,
                    border: _border,
                    tp: _tp,
                    ts: _ts,
                    tl: _tl,
                    amber: _amber,
                    isDark: _d,
                  ).animate().fadeIn(delay: 120.ms),
                  const SizedBox(height: 20),

                  // ── About ─────────────────────────────────────────────
                  _SectionLabel(label: 'About this swap', tp: _tp),
                  const SizedBox(height: 8),
                  Text(
                    post.description,
                    style: GoogleFonts.dmSans(
                      color: _ts,
                      fontSize: 14.5,
                      height: 1.7,
                    ),
                  ).animate().fadeIn(delay: 140.ms),
                  const SizedBox(height: 24),

                  // ── Availability ──────────────────────────────────────
                  if (_availabilityTags.isNotEmpty) ...[
                    _SectionLabel(label: 'Availability', tp: _tp),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availabilityTags
                          .map(
                            (t) => _AvailPill(
                              label: t,
                              surface: _surface,
                              border: _border,
                              ts: _ts,
                              isDark: _d,
                            ),
                          )
                          .toList(),
                    ).animate().fadeIn(delay: 160.ms),
                    const SizedBox(height: 24),
                  ],

                  // ── Stats ─────────────────────────────────────────────
                  _SectionLabel(label: 'Swap Stats', tp: _tp),
                  const SizedBox(height: 10),
                  _StatsRow(
                    post: post,
                    surface: _surface,
                    border: _border,
                    tp: _tp,
                    ts: _ts,
                    purple: _purple,
                    amber: _amber,
                    coral: _coral,
                    isDark: _d,
                  ).animate().fadeIn(delay: 180.ms),

                  const SizedBox(height: 110),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _availKeywords = {
    'Weekends',
    'Weekdays',
    'Online Only',
    'Online',
    'In-person',
    'Evenings',
    'Mornings',
    'Flexible',
    'Async',
    'Hybrid',
  };

  List<String> get _availabilityTags =>
      post.tags.where((t) => _availKeywords.contains(t)).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
//  Hero banner — gradient with title overlaid
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final PostModel post;
  final bool isDark;
  final Color border, tp, tl, amber;
  const _HeroBanner({
    required this.post,
    required this.isDark,
    required this.border,
    required this.tp,
    required this.tl,
    required this.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF241D52),
                  const Color(0xFF3A1830),
                  const Color(0xFF0A0815),
                ]
              : [
                  const Color(0xFFEDE8FF),
                  const Color(0xFFFFF0F3),
                  const Color(0xFFF7F6FF),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.isOpenRequest)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: amber.withOpacity(0.45)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_open_rounded, size: 12, color: amber),
                  const SizedBox(width: 5),
                  Text(
                    'Open Request',
                    style: GoogleFonts.dmSans(
                      color: amber,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            post.title,
            style: GoogleFonts.dmSans(
              color: tp,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              height: 1.2,
            ),
          ).animate().fadeIn().slideY(begin: 0.04),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 13, color: tl),
              const SizedBox(width: 4),
              Text(
                timeago.format(post.createdAt),
                style: GoogleFonts.dmSans(color: tl, fontSize: 12),
              ),
              const SizedBox(width: 12),
              Icon(Icons.bookmark_outline_rounded, size: 13, color: tl),
              const SizedBox(width: 4),
              Text(
                '${post.bookmarksCount} saves',
                style: GoogleFonts.dmSans(color: tl, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Exchange card (Offers ↕ Wants)
// ─────────────────────────────────────────────────────────────────────────────
class _ExchangeCard extends StatelessWidget {
  final PostModel post;
  final Color surface, border, bg, tl, purple, coral;
  final Color offBoxBg, offBoxBd, wantBoxBg, wantBoxBd;
  const _ExchangeCard({
    required this.post,
    required this.surface,
    required this.border,
    required this.bg,
    required this.tl,
    required this.purple,
    required this.coral,
    required this.offBoxBg,
    required this.offBoxBd,
    required this.wantBoxBg,
    required this.wantBoxBd,
  });

  @override
  Widget build(BuildContext context) {
    final isBarter = post.exchangeType == 'barter';
    final wantLabel = isBarter ? 'WANTS' : 'OFFERS';
    final wantValue = isBarter
        ? (post.skillWanted?.isNotEmpty == true
              ? post.skillWanted!
              : 'Any Skill')
        : (post.customOffer ?? 'Custom');

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C47FF).withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _SkillPanel(
              label: 'OFFERS',
              value: post.skillOffered,
              valueColor: purple,
              bg: offBoxBg,
              borderColor: offBoxBd,
              tl: tl,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: Icon(Icons.swap_vert_rounded, size: 17, color: tl),
                ),
              ],
            ),
          ),
          Expanded(
            child: _SkillPanel(
              label: wantLabel,
              value: wantValue,
              valueColor: coral,
              bg: wantBoxBg,
              borderColor: wantBoxBd,
              tl: tl,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillPanel extends StatelessWidget {
  final String label, value;
  final Color valueColor, bg, borderColor, tl;
  const _SkillPanel({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.bg,
    required this.borderColor,
    required this.tl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: tl,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Author card
// ─────────────────────────────────────────────────────────────────────────────
class _AuthorCard extends StatelessWidget {
  final PostModel post;
  final Color surface, border, tp, ts, tl, amber;
  final bool isDark;
  const _AuthorCard({
    required this.post,
    required this.surface,
    required this.border,
    required this.tp,
    required this.ts,
    required this.tl,
    required this.amber,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(userId: post.userId),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            AvatarWidget(
              avatarUrl: post.profile?.avatarUrl,
              username: post.profile?.username ?? '',
              radius: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.profile?.displayName ?? 'Unknown',
                    style: GoogleFonts.dmSans(
                      color: tp,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${post.profile?.username ?? ''}'
                    '${(post.profile?.campus?.isNotEmpty == true) ? '  ·  ${post.profile!.campus}' : ''}',
                    style: GoogleFonts.dmSans(color: ts, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if ((post.profile?.averageRating ?? 0) > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: amber.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: amber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 13, color: amber),
                    const SizedBox(width: 3),
                    Text(
                      post.profile!.averageRating.toStringAsFixed(1),
                      style: GoogleFonts.dmSans(
                        color: amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              Icon(Icons.chevron_right_rounded, color: tl, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Stats row
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final PostModel post;
  final Color surface, border, tp, ts, purple, amber, coral;
  final bool isDark;
  const _StatsRow({
    required this.post,
    required this.surface,
    required this.border,
    required this.tp,
    required this.ts,
    required this.purple,
    required this.amber,
    required this.coral,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(
          value: '${post.profile?.totalSwaps ?? 0}',
          label: 'Swaps done',
          accentColor: purple,
          surface: surface,
          border: border,
          tp: tp,
          ts: ts,
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _StatBox(
          value: (post.profile?.averageRating ?? 0) > 0
              ? post.profile!.averageRating.toStringAsFixed(1)
              : '–',
          label: 'Avg rating',
          icon: Icons.star_rounded,
          accentColor: amber,
          surface: surface,
          border: border,
          tp: tp,
          ts: ts,
          isDark: isDark,
        ),
        const SizedBox(width: 10),
        _StatBox(
          value: '${post.bookmarksCount}',
          label: 'Bookmarks',
          accentColor: coral,
          surface: surface,
          border: border,
          tp: tp,
          ts: ts,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final IconData? icon;
  final Color accentColor, surface, border, tp, ts;
  final bool isDark;
  const _StatBox({
    required this.value,
    required this.label,
    this.icon,
    required this.accentColor,
    required this.surface,
    required this.border,
    required this.tp,
    required this.ts,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: accentColor),
                  const SizedBox(width: 3),
                ],
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    color: tp,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: ts,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tag row
// ─────────────────────────────────────────────────────────────────────────────
class _TagRow extends StatelessWidget {
  final PostModel post;
  final Color purple, amber, teal, green;
  const _TagRow({
    required this.post,
    required this.purple,
    required this.amber,
    required this.teal,
    required this.green,
  });

  Color _color(String tag) {
    if (tag == 'Urgent') return AppColors.error;
    if (tag == 'Quick Help') return amber;
    if (tag == 'Online' || tag == 'Online Only') return teal;
    if (tag == 'Beginner-friendly') return green;
    return purple;
  }

  @override
  Widget build(BuildContext context) {
    final displayTags = post.tags.take(5).toList();
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: displayTags.map((t) {
        final c = _color(t);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: c.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.withOpacity(0.3)),
          ),
          child: Text(
            t,
            style: GoogleFonts.dmSans(
              color: c,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Availability pill
// ─────────────────────────────────────────────────────────────────────────────
class _AvailPill extends StatelessWidget {
  final String label;
  final Color surface, border, ts;
  final bool isDark;
  const _AvailPill({
    required this.label,
    required this.surface,
    required this.border,
    required this.ts,
    required this.isDark,
  });

  String _emoji(String l) {
    if (l.contains('Weekend')) return '🗓';
    if (l.contains('Online')) return '💻';
    if (l.contains('In-person')) return '📍';
    if (l.contains('Evening')) return '🌙';
    if (l.contains('Morning')) return '☀️';
    if (l.contains('Flexible')) return '⏳';
    if (l.contains('Async')) return '🔄';
    if (l.contains('Hybrid')) return '🏠';
    return '📅';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_emoji(label), style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: ts,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section label
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color tp;
  const _SectionLabel({required this.label, required this.tp});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        color: tp,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bottom bar (bookmark removed — now lives in app bar)
// ─────────────────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final PostModel post;
  final bool swapDone, starting, requesting, isDark;
  final VoidCallback onMarkDone, onRequestSwap, onStartChat;
  final Color surface, border, purple, ts, tl, green, cardBg, cardBd;

  const _BottomBar({
    required this.post,
    required this.swapDone,
    required this.starting,
    required this.requesting,
    required this.onMarkDone,
    required this.onRequestSwap,
    required this.onStartChat,
    required this.surface,
    required this.border,
    required this.purple,
    required this.ts,
    required this.tl,
    required this.green,
    required this.cardBg,
    required this.cardBd,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: purple.withOpacity(isDark ? 0.10 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mark as done row
              GestureDetector(
                onTap: onMarkDone,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: double.infinity,
                  height: 46,
                  decoration: BoxDecoration(
                    color: swapDone
                        ? green.withOpacity(0.08)
                        : (isDark
                              ? const Color(0xFF1B1736)
                              : const Color(0xFFF7F6FF)),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: swapDone ? green.withOpacity(0.45) : border,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        swapDone
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        color: swapDone ? green : tl,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        swapDone ? 'Swap Done ✓' : 'Mark as Swap Done',
                        style: GoogleFonts.dmSans(
                          color: swapDone ? green : ts,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 9),
              // Action buttons row — no bookmark here anymore
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary: Request Swap
                  GestureDetector(
                    onTap: requesting ? null : onRequestSwap,
                    child: Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [purple, const Color(0xFF9B7DFF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: purple.withOpacity(0.30),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: requesting
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.swap_horiz_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 9),
                                Text(
                                  'Request Swap',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  // Secondary: Start Chat
                  GestureDetector(
                    onTap: starting ? null : onStartChat,
                    child: Container(
                      height: 40,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: cardBd),
                      ),
                      child: starting
                          ? Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: purple,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: ts,
                                  size: 15,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Start Chat',
                                  style: GoogleFonts.dmSans(
                                    color: ts,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
