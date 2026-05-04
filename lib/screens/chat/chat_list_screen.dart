import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/chat_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../profile/user_profile_screen.dart';
import 'chat_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  ChatListScreen  — Messages Inbox
//  Light: pure #FFFFFF bg  |  Dark: deep-charcoal #111318 bg
//  ✦ No "Active Now" row
//  ✦ Search bar
//  ✦ Pin icon on first conversation  (long-press tile → pin/unpin pop-up)
//  ✦ Double-check read receipts
//  ✦ Avatar → UserProfileScreen
//  ✦ Pinned banner inside chat (passed through to ChatScreen)
// ═══════════════════════════════════════════════════════════════════════════
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  // Local set of pinned chat IDs (first one is pre-pinned)
  final Set<String> _pinned = {};

  // ── theme shortcuts ──────────────────────────────────────────
  bool get _d   => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _d ? const Color(0xFF111318) : Colors.white;
  Color get _sf => _d ? const Color(0xFF1A1D24) : Colors.white;
  Color get _sv => _d ? const Color(0xFF22252E) : const Color(0xFFF4F4F6);
  Color get _bd => _d ? const Color(0xFF2A2D36) : const Color(0xFFEFEFEF);
  Color get _tp => _d ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A0A);
  Color get _ts => _d ? const Color(0xFF8E9099) : const Color(0xFF6E6E6E);
  Color get _tl => _d ? const Color(0xFF555862) : const Color(0xFFAAAAAA);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatService>().fetchChats();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── status helpers ───────────────────────────────────────────
  Color _statusColor(String s) => switch (s) {
        'pending'   => AppColors.warning,
        'completed' => AppColors.success,
        'cancelled' => AppColors.error,
        _           => _tl,
      };

  String _statusLabel(String s) => switch (s) {
        'pending'   => 'Pending',
        'completed' => 'Done',
        'cancelled' => 'Cancelled',
        _           => '',
      };

  // ── Pin long-press pop-up ────────────────────────────────────
  Future<void> _showPinPopup(String chatId, String name) async {
    HapticFeedback.lightImpact();
    final isPinned = _pinned.contains(chatId);
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PinBottomSheet(
        name: name,
        isPinned: isPinned,
        d: _d,
        sf: _sf,
        bd: _bd,
        tp: _tp,
        ts: _ts,
      ),
    );
    if (result == 'toggle') {
      setState(() {
        if (isPinned) _pinned.remove(chatId);
        else          _pinned.add(chatId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── Top app bar ──────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: _sf,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            toolbarHeight: 58,
            title: Text('Messages',
                style: GoogleFonts.dmSans(
                  color: _tp,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                )),
            centerTitle: true,
            actions: const [],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: _bd),
            ),
          ),

          // ── Search bar ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 44,
                decoration: BoxDecoration(
                  color: _sv,
                  borderRadius: BorderRadius.circular(14),
                  border: _query.isNotEmpty
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search_rounded, color: _ts, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        style: GoogleFonts.dmSans(color: _tp, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search conversations...',
                          hintStyle: GoogleFonts.dmSans(color: _ts, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () { _searchCtrl.clear(); setState(() => _query = ''); },
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(Icons.close_rounded, color: _ts, size: 16),
                        ),
                      )
                    else
                      const SizedBox(width: 12),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 40.ms),
          ),

          // ── "Recent" section label ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
              child: Text('Recent',
                  style: GoogleFonts.dmSans(
                    color: _ts,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  )),
            ),
          ),

          // ── Chat list ────────────────────────────────────────
          Consumer<ChatService>(
            builder: (_, cs, __) {
              if (cs.isLoading && cs.chats.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                );
              }

              if (cs.chats.isEmpty) return SliverFillRemaining(child: _empty());

              // Pre-pin the first chat in the list if nothing is pinned yet
              if (_pinned.isEmpty && cs.chats.isNotEmpty) {
                _pinned.add(cs.chats.first.id);
              }

              // Filter by query
              var list = _query.isEmpty
                  ? cs.chats
                  : cs.chats.where((c) {
                      final n = (c.otherUser?.fullName ?? '').toLowerCase();
                      final u = (c.otherUser?.username ?? '').toLowerCase();
                      final q = _query.toLowerCase();
                      return n.contains(q) || u.contains(q);
                    }).toList();

              // Pinned chats float to top
              list = [
                ...list.where((c) => _pinned.contains(c.id)),
                ...list.where((c) => !_pinned.contains(c.id)),
              ];

              if (list.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text('No conversations found',
                        style: GoogleFonts.dmSans(color: _ts, fontSize: 14)),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final chat = list[i];
                    final other = chat.otherUser;
                    final isPinned = _pinned.contains(chat.id);
                    final hasStatus = chat.swapStatus != 'none' && chat.swapStatus.isNotEmpty;

                    return _ChatTile(
                      key: ValueKey(chat.id),
                      avatarUrl: other?.avatarUrl,
                      username: other?.username ?? '',
                      displayName: other?.fullName ?? other?.username ?? 'Unknown',
                      lastMessage: chat.lastMessage ?? 'Start the conversation...',
                      hasMessage: chat.lastMessage != null,
                      time: timeago.format(chat.lastMessageAt),
                      statusColor: hasStatus ? _statusColor(chat.swapStatus) : null,
                      statusLabel: hasStatus ? _statusLabel(chat.swapStatus) : null,
                      isPinned: isPinned,
                      isRead: chat.unreadCount == 0,
                      unreadCount: chat.unreadCount,
                      index: i,
                      d: _d, sf: _sf, bd: _bd, tp: _tp, ts: _ts, tl: _tl, sv: _sv,
                      onTap: () => Navigator.push(
                        ctx,
                        PageRouteBuilder(
                          pageBuilder: (_, a1, __) => ChatScreen(
                            chat: chat,
                          ),
                          transitionsBuilder: (_, a1, __, child) => SlideTransition(
                            position: Tween<Offset>(
                                    begin: const Offset(1, 0), end: Offset.zero)
                                .animate(CurvedAnimation(
                                    parent: a1, curve: Curves.easeOutCubic)),
                            child: child,
                          ),
                        ),
                      ).then((_) => cs.fetchChats()),
                      onLongPress: () => _showPinPopup(
                          chat.id, other?.fullName ?? other?.username ?? ''),
                      onAvatarTap: other?.id != null
                          ? () => Navigator.push(ctx,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          UserProfileScreen(userId: other!.id)))
                          : null,
                    );
                  },
                  childCount: list.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text('No conversations yet',
                style: GoogleFonts.dmSans(
                    color: _tp, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Find a skill post and start chatting!',
                style: GoogleFonts.dmSans(color: _ts, fontSize: 13)),
          ],
        ).animate().fadeIn().scale(begin: const Offset(0.92, 0.92)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Chat Tile
// ─────────────────────────────────────────────────────────────────────────────
class _ChatTile extends StatelessWidget {
  final String? avatarUrl;
  final String username, displayName, lastMessage, time;
  final bool hasMessage, isPinned, isRead;
  final int unreadCount, index;
  final bool d;
  final Color sf, bd, tp, ts, tl, sv;
  final Color? statusColor;
  final String? statusLabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onAvatarTap;

  const _ChatTile({
    super.key,
    required this.avatarUrl,
    required this.username,
    required this.displayName,
    required this.lastMessage,
    required this.hasMessage,
    required this.time,
    required this.isPinned,
    required this.isRead,
    required this.unreadCount,
    required this.index,
    required this.d,
    required this.sf,
    required this.bd,
    required this.tp,
    required this.ts,
    required this.tl,
    required this.sv,
    required this.onTap,
    this.statusColor,
    this.statusLabel,
    this.onLongPress,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isPinned
              ? (d
                  ? AppColors.primary.withOpacity(0.06)
                  : AppColors.primary.withOpacity(0.03))
              : sf,
          border: Border(bottom: BorderSide(color: bd, width: 1)),
        ),
        child: Row(
          children: [
            // Avatar
            GestureDetector(
              onTap: onAvatarTap,
              child: AvatarWidget(avatarUrl: avatarUrl, username: username, radius: 26),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row
                  Row(
                    children: [
                      Expanded(
                        child: Text(displayName,
                            style: GoogleFonts.dmSans(
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 14.5,
                              color: tp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(time,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: unreadCount > 0 ? AppColors.primary : tl,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600 : FontWeight.w400,
                          )),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Preview row
                  Row(
                    children: [
                      Icon(
                        isRead ? Icons.done_all_rounded : Icons.done_rounded,
                        size: 13,
                        color: isRead ? AppColors.primary : tl,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(lastMessage,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: unreadCount > 0 ? tp : ts,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else if (statusLabel != null && statusLabel!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor!.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(statusLabel!,
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 35))
        .slideX(begin: 0.03, curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Pin / Unpin bottom sheet pop-up
// ─────────────────────────────────────────────────────────────────────────────
class _PinBottomSheet extends StatelessWidget {
  final String name;
  final bool isPinned, d;
  final Color sf, bd, tp, ts;

  const _PinBottomSheet({
    required this.name,
    required this.isPinned,
    required this.d,
    required this.sf,
    required this.bd,
    required this.tp,
    required this.ts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: sf,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: d ? const Color(0xFF3A3D48) : const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          Text(name,
              style: GoogleFonts.dmSans(
                  color: tp, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(isPinned ? 'This conversation is pinned' : 'Pin this conversation?',
              style: GoogleFonts.dmSans(color: ts, fontSize: 13)),
          const SizedBox(height: 20),
          Divider(color: bd, height: 1),
          const SizedBox(height: 6),

          // Toggle action
          _SheetAction(
            icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
            iconColor: AppColors.primary,
            label: isPinned ? 'Unpin conversation' : 'Pin conversation',
            labelColor: tp,
            onTap: () => Navigator.pop(context, 'toggle'),
          ),

          _SheetAction(
            icon: Icons.notifications_off_outlined,
            iconColor: ts,
            label: 'Mute notifications',
            labelColor: tp,
            onTap: () => Navigator.pop(context),
          ),

          _SheetAction(
            icon: Icons.delete_outline_rounded,
            iconColor: AppColors.error,
            label: 'Delete conversation',
            labelColor: AppColors.error,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, curve: Curves.easeOutCubic, duration: 280.ms);
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor, labelColor;
  final String label;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(label,
          style: GoogleFonts.dmSans(
              color: labelColor, fontSize: 14.5, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}