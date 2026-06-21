import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/chat_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../profile/user_profile_screen.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final Set<String> _pinned = {};

  static const _purple = Color(0xFF6C63FF);
  static const _online = Color(0xFF22C55E);

  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _dark ? const Color(0xFF0D0E17) : const Color(0xFFF4F4FB);
  Color get _card => _dark ? const Color(0xFF161824) : Colors.white;
  Color get _inputBg =>
      _dark ? const Color(0xFF1C1E2C) : const Color(0xFFEFEEF9);
  Color get _border =>
      _dark ? const Color(0xFF252740) : const Color(0xFFDDDCF0);
  Color get _textMain => _dark ? Colors.white : const Color(0xFF0D0C1E);
  Color get _textSub =>
      _dark ? const Color(0xFF8E90A8) : const Color(0xFF6B698A);
  Color get _textHint =>
      _dark ? const Color(0xFF545670) : const Color(0xFFAAAAAC);

  Color _avatarColor(String name) {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

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

  Future<void> _showPinPopup(ChatModel chat) async {
    HapticFeedback.lightImpact();
    final isPinned = _pinned.contains(chat.id);
    final name = chat.otherUser?.fullName ?? chat.otherUser?.username ?? 'User';
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActionSheet(
        name: name,
        isPinned: isPinned,
        onPin: () => Navigator.pop(context, 'pin'),
        onMute: () => Navigator.pop(context),
        onDelete: () => Navigator.pop(context, 'delete'),
      ),
    );
    if (result == 'pin') {
      setState(() {
        if (isPinned) {
          _pinned.remove(chat.id);
        } else {
          _pinned.add(chat.id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Builder(
            builder: (ctx) {
              final topPad = MediaQuery.of(ctx).padding.top;
              return Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF5B4FF0), Color(0xFF8A82F8)],
                  ),
                ),
                padding: EdgeInsets.only(
                  top: topPad + 14,
                  left: 16,
                  right: 16,
                  bottom: 18,
                ),
                child: Text(
                  'Messages',
                  style: GoogleFonts.dmSans(
                    // FIX 1: _textMain is NOT const — use literal white here
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
              );
            },
          ),

          Container(height: 3, color: _bg),

          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _inputBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _query.isNotEmpty ? _purple : _border,
                  width: _query.isNotEmpty ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  // FIX 2: _textHint is NOT const — use variable, not const Icon
                  Icon(Icons.search_rounded, color: _textHint, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        textSelectionTheme: TextSelectionThemeData(
                          selectionColor: _purple.withOpacity(0.28),
                          cursorColor: _purple,
                          selectionHandleColor: _purple,
                        ),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        autofillHints: const [],
                        enableIMEPersonalizedLearning: false,
                        style: GoogleFonts.dmSans(
                          color: _textMain,
                          fontSize: 14,
                        ),
                        cursorColor: _purple,
                        decoration: InputDecoration(
                          hintText: 'Search conversations...',
                          hintStyle: GoogleFonts.dmSans(
                            color: _textHint,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.close_rounded,
                          // NOT const — _textHint is a getter
                          color: _textHint,
                          size: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 12),
                ],
              ),
            ),
          ),

          // ── "Recent" label ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent',
                style: GoogleFonts.dmSans(
                  color: _textHint,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ),

          // ── Chat list ────────────────────────────────────────────────────
          Expanded(
            child: Consumer<ChatService>(
              builder: (_, cs, __) {
                if (cs.isLoading && cs.chats.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _purple,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (cs.chats.isEmpty) return _empty();

                var list = _query.isEmpty
                    ? cs.chats
                    : cs.chats.where((c) {
                        final n = (c.otherUser?.fullName ?? '').toLowerCase();
                        final u = (c.otherUser?.username ?? '').toLowerCase();
                        final q = _query.toLowerCase();
                        return n.contains(q) || u.contains(q);
                      }).toList();

                list = [
                  ...list.where((c) => _pinned.contains(c.id)),
                  ...list.where((c) => !_pinned.contains(c.id)),
                ];

                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'No conversations found',
                      style: GoogleFonts.dmSans(color: _textHint, fontSize: 14),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: _purple,
                  backgroundColor: _card,
                  onRefresh: () => cs.fetchChats(),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final chat = list[i];
                      final other = chat.otherUser;
                      final name =
                          other?.fullName ?? other?.username ?? 'Unknown';
                      final isPinned = _pinned.contains(chat.id);

                      return _ChatTile(
                        key: ValueKey(chat.id),
                        name: name,
                        username: other?.username ?? '',
                        lastMessage:
                            chat.lastMessage ?? 'Start the conversation...',
                        time: timeago.format(chat.lastMessageAt),
                        avatarUrl: other?.avatarUrl,
                        avatarColor: _avatarColor(name),
                        initials: _initials(name),
                        isPinned: isPinned,
                        unreadCount: chat.unreadCount,
                        index: i,
                        onTap: () => Navigator.push(
                          ctx,
                          PageRouteBuilder(
                            pageBuilder: (_, a1, __) => ChatScreen(chat: chat),
                            transitionsBuilder: (_, a1, __, child) =>
                                SlideTransition(
                                  position:
                                      Tween<Offset>(
                                        begin: const Offset(1, 0),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: a1,
                                          curve: Curves.easeOutCubic,
                                        ),
                                      ),
                                  child: child,
                                ),
                          ),
                        ).then((_) => cs.fetchChats()),
                        onLongPress: () => _showPinPopup(chat),
                      );
                    },
                  ),
                );
              },
            ),
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
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _purple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 40,
            color: _purple,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'No conversations yet',
          style: GoogleFonts.dmSans(
            color: _textMain,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Find a skill post and start chatting!',
          style: GoogleFonts.dmSans(color: _textHint, fontSize: 13),
        ),
      ],
    ).animate().fadeIn().scale(begin: const Offset(0.92, 0.92)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  _ChatTile  — StatelessWidget, so theme must come from build(context)
//  FIX 3: removed the instance getters that called Theme.of(context) outside
//  build() — they are now local variables inside build() instead.
// ─────────────────────────────────────────────────────────────────────────────
class _ChatTile extends StatelessWidget {
  final String name, username, lastMessage, time, initials;
  final String? avatarUrl;
  final Color avatarColor;
  final bool isPinned;
  final int unreadCount, index;
  final VoidCallback onTap, onLongPress;

  static const _purple = Color(0xFF6C63FF);
  static const _online = Color(0xFF22C55E);

  const _ChatTile({
    super.key,
    required this.name,
    required this.username,
    required this.lastMessage,
    required this.time,
    required this.initials,
    required this.avatarColor,
    required this.isPinned,
    required this.unreadCount,
    required this.index,
    required this.onTap,
    required this.onLongPress,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    // All theme-dependent colours are LOCAL to build() — this is the fix.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = dark ? const Color(0xFF161824) : Colors.white;
    final border = dark ? const Color(0xFF252740) : const Color(0xFFDDDCF0);
    final textMain = dark ? Colors.white : const Color(0xFF0D0C1E);
    final textSub = dark ? const Color(0xFF8E90A8) : const Color(0xFF6B698A);
    final textHint = dark ? const Color(0xFF545670) : const Color(0xFFAAAAAC);

    return GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isPinned ? _purple.withOpacity(0.08) : card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPinned ? _purple.withOpacity(0.3) : border,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: avatarColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: avatarUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    initials,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                initials,
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                    // Online dot
                    Positioned(
                      bottom: 1,
                      right: 1,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: _online,
                          shape: BoxShape.circle,
                          border: Border.all(color: card, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.dmSans(
                                color: textMain,
                                fontSize: 15,
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            time,
                            style: GoogleFonts.dmSans(
                              color: unreadCount > 0 ? _purple : textHint,
                              fontSize: 11.5,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.done_all_rounded,
                            size: 13,
                            color: _purple,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lastMessage,
                              style: GoogleFonts.dmSans(
                                color: unreadCount > 0 ? textMain : textSub,
                                fontSize: 13,
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: _purple,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          if (isPinned && unreadCount == 0)
                            const Icon(
                              Icons.push_pin_rounded,
                              color: _purple,
                              size: 14,
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
        .fadeIn(delay: Duration(milliseconds: index * 40))
        .slideX(begin: 0.04, curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _ActionSheet  — same fix: theme colours inside build(), not as getters
//  FIX 4: removed instance getters that called Theme.of(context)
// ─────────────────────────────────────────────────────────────────────────────
class _ActionSheet extends StatelessWidget {
  final String name;
  final bool isPinned;
  final VoidCallback onPin, onMute, onDelete;

  static const _purple = Color(0xFF6C63FF);

  const _ActionSheet({
    required this.name,
    required this.isPinned,
    required this.onPin,
    required this.onMute,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // All colours local to build() — the fix for FIX 4.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final card = dark ? const Color(0xFF161824) : Colors.white;
    final border = dark ? const Color(0xFF252740) : const Color(0xFFDDDCF0);
    final textMain = dark ? Colors.white : const Color(0xFF0D0C1E);
    final textSub = dark ? const Color(0xFF8E90A8) : const Color(0xFF6B698A);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              name,
              style: GoogleFonts.dmSans(
                color: textMain,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _tile(
            context,
            Icons.push_pin_rounded,
            _purple,
            isPinned ? 'Unpin conversation' : 'Pin conversation',
            textMain,
            onPin,
          ),
          _tile(
            context,
            Icons.notifications_off_outlined,
            textSub,
            'Mute notifications',
            textMain,
            onMute,
          ),
          _tile(
            context,
            Icons.delete_outline_rounded,
            const Color(0xFFEF4444),
            'Delete conversation',
            const Color(0xFFEF4444),
            onDelete,
          ),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().slideY(
      begin: 0.3,
      curve: Curves.easeOutCubic,
      duration: 280.ms,
    );
  }

  // context passed explicitly so it works in a StatelessWidget
  Widget _tile(
    BuildContext context,
    IconData icon,
    Color iconColor,
    String label,
    Color labelColor,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        label,
        style: GoogleFonts.dmSans(
          color: labelColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
