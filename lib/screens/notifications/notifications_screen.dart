// lib/screens/notifications/notifications_screen.dart
// Self-contained — model + screen in one file, no external model import needed.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MODEL
// ═══════════════════════════════════════════════════════════════════════════════

enum SwaplyNotifType {
  swapRequest,
  rating,
  leaderboard,
  message,
  postExpiry,
  bookmark,
  newMatch,
}

class SwaplyNotif {
  final String id;
  final SwaplyNotifType type;
  final String title;
  final String body;
  final String timeLabel;
  final bool isUnread;
  final String? avatarInitials;
  final Color? avatarColor;
  final String? emojiIcon;
  final bool hasActions;
  final String? actionLabel;
  final String? actionRoute;

  const SwaplyNotif({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timeLabel,
    this.isUnread = false,
    this.avatarInitials,
    this.avatarColor,
    this.emojiIcon,
    this.hasActions = false,
    this.actionLabel,
    this.actionRoute,
  });

  SwaplyNotif copyWith({bool? isUnread}) => SwaplyNotif(
    id: id,
    type: type,
    title: title,
    body: body,
    timeLabel: timeLabel,
    isUnread: isUnread ?? this.isUnread,
    avatarInitials: avatarInitials,
    avatarColor: avatarColor,
    emojiIcon: emojiIcon,
    hasActions: hasActions,
    actionLabel: actionLabel,
    actionRoute: actionRoute,
  );
}

// ── Sample data ───────────────────────────────────────────────────────────────

const _purple = Color(0xFF7C5CFC);
const _pink = Color(0xFFFF4D7D);
const _amber = Color(0xFFFFB800);
const _teal = Color(0xFF00D4AA);
const _cyan = Color(0xFF00E5FF);

final _todaySample = <SwaplyNotif>[
  SwaplyNotif(
    id: 'n1',
    type: SwaplyNotifType.swapRequest,
    title: 'Harsheen Kaur',
    body: 'sent you a swap request for your Python post',
    timeLabel: '2 minutes ago',
    isUnread: true,
    avatarInitials: 'HK',
    avatarColor: _purple,
    hasActions: true,
  ),
  SwaplyNotif(
    id: 'n2',
    type: SwaplyNotifType.rating,
    title: 'Rohan Verma',
    body: 'gave you a 5-star rating after your session',
    timeLabel: '1 hour ago',
    isUnread: true,
    emojiIcon: '⭐',
    avatarColor: _amber,
  ),
  SwaplyNotif(
    id: 'n3',
    type: SwaplyNotifType.leaderboard,
    title: 'Leaderboard Update',
    body: 'You climbed to #12 on the leaderboard at Manav Rachna!',
    timeLabel: '3 hours ago',
    isUnread: true,
    emojiIcon: '🏆',
    avatarColor: _purple,
    hasActions: true,
    actionLabel: 'View Rankings →',
    actionRoute: '/leaderboard',
  ),
  SwaplyNotif(
    id: 'n4',
    type: SwaplyNotifType.message,
    title: 'Priya Sharma',
    body: 'replied to your swap post',
    timeLabel: '5 hours ago',
    avatarInitials: 'PS',
    avatarColor: _teal,
  ),
  SwaplyNotif(
    id: 'n5',
    type: SwaplyNotifType.postExpiry,
    title: 'Post Expiring Soon',
    body: 'Your post "Python & Data Analysis" expires in 2 days — renew it!',
    timeLabel: '8 hours ago',
    emojiIcon: '⏳',
    avatarColor: _purple,
    hasActions: true,
    actionLabel: 'Renew Post',
  ),
];

