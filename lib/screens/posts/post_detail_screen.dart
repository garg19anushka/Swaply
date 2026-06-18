// lib/screens/posts/post_detail_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
//  PostDetailScreen — full LIGHT theme
//  Palette:
//    bg          #F7F6FF  (faint lavender white — never cold paper)
//    surface     #FFFFFF  (cards, app bar)
//    border      #ECEAF9  (soft violet-tinted dividers)
//    tp          #110D2E  (near-black with a violet cast)
//    ts          #6B688E  (mid-tone violet-grey)
//    tl          #AAA8C4  (placeholder / timestamps)
//    purple      #6C47FF  (brand primary — AppColors.primary)
//    coral       #FF4D6D  (AppColors.secondary / wants)
//    amber       #FFBE0B  (warning / stars)
//    teal        #00C9A7  (success / done)
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

// ── Light palette constants ───────────────────────────────────────────────────
const _bg = Color(0xFFF7F6FF);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFECEAF9);
const _tp = Color(0xFF110D2E);
const _ts = Color(0xFF6B688E);
const _tl = Color(0xFFAAA8C4);
const _purple = Color(0xFF6C47FF);
const _coral = Color(0xFFFF4D6D);
const _amber = Color(0xFFFFBE0B);
const _teal = Color(0xFF00C9A7);
const _green = Color(0xFF4CAF7D);

// Offers box
const _offBoxBg = Color(0xFFF0EDFF);
const _offBoxBd = Color(0xFFD4CCFF);

// Wants box
const _wantBoxBg = Color(0xFFFFF0F3);
const _wantBoxBd = Color(0xFFFFCDD5);

