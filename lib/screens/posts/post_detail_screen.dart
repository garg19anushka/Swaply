import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../chat/chat_screen.dart';
import '../profile/user_profile_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  PostDetailScreen  –  "Skill Details"
//  Light : pure white bg, light grey card surfaces, near-black text
//  Dark  : #111318 bg, #1A1D24 app-bar, #1E222C card surfaces
//  ✦ Title = "Skill Details", left-aligned (centerTitle: false)
//  ✦ Neutral header — no gradient anywhere
//  ✦ Every colour token (text, dividers, cards, tags) reads from theme
//  ✦ "Start Chat & Swap" CTA: gradient in dark, solid primary in light
// ═══════════════════════════════════════════════════════════════════════════
class PostDetailScreen extends StatelessWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    // ── Colour tokens ──────────────────────────────────────────────────────
    final bg = dark ? const Color(0xFF111318) : Colors.white;
    final sf = dark ? const Color(0xFF1A1D24) : Colors.white;
    final sv = dark ? const Color(0xFF1E222C) : const Color(0xFFF6F6F8);
    final bd = dark ? const Color(0xFF2A2D36) : const Color(0xFFEAEAEA);
    final tp = dark ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A0A);
    final ts = dark ? const Color(0xFF8E9099) : const Color(0xFF6E6E6E);
    final tl = dark ? const Color(0xFF555862) : const Color(0xFFAAAAAA);

    final auth   = context.watch<AuthService>();
    final isOwn  = auth.currentUser?.id == post.userId;

    return Scaffold(
      backgroundColor: bg,

      // ── Bottom "Start Chat & Swap" CTA ─────────────────────────────────
      bottomNavigationBar: isOwn
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GestureDetector(
                  onTap: () async {
                    final cs = context.read<ChatService>();
                    final chat = await cs.getOrCreateChat(
                      otherUserId: post.userId,
                      postId: post.id,
                    );
                    if (chat != null && context.mounted) {
                      Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => ChatScreen(chat: chat)));
                    }
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: dark ? AppColors.primaryGradient : null,
                      color: dark ? null : AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary
                              .withOpacity(dark ? 0.28 : 0.20),
                          blurRadius: 14, offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 9),
                        Text('Start Chat & Swap',
                            style: GoogleFonts.dmSans(
                              color: Colors.white, fontSize: 15,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── Neutral sticky app bar ──────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: sf,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: tp, size: 19),
              onPressed: () => Navigator.pop(context),
            ),
            // ✦ Title left-aligned, renamed to "Skill Details"
            title: Text('Skill Details',
                style: GoogleFonts.dmSans(
                  color: tp, fontSize: 17,
                  fontWeight: FontWeight.w700, letterSpacing: -0.3,
                )),
            centerTitle: false,
            actions: [
              if (!isOwn)
                IconButton(
                  icon: Icon(
                    post.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    color: post.isBookmarked ? AppColors.primary : tp,
                    size: 22,
                  ),
                  onPressed: () =>
                      context.read<PostService>().toggleBookmark(post.id),
                ),
              if (isOwn)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: tp),
                  color: sf,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) async {
                    if (val == 'delete') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: sf,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: Text('Delete Post',
                              style: GoogleFonts.dmSans(
                                  color: tp, fontWeight: FontWeight.w700)),
                          content: Text(
                              'Are you sure you want to delete this post?',
                              style: GoogleFonts.dmSans(color: ts)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel',
                                    style: GoogleFonts.dmSans(color: tl))),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Delete',
                                    style: GoogleFonts.dmSans(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w700))),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        await context.read<PostService>().deletePost(post.id);
                        if (context.mounted) Navigator.pop(context);
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Text('Delete Post',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: bd),
            ),
          ),

          // ── Page body ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Tags
                  if (post.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 7, runSpacing: 6,
                      children: post.tags
                          .map((t) => _TagPill(tag: t))
                          .toList(),
                    ).animate().fadeIn(),
                    const SizedBox(height: 14),
                  ],

                  // Post title
                  Text(post.title,
                      style: GoogleFonts.dmSans(
                        color: tp, fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5, height: 1.2,
                      )).animate().fadeIn(delay: 40.ms),
                  const SizedBox(height: 14),

                  // Author row
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) =>
                                UserProfileScreen(userId: post.userId))),
                    child: Row(
                      children: [
                        AvatarWidget(
                          avatarUrl: post.profile?.avatarUrl,
                          username: post.profile?.username ?? '',
                          radius: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.profile?.fullName
                                    ?? post.profile?.username
                                    ?? 'Unknown',
                                style: GoogleFonts.dmSans(
                                    color: tp,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                              ),
                              Text(
                                '@${post.profile?.username ?? ''} · '
                                '${timeago.format(post.createdAt)}',
                                style: GoogleFonts.dmSans(
                                    color: ts, fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        // Rating badge
                        if ((post.profile?.averageRating ?? 0) > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppColors.warning, size: 13),
                                const SizedBox(width: 3),
                                Text(
                                  post.profile!.averageRating
                                      .toStringAsFixed(1),
                                  style: GoogleFonts.dmSans(
                                      color: AppColors.warning,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 80.ms),

                  const SizedBox(height: 20),
                  Divider(color: bd, height: 1),
                  const SizedBox(height: 18),

                  // About this swap
                  Text('About this swap',
                      style: GoogleFonts.dmSans(
                          color: tp, fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(post.description,
                      style: GoogleFonts.dmSans(
                          color: ts, fontSize: 14, height: 1.6))
                      .animate().fadeIn(delay: 120.ms),

                  const SizedBox(height: 20),

                  // Exchange card
                  _ExchangeCard(
                    post: post, dark: dark,
                    sv: sv, bd: bd, tp: tp, tl: tl,
                  ).animate().fadeIn(delay: 160.ms),

                  // Open Request banner
                  if (post.isOpenRequest) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.help_outline_rounded,
                              color: AppColors.warning, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Open Request',
                                    style: GoogleFonts.dmSans(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                Text(
                                    'Help request open to all campus members.',
                                    style: GoogleFonts.dmSans(
                                        color: ts, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Exchange Card  – full width, theme-aware background
// ─────────────────────────────────────────────────────────────────────────────
class _ExchangeCard extends StatelessWidget {
  final PostModel post;
  final bool dark;
  final Color sv, bd, tp, tl;

  const _ExchangeCard({
    required this.post,
    required this.dark,
    required this.sv,
    required this.bd,
    required this.tp,
    required this.tl,
  });

  @override
  Widget build(BuildContext context) {
    final isBarter = post.exchangeType == 'barter';
    final rightColor = isBarter ? AppColors.secondary : AppColors.accentTeal;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: sv,                                   // ← theme-aware surface
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bd, width: 1),
      ),
      child: Column(
        children: [

          // Offering ⇌ Wants row
          Row(
            children: [
              // Offering
              Expanded(
                child: _ExchangeSide(
                  icon: Icons.star_rounded,
                  color: AppColors.primary,
                  label: 'Offering',
                  value: post.skillOffered,
                  tp: tp, tl: tl, isRight: false,
                ),
              ),

              // Centre swap badge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(dark ? 0.18 : 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.swap_horiz_rounded,
                      color: AppColors.primary, size: 20),
                ),
              ),

              // Wants / Offers
              Expanded(
                child: _ExchangeSide(
                  icon: isBarter
                      ? Icons.sync_alt_rounded
                      : Icons.card_giftcard_rounded,
                  color: rightColor,
                  label: isBarter ? 'Wants' : 'Offers',
                  value: isBarter
                      ? (post.skillWanted ?? 'Open')
                      : (post.customOffer ?? 'Custom'),
                  tp: tp, tl: tl, isRight: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Exchange type label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: rightColor.withOpacity(dark ? 0.14 : 0.09),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: rightColor.withOpacity(0.25), width: 1),
            ),
            child: Text(
              isBarter ? '🔄  Barter Exchange' : '🎁  Custom Offer',
              style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: rightColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExchangeSide extends StatelessWidget {
  final IconData icon;
  final Color color, tp, tl;
  final String label, value;
  final bool isRight;

  const _ExchangeSide({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.tp,
    required this.tl,
    required this.isRight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.dmSans(
                fontSize: 9.5, color: tl,
                fontWeight: FontWeight.w700, letterSpacing: 0.6)),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: isRight
              ? [
                  Flexible(
                      child: Text(value,
                          style: GoogleFonts.dmSans(
                              color: tp, fontWeight: FontWeight.w700,
                              fontSize: 14),
                          textAlign: TextAlign.end,
                          maxLines: 2, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 5),
                  Icon(icon, color: color, size: 16),
                ]
              : [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 5),
                  Flexible(
                      child: Text(value,
                          style: GoogleFonts.dmSans(
                              color: tp, fontWeight: FontWeight.w700,
                              fontSize: 14),
                          maxLines: 2, overflow: TextOverflow.ellipsis)),
                ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tag pill  – colour based on tag name
// ─────────────────────────────────────────────────────────────────────────────
class _TagPill extends StatelessWidget {
  final String tag;
  const _TagPill({required this.tag});

  Color get _color {
    if (tag == 'Urgent') return AppColors.error;
    if (tag == 'Quick Help') return AppColors.warning;
    if (tag == 'Online') return AppColors.accentTeal;
    if (tag == 'Beginner-friendly') return const Color(0xFF4CAF7D);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(tag,
          style: GoogleFonts.dmSans(
              fontSize: 11, color: c, fontWeight: FontWeight.w600)),
    );
  }
}