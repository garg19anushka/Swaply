// lib/screens/notifications/notifications_screen.dart
//
// Full real-time notifications screen wired to NotificationService + Supabase.
// Drop this file into lib/screens/notifications/notifications_screen.dart.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/chat_model.dart';
import '../../services/notification_service.dart';
import '../../services/swap_service.dart';
import '../../utils/app_theme.dart';
import '../swaps/all_swaps_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Colour constants
// ─────────────────────────────────────────────────────────────────────────────
const _purple = Color(0xFF7C5CFC);
const _pink = Color(0xFFFF4D7D);
const _amber = Color(0xFFFFB800);
const _teal = Color(0xFF00D4AA);
const _green = Color(0xFF22C55E);
const _cyan = Color(0xFF00E5FF);

// ═════════════════════════════════════════════════════════════════════════════
//  NotificationsScreen
// ═════════════════════════════════════════════════════════════════════════════
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Local accepted/declined/renewed state (optimistic UI)
  final Set<String> _acceptedIds = {};
  final Set<String> _declinedIds = {};
  final Set<String> _renewedIds = {};

  // ── theme shortcuts ────────────────────────────────────────────────────────
  bool get _d => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _d ? const Color(0xFF080A12) : const Color(0xFFF4F3FF);
  Color get _tp => _d ? const Color(0xFFF0F2FF) : const Color(0xFF0A0814);
  Color get _ts => _d ? const Color(0xFF8890B8) : const Color(0xFF5E5A80);
  Color get _tl => _d ? const Color(0xFF404468) : const Color(0xFFA09DC0);
  Color get _bd =>
      _d ? Colors.white.withOpacity(0.07) : _purple.withOpacity(0.12);
  Color get _cardBg => _d ? const Color(0xFF0E1020) : Colors.white;
  Color get _unreadBg => _purple.withOpacity(_d ? 0.05 : 0.04);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().fetchNotifications();
      context.read<NotificationService>().subscribeToNotifications();
    });
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  void _markAllRead() {
    HapticFeedback.selectionClick();
    context.read<NotificationService>().markAllRead();
    _snack('All marked as read ✅');
  }

  void _markOneRead(NotificationModel n) {
    if (n.isRead) return;
    context.read<NotificationService>().markAsRead(n.id);
  }

  Future<void> _acceptSwap(NotificationModel n) async {
    HapticFeedback.mediumImpact();
    setState(() => _acceptedIds.add(n.id));
    _markOneRead(n);

    // Persist the action to the DB by updating the notification type.
    // _acceptedIds is in-memory only and resets on every rebuild/navigate.
    // Storing 'swap_request_accepted' in the DB means the chip renders
    // correctly after navigating away and coming back.
    await context.read<NotificationService>().updateType(
      n.id,
      'swap_request_accepted',
    );

    final swapId = n.data['swap_id'] as String?;
    if (swapId != null) {
      await context.read<SwapService>().confirmSwap(swapId);
    }

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

    // Same fix: persist so the "Declined" chip survives reload.
    context.read<NotificationService>().updateType(
      n.id,
      'swap_request_declined',
    );

    final swapId = n.data['swap_id'] as String?;
    if (swapId != null) {
      context.read<SwapService>().declineSwap(swapId);
    }

    _snack('Request declined');
  }

  void _renewPost(NotificationModel n) {
    setState(() => _renewedIds.add(n.id));
    _markOneRead(n);
    _snack('Post renewed for 30 more days! ✅');
  }

  void _handleAction(NotificationModel n) {
    _markOneRead(n);
    final route = n.data['route'] as String?;
    if (route != null && Navigator.canPop(context)) {
      Navigator.pushNamed(context, route);
      return;
    }
    switch (n.type) {
      case 'leaderboard':
        _snack('Opening leaderboard…');
      case 'new_match':
        _snack('Opening explore…');
      default:
        _snack(n.data['action_label'] as String? ?? '');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: _d ? const Color(0xFF1A1D35) : _purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── group by date ──────────────────────────────────────────────────────────
  Map<String, List<NotificationModel>> _group(List<NotificationModel> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yest = today.subtract(const Duration(days: 1));

    final Map<String, List<NotificationModel>> map = {};
    for (final n in list) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      final String key;
      if (d == today) {
        key = 'Today';
      } else if (d == yest) {
        key = 'Yesterday';
      } else {
        key = _formatDate(n.createdAt);
      }
      (map[key] ??= []).add(n);
    }
    return map;
  }

  String _formatDate(DateTime dt) {
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
    return '${months[dt.month]} ${dt.day}';
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
            Expanded(
              child: Consumer<NotificationService>(
                builder: (_, svc, __) {
                  if (svc.isLoading && svc.notifications.isEmpty) {
                    return _buildShimmer();
                  }

                  if (svc.notifications.isEmpty) {
                    return _buildEmpty();
                  }

                  final grouped = _group(svc.notifications);

                  return RefreshIndicator(
                    color: _purple,
                    onRefresh: () => context
                        .read<NotificationService>()
                        .fetchNotifications(),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 32),
                      itemCount: grouped.entries.fold<int>(
                        0,
                        (sum, e) => sum + 1 + e.value.length,
                      ),
                      itemBuilder: (_, idx) {
                        // Flatten entries into a mixed label/item list
                        final items = <dynamic>[];
                        for (final e in grouped.entries) {
                          items.add(e.key); // section label (String)
                          items.addAll(e.value); // notifications
                        }
                        final item = items[idx];
                        if (item is String) {
                          return _SectionLabel(
                            label: item,
                            isDark: _d,
                            tl: _tl,
                          ).animate().fadeIn(delay: 40.ms);
                        }
                        final n = item as NotificationModel;
                        return _NotifTile(
                          key: ValueKey(n.id),
                          notif: n,
                          isDark: _d,
                          bg: _bg,
                          tp: _tp,
                          ts: _ts,
                          tl: _tl,
                          bd: _bd,
                          cardBg: _cardBg,
                          unreadBg: _unreadBg,
                          isAccepted: _acceptedIds.contains(n.id),
                          isDeclined: _declinedIds.contains(n.id),
                          isRenewed: _renewedIds.contains(n.id),
                          onTap: () => _markOneRead(n),
                          onAccept: () => _acceptSwap(n),
                          onDecline: () => _declineSwap(n),
                          onAction: () {
                            if (n.type == 'post_expiry') {
                              _renewPost(n);
                            } else {
                              _handleAction(n);
                            }
                          },
                        ).animate().fadeIn(
                          delay: Duration(milliseconds: idx * 35),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Consumer<NotificationService>(
      builder: (_, svc, __) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _d ? const Color(0xFF141628) : const Color(0xFFEDEAFF),
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

  // ── shimmer loading ────────────────────────────────────────────────────────
  Widget _buildShimmer() {
    final base = _d ? const Color(0xFF0E1020) : const Color(0xFFEAE8FF);
    final high = _d ? const Color(0xFF1A1D35) : const Color(0xFFF4F3FF);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: 6,
      itemBuilder: (_, i) =>
          Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
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
                            height: 12,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: high,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 10,
                            width: 160,
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
                delay: Duration(milliseconds: i * 100),
                duration: const Duration(milliseconds: 1200),
                color: high.withOpacity(0.6),
              ),
    );
  }

  // ── empty state ────────────────────────────────────────────────────────────
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
          'No notifications yet',
          style: GoogleFonts.dmSans(fontSize: 13, color: _ts),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.08),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
//  Section label
// ═════════════════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  final Color tl;

  const _SectionLabel({
    required this.label,
    required this.isDark,
    required this.tl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: tl,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Notification tile
// ═════════════════════════════════════════════════════════════════════════════
class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final bool isDark;
  final Color bg, tp, ts, tl, bd, cardBg, unreadBg;
  final bool isAccepted, isDeclined, isRenewed;
  final VoidCallback onTap, onAccept, onDecline, onAction;

  const _NotifTile({
    super.key,
    required this.notif,
    required this.isDark,
    required this.bg,
    required this.tp,
    required this.ts,
    required this.tl,
    required this.bd,
    required this.cardBg,
    required this.unreadBg,
    required this.isAccepted,
    required this.isDeclined,
    required this.isRenewed,
    required this.onTap,
    required this.onAccept,
    required this.onDecline,
    required this.onAction,
  });

  // ── icon / colour for each type ──────────────────────────────────────────
  ({String? emoji, String? initials, Color color}) get _iconData {
    switch (notif.type) {
      case 'swap_request':
        final name = notif.data['sender_name'] as String? ?? notif.title;
        final parts = name.trim().split(' ');
        final init = parts.length >= 2
            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
            : name.substring(0, name.length.clamp(0, 2)).toUpperCase();
        return (emoji: null, initials: init, color: _purple);
      case 'rating':
        return (emoji: '⭐', initials: null, color: _amber);
      case 'leaderboard':
        return (emoji: '🏆', initials: null, color: _purple);
      case 'message':
        return (emoji: '💬', initials: null, color: _teal);
      case 'post_expiry':
        return (emoji: '⏳', initials: null, color: _purple);
      case 'bookmark':
        return (emoji: '🔖', initials: null, color: _pink);
      case 'new_match':
        return (emoji: '🔔', initials: null, color: _purple);
      case 'swap_accepted':
        return (emoji: '🤝', initials: null, color: _green);
      case 'swap_completed':
        return (emoji: '✅', initials: null, color: _green);
      case 'post_view':
        return (emoji: '👀', initials: null, color: _cyan);
      default:
        return (emoji: '🔔', initials: null, color: _purple);
    }
  }

  bool get _hasActions {
    switch (notif.type) {
      case 'swap_request':
      case 'post_expiry':
      case 'leaderboard':
      case 'new_match':
        return true;
      default:
        return notif.data['action_label'] != null;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
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
    return '${months[dt.month]} ${dt.day}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconData;
    final timeStr = _timeAgo(notif.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        color: !notif.isRead ? unreadBg : bg,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ─────────────────────────────────────────────
                  _Avatar(
                    emoji: icon.emoji,
                    initials: icon.initials,
                    color: icon.color,
                    isUnread: !notif.isRead,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),

                  // ── Content ────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + body
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.dmSans(
                              fontSize: 13.5,
                              color: tp,
                              height: 1.45,
                            ),
                            children: [
                              TextSpan(
                                text: notif.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (notif.body != null && notif.body!.isNotEmpty)
                                TextSpan(
                                  text: '  ${notif.body}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: ts,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: GoogleFonts.dmSans(fontSize: 11, color: tl),
                        ),

                        // ── Actions ───────────────────────────────────────
                        if (_hasActions) ...[
                          const SizedBox(height: 10),
                          _ActionRow(
                            notif: notif,
                            isDark: isDark,
                            isAccepted: isAccepted,
                            isDeclined: isDeclined,
                            isRenewed: isRenewed,
                            ts: ts,
                            bd: bd,
                            onAccept: onAccept,
                            onDecline: onDecline,
                            onAction: onAction,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: bd),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Avatar
// ─────────────────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String? emoji;
  final String? initials;
  final Color color;
  final bool isUnread, isDark;

  const _Avatar({
    required this.emoji,
    required this.initials,
    required this.color,
    required this.isUnread,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.28)),
          ),
          alignment: Alignment.center,
          child: emoji != null
              ? Text(emoji!, style: const TextStyle(fontSize: 18))
              : Text(
                  initials ?? '?',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
        ),
        if (isUnread)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: _purple,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF080A12)
                      : const Color(0xFFF4F3FF),
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Action row
// ─────────────────────────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final NotificationModel notif;
  final bool isDark, isAccepted, isDeclined, isRenewed;
  final Color ts, bd;
  final VoidCallback onAccept, onDecline, onAction;

  const _ActionRow({
    required this.notif,
    required this.isDark,
    required this.isAccepted,
    required this.isDeclined,
    required this.isRenewed,
    required this.ts,
    required this.bd,
    required this.onAccept,
    required this.onDecline,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    switch (notif.type) {
      // ── Swap request: Accept / Decline ────────────────────────────────────
      case 'swap_request':
        if (isAccepted) return _statusChip('✓ Accepted', _green);
        if (isDeclined) return _statusChip('Declined', ts);
        return Row(
          children: [
            _gradBtn('✓ Accept', onAccept),
            const SizedBox(width: 8),
            _ghostBtn('Decline', onDecline),
          ],
        );

      // These types are set in the DB after the user acts — so after a
      // reload the correct chip shows instead of the Accept/Decline buttons.
      case 'swap_request_accepted':
        return _statusChip('✓ Accepted', _green);

      case 'swap_request_declined':
        return _statusChip('Declined', ts);

      // ── Post expiry: Renew ────────────────────────────────────────────────
      case 'post_expiry':
        if (isRenewed) return _statusChip('Renewed ✅', _green);
        return _gradBtn('Renew Post', onAction);

      // ── Leaderboard / New match: single action ────────────────────────────
      case 'leaderboard':
        return _gradBtn('View Rankings →', onAction);

      case 'new_match':
        return _gradBtn('Explore →', onAction);

      // ── Generic action from data map ──────────────────────────────────────
      default:
        final label = notif.data['action_label'] as String?;
        if (label != null) return _gradBtn(label, onAction);
        return const SizedBox.shrink();
    }
  }

  Widget _gradBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_purple, _pink],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ),
  );

  Widget _ghostBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141628) : const Color(0xFFEDEAFF),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: bd),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: ts,
        ),
      ),
    ),
  );

  Widget _statusChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: color.withOpacity(0.30)),
    ),
    child: Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}
