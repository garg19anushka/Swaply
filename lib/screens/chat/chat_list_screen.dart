import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/chat_model.dart';
import '../../models/profile_model.dart';
import 'chat_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  ChatListScreen  —  Matches the dark Messages design exactly.
//  Uses Supabase Realtime for live conversation updates.
// ═══════════════════════════════════════════════════════════════════════════

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _conversations = [];
  Map<String, dynamic>? _activeSwap;
  bool _isLoading = true;
  StreamSubscription? _realtimeSub;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const _bg         = Color(0xFF0D0E17);
  static const _surface    = Color(0xFF161824);
  static const _inputBg    = Color(0xFF1C1D2A);
  static const _border     = Color(0xFF2E3048);
  static const _purple     = Color(0xFF6C63FF);
  static const _textMain   = Color(0xFFFFFFFF);
  static const _textSub    = Color(0xFF8E90A8);
  static const _textHint   = Color(0xFF545670);
  static const _purpleStart = Color(0xFF5B4FE8);
  static const _purpleEnd   = Color(0xFF7B6FF0);
  static const _online      = Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  // ── Load conversations + active swap ─────────────────────────────────────
  Future<void> _loadData() async {
    final me = _supabase.auth.currentUser;
    if (me == null) return;

    try {
      // Fetch conversations where current user is a participant
      final convRes = await _supabase
          .from('conversations')
          .select('''
            id,
            created_at,
            swap_id,
            participant1_id,
            participant2_id,
            last_message,
            last_message_at,
            p1:profiles!conversations_participant1_id_fkey(id, full_name, avatar_url),
            p2:profiles!conversations_participant2_id_fkey(id, full_name, avatar_url),
            unread_count:messages(count)
          ''')
          .or('participant1_id.eq.${me.id},participant2_id.eq.${me.id}')
          .order('last_message_at', ascending: false);

      // Fetch active swap (most recent pending swap involving current user)
      final swapRes = await _supabase
          .from('swaps')
          .select('''
            id,
            status,
            session_number,
            total_sessions,
            skill_offered,
            skill_wanted,
            other:profiles!swaps_receiver_id_fkey(id, full_name, avatar_url)
          ''')
          .or('requester_id.eq.${me.id},receiver_id.eq.${me.id}')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(convRes ?? []);
          _activeSwap = swapRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Realtime subscription ─────────────────────────────────────────────────
  void _subscribeRealtime() {
    final me = _supabase.auth.currentUser;
    if (me == null) return;

    _realtimeSub = _supabase
        .from('conversations')
        .stream(primaryKey: ['id'])
        .listen((_) => _loadData());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _getOtherName(Map<String, dynamic> conv) {
    final me = _supabase.auth.currentUser?.id;
    final p1 = conv['p1'] as Map<String, dynamic>?;
    final p2 = conv['p2'] as Map<String, dynamic>?;
    if (p1?['id'] == me) return p2?['full_name'] ?? 'User';
    return p1?['full_name'] ?? 'User';
  }

  String? _getOtherAvatar(Map<String, dynamic> conv) {
    final me = _supabase.auth.currentUser?.id;
    final p1 = conv['p1'] as Map<String, dynamic>?;
    final p2 = conv['p2'] as Map<String, dynamic>?;
    if (p1?['id'] == me) return p2?['avatar_url'];
    return p1?['avatar_url'];
  }

  String _getOtherId(Map<String, dynamic> conv) {
    final me = _supabase.auth.currentUser?.id;
    final p1 = conv['p1'] as Map<String, dynamic>?;
    final p2 = conv['p2'] as Map<String, dynamic>?;
    if (p1?['id'] == me) return p2?['id'] ?? '';
    return p1?['id'] ?? '';
  }

  int _getUnread(Map<String, dynamic> conv) {
    final unread = conv['unread_count'];
    if (unread is List && unread.isNotEmpty) {
      return (unread[0]['count'] as int?) ?? 0;
    }
    return 0;
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF6C63FF), Color(0xFF3B82F6), Color(0xFF10B981),
      Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF8B5CF6),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _timeLabel(dynamic ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts.toString()).toLocal();
      return timeago.format(dt, locale: 'en_short');
    } catch (_) {
      return '';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(topPad),
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _buildList(),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(double topPad) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_purpleStart, _purpleEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: EdgeInsets.only(top: topPad, left: 20, right: 16, bottom: 18),
      child: Row(
        children: [
          Expanded(
            child: Text('Messages',
              style: GoogleFonts.dmSans(
                color: _textMain, fontSize: 22,
                fontWeight: FontWeight.w800, letterSpacing: -0.5,
              )),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, color: _textMain, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // ── Shimmer loading ───────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.only(top: 12),
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: _surface, borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 140, color: _surface,
                    margin: const EdgeInsets.only(bottom: 6)),
                  Container(height: 12, width: 200, color: _inputBg),
                ],
              ),
            ),
          ],
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(
        duration: 1200.ms, color: _border.withOpacity(0.6)),
    );
  }

  // ── Main list ─────────────────────────────────────────────────────────────
  Widget _buildList() {
    return RefreshIndicator(
      color: _purple,
      backgroundColor: _surface,
      onRefresh: _loadData,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 12, bottom: 40),
        children: [
          // Active swap card
          if (_activeSwap != null)
            _buildActiveSwapCard().animate().fadeIn(duration: 300.ms),

          if (_activeSwap != null) const SizedBox(height: 8),

          // Conversation tiles
          if (_conversations.isEmpty)
            _buildEmpty()
          else
            ..._conversations.asMap().entries.map((e) =>
              _buildConvTile(e.value)
                .animate()
                .fadeIn(delay: Duration(milliseconds: 60 * e.key))
                .slideX(begin: 0.04, end: 0),
            ),

          // All caught up
          if (_conversations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Center(
                child: Text('✦ All caught up ✦',
                  style: GoogleFonts.dmSans(
                    color: _textHint, fontSize: 13,
                    fontWeight: FontWeight.w500,
                  )),
              ),
            ),
        ],
      ),
    );
  }

  // ── Active Swap Card ──────────────────────────────────────────────────────
  Widget _buildActiveSwapCard() {
    final swap = _activeSwap!;
    final otherName = (swap['other'] as Map<String, dynamic>?)?['full_name'] ?? 'User';
    final session = swap['session_number'] ?? 1;
    final total   = swap['total_sessions'] ?? 4;
    final skillOffered = swap['skill_offered'] ?? '';
    final skillWanted  = swap['skill_wanted'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_purple.withOpacity(0.22), _purpleEnd.withOpacity(0.14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withOpacity(0.45), width: 1.4),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _purple.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.swap_horiz_rounded, color: _purple, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Swap with $otherName',
                  style: GoogleFonts.dmSans(
                    color: _textMain, fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  )),
                const SizedBox(height: 2),
                Text(
                  'Session $session of $total · $skillOffered ↔ $skillWanted',
                  style: GoogleFonts.dmSans(color: _textSub, fontSize: 11.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_purpleStart, _purpleEnd],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('View',
              style: GoogleFonts.dmSans(
                color: Colors.white, fontSize: 12,
                fontWeight: FontWeight.w700,
              )),
          ),
        ],
      ),
    );
  }

  // ── Conversation tile ─────────────────────────────────────────────────────
  Widget _buildConvTile(Map<String, dynamic> conv) {
    final name     = _getOtherName(conv);
    final avatar   = _getOtherAvatar(conv);
    final otherId  = _getOtherId(conv);
    final lastMsg  = conv['last_message'] as String? ?? '';
    final lastAt   = conv['last_message_at'];
    final unread   = _getUnread(conv);
    final convId   = conv['id'] as String;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chat: ChatModel(
              id: convId,
              participant1: _supabase.auth.currentUser?.id ?? '',
              participant2: otherId,
              lastMessageAt: lastAt != null ? DateTime.tryParse(lastAt.toString()) ?? DateTime.now() : DateTime.now(),
              createdAt: conv['created_at'] != null ? DateTime.tryParse(conv['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
              lastMessage: lastMsg.isEmpty ? null : lastMsg,
              unreadCount: unread,
              otherUser: ProfileModel(
                id: otherId,
                username: name,
                fullName: name,
                avatarUrl: avatar,
                createdAt: DateTime.now(),
              ),
            ),
          ),
        ),
      ).then((_) => _loadData()),
      splashColor: _purple.withOpacity(0.08),
      highlightColor: _purple.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: _avatarColor(name),
                  ),
                  child: avatar != null && avatar.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(avatar, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(_initials(name),
                                style: GoogleFonts.dmSans(
                                  color: Colors.white, fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                )),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(_initials(name),
                            style: GoogleFonts.dmSans(
                              color: Colors.white, fontSize: 17,
                              fontWeight: FontWeight.w700,
                            )),
                        ),
                ),
                // Online dot
                Positioned(
                  bottom: 1, right: 1,
                  child: Container(
                    width: 11, height: 11,
                    decoration: BoxDecoration(
                      color: _online,
                      shape: BoxShape.circle,
                      border: Border.all(color: _bg, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                    style: GoogleFonts.dmSans(
                      color: _textMain, fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    )),
                  const SizedBox(height: 2),
                  Text(
                    lastMsg.isEmpty ? 'No messages yet' : lastMsg,
                    style: GoogleFonts.dmSans(
                      color: unread > 0 ? _textSub : _textHint,
                      fontSize: 13,
                      fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Time + unread badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_timeLabel(lastAt),
                  style: GoogleFonts.dmSans(
                    color: _textHint, fontSize: 11.5,
                  )),
                const SizedBox(height: 4),
                if (unread > 0)
                  Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(
                      color: _purple,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('$unread',
                        style: GoogleFonts.dmSans(
                          color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w700,
                        )),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
              color: _textHint, size: 32),
          ),
          const SizedBox(height: 16),
          Text('No conversations yet',
            style: GoogleFonts.dmSans(
              color: _textMain, fontSize: 16,
              fontWeight: FontWeight.w700,
            )),
          const SizedBox(height: 6),
          Text('Start a swap to begin chatting',
            style: GoogleFonts.dmSans(color: _textHint, fontSize: 13)),
        ],
      ),
    );
  }
}