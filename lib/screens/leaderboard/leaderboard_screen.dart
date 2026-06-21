import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/leaderboard_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../profile/user_profile_screen.dart';

// =============================================================================
//  LeaderboardScreen
// =============================================================================
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabCtrl;
  int _timePeriod = 0; // 0=This Month, 1=This Semester, 2=All Time
  String _selectedSkill = 'All Skills';
  late LeaderboardService _service;

  static const _timePeriods = ['This Month', 'This Semester', 'All Time'];

  bool get _d => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _d ? const Color(0xFF0D0E17) : const Color(0xFFF7F7FB);
  Color get _sf => _d ? const Color(0xFF161824) : Colors.white;
  Color get _sv => _d ? const Color(0xFF1E2030) : const Color(0xFFF0F0F6);
  Color get _bd => _d ? const Color(0xFF2A2D3E) : const Color(0xFFE8E8F0);
  Color get _tp => _d ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A14);
  Color get _ts => _d ? const Color(0xFF8E9099) : const Color(0xFF666680);
  Color get _tl => _d ? const Color(0xFF555868) : const Color(0xFFAAAAAC);

  @override
  void initState() {
    super.initState();
    _mainTabCtrl = TabController(length: 2, vsync: this);
    _mainTabCtrl.addListener(() => setState(() {}));
    _service = LeaderboardService();
    _service.fetchLeaderboard();
  }

  @override
  void dispose() {
    _mainTabCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  void _showHowPointsWork() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _PointsInfoSheet(d: _d, sf: _sf, bd: _bd, tp: _tp, ts: _ts, tl: _tl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _service,
      child: Scaffold(
        backgroundColor: _bg,
        body: Consumer<LeaderboardService>(
          builder: (_, svc, __) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App bar ────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, const Color(0xFF8B6CFF)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                titleSpacing: 0,
                leadingWidth: 58,
                leading: Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  'Leaderboard',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                centerTitle: false,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Main tabs: Overall / By Category ──────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _SegTab(
                    tabs: const ['Overall', 'By Category'],
                    selected: _mainTabCtrl.index,
                    sv: _sv,
                    bd: _bd,
                    ts: _ts,
                    onTap: (i) {
                      setState(() {
                        _mainTabCtrl.index = i;
                        if (i == 0) {
                          _selectedSkill = 'All Skills';
                          svc.filterBySkill(null);
                        }
                      });
                    },
                  ),
                ),
              ),

              // ── Tagline ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    children: [
                      Text(
                        'Recognizing the most active',
                        style: GoogleFonts.dmSans(color: _ts, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'and helping hands on campus! ⭐',
                        style: GoogleFonts.dmSans(color: _ts, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Skill picker (By Category only) ──────────────────
              if (_mainTabCtrl.index == 1 && !svc.isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: _SkillPicker(
                      skills: svc.allSkills,
                      selected: _selectedSkill,
                      sf: _sf,
                      sv: _sv,
                      bd: _bd,
                      tp: _tp,
                      ts: _ts,
                      onChanged: (val) {
                        setState(() => _selectedSkill = val ?? 'All Skills');
                        svc.filterBySkill(val);
                      },
                    ),
                  ),
                ),

              // ── Time period ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: _TimePeriodTab(
                    periods: _timePeriods,
                    selected: _timePeriod,
                    sv: _sv,
                    bd: _bd,
                    ts: _ts,
                    onTap: (i) => setState(() => _timePeriod = i),
                  ),
                ),
              ),

              // ── Motivation banner ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: _MotivBanner(
                    sf: _sf,
                    bd: _bd,
                    tp: _tp,
                    ts: _ts,
                    onHow: _showHowPointsWork,
                  ),
                ),
              ),

              // ── Loading ───────────────────────────────────────────
              if (svc.isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(60),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),

              // ── Empty ─────────────────────────────────────────────
              if (!svc.isLoading && svc.filteredEntries.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(60),
                    child: Column(
                      children: [
                        Icon(Icons.leaderboard_outlined, size: 56, color: _tl),
                        const SizedBox(height: 16),
                        Text(
                          'No results yet',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _tp,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Complete swaps to appear on the leaderboard!',
                          style: GoogleFonts.dmSans(fontSize: 13, color: _ts),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Podium ────────────────────────────────────────────
              if (!svc.isLoading && svc.filteredEntries.length >= 3)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _Podium(
                      entries: svc.filteredEntries,
                      d: _d,
                      tp: _tp,
                      ts: _ts,
                      onTap: (id) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(userId: id),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Ranked list ───────────────────────────────────────
              if (!svc.isLoading && svc.filteredEntries.isNotEmpty)
                Builder(
                  builder: (context) {
                    final startIdx = svc.filteredEntries.length >= 3 ? 3 : 0;
                    final items = svc.filteredEntries.skip(startIdx).toList();
                    if (items.isEmpty)
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) =>
                              _RankTile(
                                entry: items[i],
                                rank: startIdx + i + 1,
                                sf: _sf,
                                bd: _bd,
                                tp: _tp,
                                ts: _ts,
                                tl: _tl,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        UserProfileScreen(userId: items[i].id),
                                  ),
                                ),
                              ).animate().fadeIn(
                                delay: Duration(milliseconds: i * 40),
                              ),
                          childCount: items.length,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
//  Segmented tabs (Overall / By Category)
// =============================================================================
class _SegTab extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final Color sv, bd, ts;
  final ValueChanged<int> onTap;

  const _SegTab({
    required this.tabs,
    required this.selected,
    required this.sv,
    required this.bd,
    required this.ts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: sv,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bd, width: 1),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final sel = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.30),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    tabs[i],
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : ts,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// =============================================================================
//  Time period tabs
// =============================================================================
class _TimePeriodTab extends StatelessWidget {
  final List<String> periods;
  final int selected;
  final Color sv, bd, ts;
  final ValueChanged<int> onTap;

  const _TimePeriodTab({
    required this.periods,
    required this.selected,
    required this.sv,
    required this.bd,
    required this.ts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: sv,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bd, width: 1),
      ),
      child: Row(
        children: List.generate(periods.length, (i) {
          final sel = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    periods[i],
                    style: GoogleFonts.dmSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : ts,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// =============================================================================
//  Skill picker
// =============================================================================
class _SkillPicker extends StatelessWidget {
  final List<String> skills;
  final String selected;
  final Color sf, sv, bd, tp, ts;
  final ValueChanged<String?> onChanged;

  const _SkillPicker({
    required this.skills,
    required this.selected,
    required this.sf,
    required this.sv,
    required this.bd,
    required this.tp,
    required this.ts,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: sv,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: bd, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          dropdownColor: sf,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: ts, size: 20),
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: tp,
          ),
          items: skills
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s,
                    style: GoogleFonts.dmSans(color: tp, fontSize: 13),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// =============================================================================
//  Motivation banner
// =============================================================================
class _MotivBanner extends StatelessWidget {
  final Color sf, bd, tp, ts;
  final VoidCallback onHow;

  const _MotivBanner({
    required this.sf,
    required this.bd,
    required this.tp,
    required this.ts,
    required this.onHow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: sf,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: bd, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share knowledge. Build solutions.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Climb the ranks!',
                  style: GoogleFonts.dmSans(fontSize: 11, color: ts),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onHow,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How points work?',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
//  Podium (top 3)
// =============================================================================
class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final bool d;
  final Color tp, ts;
  final ValueChanged<String> onTap;

  const _Podium({
    required this.entries,
    required this.d,
    required this.tp,
    required this.ts,
    required this.onTap,
  });

  static const _medals = {
    1: Color(0xFFFFD700),
    2: Color(0xFFC0C0C0),
    3: Color(0xFFCD7F32),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        gradient: d ? AppColors.primaryGradient : null,
        color: d ? null : const Color(0xFFF4EFFF),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: d
            ? null
            : Border.all(color: AppColors.primary.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(d ? 0.22 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _item(context, entries[1], 2, 84),
          _item(context, entries[0], 1, 104),
          _item(context, entries[2], 3, 68),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    LeaderboardEntry entry,
    int rank,
    double sz,
  ) {
    final mc = _medals[rank]!;
    final tc = d ? Colors.white : tp;
    final sc = d ? Colors.white70 : ts;
    final bars = {1: 46.0, 2: 34.0, 3: 22.0};

    return GestureDetector(
      onTap: () => onTap(entry.id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AvatarWidget(
                avatarUrl: entry.avatarUrl,
                username: entry.username,
                radius: sz / 2,
                borderColor: mc,
              ),
              Positioned(
                bottom: -7,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: mc,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: rank == 1 ? Colors.black87 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            entry.username,
            style: GoogleFonts.dmSans(
              color: tc,
              fontSize: rank == 1 ? 13 : 11,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_horiz_rounded, color: sc, size: 10),
              const SizedBox(width: 3),
              Text(
                '${entry.totalSwaps}',
                style: GoogleFonts.dmSans(
                  color: sc,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFFFD700),
                size: 10,
              ),
              const SizedBox(width: 2),
              Text(
                entry.averageRating > 0
                    ? entry.averageRating.toStringAsFixed(1)
                    : '-',
                style: GoogleFonts.dmSans(
                  color: sc,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: rank == 1 ? 78 : 62,
            height: bars[rank]!,
            decoration: BoxDecoration(
              color: d
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
}

// =============================================================================
//  Rank tile (4th+)
// =============================================================================
class _RankTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final Color sf, bd, tp, ts, tl;
  final VoidCallback onTap;

  const _RankTile({
    required this.entry,
    required this.rank,
    required this.sf,
    required this.bd,
    required this.tp,
    required this.ts,
    required this.tl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final d = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: sf,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: bd, width: 1),
          boxShadow: d
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : AppShadows.card,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                '#$rank',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: tl,
                ),
              ),
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
                  Text(
                    entry.fullName ?? entry.username,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: tp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@${entry.username}',
                    style: GoogleFonts.dmSans(fontSize: 11, color: tl),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${entry.totalSwaps} swaps',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      entry.averageRating > 0
                          ? entry.averageRating.toStringAsFixed(1)
                          : '-',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
//  How Points Work bottom sheet
// =============================================================================
class _PointsInfoSheet extends StatelessWidget {
  final bool d;
  final Color sf, bd, tp, ts, tl;

  const _PointsInfoSheet({
    required this.d,
    required this.sf,
    required this.bd,
    required this.tp,
    required this.ts,
    required this.tl,
  });

  static const _rules = [
    _PR(
      Icons.swap_horiz_rounded,
      AppColors.primary,
      'Complete a Swap',
      '+10 pts',
    ),
    _PR(
      Icons.star_rounded,
      AppColors.warning,
      'Receive a 5★ Rating',
      '+20 pts',
    ),
    _PR(
      Icons.add_circle_outline_rounded,
      Color(0xFF22C55E),
      'Post a New Skill',
      '+5 pts',
    ),
    _PR(Icons.forum_outlined, Color(0xFF4CC9F0), 'Active in Chats', '+2 pts'),
    _PR(Icons.repeat_rounded, Color(0xFFFF4D6D), 'Weekly Streak', '+15 pts'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      decoration: BoxDecoration(
        color: sf,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: bd, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: bd,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How Points Work',
                    style: GoogleFonts.dmSans(
                      color: tp,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Earn points and climb the ranks',
                    style: GoogleFonts.dmSans(color: ts, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.20),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.functions_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Score = (Swaps × 10) + (Avg Rating × 20)',
                    style: GoogleFonts.dmSans(
                      color: AppColors.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Ways to earn',
            style: GoogleFonts.dmSans(
              color: tp,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ..._rules.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: r.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(r.icon, color: r.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      r.title,
                      style: GoogleFonts.dmSans(
                        color: tp,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: r.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      r.pts,
                      style: GoogleFonts.dmSans(
                        color: r.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Got it!',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PR {
  final IconData icon;
  final Color color;
  final String title, pts;
  const _PR(this.icon, this.color, this.title, this.pts);
}