final _yesterdaySample = <SwaplyNotif>[
  SwaplyNotif(
    id: 'n6',
    type: SwaplyNotifType.bookmark,
    title: 'Priya Sharma',
    body: 'bookmarked your swap post',
    timeLabel: 'Yesterday, 4:30 PM',
    avatarInitials: 'PS',
    avatarColor: _pink,
  ),
  SwaplyNotif(
    id: 'n7',
    type: SwaplyNotifType.newMatch,
    title: 'New Matches Found',
    body: '3 new people at Manav Rachna offer skills you\'re looking for',
    timeLabel: 'Yesterday, 11:00 AM',
    emojiIcon: '🔔',
    avatarColor: _purple,
    hasActions: true,
    actionLabel: 'Explore →',
    actionRoute: '/explore',
  ),
];

// ═══════════════════════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<SwaplyNotif> _today;
  late List<SwaplyNotif> _yesterday;

  final Set<String> _acceptedIds = {};
  final Set<String> _declinedIds = {};
  final Set<String> _renewedIds = {};

  @override
  void initState() {
    super.initState();
    _today = List.from(_todaySample);
    _yesterday = List.from(_yesterdaySample);
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  void _markAllRead() {
    setState(() {
      _today = _today.map((n) => n.copyWith(isUnread: false)).toList();
      _yesterday = _yesterday.map((n) => n.copyWith(isUnread: false)).toList();
    });
    _snack('All marked as read ✅');
  }

  void _markOneRead(SwaplyNotif notif) {
    if (!notif.isUnread) return;
    setState(() {
      _today = _today
          .map((n) => n.id == notif.id ? n.copyWith(isUnread: false) : n)
          .toList();
      _yesterday = _yesterday
          .map((n) => n.id == notif.id ? n.copyWith(isUnread: false) : n)
          .toList();
    });
  }

  void _handleAction(SwaplyNotif notif) {
    if (notif.type == SwaplyNotifType.postExpiry) {
      setState(() => _renewedIds.add(notif.id));
      _snack('Post renewed for 30 more days! ✅');
      return;
    }
    if (notif.actionRoute == '/leaderboard') {
      // Navigator.pushNamed(context, '/leaderboard');
      _snack('Opening leaderboard…');
      return;
    }
    if (notif.actionRoute == '/explore') {
      // Navigator.pushNamed(context, '/explore');
      _snack('Opening explore…');
      return;
    }
    _snack(notif.actionLabel ?? '');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1A1D35),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF080A12)
          : const Color(0xFFF4F3FF),
      body: SafeArea(
        child: Column(
          children: [
            _Header(isDark: isDark, onMarkAllRead: _markAllRead),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _SectionLabel(label: 'Today', isDark: isDark),
                  ..._today.map(
                    (n) => _NotifTile(
                      notif: n,
                      isDark: isDark,
                      isAccepted: _acceptedIds.contains(n.id),
                      isDeclined: _declinedIds.contains(n.id),
                      isRenewed: _renewedIds.contains(n.id),
                      onTap: () => _markOneRead(n),
                      onAccept: () {
                        setState(() => _acceptedIds.add(n.id));
                        _snack('Swap request accepted! 🎉');
                      },
                      onDecline: () {
                        setState(() => _declinedIds.add(n.id));
                        _snack('Request declined');
                      },
                      onAction: () => _handleAction(n),
                    ),
                  ),
                  _SectionLabel(label: 'Yesterday', isDark: isDark),
                  ..._yesterday.map(
                    (n) => _NotifTile(
                      notif: n,
                      isDark: isDark,
                      isAccepted: _acceptedIds.contains(n.id),
                      isDeclined: _declinedIds.contains(n.id),
                      isRenewed: _renewedIds.contains(n.id),
                      onTap: () => _markOneRead(n),
                      onAccept: () {},
                      onDecline: () {},
                      onAction: () => _handleAction(n),
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

// ═══════════════════════════════════════════════════════════════════════════════
// SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final bool isDark;
  final VoidCallback onMarkAllRead;

  const _Header({required this.isDark, required this.onMarkAllRead});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark
        ? const Color(0xFFF0F2FF)
        : const Color(0xFF0A0814);

    return Padding(
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
                color: isDark
                    ? const Color(0xFF141628)
                    : const Color(0xFFEDEAFF),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : _purple.withOpacity(0.12),
                ),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: isDark ? Colors.white70 : const Color(0xFF5E5A80),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notifications',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onMarkAllRead,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

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
          color: isDark ? const Color(0xFF404468) : const Color(0xFFA09DC0),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final SwaplyNotif notif;
  final bool isDark;
  final bool isAccepted;
  final bool isDeclined;
  final bool isRenewed;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onAction;

  const _NotifTile({
    required this.notif,
    required this.isDark,
    required this.isAccepted,
    required this.isDeclined,
    required this.isRenewed,
    required this.onTap,
    required this.onAccept,
    required this.onDecline,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF080A12) : const Color(0xFFF4F3FF);
    final unreadBg = _purple.withOpacity(isDark ? 0.04 : 0.05);
    final dividerColor = isDark
        ? Colors.white.withOpacity(0.07)
        : _purple.withOpacity(0.12);
    final textPrimary = isDark
        ? const Color(0xFFF0F2FF)
        : const Color(0xFF0A0814);
    final textSecondary = isDark
        ? const Color(0xFF8890B8)
        : const Color(0xFF5E5A80);
    final textMuted = isDark
        ? const Color(0xFF404468)
        : const Color(0xFFA09DC0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        color: notif.isUnread ? unreadBg : bg,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(notif: notif, isDark: isDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Body rich text
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: textPrimary,
                              height: 1.45,
                            ),
                            children: [
                              TextSpan(
                                text: notif.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(text: ' ${notif.body}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif.timeLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: textMuted,
                          ),
                        ),
                        if (notif.hasActions) ...[
                          const SizedBox(height: 10),
                          _ActionRow(
                            notif: notif,
                            isDark: isDark,
                            isAccepted: isAccepted,
                            isDeclined: isDeclined,
                            isRenewed: isRenewed,
                            textSecondary: textSecondary,
                            dividerColor: dividerColor,
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
            Divider(height: 1, thickness: 1, color: dividerColor),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final SwaplyNotif notif;
  final bool isDark;

  const _Avatar({required this.notif, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final accent = notif.avatarColor ?? _purple;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.25)),
          ),
          alignment: Alignment.center,
          child: notif.emojiIcon != null
              ? Text(notif.emojiIcon!, style: const TextStyle(fontSize: 18))
              : Text(
                  notif.avatarInitials ?? '?',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
        ),
        if (notif.isUnread)
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

class _ActionRow extends StatelessWidget {
  final SwaplyNotif notif;
  final bool isDark;
  final bool isAccepted;
  final bool isDeclined;
  final bool isRenewed;
  final Color textSecondary;
  final Color dividerColor;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onAction;

  const _ActionRow({
    required this.notif,
    required this.isDark,
    required this.isAccepted,
    required this.isDeclined,
    required this.isRenewed,
    required this.textSecondary,
    required this.dividerColor,
    required this.onAccept,
    required this.onDecline,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    // ── Swap request ────────────────────────────────────────────────────────
    if (notif.type == SwaplyNotifType.swapRequest) {
      if (isAccepted) return _chip('✓ Accepted', Colors.green.shade400);
      if (isDeclined) return _chip('Declined', textSecondary);
      return Row(
        children: [
          _gradBtn('✓ Accept', onAccept),
          const SizedBox(width: 8),
          _ghostBtn('Decline', onDecline),
        ],
      );
    }

    // ── Post expiry ─────────────────────────────────────────────────────────
    if (notif.type == SwaplyNotifType.postExpiry) {
      if (isRenewed) return _chip('Renewed ✅', Colors.green.shade400);
      return _gradBtn(notif.actionLabel ?? 'Renew Post', onAction);
    }

    // ── Generic action button ───────────────────────────────────────────────
    if (notif.actionLabel != null) {
      return _gradBtn(notif.actionLabel!, onAction);
    }

    return const SizedBox.shrink();
  }

  Widget _gradBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C5CFC), Color(0xFFFF4D7D)],
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
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
        border: Border.all(color: dividerColor),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
      ),
    ),
  );

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: color.withOpacity(0.3)),
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