// Bottom bar card surface
const _cardBg = Color(0xFFFFFFFF);
const _cardBd = Color(0xFFECEAF9);

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
          MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
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
              child: const Icon(
                Icons.chevron_left_rounded,
                color: _tp,
                size: 22,
              ),
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
              onToggleSave: _toggleSave,
              onRequestSwap: _requestSwap,
              onStartChat: _startSwap,
            ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero header — gradient banner ─────────────────────────────
            _HeroBanner(post: post),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tags ─────────────────────────────────────────────
                  if (post.tags.isNotEmpty) ...[
                    _TagRow(post: post),
                    const SizedBox(height: 18),
                  ],

                  // ── Skill exchange card ───────────────────────────────
                  _ExchangeCard(post: post)
                      .animate()
                      .fadeIn(delay: 80.ms)
                      .slideY(begin: 0.04, delay: 80.ms),
                  const SizedBox(height: 20),

                  // ── Author card ───────────────────────────────────────
                  _AuthorCard(post: post).animate().fadeIn(delay: 120.ms),
                  const SizedBox(height: 20),

                  // ── About ─────────────────────────────────────────────
                  _SectionLabel(label: 'About this swap'),
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
                    _SectionLabel(label: 'Availability'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availabilityTags
                          .map((t) => _AvailPill(label: t))
                          .toList(),
                    ).animate().fadeIn(delay: 160.ms),
                    const SizedBox(height: 24),
                  ],

                  // ── Stats ─────────────────────────────────────────────
                  _SectionLabel(label: 'Swap Stats'),
                  const SizedBox(height: 10),
                  _StatsRow(post: post).animate().fadeIn(delay: 180.ms),

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
  const _HeroBanner({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEDE8FF), Color(0xFFFFF0F3), Color(0xFFF7F6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: _border)),
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
                color: _amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _amber.withOpacity(0.45)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_open_rounded, size: 12, color: _amber),
                  const SizedBox(width: 5),
                  Text(
                    'Open Request',
                    style: GoogleFonts.dmSans(
                      color: _amber,
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
              color: _tp,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              height: 1.2,
            ),
          ).animate().fadeIn().slideY(begin: 0.04),
          const SizedBox(height: 8),
          // Small meta row
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 13, color: _tl),
              const SizedBox(width: 4),
              Text(
                timeago.format(post.createdAt),
                style: GoogleFonts.dmSans(color: _tl, fontSize: 12),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.bookmark_outline_rounded, size: 13, color: _tl),
              const SizedBox(width: 4),
              Text(
                '${post.bookmarksCount} saves',
                style: GoogleFonts.dmSans(color: _tl, fontSize: 12),
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
  const _ExchangeCard({required this.post});

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
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
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
          // OFFERS
          Expanded(
            child: _SkillPanel(
              label: 'OFFERS',
              value: post.skillOffered,
              valueColor: _purple,
              bg: _offBoxBg,
              borderColor: _offBoxBd,
            ),
          ),
          // swap arrow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    size: 17,
                    color: _tl,
                  ),
                ),
              ],
            ),
          ),
          // WANTS / OFFERS
          Expanded(
            child: _SkillPanel(
              label: wantLabel,
              value: wantValue,
              valueColor: _coral,
              bg: _wantBoxBg,
              borderColor: _wantBoxBd,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillPanel extends StatelessWidget {
  final String label, value;
  final Color valueColor, bg, borderColor;
  const _SkillPanel({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.bg,
    required this.borderColor,
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
              color: _tl,
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
  const _AuthorCard({required this.post});

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
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                      color: _tp,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${post.profile?.username ?? ''}'
                    '${(post.profile?.campus?.isNotEmpty == true) ? '  ·  ${post.profile!.campus}' : ''}',
                    style: GoogleFonts.dmSans(color: _ts, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // rating badge
            if ((post.profile?.averageRating ?? 0) > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _amber.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _amber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 13, color: _amber),
                    const SizedBox(width: 3),
                    Text(
                      post.profile!.averageRating.toStringAsFixed(1),
                      style: GoogleFonts.dmSans(
                        color: _amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: _tl, size: 20),
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
  const _StatsRow({required this.post});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(
          value: '${post.profile?.totalSwaps ?? 0}',
          label: 'Swaps done',
          accentColor: _purple,
        ),
        const SizedBox(width: 10),
        _StatBox(
          value: (post.profile?.averageRating ?? 0) > 0
              ? post.profile!.averageRating.toStringAsFixed(1)
              : '–',
          label: 'Avg rating',
          icon: Icons.star_rounded,
          accentColor: _amber,
        ),
        const SizedBox(width: 10),
        _StatBox(
          value: '${post.bookmarksCount}',
          label: 'Bookmarks',
          accentColor: _coral,
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label;
  final IconData? icon;
  final Color accentColor;
  const _StatBox({
    required this.value,
    required this.label,
    this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                    color: _tp,
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
                color: _ts,
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
  const _TagRow({required this.post});

  Color _color(String tag) {
    if (tag == 'Urgent') return AppColors.error;
    if (tag == 'Quick Help') return _amber;
    if (tag == 'Online' || tag == 'Online Only') return _teal;
    if (tag == 'Beginner-friendly') return _green;
    return _purple;
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
  const _AvailPill({required this.label});

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
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              color: _ts,
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
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        color: _tp,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bottom bar (extracted to keep build() clean)
// ─────────────────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final PostModel post;
  final bool swapDone, starting, requesting;
  final VoidCallback onMarkDone, onToggleSave, onRequestSwap, onStartChat;

  const _BottomBar({
    required this.post,
    required this.swapDone,
    required this.starting,
    required this.requesting,
    required this.onMarkDone,
    required this.onToggleSave,
    required this.onRequestSwap,
    required this.onStartChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D6C47FF),
            blurRadius: 20,
            offset: Offset(0, -4),
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
                        ? _green.withOpacity(0.08)
                        : const Color(0xFFF7F6FF),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: swapDone ? _green.withOpacity(0.45) : _border,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        swapDone
                            ? Icons.check_circle_rounded
                            : Icons.check_circle_outline_rounded,
                        color: swapDone ? _green : _tl,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        swapDone ? 'Swap Done ✓' : 'Mark as Swap Done',
                        style: GoogleFonts.dmSans(
                          color: swapDone ? _green : _ts,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 9),
              // Bookmark + action buttons row
              Row(
                children: [
                  // Bookmark
                  GestureDetector(
                    onTap: onToggleSave,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 50,
                      height: 52,
                      decoration: BoxDecoration(
                        color: post.isBookmarked
                            ? _purple.withOpacity(0.08)
                            : _cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: post.isBookmarked
                              ? _purple.withOpacity(0.45)
                              : _cardBd,
                          width: post.isBookmarked ? 1.5 : 1,
                        ),
                      ),
                      child: Icon(
                        post.isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        color: post.isBookmarked ? _purple : _ts,
                        size: 21,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Primary: Request Swap
                        GestureDetector(
                          onTap: requesting ? null : onRequestSwap,
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_purple, Color(0xFF9B7DFF)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: _purple.withOpacity(0.30),
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
                            decoration: BoxDecoration(
                              color: _cardBg,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: _cardBd),
                            ),
                            child: starting
                                ? const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: _purple,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        color: _ts,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        'Start Chat',
                                        style: GoogleFonts.dmSans(
                                          color: _ts,
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
