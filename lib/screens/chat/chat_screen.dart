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
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;
  MessageModel? _replyTarget;
  String? _selectedMsgId;

  // ── theme shortcuts ──────────────────────────────────────────
  bool get _d => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _d ? const Color(0xFF0E1117) : Colors.white;
  Color get _sf => _d ? const Color(0xFF161A22) : Colors.white;
  Color get _sv => _d ? const Color(0xFF1E222C) : const Color(0xFFF2F2F5);
  Color get _bd => _d ? const Color(0xFF272B36) : const Color(0xFFEAEAEA);
  Color get _tp => _d ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A0A);
  Color get _ts => _d ? const Color(0xFF8E9099) : const Color(0xFF6E6E6E);
  Color get _tl => _d ? const Color(0xFF555862) : const Color(0xFFAAAAAA);

  // Outgoing: slate-blue gradient (dark) / primary violet-pink (light)
  LinearGradient get _outGrad => _d
      ? const LinearGradient(
          colors: [Color(0xFF3B4EAD), Color(0xFF6C47FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : AppColors.primaryGradient;

  // Incoming: deep-lavender (dark) / pale lavender (light)
  Color get _inBg => _d ? const Color(0xFF262D3D) : const Color(0xFFF0EEFF);
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
    setState(() {
      _isSending = true;
      _replyTarget = null;
    });
    await context.read<ChatService>().sendMessage(
      chatId: widget.chat.id,
      content: text,
    );
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  // ── Pick & send image ────────────────────────────────────────
  Future<void> _pickImage() async {
    final p = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (p == null) return;
    setState(() => _isSending = true);
    final cs = context.read<ChatService>();
    final url = await cs.uploadChatImage(File(p.path));
    if (url != null) {
      await cs.sendMessage(
        chatId: widget.chat.id,
        imageUrl: url,
        messageType: 'image',
      );
      _scrollToBottom();
    }
    setState(() => _isSending = false);
  }

  // ── Schedule session sheet ───────────────────────────────────
  void _showScheduleSheet() {
    final bool d = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = d ? const Color(0xFF1A1D2B) : Colors.white;
    final labelClr = d ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A0A);
    final subClr = d ? const Color(0xFF8E9099) : const Color(0xFF6E6E6E);
    final chipBg = d ? const Color(0xFF262D3D) : const Color(0xFFF0EEFF);
    final chipBorder = d ? const Color(0xFF353B50) : const Color(0xFFDDD8FF);

    // Date options: next 6 days from today
    final today = DateTime.now();
    final dates = List.generate(6, (i) => today.add(Duration(days: i)));
    final times = [
      '10:00 AM',
      '2:00 PM',
      '4:00 PM',
      '6:00 PM',
      '7:00 PM',
      '8:00 PM',
    ];

    int selDate = 2; // Mon highlighted like screenshot
    int selTime = 2; // 4:00 PM

    final dayFmt = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monFmt = [
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

    String fmtDate(DateTime d) =>
        '${dayFmt[d.weekday - 1]} ${monFmt[d.month - 1]} ${d.day}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSS) => Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 14),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: d
                          ? const Color(0xFF353B50)
                          : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Row(
                  children: [
                    const Text('🗓', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      'Schedule Session',
                      style: GoogleFonts.dmSans(
                        color: labelClr,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick a time — both of you will get a reminder 30 mins before',
                  style: GoogleFonts.dmSans(
                    color: subClr,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // DATE label
                Text(
                  'DATE',
                  style: GoogleFonts.dmSans(
                    color: subClr,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),

                // Date chips grid (2 rows of 3)
                ...[
                  [0, 1, 2],
                  [3, 4, 5],
                ].map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: row.map((idx) {
                        final selected = selDate == idx;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSS(() => selDate = idx),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF4A47C4)
                                    : chipBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? Colors.transparent
                                      : chipBorder,
                                  width: 1,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF4A47C4,
                                          ).withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  fmtDate(dates[idx]),
                                  style: GoogleFonts.dmSans(
                                    color: selected ? Colors.white : labelClr,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // TIME label
                Text(
                  'TIME',
                  style: GoogleFonts.dmSans(
                    color: subClr,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),

                // Time chips grid (2 rows of 3)
                ...[
                  [0, 1, 2],
                  [3, 4, 5],
                ].map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: row.map((idx) {
                        final selected = selTime == idx;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSS(() => selTime = idx),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF4A47C4)
                                    : chipBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? Colors.transparent
                                      : chipBorder,
                                  width: 1,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF4A47C4,
                                          ).withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  times[idx],
                                  style: GoogleFonts.dmSans(
                                    color: selected ? Colors.white : labelClr,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Cancel / Confirm row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: d
                                ? const Color(0xFF262D3D)
                                : const Color(0xFFF0EEFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: chipBorder, width: 1),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.dmSans(
                                color: labelClr,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          final picked = fmtDate(dates[selDate]);
                          final time = times[selTime];
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Text(
                                    '📅',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Session scheduled: $picked at $time',
                                      style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B4ACF),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF4B4ACF,
                                ).withOpacity(0.45),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Confirm Session',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Confirm swap dialog ──────────────────────────────────────
  Future<void> _confirmSwap() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirm Swap 🤝',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Confirm a skill swap with '
          '${widget.chat.otherUser?.fullName ?? widget.chat.otherUser?.username}?\n\n'
          'This marks it as pending until both parties complete it.',
          style: GoogleFonts.dmSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<ChatService>().confirmSwap(
        chatId: widget.chat.id,
        otherUserId: widget.chat.otherUser?.id ?? '',
        postId: widget.chat.postId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Swap confirmed! 🎉'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() {});
      }
    }
  }

  // ── Complete swap dialog ─────────────────────────────────────
  Future<void> _completeSwap() async {
    final swaps = await context.read<ChatService>().fetchUserSwaps();
    final swap = swaps.firstWhere(
      (s) => s.chatId == widget.chat.id && s.status == 'pending',
      orElse: () => SwapModel(
        id: '',
        chatId: '',
        initiatorId: '',
        receiverId: '',
        status: 'pending',
        createdAt: DateTime.now(),
      ),
    );
    if (swap.id.isEmpty || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Mark Swap Complete?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: const Text('Confirm the skill swap has been completed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Complete'),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<ChatService>().markSwapCompleted(
        swap.id,
        widget.chat.id,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Swap complete! 🎉 Please rate your experience.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      setState(() {});
    }
  }

  // ── Pinned/starred local state (no DB required) ─────────────
  final Set<String> _pinnedIds = {};
  final Set<String> _starredIds = {};
  final Set<String> _selectedIds = {};
  bool _selectMode = false;

  // ── Long-press (500 ms) → WhatsApp-style sheet ───────────────
  void _onLongPress(MessageModel msg) {
    HapticFeedback.mediumImpact();
    setState(() => _selectedMsgId = msg.id);
    _showMsgActionSheet(msg);
  }

  void _dismissOverlay() {
    if (mounted) setState(() => _selectedMsgId = null);
  }

  void _showMsgActionSheet(MessageModel msg) {
    final myId = context.read<AuthService>().currentUser?.id ?? '';
    final isMe = msg.senderId == myId;

    final menuBg = _d ? const Color(0xFF1C1F2B) : Colors.white;
    final divColor = _d ? const Color(0xFF2A2E3A) : const Color(0xFFEEEEEE);
    final labelClr = _d ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A0A);
    final subClr = _d ? const Color(0xFF8E9099) : const Color(0xFF6E6E6E);

    // local emoji state
    String? pickedEmoji;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, sheetState) {
          final isPinned = _pinnedIds.contains(msg.id);
          final isStarred = _starredIds.contains(msg.id);
          final isSelected = _selectedIds.contains(msg.id);

          return Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 14),
            decoration: BoxDecoration(
              color: menuBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // drag handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  decoration: BoxDecoration(
                    color: divColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // ── Emoji reaction row ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ...['👍', '❤️', '😂', '😮', '😢', '🙏'].map((e) {
                        final sel = pickedEmoji == e || msg.reaction == e;
                        return GestureDetector(
                          onTap: () {
                            final newEmoji = sel ? null : e;
                            sheetState(() => pickedEmoji = newEmoji);
                            // Save reaction to message model via ChatService
                            context.read<ChatService>().reactToMessage(
                              msg.id,
                              newEmoji,
                            );
                            Navigator.pop(ctx);
                            _dismissOverlay();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary.withOpacity(0.18)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        );
                      }),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _dismissOverlay();
                          _showFullEmojiPicker(msg);
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: divColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 20,
                            color: subClr,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: divColor),

                // ── Reply ──────────────────────────────────────
                _SheetAction(
                  icon: Icons.reply_rounded,
                  label: 'Reply',
                  color: labelClr,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _replyTarget = msg;
                      _selectedMsgId = null;
                    });
                  },
                ),
                Divider(height: 1, color: divColor),

                // ── Copy (text only) ───────────────────────────
                if (msg.content != null && msg.content!.isNotEmpty) ...[
                  _SheetAction(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    color: labelClr,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: msg.content!));
                      Navigator.pop(ctx);
                      _dismissOverlay();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.copy_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Copied to clipboard',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      msg.content!.length > 50
                                          ? '${msg.content!.substring(0, 50)}…'
                                          : msg.content!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: _d
                              ? const Color(0xFF2A2E3A)
                              : const Color(0xFF333333),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, color: divColor),
                ],

                // ── Forward ────────────────────────────────────
                _SheetAction(
                  icon: Icons.shortcut_rounded,
                  label: 'Forward',
                  color: labelClr,
                  onTap: () {
                    Navigator.pop(ctx);
                    _dismissOverlay();
                    _showForwardSheet(msg);
                  },
                ),
                Divider(height: 1, color: divColor),

                // ── Pin / Unpin ────────────────────────────────
                _SheetAction(
                  icon: isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  label: isPinned ? 'Unpin' : 'Pin',
                  color: isPinned ? AppColors.primary : labelClr,
                  onTap: () {
                    setState(() {
                      if (isPinned)
                        _pinnedIds.remove(msg.id);
                      else
                        _pinnedIds.add(msg.id);
                    });
                    Navigator.pop(ctx);
                    _dismissOverlay();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isPinned ? 'Message unpinned' : 'Message pinned 📌',
                        ),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: divColor),

                // ── Star / Unstar ──────────────────────────────
                _SheetAction(
                  icon: isStarred
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  label: isStarred ? 'Unstar' : 'Star',
                  color: isStarred ? const Color(0xFFFBBF24) : labelClr,
                  onTap: () {
                    setState(() {
                      if (isStarred)
                        _starredIds.remove(msg.id);
                      else
                        _starredIds.add(msg.id);
                    });
                    Navigator.pop(ctx);
                    _dismissOverlay();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              isStarred
                                  ? Icons.star_outline_rounded
                                  : Icons.star_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isStarred
                                  ? 'Removed from starred'
                                  : 'Message starred',
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: _d
                            ? const Color(0xFF2A2E3A)
                            : const Color(0xFF4A4A4A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: divColor),

                // ── Select ─────────────────────────────────────
                _SheetAction(
                  icon: isSelected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  label: isSelected ? 'Deselect' : 'Select',
                  color: isSelected ? AppColors.primary : labelClr,
                  onTap: () {
                    setState(() {
                      if (isSelected)
                        _selectedIds.remove(msg.id);
                      else {
                        _selectedIds.add(msg.id);
                        _selectMode = true;
                      }
                    });
                    Navigator.pop(ctx);
                    _dismissOverlay();
                  },
                ),
                Divider(height: 1, color: divColor),

                // ── Report (incoming only) ─────────────────────
                _SheetAction(
                  icon: Icons.thumb_down_alt_outlined,
                  label: 'Report',
                  color: !isMe ? AppColors.error : subClr,
                  enabled: !isMe,
                  onTap: !isMe
                      ? () {
                          Navigator.pop(ctx);
                          _dismissOverlay();
                          _showReportSheet(msg);
                        }
                      : null,
                ),
                Divider(height: 1, color: divColor),

                // ── Delete (own only) ──────────────────────────
                _SheetAction(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: isMe ? AppColors.error : subClr,
                  enabled: isMe,
                  onTap: isMe
                      ? () {
                          Navigator.pop(ctx);
                          _deleteMsg(msg);
                        }
                      : null,
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          );
        },
      ),
    ).whenComplete(_dismissOverlay);
  }

  // ── Delete message ───────────────────────────────────────────
  Future<void> _deleteMsg(MessageModel msg) async {
    _dismissOverlay();
    final confirmed = await _showDeleteConfirmDialog(single: true);
    if (!confirmed || !mounted) return;
    await context.read<ChatService>().deleteMessage(msg.id, widget.chat.id);
  }

  // ── Confirmation popup for delete ────────────────────────────
  Future<bool> _showDeleteConfirmDialog({bool single = true}) async {
    final d = Theme.of(context).brightness == Brightness.dark;
    final bgClr = d ? const Color(0xFF1C1F2B) : Colors.white;
    final labelClr = d ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A0A);
    final subClr = d ? const Color(0xFF8E9099) : const Color(0xFF6E6E6E);
    final cancelBg = d ? const Color(0xFF262D3D) : const Color(0xFFF0EEFF);
    final cancelBdr = d ? const Color(0xFF353B50) : const Color(0xFFDDD8FF);

    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withOpacity(0.55),
          builder: (dlgCtx) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: bgClr,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.30),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    single ? 'Delete Message?' : 'Delete Messages?',
                    style: GoogleFonts.dmSans(
                      color: labelClr,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    single
                        ? 'This message will be permanently deleted and cannot be recovered.'
                        : 'The selected messages will be permanently deleted and cannot be recovered.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: subClr,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(dlgCtx, false),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: cancelBg,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: cancelBdr, width: 1),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.dmSans(
                                  color: labelClr,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(dlgCtx, true),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Delete',
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthService>().currentUser?.id ?? '';
    final other = widget.chat.otherUser;
    return GestureDetector(
      onTap: _selectedMsgId != null ? _dismissOverlay : null,
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            // ── Gradient header (dark) / white (light) ─────────
            Container(
              decoration: BoxDecoration(
                gradient: _d
                    ? const LinearGradient(
                        colors: [Color(0xFF5B4FD9), Color(0xFF7C6FE0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: _d ? null : Colors.white,
                border: _d
                    ? null
                    : const Border(
                        bottom: BorderSide(
                          color: Color(0xFFE0DEEE),
                          width: 0.8,
                        ),
                      ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 16, 10),
                  child: Row(
                    children: [
                      // Back
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: _d ? Colors.white : const Color(0xFF0D0C1E),
                          size: 19,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),

                      // Avatar → profile
                      GestureDetector(
                        onTap: other?.id != null
                            ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UserProfileScreen(userId: other!.id),
                                ),
                              )
                            : null,
                        child: AvatarWidget(
                          avatarUrl: other?.avatarUrl,
                          username: other?.username ?? '',
                          radius: 18,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Name + username
                      Expanded(
                        child: GestureDetector(
                          onTap: other?.id != null
                              ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        UserProfileScreen(userId: other!.id),
                                  ),
                                )
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                other?.fullName ?? other?.username ?? 'User',
                                style: GoogleFonts.dmSans(
                                  color: _d
                                      ? Colors.white
                                      : const Color(0xFF0D0C1E),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '@${other?.username ?? ''}',
                                style: GoogleFonts.dmSans(
                                  color: _d
                                      ? Colors.white70
                                      : const Color(0xFF6B698A),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Schedule button (always visible) ─────────────
                      GestureDetector(
                        onTap: _showScheduleSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _d
                                ? Colors.white.withOpacity(0.15)
                                : const Color(0xFF6C63FF).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _d
                                  ? Colors.white.withOpacity(0.35)
                                  : const Color(0xFF6C63FF).withOpacity(0.45),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🗓', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 5),
                              Text(
                                'Schedule',
                                style: GoogleFonts.dmSans(
                                  color: _d
                                      ? Colors.white
                                      : const Color(0xFF5B4FE8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    );
                  }
                  if (cs.messages.isEmpty) return _emptyChat();

                  return Stack(
                    children: [
                      // ── Pinned message banner ────────────────
                      if (_pinnedIds.isNotEmpty)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.12),
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.primary.withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.push_pin_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${_pinnedIds.length} pinned message${_pinnedIds.length > 1 ? "s" : ""}',
                                    style: GoogleFonts.dmSans(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _pinnedIds.clear()),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      ListView.builder(
                        controller: _scrollCtrl,
                        padding: EdgeInsets.fromLTRB(
                          12,
                          _pinnedIds.isNotEmpty ? 44 : 12,
                          12,
                          8,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: cs.messages.length,
                        itemBuilder: (_, i) {
                          final msg = cs.messages[i];
                          final isMe = msg.senderId == myId;
                          if (msg.messageType == 'system') {
                            return _sysMsg(msg.content ?? '');
                          }
                          final isPinned = _pinnedIds.contains(msg.id);
                          final isStarred = _starredIds.contains(msg.id);
                          final isSel = _selectedIds.contains(msg.id);

                          return _SwipeToReply(
                            key: ValueKey(msg.id),
                            isMe: isMe,
                            onSwipe: () => setState(() => _replyTarget = msg),
                            child: _MsgRow(
                              msg: msg,
                              isMe: isMe,
                              isHighlighted: _selectedMsgId == msg.id,
                              isPinned: isPinned,
                              isStarred: isStarred,
                              isSelected: isSel,
                              selectMode: _selectMode,
                              longPressDuration: const Duration(
                                milliseconds: 350,
                              ),
                              onLongPress: () => _onLongPress(msg),
                              onTap: _selectMode
                                  ? () => setState(() {
                                      if (isSel)
                                        _selectedIds.remove(msg.id);
                                      else
                                        _selectedIds.add(msg.id);
                                    })
                                  : null,
                              onMenuTap: () => _onLongPress(msg),
                              bubbleBuilder: (showMenu) =>
                                  _Bubble(
                                    msg: msg,
                                    isMe: isMe,
                                    outGrad: _outGrad,
                                    inBg: _inBg,
                                    inText: _inText,
                                    tl: _tl,
                                    showMenuIcon: showMenu,
                                    onMenuTap: () => _onLongPress(msg),
                                  ).animate().fadeIn(
                                    delay: Duration(milliseconds: i * 18),
                                  ),
                            ),
                          );
                        },
                      ),

                      // select-mode top bar
                      if (_selectMode)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            color: _sf,
                            child: Row(
                              children: [
                                Text(
                                  '${_selectedIds.length} selected',
                                  style: GoogleFonts.dmSans(
                                    color: _tp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  icon: Icon(
                                    Icons.shortcut_rounded,
                                    color: AppColors.primary,
                                  ),
                                  label: Text(
                                    'Forward',
                                    style: GoogleFonts.dmSans(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  onPressed: _selectedIds.isEmpty
                                      ? null
                                      : () {
                                          final msgs = cs.messages
                                              .where(
                                                (m) =>
                                                    _selectedIds.contains(m.id),
                                              )
                                              .toList();
                                          setState(() {
                                            _selectedIds.clear();
                                            _selectMode = false;
                                          });
                                          if (msgs.isNotEmpty)
                                            _showForwardSheet(msgs.first);
                                        },
                                ),
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red,
                                  ),
                                  label: Text(
                                    'Delete',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.red,
                                    ),
                                  ),
                                  onPressed: _selectedIds.isEmpty
                                      ? null
                                      : () async {
                                          final confirmed =
                                              await _showDeleteConfirmDialog(
                                                single:
                                                    _selectedIds.length == 1,
                                              );
                                          if (!confirmed || !mounted) return;
                                          for (final id in _selectedIds) {
                                            await context
                                                .read<ChatService>()
                                                .deleteMessage(
                                                  id,
                                                  widget.chat.id,
                                                );
                                          }
                                          setState(() {
                                            _selectedIds.clear();
                                            _selectMode = false;
                                          });
                                        },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  color: _tp,
                                  onPressed: () => setState(() {
                                    _selectedIds.clear();
                                    _selectMode = false;
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // ── Input bar ──────────────────────────────────────
            _InputBar(
              controller: _msgCtrl,
              isSending: _isSending,
              replyTarget: _replyTarget,
              d: _d,
              sf: _sf,
              sv: _sv,
              bd: _bd,
              tp: _tp,
              ts: _ts,
              onCancelReply: () => setState(() => _replyTarget = null),
              onSend: _send,
              onPickImage: _pickImage,
            ),
          ],
        ),
      ),
    );
  }

  // ── Full emoji picker ─────────────────────────────────────────────────────
  void _showFullEmojiPicker(MessageModel msg) {
    final bool d = Theme.of(context).brightness == Brightness.dark;
    final menuBg = d ? const Color(0xFF1C1F2B) : Colors.white;
    final divColor = d ? const Color(0xFF2A2E3A) : const Color(0xFFEEEEEE);
    final labelClr = d ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A0A);

    const allEmojis = [
      '😀',
      '😁',
      '😂',
      '🤣',
      '😃',
      '😄',
      '😅',
      '😆',
      '😉',
      '😊',
      '😋',
      '😎',
      '😍',
      '🥰',
      '😘',
      '🤩',
      '😇',
      '🙂',
      '😏',
      '😒',
      '😞',
      '😔',
      '😟',
      '😕',
      '🙁',
      '☹️',
      '😣',
      '😖',
      '😫',
      '😩',
      '🥺',
      '😢',
      '😭',
      '😤',
      '😠',
      '😡',
      '🤬',
      '🤯',
      '😳',
      '🥵',
      '😱',
      '😨',
      '😰',
      '😥',
      '🤗',
      '🤔',
      '🤭',
      '🤫',
      '🤥',
      '😶',
      '😑',
      '😬',
      '🙄',
      '😯',
      '😦',
      '😧',
      '😮',
      '😲',
      '🥱',
      '😴',
      '🤤',
      '😪',
      '😵',
      '🤐',
      '🥴',
      '🤢',
      '🤮',
      '🤧',
      '😷',
      '🤒',
      '👍',
      '👎',
      '👋',
      '🤚',
      '✋',
      '🖐',
      '👌',
      '🤌',
      '🤏',
      '✌️',
      '🤞',
      '🤟',
      '🤘',
      '🤙',
      '👈',
      '👉',
      '👆',
      '👇',
      '☝️',
      '👍',
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '🤍',
      '🤎',
      '💕',
      '💞',
      '💓',
      '💗',
      '💖',
      '💘',
      '💝',
      '💟',
      '☮️',
      '✝️',
      '🕊️',
      '🎉',
      '🎊',
      '🎈',
      '🎁',
      '🎀',
      '🏆',
      '🥇',
      '🌟',
      '⭐',
      '✨',
      '🔥',
      '💫',
      '🌈',
      '🌸',
      '🌺',
      '🌻',
      '🍀',
      '🌙',
      '⚡',
      '❄️',
      '🙏',
      '👏',
      '🤝',
      '💪',
      '🦾',
      '🫶',
      '💅',
      '🫠',
      '🥹',
      '😌',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 14),
        decoration: BoxDecoration(
          color: menuBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: divColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  Text(
                    'React to message',
                    style: GoogleFonts.dmSans(
                      color: labelClr,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: divColor),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                itemCount: allEmojis.length,
                itemBuilder: (_, idx) {
                  final e = allEmojis[idx];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      context.read<ChatService>().reactToMessage(
                        msg.id,
                        msg.reaction == e ? null : e,
                      );
                      _dismissOverlay();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 24)),
                      ),
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

  // ── Forward sheet ─────────────────────────────────────────────────────────
  void _showForwardSheet(MessageModel msg) {
    final cs = context.read<ChatService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _d ? const Color(0xFF1E222C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Forward to',
              style: GoogleFonts.dmSans(
                color: _tp,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (cs.chats.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No other conversations',
                  style: GoogleFonts.dmSans(color: _ts),
                ),
              )
            else
              ...cs.chats
                  .where((c) => c.id != widget.chat.id)
                  .take(6)
                  .map(
                    (c) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: AvatarWidget(
                        avatarUrl: c.otherUser?.avatarUrl,
                        username: c.otherUser?.username ?? '',
                        radius: 20,
                      ),
                      title: Text(
                        c.otherUser?.fullName ??
                            c.otherUser?.username ??
                            'User',
                        style: GoogleFonts.dmSans(
                          color: _tp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // Forward inline using sendMessage (no forwardMessage needed)
                        final fwdContent = msg.content != null
                            ? '↪ ${msg.content}'
                            : null;
                        context.read<ChatService>().sendMessage(
                          chatId: c.id,
                          content: fwdContent,
                          imageUrl: msg.imageUrl,
                          messageType: msg.messageType,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Forwarded to ${c.otherUser?.fullName ?? 'User'}',
                            ),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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

  // ── Report sheet ─────────────────────────────────────────────────────────
  void _showReportSheet(MessageModel msg) {
    final reasons = [
      'Spam or irrelevant',
      'Harassment or bullying',
      'Inappropriate content',
      'Fake profile',
      'Other',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _d ? const Color(0xFF1E222C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report message',
              style: GoogleFonts.dmSans(
                color: _tp,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select a reason',
              style: GoogleFonts.dmSans(color: _ts, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ...reasons.map(
              (r) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.flag_outlined,
                  color: AppColors.error,
                  size: 20,
                ),
                title: Text(
                  r,
                  style: GoogleFonts.dmSans(
                    color: _tp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Message reported. Thank you.'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
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
      child: Text(
        content,
        style: GoogleFonts.dmSans(
          fontSize: 11.5,
          color: AppColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  Widget _emptyChat() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.waving_hand_rounded, size: 40, color: _ts),
        const SizedBox(height: 12),
        Text(
          'Say hello!',
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _tp,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Start your SkillSwap conversation',
          style: GoogleFonts.dmSans(color: _ts, fontSize: 13),
        ),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Message row: handles long-press (mobile) + hover pull-bar (web)
// ─────────────────────────────────────────────────────────────────────────────
class _MsgRow extends StatefulWidget {
  final MessageModel msg;
  final bool isMe;
  final bool isHighlighted, isPinned, isStarred, isSelected, selectMode;
  final Duration longPressDuration;
  final VoidCallback onLongPress;
  final VoidCallback? onTap;
  final VoidCallback onMenuTap;
  // bubble builder accepts showMenu so the interior icon fades in/out
  final Widget Function(bool showMenu) bubbleBuilder;

  const _MsgRow({
    required this.msg,
    required this.isMe,
    required this.isHighlighted,
    required this.isPinned,
    required this.isStarred,
    required this.isSelected,
    required this.selectMode,
    required this.longPressDuration,
    required this.onLongPress,
    required this.onTap,
    required this.onMenuTap,
    required this.bubbleBuilder,
  });

  @override
  State<_MsgRow> createState() => _MsgRowState();
}

class _MsgRowState extends State<_MsgRow> {
  bool _hovered = false;
  bool _longPressed = false;

  void _handleTap() {
    widget.onTap?.call();
  }

  void _handleLongPress() {
    setState(() => _longPressed = true);
    widget.onLongPress();
    // auto-hide icon after sheet dismisses (1.5 s fallback)
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _longPressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final showMenu = _hovered || _longPressed;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
      }),
      child: GestureDetector(
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: (widget.isHighlighted || widget.isSelected)
              ? BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Select checkbox (select mode) ─────────────
              if (widget.selectMode)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: AnimatedScale(
                    scale: widget.selectMode ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Checkbox(
                      value: widget.isSelected,
                      onChanged: (_) => widget.onTap?.call(),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

              // ── Bubble (built with current showMenu state) ─
              Expanded(
                child: Stack(
                  children: [
                    widget.bubbleBuilder(showMenu),
                    // Starred badge
                    if (widget.isStarred)
                      Positioned(
                        right: widget.isMe ? 16 : null,
                        left: widget.isMe ? null : 16,
                        bottom: 22,
                        child: const Text("⭐", style: TextStyle(fontSize: 12)),
                      ),
                    // Pinned badge
                    if (widget.isPinned)
                      Positioned(
                        right: widget.isMe ? 16 : null,
                        left: widget.isMe ? null : 16,
                        bottom: 22,
                        child: const Icon(
                          Icons.push_pin_rounded,
                          size: 12,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
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
  const _SwipeToReply({
    super.key,
    required this.isMe,
    required this.onSwipe,
    required this.child,
  });

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
                left: 0,
                top: 0,
                bottom: 0,
                child: Opacity(
                  opacity: (_dx / 60).clamp(0, 1),
                  child: const Center(
                    child: Icon(
                      Icons.reply_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
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
  final VoidCallback? onMenuTap;
  final bool showMenuIcon;

  const _Bubble({
    required this.msg,
    required this.isMe,
    required this.outGrad,
    required this.inBg,
    required this.inText,
    required this.tl,
    this.onMenuTap,
    this.showMenuIcon = false,
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
    final hasReaction = msg.reaction != null && msg.reaction!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 60 : 8,
        right: isMe ? 8 : 60,
        bottom: hasReaction ? 14 : 6,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Bubble container with interior menu icon overlay ──
                Stack(
                  children: [
                    Container(
                      padding: (msg.messageType == 'image')
                          ? EdgeInsets.zero
                          : isVoice
                          ? const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            )
                          : const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 10,
                            ),
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
                              child: Image.network(
                                msg.imageUrl!,
                                width: 200,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Padding(
                              // extra right padding so text never overlaps menu icon
                              padding: const EdgeInsets.only(right: 18),
                              child: Text(
                                msg.content ?? '',
                                style: GoogleFonts.dmSans(
                                  color: isMe ? Colors.white : inText,
                                  fontSize: 14,
                                  height: 1.45,
                                ),
                              ),
                            ),
                    ),
                    // ── Interior menu chevron — fades in on hover/long-press ──
                    if (onMenuTap != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: AnimatedOpacity(
                          opacity: showMenuIcon ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeInOut,
                          child: IgnorePointer(
                            ignoring: !showMenuIcon,
                            child: GestureDetector(
                              onTap: onMenuTap,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.white.withOpacity(0.22)
                                      : Colors.black.withOpacity(0.14),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.expand_more_rounded,
                                  size: 15,
                                  color: isMe
                                      ? Colors.white.withOpacity(0.90)
                                      : inText.withOpacity(0.65),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // ── Reaction emoji — floating at bottom-right corner ──
                if (hasReaction)
                  Positioned(
                    bottom: -10,
                    right: isMe ? 6 : null,
                    left: isMe ? null : 6,
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierColor: Colors.black.withOpacity(0.55),
                          builder: (_) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1F2B),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    msg.reaction!,
                                    style: const TextStyle(fontSize: 40),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2A2E3A),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            isMe ? 'Y' : 'T',
                                            style: GoogleFonts.dmSans(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          isMe ? 'You' : 'Them',
                                          style: GoogleFonts.dmSans(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pop(context);
                                          context
                                              .read<ChatService>()
                                              .reactToMessage(msg.id, null);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.red.withOpacity(
                                                0.4,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            'Click to remove',
                                            style: GoogleFonts.dmSans(
                                              color: Colors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
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
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF262D3D),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.15),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          msg.reaction!,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeago.format(msg.createdAt),
                  style: GoogleFonts.dmSans(fontSize: 10, color: tl),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
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
            color: iconColor.withOpacity(0.7),
            bars: 18,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '0:12',
          style: GoogleFonts.dmSans(
            color: iconColor.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Input bar
// ─────────────────────────────────────────────────────────────────────────────
//  Input bar  — matches image 2 exactly
//  • dark strip bg, no border, image icon left, bare text field, mic + send right
//  • while recording: red animated bar replaces text field, cancel + send shown
// ─────────────────────────────────────────────────────────────────────────────
class _InputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final MessageModel? replyTarget;
  final bool d;
  final Color sf, sv, bd, tp, ts;
  final VoidCallback onCancelReply, onSend, onPickImage;

  const _InputBar({
    required this.controller,
    required this.isSending,
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
  });

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    final ts = widget.ts;

    // Exact colours from screenshot
    const barBg = Color(0xFF12151E); // near-black navy strip
    const iconClr = Color(0xFF6C5FD9); // purple for image icon
    const hintClr = Color(0xFF4A4D5A); // dim hint text
    const sendClr = Color(0xFF6C5FD9); // solid purple circle

    return Container(
      color: barBg,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Reply preview (unchanged) ─────────────────────
            if (widget.replyTarget != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.reply_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        widget.replyTarget!.content ??
                            (widget.replyTarget!.messageType == 'image'
                                ? '📷 Photo'
                                : widget.replyTarget!.messageType == 'voice'
                                ? '🎤 Voice note'
                                : ''),
                        style: GoogleFonts.dmSans(
                          color: ts,
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onCancelReply,
                      child: Icon(Icons.close_rounded, size: 16, color: ts),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.4, duration: 200.ms),

            // ── Main input row ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Gradient rectangle input container ────
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1C2033), Color(0xFF252A3A)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Image icon — left
                          GestureDetector(
                            onTap: widget.onPickImage,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(
                                Icons.image_outlined,
                                color: iconClr,
                                size: 20,
                              ),
                            ),
                          ),
                          // Text field
                          Expanded(
                            child: TextField(
                              controller: widget.controller,
                              maxLines: 1,
                              textCapitalization: TextCapitalization.sentences,
                              style: GoogleFonts.dmSans(
                                color: d
                                    ? Colors.white
                                    : const Color(0xFF0A0A0A),
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: GoogleFonts.dmSans(
                                  color: hintClr,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                              ),
                              onSubmitted: (_) => widget.onSend(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ── Send rounded-square ───────────────────────────
                  GestureDetector(
                    onTap: widget.isSending ? null : widget.onSend,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B5EFF), Color(0xFF5B3FE8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C5FD9).withOpacity(0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: widget.isSending
                          ? const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
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
//  Bottom-sheet action row (WhatsApp-style)
// ─────────────────────────────────────────────────────────────────────────────
class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.color,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Context menu item (legacy — kept for compatibility)
// ─────────────────────────────────────────────────────────────────────────────
class _CtxAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _CtxAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap != null ? 1.0 : 0.38,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: color,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
    3.0,
    6.0,
    10.0,
    7.0,
    4.0,
    9.0,
    5.0,
    8.0,
    11.0,
    5.0,
    7.0,
    4.0,
    10.0,
    6.0,
    3.0,
    8.0,
    5.0,
    9.0,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final midY = size.height / 2;
    final count = math.min(bars, _heights.length);
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
