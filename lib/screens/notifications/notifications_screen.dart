import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  NotificationsScreen
//  Light: pure white bg, white cards, #E5E5E5 borders
//  Dark:  #111318 bg, #1A1D24 cards, #2A2D36 borders
//  ✦ Neutral header — no gradient, title left-aligned
//  ✦ Unread: primary tint bg + purple border
//  ✦ All text tokens theme-aware
// ═══════════════════════════════════════════════════════════════════════════
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // ── theme shortcuts ──────────────────────────────────────────────────────
  bool  get _d  => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _d ? const Color(0xFF111318) : Colors.white;
  Color get _sf => _d ? const Color(0xFF1A1D24) : Colors.white;
  Color get _bd => _d ? const Color(0xFF2A2D36) : const Color(0xFFE5E5E5);
  Color get _tp => _d ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A0A);
  Color get _ts => _d ? const Color(0xFF8E9099) : const Color(0xFF6E6E6E);
  Color get _tl => _d ? const Color(0xFF555862) : const Color(0xFFAAAAAA);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().markAllRead();
    });
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'message':  return Icons.chat_bubble_outline_rounded;
      case 'swap':     return Icons.swap_horiz_rounded;
      case 'rating':   return Icons.star_outline_rounded;
      case 'bookmark': return Icons.bookmark_outline_rounded;
      default:         return Icons.notifications_outlined;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'message':  return AppColors.primary;
      case 'swap':     return AppColors.success;
      case 'rating':   return AppColors.warning;
      default:         return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── Neutral sticky app bar ──────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: _sf,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: _tp, size: 19),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Notifications',
                style: GoogleFonts.dmSans(
                  color: _tp, fontSize: 18,
                  fontWeight: FontWeight.w800, letterSpacing: -0.4,
                )),
            centerTitle: false,
            actions: [
              // Mark all read button
              Consumer<NotificationService>(
                builder: (_, ns, __) {
                  if (ns.notifications.isEmpty) return const SizedBox();
                  return TextButton(
                    onPressed: () => ns.markAllRead(),
                    child: Text('Clear all',
                        style: GoogleFonts.dmSans(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: _bd),
            ),
          ),

          // ── Notifications list ──────────────────────────────────────
          Consumer<NotificationService>(
            builder: (_, ns, __) {
              if (ns.isLoading) {
                return SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                );
              }

              if (ns.notifications.isEmpty) {
                return SliverFillRemaining(child: _empty());
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final n     = ns.notifications[i];
                      final color = _colorFor(n.type);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          // Unread: tinted bg + purple border
                          // Read:   surface bg + standard border
                          color: n.isRead
                              ? _sf
                              : AppColors.primary.withOpacity(_d ? 0.08 : 0.04),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: n.isRead
                                ? _bd
                                : AppColors.primary.withOpacity(0.28),
                            width: n.isRead ? 1 : 1.5,
                          ),
                          boxShadow: _d
                              ? [BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2))]
                              : AppShadows.card,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon badge
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_iconFor(n.type),
                                    color: color, size: 20),
                              ),
                              const SizedBox(width: 12),

                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(n.title,
                                              style: GoogleFonts.dmSans(
                                                color: _tp,
                                                fontWeight: n.isRead
                                                    ? FontWeight.w500
                                                    : FontWeight.w700,
                                                fontSize: 13.5,
                                              )),
                                        ),
                                        // Unread dot
                                        if (!n.isRead)
                                          Container(
                                            width: 8, height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (n.body != null &&
                                        n.body!.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(n.body!,
                                          style: GoogleFonts.dmSans(
                                            color: _ts,
                                            fontSize: 12.5,
                                            height: 1.4,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                    const SizedBox(height: 5),
                                    Text(
                                      timeago.format(n.createdAt),
                                      style: GoogleFonts.dmSans(
                                          color: _tl, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: i * 40))
                          .slideX(
                              begin: 0.03,
                              delay: Duration(milliseconds: i * 40),
                              curve: Curves.easeOutCubic);
                    },
                    childCount: ns.notifications.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded,
                size: 44, color: _tl),
          ),
          const SizedBox(height: 16),
          Text('No notifications yet',
              style: GoogleFonts.dmSans(
                color: _tp, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text("You're all caught up!",
              style: GoogleFonts.dmSans(color: _ts, fontSize: 13)),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.92, 0.92)),
    );
  }
}