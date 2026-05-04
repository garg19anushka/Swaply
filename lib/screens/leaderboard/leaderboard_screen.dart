import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/leaderboard_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../profile/user_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedSkill = 'All Skills';
  late LeaderboardService _service;

  // ── theme shortcuts ──────────────────────────────────────────────────────
  bool   get _d  => Theme.of(context).brightness == Brightness.dark;
  Color  get _bg => _d ? const Color(0xFF111318) : Colors.white;
  Color  get _sf => _d ? const Color(0xFF1A1D24) : Colors.white;
  Color  get _sv => _d ? const Color(0xFF22252E) : const Color(0xFFF2F2F4);
  Color  get _bd => _d ? const Color(0xFF2A2D36) : const Color(0xFFEFEFEF);
  Color  get _tp => _d ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A0A);
  Color  get _ts => _d ? const Color(0xFF8E9099) : const Color(0xFF6E6E6E);
  Color  get _tl => _d ? const Color(0xFF555862) : const Color(0xFFAAAAAA);

  @override
  void initState() {
    super.initState();
    _service = LeaderboardService();
    _service.fetchLeaderboard();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _service,
      child: Scaffold(
        backgroundColor: _bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── Neutral sticky app bar ────────────────────────────────────
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
              title: Text('Leaderboard',
                  style: GoogleFonts.dmSans(
                    color: _tp, fontSize: 18,
                    fontWeight: FontWeight.w800, letterSpacing: -0.4,
                  )),
              centerTitle: false,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(height: 1, thickness: 1, color: _bd),
              ),
            ),

            // ── Skill filter + user count ─────────────────────────────────
            SliverToBoxAdapter(
              child: Consumer<LeaderboardService>(
                builder: (_, svc, __) {
                  if (svc.isLoading) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 2),
                            decoration: BoxDecoration(
                              color: _sv,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: _bd, width: 1),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSkill,
                                isExpanded: true,
                                dropdownColor: _sf,
                                icon: Icon(Icons.keyboard_arrow_down_rounded,
                                    color: _ts, size: 20),
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _tp,
                                ),
                                items: svc.allSkills.map((skill) =>
                                    DropdownMenuItem(
                                      value: skill,
                                      child: Text(skill,
                                          style: GoogleFonts.dmSans(
                                              color: _tp, fontSize: 13)),
                                    )).toList(),
                                onChanged: (val) {
                                  setState(() =>
                                      _selectedSkill = val ?? 'All Skills');
                                  svc.filterBySkill(val);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _sv,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: _bd, width: 1),
                          ),
                          child: Text(
                            '${svc.filteredEntries.length} users',
                            style: GoogleFonts.dmSans(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: _ts,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Podium (top 3) ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Consumer<LeaderboardService>(
                builder: (_, svc, __) {
                  if (svc.isLoading) {
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2),
                      ),
                    );
                  }
                  if (svc.filteredEntries.isEmpty) return _empty();
                  if (svc.filteredEntries.length >= 3) {
                    return _podium(svc.filteredEntries);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            // ── Ranked list (4th+) ────────────────────────────────────────
            Consumer<LeaderboardService>(
              builder: (_, svc, __) {
                if (svc.isLoading || svc.filteredEntries.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                final startIdx = svc.filteredEntries.length >= 3 ? 3 : 0;
                final items = svc.filteredEntries.skip(startIdx).toList();
                if (items.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _rankTile(items[i], startIdx + i + 1)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: i * 50)),
                      childCount: items.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Podium ────────────────────────────────────────────────────────────────
  Widget _podium(List<LeaderboardEntry> entries) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        // Dark: keep gradient  |  Light: soft purple-tinted surface
        gradient: _d ? AppColors.primaryGradient : null,
        color: _d ? null : const Color(0xFFF4EFFF),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: _d ? null : Border.all(
            color: AppColors.primary.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(_d ? 0.22 : 0.10),
            blurRadius: 16, offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _podiumItem(entries[1], 2, 90),
          _podiumItem(entries[0], 1, 110),
          _podiumItem(entries[2], 3, 72),
        ],
      ),
    );
  }

  Widget _podiumItem(LeaderboardEntry entry, int rank, double avatarSize) {
    final medalColors = {1: const Color(0xFFFFD700), 2: const Color(0xFFC0C0C0), 3: const Color(0xFFCD7F32)};
    final medalColor = medalColors[rank]!;
    // Text colour: white on dark gradient, near-black on light surface
    final textColor = _d ? Colors.white : _tp;
    final subColor  = _d ? Colors.white70 : _ts;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => UserProfileScreen(userId: entry.id))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarWidget(
                avatarUrl: entry.avatarUrl,
                username: entry.username,
                radius: avatarSize / 2,
                borderColor: medalColor,
              ),
              Positioned(
                bottom: -6, left: 0, right: 0,
                child: Center(
                  child: Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: medalColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _d ? Colors.white : Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text('$rank',
                          style: GoogleFonts.dmSans(
                            fontSize: 10, fontWeight: FontWeight.w800,
                            color: rank == 1
                                ? Colors.black87 : Colors.white,
                          )),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(entry.username,
              style: GoogleFonts.dmSans(
                color: textColor,
                fontSize: rank == 1 ? 13 : 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_horiz_rounded, color: subColor, size: 11),
              const SizedBox(width: 3),
              Text('${entry.totalSwaps}',
                  style: GoogleFonts.dmSans(
                      color: subColor, fontSize: 10,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 5),
              const Icon(Icons.star_rounded,
                  color: Color(0xFFFFD700), size: 11),
              const SizedBox(width: 3),
              Text(
                entry.averageRating > 0
                    ? entry.averageRating.toStringAsFixed(1) : '-',
                style: GoogleFonts.dmSans(
                    color: subColor, fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Podium bar
          Container(
            width: rank == 1 ? 80 : 65,
            height: rank == 1 ? 48 : rank == 2 ? 36 : 24,
            decoration: BoxDecoration(
              color: _d
                  ? Colors.white.withOpacity(0.18)
                  : AppColors.primary.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rank tile (4th+) ────────────────────────────────────────────────────
  Widget _rankTile(LeaderboardEntry entry, int rank) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => UserProfileScreen(userId: entry.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _sf,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: _bd, width: 1),
          boxShadow: _d
              ? [BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 8, offset: const Offset(0, 2))]
              : AppShadows.card,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text('#$rank',
                  style: GoogleFonts.dmSans(
                    fontSize: 14, fontWeight: FontWeight.w800, color: _tl,
                  )),
            ),
            AvatarWidget(
              avatarUrl: entry.avatarUrl,
              username: entry.username,
              radius: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.fullName ?? entry.username,
                      style: GoogleFonts.dmSans(
                        fontSize: 14, fontWeight: FontWeight.w700, color: _tp,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('@${entry.username}',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: _tl)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(children: [
                  const Icon(Icons.swap_horiz_rounded,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text('${entry.totalSwaps} swaps',
                      style: GoogleFonts.dmSans(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      )),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.star_rounded,
                      size: 13, color: AppColors.warning),
                  const SizedBox(width: 3),
                  Text(
                    entry.averageRating > 0
                        ? entry.averageRating.toStringAsFixed(1) : '-',
                    style: GoogleFonts.dmSans(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────
  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.leaderboard_outlined, size: 56, color: _tl),
            const SizedBox(height: 16),
            Text('No results for this skill',
                style: GoogleFonts.dmSans(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _ts,
                )),
            const SizedBox(height: 6),
            Text('Try selecting a different skill category.',
                style: GoogleFonts.dmSans(fontSize: 13, color: _tl)),
          ],
        ),
      ),
    );
  }
}