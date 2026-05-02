import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/chat_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../profile/user_profile_screen.dart';
import 'rate_swap_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  ChatScreen
//  Light: pure white bg, lavender incoming, primary-grad outgoing (right)
//  Dark: deep-slate bg, dim-lavender incoming, slate-blue outgoing (right)
//  ✦ Skill badge next to contact name in header
//  ✦ Pinned banner when isPinned=true
//  ✦ Pin/unpin pop-up from header kebab
//  ✦ Swipe-to-reply → inline reply preview above input bar
//  ✦ Long-press → 6-emoji row + context menu (Edit greyed for incoming)
//  ✦ Input bar: media (+) · text field · waveform voice icon · send
//  ✦ Voice-note playback waveform inside bubble
//  ✦ Avatar → UserProfileScreen
// ═══════════════════════════════════════════════════════════════════════════

class ChatScreen extends StatefulWidget {
  final ChatModel chat;
  const ChatScreen({super.key, required this.chat});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending   = false;
  bool _isRecording = false;
  MessageModel? _replyTarget;
  String?       _selectedMsgId;
  Offset        _overlayPos = Offset.zero;

  // ── theme shortcuts ──────────────────────────────────────────
  bool   get _d   => Theme.of(context).brightness == Brightness.dark;
  Color  get _bg  => _d ? const Color(0xFF0E1117) : Colors.white;
  Color  get _sf  => _d ? const Color(0xFF161A22) : Colors.white;
  Color  get _sv  => _d ? const Color(0xFF1E222C) : const Color(0xFFF2F2F5);
  Color  get _bd  => _d ? const Color(0xFF272B36) : const Color(0xFFEAEAEA);
  Color  get _tp  => _d ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A0A);
  Color  get _ts  => _d ? const Color(0xFF8E9099) : const Color(0xFF6E6E6E);
  Color  get _tl  => _d ? const Color(0xFF555862) : const Color(0xFFAAAAAA);

  // Outgoing: slate-blue gradient (dark) / primary violet-pink (light)
  LinearGradient get _outGrad => _d
      ? const LinearGradient(
          colors: [Color(0xFF3B4EAD), Color(0xFF6C47FF)],
          begin: Alignment.topLeft, end: Alignment.bottomRight)
      : AppColors.primaryGradient;

  // Incoming: deep-lavender (dark) / pale lavender (light)
  Color get _inBg   => _d ? const Color(0xFF262D3D) : const Color(0xFFF0EEFF);
  Color get _inText => _d ? const Color(0xFFD8DCF0) : const Color(0xFF2D2D2D);

  @override
  void initState() {
    super.initState();
    final cs = context.read<ChatService>();
    cs.fetchMessages(widget.chat.id).then((_) => _scrollToBottom());
    cs.subscribeToChat(widget.chat.id);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    context.read<ChatService>().unsubscribeFromChat();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Send text message ────────────────────────────────────────
  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    setState(() { _isSending = true; _replyTarget = null; });
    await context.read<ChatService>().sendMessage(
        chatId: widget.chat.id, content: text);
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  // ── Pick & send image ────────────────────────────────────────
  Future<void> _pickImage() async {
    final p = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (p == null) return;
    setState(() => _isSending = true);
    final cs  = context.read<ChatService>();
    final url = await cs.uploadChatImage(File(p.path));
    if (url != null) {
      await cs.sendMessage(
          chatId: widget.chat.id, imageUrl: url, messageType: 'image');
      _scrollToBottom();
    }
    setState(() => _isSending = false);
  }

  // ── Confirm swap dialog ──────────────────────────────────────
  Future<void> _confirmSwap() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confirm Swap 🤝',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text(
          'Confirm a skill swap with '
          '${widget.chat.otherUser?.fullName ?? widget.chat.otherUser?.username}?\n\n'
          'This marks it as pending until both parties complete it.',
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<ChatService>().confirmSwap(
          chatId: widget.chat.id,
          otherUserId: widget.chat.otherUser?.id ?? '',
          postId: widget.chat.postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Swap confirmed! 🎉'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
        setState(() {});
      }
    }
  }

  // ── Complete swap dialog ─────────────────────────────────────
  Future<void> _completeSwap() async {
    final swaps = await context.read<ChatService>().fetchUserSwaps();
    final swap = swaps.firstWhere(
      (s) => s.chatId == widget.chat.id && s.status == 'pending',
      orElse: () => SwapModel(id: '', chatId: '', initiatorId: '',
          receiverId: '', status: 'pending', createdAt: DateTime.now()),
    );
    if (swap.id.isEmpty || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Mark Swap Complete?',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: const Text('Confirm the skill swap has been completed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success),
              child: const Text('Complete')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<ChatService>().markSwapCompleted(
          swap.id, widget.chat.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Swap complete! 🎉 Please rate your experience.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      setState(() {});
    }
  }

  // ── Long-press overlay ───────────────────────────────────────
  void _onLongPress(MessageModel msg, Offset globalPos) {
    HapticFeedback.mediumImpact();
    setState(() { _selectedMsgId = msg.id; _overlayPos = globalPos; });
  }

  void _dismissOverlay() => setState(() => _selectedMsgId = null);

  // ── Delete message ───────────────────────────────────────────
  Future<void> _deleteMsg(MessageModel msg) async {
    _dismissOverlay();
    await context.read<ChatService>().deleteMessage(msg.id, widget.chat.id);
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthService>().currentUser?.id ?? '';
    final other = widget.chat.otherUser;
    final swapDone = widget.chat.swapStatus == 'completed'
        || widget.chat.swapStatus == 'cancelled';
    final swapPending = widget.chat.swapStatus == 'pending';

    return GestureDetector(
      onTap: _selectedMsgId != null ? _dismissOverlay : null,
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [

            // ── Neutral header ────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: _sf,
                border: Border(bottom: BorderSide(color: _bd, width: 1)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 12, 10),
                  child: Row(
                    children: [
                      // Back
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: _tp, size: 19),
                        onPressed: () => Navigator.pop(context),
                      ),

                      // Avatar → profile
                      GestureDetector(
                        onTap: other?.id != null
                            ? () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) => UserProfileScreen(
                                        userId: other!.id)))
                            : null,
                        child: AvatarWidget(
                          avatarUrl: other?.avatarUrl,
                          username: other?.username ?? '',
                          radius: 20,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Name + username
                      Expanded(
                        child: GestureDetector(
                          onTap: other?.id != null
                              ? () => Navigator.push(context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          UserProfileScreen(userId: other!.id)))
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                other?.fullName ?? other?.username ?? 'User',
                                style: GoogleFonts.dmSans(
                                  color: _tp,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '@${other?.username ?? ''}',
                                style: GoogleFonts.dmSans(
                                    color: _ts, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Swap action button (neutral style)
                      if (!swapDone && !swapPending)
                        _HeaderBtn(
                            icon: Icons.handshake_outlined,
                            label: 'Confirm Swap',
                            onTap: _confirmSwap,
                            tp: _tp, bd: _bd, sv: _sv)
                      else if (swapPending)
                        _HeaderBtn(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Complete',
                            color: AppColors.success,
                            onTap: _completeSwap,
                            tp: _tp, bd: _bd, sv: _sv),
                    ],
                  ),
                ),
              ),
            ),

            // ── Messages ──────────────────────────────────────
            Expanded(
              child: Consumer<ChatService>(
                builder: (_, cs, __) {
                  if (cs.isLoadingMessages && cs.messages.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    );
                  }
                  if (cs.messages.isEmpty) return _emptyChat();

                  return Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        physics: const BouncingScrollPhysics(),
                        itemCount: cs.messages.length,
                        itemBuilder: (_, i) {
                          final msg = cs.messages[i];
                          final isMe = msg.senderId == myId;
                          if (msg.messageType == 'system') {
                            return _sysMsg(msg.content ?? '');
                          }
                          return _SwipeToReply(
                            key: ValueKey(msg.id),
                            isMe: isMe,
                            onSwipe: () =>
                                setState(() => _replyTarget = msg),
                            child: GestureDetector(
                              onLongPressStart: (d) =>
                                  _onLongPress(msg, d.globalPosition),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 150),
                                decoration: _selectedMsgId == msg.id
                                    ? BoxDecoration(
                                        color: AppColors.primary
                                            .withOpacity(0.06),
                                        borderRadius:
                                            BorderRadius.circular(12))
                                    : null,
                                child: _Bubble(
                                  msg: msg,
                                  isMe: isMe,
                                  outGrad: _outGrad,
                                  inBg: _inBg,
                                  inText: _inText,
                                  tl: _tl,
                                ).animate().fadeIn(
                                    delay: Duration(
                                        milliseconds: i * 18)),
                              ),
                            ),
                          );
                        },
                      ),

                      // Long-press overlay
                      if (_selectedMsgId != null)
                        _buildOverlay(cs, myId),
                    ],
                  );
                },
              ),
            ),

            // ── Input bar ──────────────────────────────────────
            _InputBar(
              controller: _msgCtrl,
              isSending: _isSending,
              isRecording: _isRecording,
              replyTarget: _replyTarget,
              d: _d, sf: _sf, sv: _sv, bd: _bd, tp: _tp, ts: _ts,
              onCancelReply: () => setState(() => _replyTarget = null),
              onSend: _send,
              onPickImage: _pickImage,
              onToggleRecord: () =>
                  setState(() => _isRecording = !_isRecording),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reaction + context overlay ───────────────────────────────
  Widget _buildOverlay(ChatService cs, String myId) {
    final msg = cs.messages.firstWhere((m) => m.id == _selectedMsgId,
        orElse: () => cs.messages.first);
    final isMe = msg.senderId == myId;
    final screen = MediaQuery.of(context).size;
    final left  = (_overlayPos.dx - 110).clamp(8.0, screen.width - 240.0);
    final top   = (_overlayPos.dy - 140).clamp(
        MediaQuery.of(context).padding.top + 56.0,
        screen.height - 220.0);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _dismissOverlay,
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
        ),
        Positioned(
          left: left, top: top,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 6 emoji reactions
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _d
                      ? const Color(0xFF1E222C)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['❤️','😂','😮','😢','👍','🔥']
                      .map((e) => GestureDetector(
                            onTap: _dismissOverlay,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5),
                              child: Text(e,
                                  style:
                                      const TextStyle(fontSize: 22)),
                            ),
                          ))
                      .toList(),
                ),
              ).animate().scale(
                  begin: const Offset(0.7, 0.7),
                  curve: Curves.elasticOut,
                  duration: 400.ms),

              const SizedBox(height: 8),

              // Context menu
              Container(
                width: 210,
                decoration: BoxDecoration(
                  color: _d
                      ? const Color(0xFF1E222C)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.14),
                        blurRadius: 16,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _CtxAction(
                      icon: Icons.reply_rounded,
                      label: 'Reply',
                      color: _tp,
                      onTap: () {
                        setState(() {
                          _replyTarget = msg;
                          _selectedMsgId = null;
                        });
                      },
                    ),
                    Divider(height: 1, color: _bd),
                    // Edit — greyed for incoming
                    _CtxAction(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: isMe ? _tp : _tl,
                      onTap: isMe ? _dismissOverlay : null,
                    ),
                    Divider(height: 1, color: _bd),
                    // Delete — red, only own messages
                    _CtxAction(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      color: isMe ? AppColors.error : _tl,
                      onTap: isMe ? () => _deleteMsg(msg) : null,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 60.ms),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sysMsg(String content) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(content,
              style: GoogleFonts.dmSans(
                  fontSize: 11.5,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600)),
        ),
      );

  Widget _emptyChat() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.waving_hand_rounded, size: 40, color: _ts),
            const SizedBox(height: 12),
            Text('Say hello!',
                style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _tp)),
            const SizedBox(height: 4),
            Text('Start your SkillSwap conversation',
                style: GoogleFonts.dmSans(color: _ts, fontSize: 13)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Header action button  – neutral themed
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color tp, bd, sv;

  const _HeaderBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tp,
    required this.bd,
    required this.sv,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: sv,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: bd, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.dmSans(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Swipe-to-reply wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _SwipeToReply extends StatefulWidget {
  final bool isMe;
  final VoidCallback onSwipe;
  final Widget child;
  const _SwipeToReply(
      {super.key,
      required this.isMe,
      required this.onSwipe,
      required this.child});

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply> {
  double _dx = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        if (!widget.isMe && d.delta.dx > 0) {
          setState(() => _dx = math.min(_dx + d.delta.dx, 60));
        }
      },
      onHorizontalDragEnd: (_) {
        if (_dx >= 40) widget.onSwipe();
        setState(() => _dx = 0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        transform: Matrix4.translationValues(_dx, 0, 0),
        child: Stack(
          children: [
            widget.child,
            if (_dx > 8)
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Opacity(
                  opacity: (_dx / 60).clamp(0, 1),
                  child: const Center(
                    child: Icon(Icons.reply_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Message bubble
// ─────────────────────────────────────────────────────────────────────────────
class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  final LinearGradient outGrad;
  final Color inBg, inText, tl;

  const _Bubble({
    required this.msg,
    required this.isMe,
    required this.outGrad,
    required this.inBg,
    required this.inText,
    required this.tl,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 18),
    );

    // Voice note bubble
    final isVoice = msg.messageType == 'voice';

    return Padding(
      padding: EdgeInsets.only(
        left:  isMe ? 60 : 8,
        right: isMe ? 8 : 60,
        bottom: 6,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: (msg.messageType == 'image')
                ? EdgeInsets.zero
                : isVoice
                    ? const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10)
                    : const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              gradient: isMe ? outGrad : null,
              color: isMe ? null : inBg,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isMe ? 0.12 : 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isVoice
                ? _VoiceNoteBubble(isMe: isMe, inText: inText)
                : msg.messageType == 'image' && msg.imageUrl != null
                    ? ClipRRect(
                        borderRadius: radius,
                        child: Image.network(msg.imageUrl!,
                            width: 200, fit: BoxFit.cover),
                      )
                    : Text(
                        msg.content ?? '',
                        style: GoogleFonts.dmSans(
                          color: isMe ? Colors.white : inText,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeago.format(msg.createdAt),
                style:
                    GoogleFonts.dmSans(fontSize: 10, color: tl),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  msg.isRead
                      ? Icons.done_all_rounded
                      : Icons.done_rounded,
                  size: 13,
                  color: msg.isRead ? AppColors.primary : tl,
                ),
              ],
            ],
          ),
        ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Voice-note playback bubble (waveform + play icon)
// ─────────────────────────────────────────────────────────────────────────────
class _VoiceNoteBubble extends StatelessWidget {
  final bool isMe;
  final Color inText;
  const _VoiceNoteBubble({required this.isMe, required this.inText});

  @override
  Widget build(BuildContext context) {
    final iconColor = isMe ? Colors.white : inText;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.play_circle_filled_rounded, color: iconColor, size: 28),
        const SizedBox(width: 8),
        CustomPaint(
          size: const Size(90, 24),
          painter: _WaveformPainter(
              color: iconColor.withOpacity(0.7), bars: 18),
        ),
        const SizedBox(width: 8),
        Text('0:12',
            style: GoogleFonts.dmSans(
                color: iconColor.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Input bar
// ─────────────────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending, isRecording;
  final MessageModel? replyTarget;
  final bool d;
  final Color sf, sv, bd, tp, ts;
  final VoidCallback onCancelReply, onSend, onPickImage, onToggleRecord;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.isRecording,
    required this.replyTarget,
    required this.d,
    required this.sf,
    required this.sv,
    required this.bd,
    required this.tp,
    required this.ts,
    required this.onCancelReply,
    required this.onSend,
    required this.onPickImage,
    required this.onToggleRecord,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: sf,
        border: Border(top: BorderSide(color: bd, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Inline reply preview ──────────────────────────
            if (replyTarget != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                      left: BorderSide(color: AppColors.primary, width: 3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply_rounded,
                        size: 15, color: AppColors.primary),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        replyTarget!.content ??
                            (replyTarget!.messageType == 'image'
                                ? '📷 Photo'
                                : replyTarget!.messageType == 'voice'
                                    ? '🎤 Voice note'
                                    : ''),
                        style: GoogleFonts.dmSans(
                            color: ts,
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancelReply,
                      child: Icon(Icons.close_rounded, size: 16, color: ts),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.4, duration: 200.ms),

            // ── Main row ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Media (+)
                  GestureDetector(
                    onTap: onPickImage,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Text field + waveform icon
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: sv,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              maxLines: 4,
                              minLines: 1,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              style: GoogleFonts.dmSans(
                                  color: tp, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: GoogleFonts.dmSans(
                                    color: ts, fontSize: 14),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 11),
                              ),
                              onSubmitted: (_) => onSend(),
                            ),
                          ),
                          // Mic / voice note button
                          GestureDetector(
                            onTap: onToggleRecord,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10, bottom: 9),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: isRecording
                                      ? AppColors.error.withOpacity(0.15)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isRecording
                                      ? Icons.stop_circle_outlined
                                      : Icons.mic_rounded,
                                  size: 22,
                                  color: isRecording
                                      ? AppColors.error
                                      : (d
                                          ? const Color(0xFF8E9099)
                                          : const Color(0xFFAAAAAA)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  GestureDetector(
                    onTap: isSending ? null : onSend,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: isSending
                          ? const Center(
                              child: SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white)))
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 18),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Context menu item
// ─────────────────────────────────────────────────────────────────────────────
class _CtxAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _CtxAction(
      {required this.icon,
      required this.label,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap != null ? 1.0 : 0.38,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Text(label,
                  style: GoogleFonts.dmSans(
                      color: color,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Waveform custom painter (used in input bar + voice bubble)
// ─────────────────────────────────────────────────────────────────────────────
class _WaveformPainter extends CustomPainter {
  final Color color;
  final int bars;
  const _WaveformPainter({required this.color, this.bars = 7});

  static const _heights = [
    3.0, 6.0, 10.0, 7.0, 4.0, 9.0, 5.0, 8.0, 11.0, 5.0,
    7.0, 4.0, 10.0, 6.0, 3.0, 8.0, 5.0, 9.0,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final midY    = size.height / 2;
    final count   = math.min(bars, _heights.length);
    final spacing = size.width / (count + 1);

    for (var i = 0; i < count; i++) {
      final x = spacing * (i + 1);
      final h = _heights[i].clamp(2.0, size.height / 2 - 1);
      canvas.drawLine(Offset(x, midY - h), Offset(x, midY + h), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.color != color || old.bars != bars;
}