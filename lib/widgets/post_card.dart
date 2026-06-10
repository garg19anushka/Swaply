// lib/widgets/post_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_model.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onSwap;
  final VoidCallback? onBookmark;

  const PostCard({super.key, required this.post, this.onSwap, this.onBookmark});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _swapCtrl;
  late Animation<double> _swapScale;

  @override
  void initState() {
    super.initState();
    _swapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _swapScale = Tween(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _swapCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _swapCtrl.dispose();
    super.dispose();
  }

  // ── theme ────────────────────────────────────────────────────────────────────
  bool get _dark => Theme.of(context).brightness == Brightness.dark;

  Color get _cardBg =>
      _dark ? const Color(0xFF12152A) : const Color(0xFFF8F9FA);
  Color get _cardBdr =>
      _dark ? const Color(0xFF1E2240) : const Color(0xFFE2E6F0);
  Color get _panelBg =>
      _dark ? const Color(0xFF0D0D1A) : const Color(0xFFEEF0F8);
  Color get _panelBdr =>
      _dark ? const Color(0xFF1A1D30) : const Color(0xFFD8DCF0);
  Color get _titleCol => _dark ? Colors.white : const Color(0xFF0F1220);
  Color get _descCol =>
      _dark ? const Color(0xFF8A8FA8) : const Color(0xFF5A6080);
  Color get _metaCol =>
      _dark ? const Color(0xFF8A8FA8) : const Color(0xFF8A90A8);
  Color get _labelCol =>
      _dark ? const Color(0xFF8A8FA8) : const Color(0xFF8A90A8);
  Color get _offersCol =>
      _dark ? const Color(0xFF7B6EF6) : const Color(0xFF3B48C8);
  Color get _wantsCol =>
      _dark ? const Color(0xFFE8855A) : const Color(0xFFBF5C3A);
  Color get _tagBg => _dark ? const Color(0xFF1A1D2E) : const Color(0xFFEAECF8);
  Color get _tagBdr =>
      _dark ? const Color(0xFF2E3150) : const Color(0xFFD0D4EC);
  Color get _tagTxt =>
      _dark ? const Color(0xFF7B8BD4) : const Color(0xFF4A56A8);
  Color get _avatarBg =>
      _dark ? const Color(0xFF6C63FF) : const Color(0xFF5B52D0);
  Color get _swapA => const Color(0xFF6860E8);
  Color get _swapB => const Color(0xFF5B52D0);
  Color get _shadow => _dark
      ? Colors.black.withOpacity(0.38)
      : const Color(0xFFB0B8D8).withOpacity(0.22);

  // Save button colours
  Color get _saveBg => widget.post.isBookmarked
      ? (_dark ? const Color(0xFF2A2D44) : const Color(0xFFEAE8FF))
      : (_dark ? const Color(0xFF1A1D2E) : const Color(0xFFEEF0F8));
  Color get _saveBdr => widget.post.isBookmarked
      ? (_dark ? const Color(0xFF6C63FF) : const Color(0xFF5B52D0))
      : (_dark ? const Color(0xFF2E3150) : const Color(0xFFD0D4EC));
  Color get _saveTxt => widget.post.isBookmarked
      ? (_dark ? const Color(0xFF6C63FF) : const Color(0xFF5B52D0))
      : (_dark ? const Color(0xFFB0B8D4) : const Color(0xFF5A6080));

  // ── helpers ──────────────────────────────────────────────────────────────────
  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  // ── sub-widgets ──────────────────────────────────────────────────────────────
  Widget _avatar() {
    final name = widget.post.profile?.displayName ?? 'U';
    final url = widget.post.profile?.avatarUrl;
    return CircleAvatar(
      radius: 21,
      backgroundColor: _avatarBg,
      child: url != null && url.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: url,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Text(
                  _initials(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          : Text(
              _initials(name),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
    );
  }

  Widget _authorRow() {
    final name = widget.post.profile?.displayName ?? 'Unknown';
    final username = widget.post.profile?.username ?? '';
    final campus = widget.post.profile?.campus ?? '';
    final ago = timeago.format(widget.post.createdAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _avatar(),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(
                  color: _titleCol,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '@$username${campus.isNotEmpty ? ' · $campus' : ''}',
                style: GoogleFonts.poppins(color: _metaCol, fontSize: 11.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(ago, style: GoogleFonts.poppins(color: _metaCol, fontSize: 11.5)),
      ],
    );
  }

  // ── OFFERS / WANTS panel ─────────────────────────────────────────────────────

  // Panel background tones — slightly distinct per side for visual separation
  Color get _offersPanelBg => _dark
      ? const Color(0xFF0E1128) // deep navy-blue tint
      : const Color(0xFFECEEFA);
  Color get _wantsPanelBg => _dark
      ? const Color(0xFF120E16) // deep maroon-dark tint
      : const Color(0xFFFAECEC);
  Color get _offersPanelBdr =>
      _dark ? const Color(0xFF252A4A) : const Color(0xFFCDD2EE);
  Color get _wantsPanelBdr =>
      _dark ? const Color(0xFF3A2030) : const Color(0xFFEECDCD);

  Widget _offersWantsPanel() {
    final isCustom = widget.post.exchangeType == 'custom';
    final rightLabel = isCustom ? 'OFFERS' : 'WANTS';
    final rightValue = isCustom
        ? (widget.post.customOffer ?? '—')
        : (widget.post.skillWanted ?? '—');

    return Row(
      children: [
        // ── Left box: OFFERS ───────────────────────────────────────────────
        Expanded(
          child: _skillBox(
            label: 'OFFERS',
            value: widget.post.skillOffered, // ← live from Supabase
            valueColor: _offersCol,
            bg: _offersPanelBg,
            borderColor: _offersPanelBdr,
          ),
        ),

        // ── Free-floating ↑↓ icon in the gap ──────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                color: _dark
                    ? const Color(0xFF6870A8)
                    : const Color(0xFF8890C0),
                size: 13,
              ),
              const SizedBox(height: 1),
              Icon(
                Icons.arrow_downward_rounded,
                color: _dark
                    ? const Color(0xFF6870A8)
                    : const Color(0xFF8890C0),
                size: 13,
              ),
            ],
          ),
        ),

        // ── Right box: WANTS ───────────────────────────────────────────────
        Expanded(
          child: _skillBox(
            label: rightLabel,
            value: rightValue, // ← live from Supabase
            valueColor: _wantsCol,
            bg: _wantsPanelBg,
            borderColor: _wantsPanelBdr,
          ),
        ),
      ],
    );
  }

  Widget _skillBox({
    required String label,
    required String value,
    required Color valueColor,
    required Color bg,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Label — small caps, muted
          Text(
            label,
            style: GoogleFonts.poppins(
              color: _dark ? const Color(0xFF7880B0) : const Color(0xFF8890C0),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 6),
          // Value — bound to live Supabase field
          Text(
            value,
            style: GoogleFonts.poppins(
              color: valueColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _tags() {
    if (widget.post.tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: widget.post.tags.map(_chip).toList(),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
      decoration: BoxDecoration(
        color: _tagBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _tagBdr),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: _tagTxt,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _footer() {
    final saves = widget.post.bookmarksCount;
    final swaps = widget.post.swapCount;

    return Row(
      children: [
        const Text('🔥', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          '$saves saves',
          style: GoogleFonts.poppins(color: _metaCol, fontSize: 12),
        ),
        const SizedBox(width: 10),
        Icon(Icons.swap_horiz_rounded, color: _metaCol, size: 14),
        const SizedBox(width: 4),
        Text(
          '$swaps swaps',
          style: GoogleFonts.poppins(color: _metaCol, fontSize: 12),
        ),
        const Spacer(),
        _saveBtn(),
        const SizedBox(width: 8),
        _swapBtn(),
      ],
    );
  }

  Widget _saveBtn() {
    return GestureDetector(
      onTap: widget.onBookmark,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: _saveBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _saveBdr),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.post.isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: _saveTxt,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              'Save',
              style: GoogleFonts.poppins(
                color: _saveTxt,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swapBtn() {
    return ScaleTransition(
      scale: _swapScale,
      child: GestureDetector(
        onTapDown: (_) => _swapCtrl.forward(),
        onTapUp: (_) {
          _swapCtrl.reverse();
          widget.onSwap?.call();
        },
        onTapCancel: () => _swapCtrl.reverse(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_swapA, _swapB],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: _swapB.withOpacity(0.38),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Swap',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '→',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBdr),
        boxShadow: [
          BoxShadow(color: _shadow, blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _authorRow(),
            const SizedBox(height: 12),
            Text(
              widget.post.title,
              style: GoogleFonts.poppins(
                color: _titleCol,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.post.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: _descCol,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            _offersWantsPanel(),
            const SizedBox(height: 12),
            _tags(),
            const SizedBox(height: 14),
            _footer(),
          ],
        ),
      ),
    );
  }
}
