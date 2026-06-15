// lib/screens/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/chat_model.dart';
import '../../services/notification_service.dart';
import '../../services/post_service.dart';
import '../../services/swap_service.dart';
import '../../utils/app_theme.dart';
import '../swaps/all_swaps_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Filter types
// ─────────────────────────────────────────────────────────────────────────────
enum _Filter {
  all,
  swap,
  rating,
  leaderboard,
  expiry,
  match;

  String get label {
    switch (this) {
      case all:
        return 'All';
      case swap:
        return 'Swap Requests';
      case rating:
        return 'Ratings';
      case leaderboard:
        return 'Leaderboard';
      case expiry:
        return 'Expiry';
      case match:
        return 'Matches';
    }
  }

  // Which DB notification types fall under this filter
  bool matches(String type) {
    switch (this) {
      case all:
        return true;
      case swap:
        return [
          'swap_request',
          'swap_request_accepted',
          'swap_request_declined',
          'swap_accepted',
          'swap_declined',
          'swap_completed',
        ].contains(type);
      case rating:
        return type == 'rating';
      case leaderboard:
        return type == 'leaderboard';
      case expiry:
        return type == 'post_expiry';
      case match:
        return ['new_match', 'bookmark'].contains(type);
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  NotificationsScreen
// ═════════════════════════════════════════════════════════════════════════════
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _Filter _activeFilter = _Filter.all;
  final Set<String> _acceptedIds = {};
  final Set<String> _declinedIds = {};
  final Set<String> _renewedIds = {};

  // ── theme ──────────────────────────────────────────────────────────────────
  bool get _d => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _d ? const Color(0xFF080A12) : const Color(0xFFFAFAFA);
  Color get _surface => _d ? const Color(0xFF0E1020) : Colors.white;
  Color get _tp => _d ? const Color(0xFFF0F2FF) : const Color(0xFF0A0A0A);
  Color get _ts => _d ? const Color(0xFF8890B8) : const Color(0xFF6E6E6E);
  Color get _tl => _d ? const Color(0xFF404468) : const Color(0xFFAAAAAA);
  Color get _bd =>
      _d ? Colors.white.withOpacity(0.07) : const Color(0xFFEFEFEF);
  Color get _unreadBg => _d ? const Color(0xFF100E22) : const Color(0xFFF3F0FF);
  Color get _chipBg => _d ? const Color(0xFF141628) : const Color(0xFFEDEAFF);

  static const _purple = Color(0xFF7C5CFC);
  static const _coral = Color(0xFFFF6B6B);
  static const _teal = Color(0xFF4ECDC4);
  static const _gold = Color(0xFFFFD700);
  static const _green = Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().fetchNotifications();
      context.read<NotificationService>().subscribeToNotifications();
      context.read<SwapService>().fetchAllSwaps();
    });
  }

  // ── actions ────────────────────────────────────────────────────────────────
  void _markAllRead() {
    HapticFeedback.selectionClick();
    context.read<NotificationService>().markAllRead();
    _snack('All marked as read ✅');
  }

  void _markOneRead(NotificationModel n) {
    if (!n.isRead) context.read<NotificationService>().markAsRead(n.id);
  }

  Future<void> _acceptSwap(NotificationModel n) async {
    HapticFeedback.mediumImpact();
    setState(() => _acceptedIds.add(n.id));
    _markOneRead(n);
    await context.read<NotificationService>().updateType(
      n.id,
      'swap_request_accepted',
    );
    final swapId = n.data['swap_id'] as String?;
    if (swapId != null) await context.read<SwapService>().confirmSwap(swapId);
    _snack('Swap confirmed! 🎉');
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AllSwapsScreen()),
      );
    }
  }

  void _declineSwap(NotificationModel n) {
    HapticFeedback.lightImpact();
    setState(() => _declinedIds.add(n.id));
    _markOneRead(n);
    context.read<NotificationService>().updateType(
      n.id,
      'swap_request_declined',
    );
    final swapId = n.data['swap_id'] as String?;
    if (swapId != null) context.read<SwapService>().declineSwap(swapId);
    _snack('Request declined');
  }

  Future<void> _renewPost(NotificationModel n) async {
    setState(() => _renewedIds.add(n.id));
    _markOneRead(n);
    final postId = n.data['post_id'] as String?;
    if (postId != null) {
      final success = await context.read<PostService>().renewPost(postId);
      if (success) {
        _snack('Post renewed for 30 more days ✅');
      } else {
        setState(() => _renewedIds.remove(n.id)); // revert on failure
        _snack('Could not renew post. Please try again.');
      }
    } else {
      _snack('Post renewed ✅');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: _d ? const Color(0xFF1A1D35) : _purple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ── filtering ──────────────────────────────────────────────────────────────
  List<NotificationModel> _filtered(List<NotificationModel> all) =>
      all.where((n) => _activeFilter.matches(n.type)).toList();

  // ── grouping ───────────────────────────────────────────────────────────────
  Map<String, List<NotificationModel>> _group(List<NotificationModel> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yest = today.subtract(const Duration(days: 1));
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final Map<String, List<NotificationModel>> map = {};
    for (final n in list) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      final key = d == today
          ? 'Today'
          : d == yest
          ? 'Yesterday'
          : '${months[n.createdAt.month]} ${n.createdAt.day}';
      (map[key] ??= []).add(n);
    }
    return map;
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterRow(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Consumer<NotificationService>(
      builder: (_, svc, __) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
        child: Row(
          children: [
            // back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _chipBg,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _bd),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: _d ? Colors.white70 : const Color(0xFF5E5A80),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _tp,
                    ),
                  ),
                  if (svc.unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _purple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${svc.unreadCount}',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (svc.unreadCount > 0)
              GestureDetector(
                onTap: _markAllRead,
                child: Text(
                  'Mark all read',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _purple,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── filter chips ───────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _Filter.values.map((f) {
          final active = _activeFilter == f;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _activeFilter = f);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active ? _purple : _chipBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? _purple : _bd, width: 1.5),
              ),
              child: Text(
                f.label,
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? Colors.white : _ts,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── body ───────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Consumer<NotificationService>(
      builder: (_, svc, __) {
        if (svc.isLoading && svc.notifications.isEmpty) return _buildShimmer();

        final filtered = _filtered(svc.notifications);

        if (filtered.isEmpty) return _buildEmpty();

        final grouped = _group(filtered);
        final items = <dynamic>[];
        for (final e in grouped.entries) {
          items.add(e.key);
          items.addAll(e.value);
        }

        return RefreshIndicator(
          color: _purple,
          onRefresh: () =>
              context.read<NotificationService>().fetchNotifications(),
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 32),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              if (item is String) {
                return _SectionHeader(
                  label: item,
                  count: (grouped[item] ?? []).where((n) => !n.isRead).length,
                  tp: _tp,
                  tl: _tl,
                  purple: _purple,
                ).animate().fadeIn(delay: 30.ms);
              }
              final n = item as NotificationModel;
              return _NotifCard(
                key: ValueKey(n.id),
                notif: n,
                isDark: _d,
                surface: _surface,
                tp: _tp,
                ts: _ts,
                tl: _tl,
                bd: _bd,
                unreadBg: _unreadBg,
                isAccepted:
                    _acceptedIds.contains(n.id) ||
                    n.type == 'swap_request_accepted',
                isDeclined:
                    _declinedIds.contains(n.id) ||
                    n.type == 'swap_request_declined',
                isRenewed: _renewedIds.contains(n.id),
                onTap: () => _markOneRead(n),
                onAccept: () => _acceptSwap(n),
                onDecline: () => _declineSwap(n),
                onRenew: () => _renewPost(n),
              ).animate().fadeIn(delay: Duration(milliseconds: i * 30));
            },
          ),
        );
      },
    );
  }

  // ── shimmer ────────────────────────────────────────────────────────────────
  Widget _buildShimmer() {
    final base = _d ? const Color(0xFF0E1020) : const Color(0xFFEEEEEE);
    final high = _d ? const Color(0xFF1A1D35) : const Color(0xFFF8F8F8);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      itemCount: 5,
      itemBuilder: (_, i) =>
          Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: high,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 11,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: high,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Container(
                            height: 10,
                            width: 180,
                            decoration: BoxDecoration(
                              color: high,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 9,
                            width: 80,
                            decoration: BoxDecoration(
                              color: high,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                delay: Duration(milliseconds: i * 80),
                duration: const Duration(milliseconds: 1100),
                color: high.withOpacity(0.5),
              ),
    );
  }

  // ── empty ──────────────────────────────────────────────────────────────────
  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _purple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('🔔', style: TextStyle(fontSize: 34)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'All caught up!',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _tp,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _activeFilter == _Filter.all
              ? 'No notifications yet'
              : 'No ${_activeFilter.label.toLowerCase()} notifications',
          style: GoogleFonts.dmSans(fontSize: 13, color: _ts),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.08),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
//  Section header
// ═════════════════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color tp, tl, purple;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.tp,
    required this.tl,
    required this.purple,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: tl,
            ),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: purple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count new',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: purple,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Notification card
// ═════════════════════════════════════════════════════════════════════════════
class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  final bool isDark;
  final Color surface, tp, ts, tl, bd, unreadBg;
  final bool isAccepted, isDeclined, isRenewed;
  final VoidCallback onTap, onAccept, onDecline, onRenew;

  static const _purple = Color(0xFF7C5CFC);
  static const _coral = Color(0xFFFF6B6B);
  static const _teal = Color(0xFF4ECDC4);
  static const _gold = Color(0xFFFFD700);
  static const _green = Color(0xFF22C55E);
  static const _amber = Color(0xFFFFB800);

  const _NotifCard({
    super.key,
    required this.notif,
    required this.isDark,
    required this.surface,
    required this.tp,
    required this.ts,
    required this.tl,
    required this.bd,
    required this.unreadBg,
    required this.isAccepted,
    required this.isDeclined,
    required this.isRenewed,
    required this.onTap,
    required this.onAccept,
    required this.onDecline,
    required this.onRenew,
  });

  // ── per-type icon config ──────────────────────────────────────────────────
  ({String? emoji, String? initials, Color color, Color? badgeColor})
  get _icon {
    switch (notif.type) {
      case 'swap_request':
        final name = notif.data['requester_name'] as String? ?? notif.title;
        final parts = name.trim().split(' ');
        final init = parts.length >= 2
            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
            : name.substring(0, name.length.clamp(0, 2)).toUpperCase();
        return (
          emoji: null,
          initials: init,
          color: _purple,
          badgeColor: _purple,
        );
      case 'swap_request_accepted':
      case 'swap_accepted':
        return (emoji: '🤝', initials: null, color: _green, badgeColor: _green);
      case 'swap_request_declined':
      case 'swap_declined':
        return (emoji: '✗', initials: null, color: _coral, badgeColor: _coral);
      case 'swap_completed':
        return (emoji: '✅', initials: null, color: _green, badgeColor: null);
      case 'rating':
        return (emoji: '⭐', initials: null, color: _amber, badgeColor: _gold);
      case 'leaderboard':
        return (emoji: '🏆', initials: null, color: _gold, badgeColor: null);
      case 'post_expiry':
        return (emoji: '⏳', initials: null, color: _coral, badgeColor: null);
      case 'new_match':
      case 'bookmark':
        return (emoji: '🔖', initials: null, color: _teal, badgeColor: null);
      default:
        return (emoji: '🔔', initials: null, color: _purple, badgeColor: null);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const m = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[dt.month]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final icon = _icon;
    final isUnread = !notif.isRead;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        decoration: BoxDecoration(
          color: isUnread ? unreadBg : surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread ? _purple.withOpacity(0.28) : bd,
            width: isUnread ? 1.5 : 1,
          ),
          boxShadow: isUnread
              ? [
                  BoxShadow(
                    color: _purple.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // left accent bar for unread
            if (isUnread)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: _purple,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── avatar ────────────────────────────────────────────────
                  _buildAvatar(icon, isUnread),
                  const SizedBox(width: 12),
                  // ── content ───────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // name + time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: tp,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _timeAgo(notif.createdAt),
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: tl,
                              ),
                            ),
                          ],
                        ),
                        // body
                        if (notif.body != null && notif.body!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            notif.body!,
                            style: GoogleFonts.dmSans(
                              fontSize: 12.5,
                              color: ts,
                              height: 1.45,
                            ),
                          ),
                        ],
                        // skill exchange pill (swap requests)
                        if (notif.type == 'swap_request') ...[
                          const SizedBox(height: 8),
                          _buildSkillPill(),
                        ],
                        // leaderboard badge
                        if (notif.type == 'leaderboard') ...[
                          const SizedBox(height: 8),
                          _buildLeaderboardBadge(),
                        ],
                        // star rating
                        if (notif.type == 'rating') ...[
                          const SizedBox(height: 6),
                          _buildStars(),
                        ],
                        // expiry bar
                        if (notif.type == 'post_expiry') ...[
                          const SizedBox(height: 8),
                          _buildExpiryBar(),
                        ],
                        // match skill pill
                        if (notif.type == 'new_match' ||
                            notif.type == 'bookmark') ...[
                          const SizedBox(height: 8),
                          _buildMatchPill(),
                        ],
                        // action buttons
                        const SizedBox(height: 10),
                        _buildActions(context),
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

  // ── avatar ─────────────────────────────────────────────────────────────────
  Widget _buildAvatar(
    ({String? emoji, String? initials, Color color, Color? badgeColor}) icon,
    bool isUnread,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: icon.color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: icon.color.withOpacity(0.3)),
          ),
          alignment: Alignment.center,
          child: icon.emoji != null
              ? Text(icon.emoji!, style: const TextStyle(fontSize: 19))
              : Text(
                  icon.initials ?? '?',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: icon.color,
                  ),
                ),
        ),
        // unread dot
        if (isUnread)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _purple,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF080A12)
                      : const Color(0xFFFAFAFA),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(color: _purple.withOpacity(0.6), blurRadius: 5),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── skill exchange pill ────────────────────────────────────────────────────
  Widget _buildSkillPill() {
    final offered = notif.data['offered_skill'] as String?;
    final wanted = notif.data['wanted_skill'] as String?;
    if (offered == null && wanted == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141628) : const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _purple.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (offered != null) _SkillTag(label: offered, color: _purple),
          if (offered != null && wanted != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '⇄',
                style: TextStyle(color: _purple.withOpacity(0.6), fontSize: 13),
              ),
            ),
          if (wanted != null) _SkillTag(label: wanted, color: _coral),
        ],
      ),
    );
  }

  // ── leaderboard badge ──────────────────────────────────────────────────────
  Widget _buildLeaderboardBadge() {
    final rank = notif.data['rank'] as String? ?? '#?';
    final points = notif.data['points'] as String?;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_gold.withOpacity(0.15), Colors.orange.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _gold.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏅', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            points != null ? 'Rank $rank · $points pts' : 'Rank $rank',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _gold,
            ),
          ),
        ],
      ),
    );
  }

  // ── star rating ────────────────────────────────────────────────────────────
  Widget _buildStars() {
    final rating = (notif.data['rating'] as num?)?.toInt() ?? 5;
    return Row(
      children: [
        Row(
          children: List.generate(
            5,
            (i) => Text(
              i < rating ? '★' : '☆',
              style: TextStyle(
                fontSize: 14,
                color: i < rating ? _gold : _gold.withOpacity(0.3),
              ),
            ),
          ),
        ),
        if (notif.data['review'] != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '"${notif.data['review']}"',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(fontSize: 11, color: ts),
            ),
          ),
        ],
      ],
    );
  }

  // ── expiry bar ─────────────────────────────────────────────────────────────
  Widget _buildExpiryBar() {
    final pct = (notif.data['expiry_pct'] as num?)?.toDouble() ?? 0.25;
    final hrs = notif.data['hours_left'] as String? ?? '?';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 5,
            backgroundColor: isDark
                ? const Color(0xFF1A1D35)
                : const Color(0xFFEEEEEE),
            valueColor: AlwaysStoppedAnimation<Color>(_coral),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(pct * 100).toInt()}% remaining',
              style: GoogleFonts.dmSans(fontSize: 10, color: ts),
            ),
            Text(
              '$hrs hrs left',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _coral,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── match pill ─────────────────────────────────────────────────────────────
  Widget _buildMatchPill() {
    final s1 = notif.data['skill_1'] as String?;
    final s2 = notif.data['skill_2'] as String?;
    if (s1 == null && s2 == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1E1D) : const Color(0xFFE8FAF9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _teal.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (s1 != null) _SkillTag(label: s1, color: _teal),
          if (s1 != null && s2 != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '✦',
                style: TextStyle(color: _teal.withOpacity(0.7), fontSize: 11),
              ),
            ),
          if (s2 != null) _SkillTag(label: s2, color: _purple),
        ],
      ),
    );
  }

  // ── action buttons ─────────────────────────────────────────────────────────
  Widget _buildActions(BuildContext context) {
    switch (notif.type) {
      case 'swap_request':
        if (isAccepted) return _chip('✓ Accepted', _green);
        if (isDeclined) return _chip('Declined', ts);
        return Row(
          children: [
            _gradBtn('✓ Accept', onAccept),
            const SizedBox(width: 8),
            _ghostBtn('Decline', onDecline),
          ],
        );

      case 'swap_request_accepted':
        return _chip('✓ Accepted', _green);
      case 'swap_request_declined':
        return _chip('Declined', ts);

      case 'swap_accepted':
        return _outlineBtn('View My Swaps', () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AllSwapsScreen()),
          );
        }, color: _green);

      case 'swap_declined':
        return _chip('Request was declined', _coral);

      case 'post_expiry':
        if (isRenewed) return _chip('Renewed ✅', _green);
        return Row(
          children: [
            _gradBtn(
              'Renew Post',
              onRenew,
              colors: [_coral, const Color(0xFFFF8E53)],
            ),
            const SizedBox(width: 8),
            _ghostBtn('View Post', () {}),
          ],
        );

      case 'leaderboard':
        return _outlineBtn('View Leaderboard →', () {}, color: _gold);

      case 'new_match':
      case 'bookmark':
        return Row(
          children: [
            _gradBtn(
              'View Profile',
              () {},
              colors: [_teal, const Color(0xFF00D4AA)],
            ),
            const SizedBox(width: 8),
            _ghostBtn('Message', () {}),
          ],
        );

      case 'rating':
        return _outlineBtn('View Review', () {}, color: _amber);

      default:
        final label = notif.data['action_label'] as String?;
        if (label != null) return _gradBtn(label, () {});
        return const SizedBox.shrink();
    }
  }

  Widget _gradBtn(
    String label,
    VoidCallback onTap, {
    List<Color> colors = const [_purple, Color(0xFFFF4D7D)],
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ),
  );

  Widget _ghostBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141628) : const Color(0xFFEDEAFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bd),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: ts,
        ),
      ),
    ),
  );

  Widget _outlineBtn(
    String label,
    VoidCallback onTap, {
    required Color color,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ),
  );

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
//  Skill tag pill
// ═════════════════════════════════════════════════════════════════════════════
class _SkillTag extends StatelessWidget {
  final String label;
  final Color color;
  const _SkillTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}
