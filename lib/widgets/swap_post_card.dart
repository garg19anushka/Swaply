import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:Swaply/models/post_model.dart';
import 'package:Swaply/utils/app_theme.dart';
import 'package:Swaply/services/post_service.dart';
import 'package:Swaply/services/chat_service.dart';
import 'package:Swaply/services/auth_service.dart';
import 'package:Swaply/screens/chat/chat_screen.dart';

typedef PostCard = SwapPostCard;

class SwapPostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onSwap;
  final VoidCallback? onBookmark;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onTapAuthor;
  final bool isOwn;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const SwapPostCard({
    super.key,
    required this.post,
    this.onSwap,
    this.onBookmark,
    this.onBookmarkToggle,
    this.onTapAuthor,
    this.isOwn = false,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<SwapPostCard> createState() => _SwapPostCardState();
}

class _SwapPostCardState extends State<SwapPostCard> {
  bool _swapping = false;

  // ── Theme ─────────────────────────────────────────────────────────────────
  bool get _d => Theme.of(context).brightness == Brightness.dark;

  // Card always uses a rich dark surface to match screenshot
  Color get _cardBg => _d ? const Color(0xFF111828) : const Color(0xFF141828);
  Color get _cardBd => _d ? const Color(0xFF1E2A3A) : const Color(0xFF1E2A3A);
  Color get _tp => const Color(0xFFF1F5FB);
  Color get _ts => const Color(0xFF8090A8);
  Color get _tl => const Color(0xFF4A5A6E);

  // OFFERS/WANTS box
  Color get _boxBg => const Color(0xFF0D1520);
  Color get _boxBd => const Color(0xFF1E2E42);

  // Tag chips
  Color get _chipBg => const Color(0xFF1A2535);
  Color get _chipBd => const Color(0xFF253447);
  Color get _chipTxt => const Color(0xFF7BA7D4);

  // Save btn
  Color get _saveBg => const Color(0xFF1A2535);
  Color get _saveBd => const Color(0xFF2A3A50);

  static const _offClr = Color(0xFF7C5CFC); // purple  — OFFERS
  static const _wantClr = Color(0xFFFF6B6B); // coral   — WANTS

  // ── Avatar gradient per initial ───────────────────────────────────────────
  static const _grads = [
    [Color(0xFF7C5CFC), Color(0xFFFF4D7D)],
    [Color(0xFF00C9A7), Color(0xFF4CC9F0)],
    [Color(0xFFFFBE0B), Color(0xFFFF6B35)],
    [Color(0xFF6C47FF), Color(0xFF00C9A7)],
    [Color(0xFFFF4D6D), Color(0xFFFF9F43)],
  ];

  String get _initials {
    final n =
        widget.post.profile?.fullName ?? widget.post.profile?.username ?? '?';
    final p = n.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return n.substring(0, n.length.clamp(0, 2)).toUpperCase();
  }

  List<Color> get _avatarGrad {
    if (_initials.isEmpty) return _grads[0];
    return _grads[_initials.codeUnitAt(0) % _grads.length];
  }

  String get _displayName =>
      widget.post.profile?.fullName ?? widget.post.profile?.username ?? 'User';

  String get _handle => '@${widget.post.profile?.username ?? 'user'}';

  String get _campus => widget.post.profile?.campus?.isNotEmpty == true
      ? widget.post.profile!.campus!
      : '';

  String get _timeAgo {
    final d = DateTime.now().difference(widget.post.createdAt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  // ── Swap → opens real chat ────────────────────────────────────────────────
  Future<void> _onSwapTap() async {
    if (widget.isOwn) {
      widget.onSwap?.call();
      return;
    }
    final authorId = widget.post.userId;
    final myId = context.read<AuthService>().currentUser?.id;
    if (authorId == null || myId == null || myId == authorId) {
      widget.onSwap?.call();
      return;
    }
    setState(() => _swapping = true);
    HapticFeedback.mediumImpact();
    try {
      final chat = await context.read<ChatService>().getOrCreateChat(
        otherUserId: authorId,
        postId: widget.post.id,
      );
      if (!mounted) return;
      if (chat != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
        );
      } else {
        _snack('Could not open chat. Try again.');
      }
    } catch (e) {
      if (mounted) _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _swapping = false);
    }
  }

  // ── Save toggle → real Supabase bookmark ──────────────────────────────────
  Future<void> _onSaveTap() async {
    HapticFeedback.lightImpact();
    final cb = widget.onBookmarkToggle ?? widget.onBookmark;
    if (cb != null) {
      cb();
    } else {
      await context.read<PostService>().toggleBookmark(widget.post.id);
      if (mounted) setState(() {});
    }
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

  // ─────────────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    // Tags: dedupe, max 4
    final tagSet = <String>{...post.tags};
    final tags = tagSet.take(4).toList();

    final saves = post.bookmarksCount;

    return GestureDetector(
      onTap: widget.onSwap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _cardBd, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildTitle(post),
              const SizedBox(height: 6),
              _buildDescription(post),
              const SizedBox(height: 14),
              _buildOffersWants(post),
              const SizedBox(height: 12),
              if (tags.isNotEmpty) ...[
                _buildTags(tags),
                const SizedBox(height: 14),
              ],
              _buildFooter(post, saves),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Gradient avatar with initials
        GestureDetector(
          onTap: widget.onTapAuthor,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _avatarGrad,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(
                _initials,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Name + handle · campus
        Expanded(
          child: GestureDetector(
            onTap: widget.onTapAuthor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayName,
                  style: GoogleFonts.dmSans(
                    color: _tp,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _campus.isNotEmpty ? '$_handle · $_campus' : _handle,
                  style: GoogleFonts.dmSans(
                    color: _tl,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Time ago
        Text(
          _timeAgo,
          style: GoogleFonts.dmSans(
            color: _tl,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Title ─────────────────────────────────────────────────────────────────
  Widget _buildTitle(PostModel post) => Text(
    post.title,
    style: GoogleFonts.dmSans(
      color: _tp,
      fontSize: 16.5,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      height: 1.22,
    ),
  );

  // ── Description ───────────────────────────────────────────────────────────
  Widget _buildDescription(PostModel post) => Text(
    post.description,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: GoogleFonts.dmSans(
      color: _ts,
      fontSize: 13.5,
      height: 1.5,
      fontWeight: FontWeight.w400,
    ),
  );

  // ── OFFERS ⇅ WANTS box ────────────────────────────────────────────────────
  Widget _buildOffersWants(PostModel post) {
    final isBarter = post.exchangeType == 'barter';
    final wantLabel = isBarter ? 'WANTS' : 'OFFERS';
    final wantValue = isBarter
        ? (post.skillWanted?.isNotEmpty == true
              ? post.skillWanted!
              : 'Any Skill')
        : (post.customOffer ?? 'Custom');

    return Container(
      decoration: BoxDecoration(
        color: _boxBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _boxBd, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // OFFERS
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'OFFERS',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF4A5A72),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      post.skillOffered,
                      style: GoogleFonts.dmSans(
                        color: _offClr,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Centre ⇅ icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2535),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF253447), width: 1),
                ),
                child: const Icon(
                  Icons.swap_vert_rounded,
                  size: 16,
                  color: Color(0xFF5A7A9A),
                ),
              ),
            ),

            // WANTS
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 13, 14, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      wantLabel,
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF4A5A72),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      wantValue,
                      style: GoogleFonts.dmSans(
                        color: _wantClr,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tag chips ─────────────────────────────────────────────────────────────
  Widget _buildTags(List<String> tags) => Wrap(
    spacing: 7,
    runSpacing: 7,
    children: tags
        .map(
          (t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _chipBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _chipBd, width: 1),
            ),
            child: Text(
              t,
              style: GoogleFonts.dmSans(
                color: _chipTxt,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        )
        .toList(),
  );

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter(PostModel post, int saves) {
    final saved = post.isBookmarked;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 🔥 saves
        const Text('🔥', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          '$saves save${saves == 1 ? '' : 's'}',
          style: GoogleFonts.dmSans(
            color: _tl,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        // ⇅ swaps (placeholder — real swaps_count column not yet in DB)
        const Text(
          '⇅',
          style: TextStyle(fontSize: 13, color: Color(0xFF5A7A9A)),
        ),
        const SizedBox(width: 4),
        Text(
          '${post.bookmarksCount > 0 ? (post.bookmarksCount * 0.6).round() : 0} swaps',
          style: GoogleFonts.dmSans(
            color: _tl,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),

        const Spacer(),

        // [□ Save] outlined pill
        if (!widget.isOwn)
          GestureDetector(
            onTap: _onSaveTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: saved
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: saved ? AppColors.primary.withOpacity(0.6) : _saveBd,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    size: 14,
                    color: saved ? AppColors.primary : _ts,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Save',
                    style: GoogleFonts.dmSans(
                      color: saved ? AppColors.primary : _ts,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (!widget.isOwn) const SizedBox(width: 8),

        // [Swap →] gradient pill
        if (!widget.isOwn)
          GestureDetector(
            onTap: _swapping ? null : _onSwapTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: _swapping
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF7C5CFC), Color(0xFFFF4D7D)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                color: _swapping
                    ? const Color(0xFF7C5CFC).withOpacity(0.5)
                    : null,
                borderRadius: BorderRadius.circular(999),
                boxShadow: _swapping
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF7C5CFC).withOpacity(0.40),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: _swapping
                  ? const SizedBox(
                      width: 46,
                      height: 16,
                      child: Center(
                        child: SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Swap',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
            ),
          ),

        // Own post: edit + delete instead
        if (widget.isOwn) ...[
          _SmallBtn(
            icon: Icons.edit_outlined,
            color: AppColors.primary,
            onTap: widget.onEdit ?? () {},
          ),
          const SizedBox(width: 8),
          _SmallBtn(
            icon: Icons.delete_outline_rounded,
            color: AppColors.error,
            onTap: widget.onDelete ?? () {},
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Small edit / delete icon button (own posts)
// ─────────────────────────────────────────────────────────────────────────────
class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SmallBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
