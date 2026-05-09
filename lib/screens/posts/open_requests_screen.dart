import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/post_card.dart';
import '../../widgets/shimmer_card.dart';
import 'package:Swaply/widgets/swap_post_card.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  OpenRequestsScreen
//  Light: pure white bg  |  Dark: #111318 bg
//  ✦ Neutral header — no gradient, title left-aligned
//  ✦ Info banner, cards, empty state all theme-aware
// ═══════════════════════════════════════════════════════════════════════════
class OpenRequestsScreen extends StatefulWidget {
  const OpenRequestsScreen({super.key});

  @override
  State<OpenRequestsScreen> createState() => _OpenRequestsScreenState();
}

class _OpenRequestsScreenState extends State<OpenRequestsScreen> {
  // ── theme shortcuts ──────────────────────────────────────────────────────
  bool get _d => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _d ? const Color(0xFF0D0E17) : const Color(0xFFF4F4FB);
  Color get _sf => _d ? const Color(0xFF1A1D24) : Colors.white;
  Color get _bd => _d ? const Color(0xFF2A2D36) : const Color(0xFFDDDCF0);
  Color get _tp => _d ? const Color(0xFFF2F2F4) : const Color(0xFF0D0C1E);
  Color get _ts => _d ? const Color(0xFF8E9099) : const Color(0xFF6B698A);
  Color get _tl => _d ? const Color(0xFF555862) : const Color(0xFFAAAAAC);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostService>().fetchOpenRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient header matching Create Swap Post ───────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF5B4FE8), Color(0xFF7B6FF0)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 4,
                right: 16,
                bottom: 18,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  Text(
                    'Open Requests',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Info banner ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(_d ? 0.1 : 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Students posting requests for help — respond by starting a chat!',
                        style: GoogleFonts.dmSans(
                          color: _ts,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 50.ms),
          ),

          // ── Content ─────────────────────────────────────────────────
          Consumer<PostService>(
            builder: (_, ps, __) {
              // Loading shimmer
              if (ps.isLoading && ps.openRequests.isEmpty) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const ShimmerCard(),
                      childCount: 4,
                    ),
                  ),
                );
              }

              // Empty state
              if (ps.openRequests.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.help_outline_rounded,
                            size: 44,
                            color: _tl,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No open requests yet',
                          style: GoogleFonts.dmSans(
                            color: _tp,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Be the first to post a help request!',
                          style: GoogleFonts.dmSans(color: _ts, fontSize: 13),
                        ),
                      ],
                    ).animate().fadeIn().scale(begin: const Offset(0.92, 0.92)),
                  ),
                );
              }

              // Requests list
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) =>
                        PostCard(
                              post: ps.openRequests[i],
                              onBookmarkToggle: () =>
                                  ps.toggleBookmark(ps.openRequests[i].id),
                            )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: i * 55))
                            .slideY(
                              begin: 0.06,
                              delay: Duration(milliseconds: i * 55),
                              curve: Curves.easeOutCubic,
                            ),
                    childCount: ps.openRequests.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
