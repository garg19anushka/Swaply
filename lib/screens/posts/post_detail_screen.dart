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
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../chat/chat_screen.dart';
import '../profile/user_profile_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  PostDetailScreen  –  "Skill Details"
// ═══════════════════════════════════════════════════════════════════════════
class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _starting = false;

  // ── Theme tokens ──────────────────────────────────────────────────────────
  bool get _d => Theme.of(context).brightness == Brightness.dark;

  // Card always renders on a near-black surface (matches screenshot dark style)
  Color get _bg => _d ? const Color(0xFF0E0D1C) : const Color(0xFF12111F);
  Color get _sf => _d ? const Color(0xFF161526) : const Color(0xFF1A1830);
  Color get _card => _d ? const Color(0xFF1A1930) : const Color(0xFF1E1C35);
  Color get _bd => _d ? const Color(0xFF252442) : const Color(0xFF2A2848);
  Color get _tp => const Color(0xFFF0F0FF);
  Color get _ts => const Color(0xFF9090B8);
  Color get _tl => const Color(0xFF555578);

  static const _purple = Color(0xFF7C5CFC);
  static const _offClr = Color(0xFF7C5CFC);
  static const _wantClr = Color(0xFFFF4D6D);
  static const _warning = Color(0xFFFFC107);

  PostModel get post => widget.post;

  // ── CTA: Start Chat & Swap ────────────────────────────────────────────────
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

  // ── Bookmark toggle ───────────────────────────────────────────────────────
  Future<void> _toggleSave() async {
    HapticFeedback.lightImpact();
    await context.read<PostService>().toggleBookmark(post.id);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isOwn = auth.currentUser?.id == post.userId;
    final isBarter = post.exchangeType == 'barter';

    return Scaffold(
      backgroundColor: _bg,

      // ── AppBar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _sf,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _bd, width: 1),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _bd),
        ),
        actions: [
          // Bookmark icon top-right
          GestureDetector(
            onTap: _toggleSave,
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Icon(
                post.isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                color: post.isBookmarked ? _purple : _ts,
                size: 22,
              ),
            ),
          ),
        ],
      ),

      // ── CTA bottom bar ──────────────────────────────────────────────────
      bottomNavigationBar: isOwn
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    // Bookmark button (left)
                    GestureDetector(
                      onTap: _toggleSave,
                      child: Container(
                        width: 50,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: post.isBookmarked
                                ? _purple.withOpacity(0.6)
                                : _bd,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          post.isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          color: post.isBookmarked ? _purple : _ts,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Start Chat & Swap (full-width gradient)
                    Expanded(
                      child: GestureDetector(
                        onTap: _starting ? null : _startSwap,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5B52E8), Color(0xFF7C5CFC)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _purple.withOpacity(0.45),
                                blurRadius: 16,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _starting
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
                                      Icons.chat_bubble_outline_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 9),
                                    Text(
                                      'Start Chat & Swap',
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
                    ),
                  ],
                ),
              ),
            ),

      // ── Body ─────────────────────────────────────────────────────────────
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Open Request badge + tags ──────────────────────────────
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  if (post.isOpenRequest)
                    _Pill(
                      label: 'Open Request',
                      icon: Icons.lock_open_rounded,
                      color: _warning,
                    ),
                  ...post.tags.map((t) => _TagPill(tag: t)),
                ],
              ).animate().fadeIn(),
              const SizedBox(height: 16),

              // ── Title ─────────────────────────────────────────────────
              Text(
                post.title,
                style: GoogleFonts.dmSans(
                  color: _tp,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.25,
                ),
              ).animate().fadeIn(delay: 40.ms),
              const SizedBox(height: 16),

              // ── Author card ───────────────────────────────────────────
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileScreen(userId: post.userId),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _bd, width: 1),
                  ),
                  child: Row(
                    children: [
                      AvatarWidget(
                        avatarUrl: post.profile?.avatarUrl,
                        username: post.profile?.username ?? '',
                        radius: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.profile?.fullName ??
                                  post.profile?.username ??
                                  'Unknown',
                              style: GoogleFonts.dmSans(
                                color: _tp,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '@${post.profile?.username ?? ''}'
                              '${(post.profile?.campus?.isNotEmpty == true) ? ' · ${post.profile!.campus}' : ''}'
                              ' · ${timeago.format(post.createdAt)}',
                              style: GoogleFonts.dmSans(
                                color: _ts,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: _tl, size: 20),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 80.ms),
              const SizedBox(height: 20),

              // ── SKILL EXCHANGE card ───────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _bd, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header label
                    Text(
                      'SKILL EXCHANGE',
                      style: GoogleFonts.dmSans(
                        color: _tl,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // OFFERING ↔ OPEN TO
                    Row(
                      children: [
                        // OFFERING side
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OFFERING',
                                style: GoogleFonts.dmSans(
                                  color: _tl,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _purple.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _purple.withOpacity(0.35),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  post.skillOffered,
                                  style: GoogleFonts.dmSans(
                                    color: _offClr,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Swap icon
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF252445),
                              shape: BoxShape.circle,
                              border: Border.all(color: _bd, width: 1),
                            ),
                            child: Icon(
                              Icons.swap_horiz_rounded,
                              color: _ts,
                              size: 18,
                            ),
                          ),
                        ),
                        // OPEN TO side
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isBarter ? 'OPEN TO' : 'OFFERING',
                                style: GoogleFonts.dmSans(
                                  color: _tl,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _wantClr.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _wantClr.withOpacity(0.35),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  isBarter
                                      ? (post.skillWanted ?? 'Any Skill')
                                      : (post.customOffer ?? 'Custom'),
                                  style: GoogleFonts.dmSans(
                                    color: _wantClr,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 120.ms),
              const SizedBox(height: 20),

              // ── About this swap ───────────────────────────────────────
              Text(
                'About this swap',
                style: GoogleFonts.dmSans(
                  color: _tp,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.description,
                style: GoogleFonts.dmSans(
                  color: _ts,
                  fontSize: 14,
                  height: 1.65,
                ),
              ).animate().fadeIn(delay: 140.ms),
              const SizedBox(height: 20),

              // ── Availability pills (derived from tags) ────────────────
              if (_availabilityTags.isNotEmpty) ...[
                Text(
                  'Availability',
                  style: GoogleFonts.dmSans(
                    color: _tp,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availabilityTags
                      .map(
                        (t) => _AvailabilityPill(
                          label: t,
                          card: _card,
                          bd: _bd,
                          ts: _ts,
                        ),
                      )
                      .toList(),
                ).animate().fadeIn(delay: 160.ms),
                const SizedBox(height: 20),
              ],

              // ── Swap Stats ────────────────────────────────────────────
              Text(
                'Swap Stats',
                style: GoogleFonts.dmSans(
                  color: _tp,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatBox(
                    value: '${post.profile?.totalSwaps ?? 0}',
                    label: 'Swaps done',
                    icon: null,
                    card: _card,
                    bd: _bd,
                    tp: _tp,
                    ts: _ts,
                  ),
                  const SizedBox(width: 10),
                  _StatBox(
                    value: (post.profile?.averageRating ?? 0) > 0
                        ? post.profile!.averageRating.toStringAsFixed(1)
                        : '–',
                    label: 'Avg rating',
                    icon: Icons.star_rounded,
                    iconColor: _warning,
                    card: _card,
                    bd: _bd,
                    tp: _tp,
                    ts: _ts,
                  ),
                  const SizedBox(width: 10),
                  _StatBox(
                    value: '${post.bookmarksCount}',
                    label: 'Bookmarks',
                    icon: null,
                    card: _card,
                    bd: _bd,
                    tp: _tp,
                    ts: _ts,
                  ),
                ],
              ).animate().fadeIn(delay: 180.ms),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // Derive availability from tags
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
//  Pill  –  coloured badge (Open Request, etc.)
// ─────────────────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Pill({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tag pill
// ─────────────────────────────────────────────────────────────────────────────
class _TagPill extends StatelessWidget {
  final String tag;
  const _TagPill({required this.tag});

  Color get _color {
    if (tag == 'Urgent') return AppColors.error;
    if (tag == 'Quick Help') return AppColors.warning;
    if (tag == 'Online' || tag == 'Online Only') return AppColors.accentTeal;
    if (tag == 'Beginner-friendly') return const Color(0xFF4CAF7D);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.35), width: 1),
      ),
      child: Text(
        tag,
        style: GoogleFonts.dmSans(
          fontSize: 11.5,
          color: c,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Availability pill  – emoji icon + label
// ─────────────────────────────────────────────────────────────────────────────
class _AvailabilityPill extends StatelessWidget {
  final String label;
  final Color card, bd, ts;
  const _AvailabilityPill({
    required this.label,
    required this.card,
    required this.bd,
    required this.ts,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bd, width: 1),
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
//  Stat box
// ─────────────────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String value, label;
  final IconData? icon;
  final Color? iconColor;
  final Color card, bd, tp, ts;

  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    this.iconColor,
    required this.card,
    required this.bd,
    required this.tp,
    required this.ts,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bd, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: iconColor),
                  const SizedBox(width: 4),
                ],
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    color: tp,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
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
