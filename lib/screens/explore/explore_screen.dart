import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/shimmer_card.dart';
import '../posts/post_detail_screen.dart';
import '../posts/create_post_screen.dart';
import '../posts/open_requests_screen.dart' show OpenRequestsScreen;
import '../notifications/notifications_screen.dart';
import '../profile/user_profile_screen.dart';
import '../../widgets/swap_post_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Category chip data  (top pill row: All / Design / Coding …)
// ─────────────────────────────────────────────────────────────────────────────
class _Cat {
  final String label;
  final IconData icon;
  const _Cat(this.label, this.icon);
}

const _cats = [
  _Cat('All', Icons.apps_rounded),
  _Cat('Design', Icons.palette_outlined),
  _Cat('Coding', Icons.code_rounded),
  _Cat('Music', Icons.music_note_rounded),
  _Cat('Writing', Icons.edit_note_rounded),
  _Cat('Math', Icons.calculate_outlined),
  _Cat('Language', Icons.translate_rounded),
  _Cat('Photo', Icons.camera_alt_outlined),
  _Cat('Fitness', Icons.fitness_center_rounded),
  _Cat('Finance', Icons.attach_money_rounded),
  _Cat('Business', Icons.business_center_outlined),
  _Cat('DIY', Icons.handyman_outlined),
];

// Exchange-type filter options (second pill row)
const _exchangeTypes = [
  (value: 'all', label: 'All Types', icon: Icons.swap_horiz_rounded),
  (value: 'barter', label: 'Barter', icon: Icons.sync_alt_rounded),
  (value: 'open_request', label: 'Open Req', icon: Icons.lock_open_rounded),
  (value: 'custom', label: 'Custom', icon: Icons.auto_awesome_rounded),
];

// Trending skills row (shown below search bar)
class _Trend {
  final String label;
  final IconData icon;
  const _Trend(this.label, this.icon);
}

const _trends = [
  _Trend('All', Icons.apps_rounded),
  _Trend('UI/UX Design', Icons.design_services_outlined),
  _Trend('Video Editing', Icons.video_camera_back_outlined),
  _Trend('Photography', Icons.camera_alt_outlined),
  _Trend('Public Speaking', Icons.mic_none_rounded),
  _Trend('Excel', Icons.table_chart_outlined),
  _Trend('Python', Icons.code_rounded),
  _Trend('Music', Icons.music_note_rounded),
  _Trend('Writing', Icons.edit_note_rounded),
  _Trend('Figma', Icons.brush_outlined),
  _Trend('Data Analysis', Icons.bar_chart_rounded),
  _Trend('Marketing', Icons.campaign_outlined),
  _Trend('Finance', Icons.attach_money_rounded),
];

// Grid card gradients
const _cardGrads = [
  [Color(0xFFBBDEFB), Color(0xFF90CAF9)],
  [Color(0xFFF8BBD0), Color(0xFFF48FB1)],
  [Color(0xFFB2EBF2), Color(0xFF80DEEA)],
  [Color(0xFFDCEDC8), Color(0xFFC5E1A5)],
  [Color(0xFFFFE0B2), Color(0xFFFFCC80)],
  [Color(0xFFE1BEE7), Color(0xFFCE93D8)],
];
List<Color> _gradFor(PostModel p) =>
    _cardGrads[p.skillOffered.length % _cardGrads.length];

// ═════════════════════════════════════════════════════════════════════════════
//  ExploreScreen
// ═════════════════════════════════════════════════════════════════════════════
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _activeTrend = 'All'; // trending skills row
  String _activeCat = 'All';
  String _exchangeType = 'all';
  String _sortBy = 'newest';
  String _skillType = 'all';
  String _availability = 'all';
  String _sessionFormat = 'all';
  bool _isGridView = false;

  // ── theme ─────────────────────────────────────────────────────────────────
  bool get _d => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _d ? const Color(0xFF0A0A14) : Colors.white;
  Color get _sf => _d ? const Color(0xFF0E0E1C) : Colors.white;
  Color get _sv => _d ? const Color(0xFF1A1A2E) : const Color(0xFFF2F2F4);
  Color get _bd => _d ? const Color(0xFF1E1E2E) : AppColors.divider;
  Color get _tp => _d ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get _ts => _d ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get _tl => _d ? const Color(0xFF555575) : AppColors.textLight;
  Color get _cb => _d ? const Color(0xFF1A1A2E) : const Color(0xFFF2F2F4);
  Color get _ce => _d ? const Color(0xFF252540) : AppColors.border;

  // chip colours (inactive) — used by both chip rows
  Color get _chipBg => _d ? const Color(0xFF13132A) : const Color(0xFFF0F0F8);
  Color get _chipBd => _d ? const Color(0xFF2A2A45) : const Color(0xFFDDDDEE);

  static const _purple = Color(0xFF7C5CFC);

  // ── init / dispose ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<PostService>().fetchPosts(),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── data methods ──────────────────────────────────────────────────────────
  void _search(String q) {
    setState(() => _query = q);
    _refetch();
  }

  void _setCat(String cat) {
    setState(() {
      _activeCat = cat;
      _activeTrend = 'All'; // deselect trend when category is picked
    });
    if (cat == 'All') {
      _searchCtrl.clear();
      _search('');
    } else {
      _searchCtrl.text = cat;
      _search(cat);
    }
  }

  void _setTrend(String trend) {
    setState(() => _activeTrend = trend);
    if (trend == 'All') {
      _searchCtrl.clear();
      _search('');
      setState(() => _activeCat = 'All');
    } else {
      _searchCtrl.text = trend;
      _search(trend);
      setState(() => _activeCat = 'All');
    }
  }

  void _setExchangeType(String v) {
    setState(() => _exchangeType = v);
    _refetch();
  }

  void _refetch() {
    final exType = (_exchangeType == 'all') ? null : _exchangeType;
    context.read<PostService>().fetchPosts(
      searchQuery: _query.isEmpty ? null : _query,
      exchangeType: exType,
    );
  }

  List<PostModel> _filteredPosts(List<PostModel> raw) {
    List<PostModel> posts = List.of(raw);

    if (_skillType != 'all') {
      const kws = {
        'technical': {
          'coding',
          'programming',
          'data',
          'ai',
          'ml',
          'web',
          'app',
          'flutter',
          'react',
          'java',
          'python',
          'math',
        },
        'creative': {
          'design',
          'art',
          'photo',
          'video',
          'music',
          'drawing',
          'illustration',
          'canva',
          'figma',
          'editing',
        },
        'soft': {
          'communication',
          'leadership',
          'teamwork',
          'speaking',
          'presentation',
          'negotiation',
        },
        'language': {
          'language',
          'english',
          'hindi',
          'french',
          'spanish',
          'german',
          'japanese',
          'translation',
        },
        'academic': {
          'writing',
          'research',
          'essay',
          'academic',
          'study',
          'tutor',
          'homework',
          'assignment',
        },
        'fitness': {
          'fitness',
          'yoga',
          'gym',
          'workout',
          'nutrition',
          'health',
          'sport',
          'dance',
        },
        'business': {
          'business',
          'marketing',
          'finance',
          'accounting',
          'sales',
          'startup',
          'excel',
        },
      };
      final k = kws[_skillType] ?? {};
      if (k.isNotEmpty) {
        posts = posts.where((p) {
          final hay = '${p.skillOffered} ${p.title} ${p.tags.join(' ')}'
              .toLowerCase();
          return k.any((kw) => hay.contains(kw));
        }).toList();
      }
    }

    if (_availability != 'all') {
      final now = DateTime.now();
      posts = posts.where((p) {
        final hrs = now.difference(p.createdAt).inHours;
        switch (_availability) {
          case 'now':
            return hrs < 24;
          case 'this_week':
            return hrs < 168;
          case 'weekends':
            return now.weekday >= 6;
          case 'evenings':
            return now.hour >= 17;
          default:
            return true;
        }
      }).toList();
    }

    if (_sessionFormat != 'all') {
      posts = posts.where((p) {
        final hay = '${p.title} ${p.description} ${p.tags.join(' ')}'
            .toLowerCase();
        switch (_sessionFormat) {
          case 'online':
            return hay.contains('online') ||
                hay.contains('virtual') ||
                hay.contains('remote');
          case 'in_person':
            return hay.contains('in person') ||
                hay.contains('offline') ||
                hay.contains('campus');
          case 'hybrid':
            return hay.contains('hybrid') || hay.contains('both');
          case 'async':
            return hay.contains('async') ||
                hay.contains('self-paced') ||
                hay.contains('flexible');
          default:
            return true;
        }
      }).toList();
    }

    switch (_sortBy) {
      case 'oldest':
        posts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case 'rating_high':
        posts.sort(
          (a, b) => (b.profile?.averageRating ?? 0).compareTo(
            a.profile?.averageRating ?? 0,
          ),
        );
      case 'rating_low':
        posts.sort(
          (a, b) => (a.profile?.averageRating ?? 0).compareTo(
            b.profile?.averageRating ?? 0,
          ),
        );
    }
    return posts;
  }

  // ── filter bottom sheet ───────────────────────────────────────────────────
  void _showFilterSheet() {
    String localSort = _sortBy;
    String localExchange = _exchangeType;
    String localSkillType = _skillType;
    String localAvailability = _availability;
    String localSessionFormat = _sessionFormat;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) {
          final sheetBg = _d ? const Color(0xFF111126) : Colors.white;
          final rowBg = _d ? const Color(0xFF191932) : const Color(0xFFF5F5FA);
          final divClr = _d ? const Color(0xFF252545) : const Color(0xFFEAEAF0);
          const activeClr = _purple;

          Widget radioRow({
            required String label,
            required IconData icon,
            required bool active,
            required VoidCallback onTap,
            bool isFirst = false,
            bool isLast = false,
          }) => GestureDetector(
            onTap: () {
              onTap();
              setSt(() {});
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              decoration: BoxDecoration(
                color: active ? activeClr.withOpacity(0.12) : rowBg,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isFirst ? 14 : 0),
                  bottom: Radius.circular(isLast ? 14 : 0),
                ),
                border: Border.all(
                  color: active
                      ? activeClr.withOpacity(0.6)
                      : Colors.transparent,
                  width: active ? 1.5 : 0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  Icon(icon, size: 17, color: active ? activeClr : _ts),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? activeClr : _tp,
                      ),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? activeClr : divClr,
                        width: active ? 0 : 2,
                      ),
                      color: active ? activeClr : Colors.transparent,
                    ),
                    child: active
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );

          Widget segChip(String label, bool active, VoidCallback onTap) =>
              GestureDetector(
                onTap: () {
                  onTap();
                  setSt(() {});
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: active ? activeClr : rowBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: active ? activeClr : divClr,
                      width: active ? 0 : 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? Colors.white : _ts,
                    ),
                  ),
                ),
              );

          Widget sectionLabel(String text) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                color: _ts,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          );

          Widget divider() => Container(height: 1, color: divClr);

          return Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _d ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'Filters',
                        style: GoogleFonts.dmSans(
                          color: _tp,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _sortBy = 'newest';
                            _exchangeType = 'all';
                            _skillType = 'all';
                            _availability = 'all';
                            _sessionFormat = 'all';
                          });
                          _refetch();
                          setSt(() {});
                        },
                        child: Text(
                          'Reset all',
                          style: GoogleFonts.dmSans(
                            color: activeClr,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  sectionLabel('Sort By'),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      children: [
                        radioRow(
                          label: 'Newest First',
                          icon: Icons.arrow_downward_rounded,
                          active: localSort == 'newest',
                          onTap: () => localSort = 'newest',
                          isFirst: true,
                        ),
                        divider(),
                        radioRow(
                          label: 'Oldest First',
                          icon: Icons.arrow_upward_rounded,
                          active: localSort == 'oldest',
                          onTap: () => localSort = 'oldest',
                        ),
                        divider(),
                        radioRow(
                          label: 'Rating: High → Low',
                          icon: Icons.star_rounded,
                          active: localSort == 'rating_high',
                          onTap: () => localSort = 'rating_high',
                        ),
                        divider(),
                        radioRow(
                          label: 'Rating: Low → High',
                          icon: Icons.star_outline_rounded,
                          active: localSort == 'rating_low',
                          onTap: () => localSort = 'rating_low',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  sectionLabel('Skill Type'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in [
                        ('all', 'All Types'),
                        ('technical', 'Technical'),
                        ('creative', 'Creative'),
                        ('soft', 'Soft Skills'),
                        ('language', 'Language'),
                        ('academic', 'Academic'),
                        ('fitness', 'Fitness'),
                        ('business', 'Business'),
                      ])
                        segChip(
                          r.$2,
                          localSkillType == r.$1,
                          () => localSkillType = r.$1,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  sectionLabel('Availability'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in [
                        ('all', 'Any Time'),
                        ('now', 'Available Now'),
                        ('this_week', 'This Week'),
                        ('weekends', 'Weekends'),
                        ('evenings', 'Evenings'),
                      ])
                        segChip(
                          r.$2,
                          localAvailability == r.$1,
                          () => localAvailability = r.$1,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  sectionLabel('Session Format'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in [
                        ('all', 'Any Format'),
                        ('online', 'Online'),
                        ('in_person', 'In Person'),
                        ('hybrid', 'Hybrid'),
                        ('async', 'Async / Self-paced'),
                      ])
                        segChip(
                          r.$2,
                          localSessionFormat == r.$1,
                          () => localSessionFormat = r.$1,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _sortBy = localSort;
                        _exchangeType = localExchange;
                        _skillType = localSkillType;
                        _availability = localAvailability;
                        _sessionFormat = localSessionFormat;
                      });
                      _refetch();
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _purple,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Apply Filters',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── delete dialog ─────────────────────────────────────────────────────────
  Future<void> _delete(String postId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete post?',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
        content: Text('This cannot be undone.', style: GoogleFonts.dmSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: _ts)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.dmSans(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<PostService>().deletePost(postId);
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final myId = context.watch<AuthService>().currentUser?.id;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
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
            automaticallyImplyLeading: false,
            toolbarHeight: 56,
            titleSpacing: 20,
            centerTitle: false,
            title: Text(
              'Explore',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OpenRequestsScreen()),
                ),
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Search bar ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: _sv,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 13),
                          Icon(Icons.search_rounded, color: _ts, size: 19),
                          const SizedBox(width: 9),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (q) {
                                if (_activeCat != 'All' && q != _activeCat) {
                                  setState(() => _activeCat = 'All');
                                }
                                _search(q);
                              },
                              style: GoogleFonts.dmSans(
                                color: _tp,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search skills, people, or topics...',
                                hintStyle: GoogleFonts.dmSans(
                                  color: _ts,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                filled: false,
                              ),
                            ),
                          ),
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                _search('');
                                setState(() {
                                  _activeCat = 'All';
                                  _activeTrend = 'All';
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(11),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: _ts,
                                  size: 17,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 13),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _hasActiveFilters ? _purple : _sv,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: _hasActiveFilters ? Colors.white : _ts,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 40.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // ── Trending Skills row ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Trending Skills',
                    style: GoogleFonts.dmSans(
                      color: _tp,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _trends.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 7),
                    itemBuilder: (_, i) {
                      final t = _trends[i];
                      final active = _activeTrend == t.label;
                      return _TrendChip(
                        label: t.label,
                        icon: t.icon,
                        active: active,
                        dark: _d,
                        onTap: () => _setTrend(t.label),
                      );
                    },
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 50.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Exchange type row ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: _exchangeTypes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final et = _exchangeTypes[i];
                  final active = _exchangeType == et.value;
                  return _ExchangeChip(
                    label: et.label,
                    icon: et.icon,
                    active: active,
                    dark: _d,
                    chipBg: _chipBg,
                    chipBd: _chipBd,
                    onTap: () => _setExchangeType(et.value),
                  );
                },
              ),
            ).animate().fadeIn(delay: 80.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── "N skills found" + List / Grid toggle ────────────────────────
          Consumer<PostService>(
            builder: (_, ps, __) {
              final filtered = _filteredPosts(ps.posts);
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} skill${filtered.length == 1 ? '' : 's'} found',
                        style: GoogleFonts.dmSans(
                          color: _ts,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      _ViewToggleBtn(
                        icon: Icons.view_list_rounded,
                        label: 'List',
                        active: !_isGridView,
                        dark: _d,
                        onTap: () => setState(() => _isGridView = false),
                      ),
                      const SizedBox(width: 8),
                      _ViewToggleBtn(
                        icon: Icons.grid_view_rounded,
                        label: 'Grid',
                        active: _isGridView,
                        dark: _d,
                        onTap: () => setState(() => _isGridView = true),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),
              );
            },
          ),

          // ── Posts ────────────────────────────────────────────────────────
          Consumer<PostService>(
            builder: (_, ps, __) {
              if (ps.isLoading && ps.posts.isEmpty) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const ShimmerCard(),
                      childCount: 4,
                    ),
                  ),
                );
              }

              final filtered = _filteredPosts(ps.posts);

              if (filtered.isEmpty) {
                return SliverFillRemaining(child: _empty());
              }

              // ── GRID VIEW ──────────────────────────────────────────────
              if (_isGridView) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                    delegate: SliverChildBuilderDelegate((_, i) {
                      final p = filtered[i];
                      return _ExploreCard(
                            key: ValueKey(p.id),
                            post: p,
                            gradient: _gradFor(p),
                            isOwn: p.userId == myId,
                            d: _d,
                            tp: _tp,
                            ts: _ts,
                            tl: _tl,
                            cardSurface: _d
                                ? const Color(0xFF111126)
                                : Colors.white,
                            cardBorder: _ce,
                            stripBg: _d
                                ? const Color(0xFF0C0C1E)
                                : const Color(0xFFF2F2FA),
                            stripDivider: _d
                                ? const Color(0xFF1C1C34)
                                : const Color(0xFFDDDDEE),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PostDetailScreen(post: p),
                                ),
                              );
                            },
                            onAuthorTap: () {
                              if (p.profile?.id != null)
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserProfileScreen(
                                      userId: p.profile!.id,
                                    ),
                                  ),
                                );
                            },
                            onBookmark: () => ps.toggleBookmark(p.id),
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreatePostScreen(post: p),
                              ),
                            ),
                            onDelete: () => _delete(p.id),
                          )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: i * 30))
                          .slideY(begin: 0.05);
                    }, childCount: filtered.length),
                  ),
                );
              }

              // ── LIST VIEW ──────────────────────────────────────────────
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final p = filtered[i];
                    return SwapPostCard(
                          key: ValueKey(p.id),
                          post: p,
                          isOwn: p.userId == myId,
                          onSwap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PostDetailScreen(post: p),
                              ),
                            );
                          },
                          onBookmark: () => ps.toggleBookmark(p.id),
                          onTapAuthor: () {
                            if (p.profile?.id != null) {
                              HapticFeedback.selectionClick();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UserProfileScreen(userId: p.profile!.id),
                                ),
                              );
                            }
                          },
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreatePostScreen(post: p),
                            ),
                          ),
                          onDelete: () => _delete(p.id),
                        )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: i * 40))
                        .slideY(
                          begin: 0.06,
                          delay: Duration(milliseconds: i * 40),
                          curve: Curves.easeOutCubic,
                        );
                  }, childCount: filtered.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters =>
      _skillType != 'all' ||
      _sortBy != 'newest' ||
      _availability != 'all' ||
      _sessionFormat != 'all';

  Widget _empty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.07),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.search_off_rounded,
            size: 42,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'No results found',
          style: GoogleFonts.dmSans(
            color: _tp,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Try a different search or filter',
          style: GoogleFonts.dmSans(color: _ts, fontSize: 13),
        ),
      ],
    ).animate().fadeIn(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Trending skill chip  (horizontal scroll row below search bar)
//  — exact style from screenshot: borderless inactive, muted icon, flat pill
// ─────────────────────────────────────────────────────────────────────────────
class _TrendChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active, dark;
  final VoidCallback onTap;

  const _TrendChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.dark,
    required this.onTap,
  });

  static const _purple = Color(0xFF7C5CFC);

  @override
  Widget build(BuildContext context) {
    final inactiveBg = dark ? const Color(0xFF12112A) : const Color(0xFFEEEEF8);
    final iconColor = active
        ? Colors.white
        : (dark ? const Color(0xFF6060A0) : const Color(0xFF8080B0));
    final textColor = active
        ? Colors.white
        : (dark ? const Color(0xFFB0B0D8) : const Color(0xFF444466));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _purple : inactiveBg,
          borderRadius: BorderRadius.circular(10),
          border: active ? Border.all(color: _purple, width: 1) : null,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _purple.withOpacity(0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: textColor,
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Category chip  (top row: All / Design / Coding …)
//  — matches trending-skills pill: borderless inactive, muted icons, flat
// ─────────────────────────────────────────────────────────────────────────────
class _CatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active, dark;
  final Color chipBg, chipBd;
  final VoidCallback onTap;

  const _CatChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.dark,
    required this.chipBg,
    required this.chipBd,
    required this.onTap,
  });

  static const _purple = Color(0xFF7C5CFC);

  @override
  Widget build(BuildContext context) {
    // Inactive: deep navy bg, NO border, muted grey-blue icon + text
    // Active: solid purple fill, white icon + text, subtle glow
    final inactiveBg = dark ? const Color(0xFF12112A) : const Color(0xFFEEEEF8);
    final iconColor = active
        ? Colors.white
        : (dark ? const Color(0xFF6060A0) : const Color(0xFF8080B0));
    final textColor = active
        ? Colors.white
        : (dark ? const Color(0xFFB0B0D8) : const Color(0xFF444466));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _purple : inactiveBg,
          borderRadius: BorderRadius.circular(10),
          // No border on inactive — flat look matching the screenshot
          border: active ? Border.all(color: _purple, width: 1) : null,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _purple.withOpacity(0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: textColor,
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Exchange-type chip  (All Types / Barter / Open Req / Custom)
//  — unified trending-skills pill style, consistent purple accent
// ─────────────────────────────────────────────────────────────────────────────
class _ExchangeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active, dark;
  final Color chipBg, chipBd;
  final VoidCallback onTap;

  const _ExchangeChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.dark,
    required this.chipBg,
    required this.chipBd,
    required this.onTap,
  });

  static const _purple = Color(0xFF7C5CFC);

  @override
  Widget build(BuildContext context) {
    final inactiveBg = dark ? const Color(0xFF12112A) : const Color(0xFFEEEEF8);
    final iconColor = active
        ? Colors.white
        : (dark ? const Color(0xFF6060A0) : const Color(0xFF8080B0));
    final textColor = active
        ? Colors.white
        : (dark ? const Color(0xFFB0B0D8) : const Color(0xFF444466));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _purple : inactiveBg,
          borderRadius: BorderRadius.circular(10),
          border: active ? Border.all(color: _purple, width: 1) : null,
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _purple.withOpacity(0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: textColor,
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  List / Grid toggle button
// ─────────────────────────────────────────────────────────────────────────────
class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active, dark;
  final VoidCallback onTap;

  const _ViewToggleBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.dark,
    required this.onTap,
  });

  static const _purple = Color(0xFF7C5CFC);

  @override
  Widget build(BuildContext context) {
    final inactiveBg = dark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0F8);
    final inactiveBd = dark ? const Color(0xFF2A2A42) : const Color(0xFFDDDDEE);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _purple : inactiveBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? _purple : inactiveBd),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _purple.withOpacity(0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active
                  ? Colors.white
                  : (dark ? const Color(0xFF9090B0) : const Color(0xFF555575)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active
                    ? Colors.white
                    : (dark
                          ? const Color(0xFF9090B0)
                          : const Color(0xFF555575)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Header icon button
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final bool dark;
  final Color tp;
  final VoidCallback onTap;

  const _HeaderIconBtn({
    required this.icon,
    required this.dark,
    required this.tp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurfaceVariant : const Color(0xFFF2F2F4),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 19, color: tp),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Grid card  (_ExploreCard)
// ─────────────────────────────────────────────────────────────────────────────
class _ExploreCard extends StatelessWidget {
  final PostModel post;
  final List<Color> gradient;
  final bool isOwn, d;
  final Color tp, ts, tl, cardSurface, cardBorder, stripBg, stripDivider;
  final VoidCallback onTap, onAuthorTap, onBookmark, onEdit, onDelete;

  const _ExploreCard({
    super.key,
    required this.post,
    required this.gradient,
    required this.isOwn,
    required this.d,
    required this.tp,
    required this.ts,
    required this.tl,
    required this.cardSurface,
    required this.cardBorder,
    required this.stripBg,
    required this.stripDivider,
    required this.onTap,
    required this.onAuthorTap,
    required this.onBookmark,
    required this.onEdit,
    required this.onDelete,
  });

  String get _catLabel {
    final s = post.skillOffered.toLowerCase();
    if (s.contains('design') || s.contains('figma') || s.contains('canva'))
      return 'Design';
    if (s.contains('code') ||
        s.contains('flutter') ||
        s.contains('python') ||
        s.contains('java') ||
        s.contains('react') ||
        s.contains('dev'))
      return 'Dev';
    if (s.contains('music') || s.contains('guitar') || s.contains('piano'))
      return 'Music';
    if (s.contains('math')) return 'Math';
    if (post.isOpenRequest) return 'Help';
    return 'Skill';
  }

  @override
  Widget build(BuildContext context) {
    final isBarter = post.exchangeType == 'barter';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(d ? 0.20 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient header
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -14,
                      top: -14,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.82),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _catLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: gradient[1],
                          ),
                        ),
                      ),
                    ),
                    if (isOwn)
                      Positioned(
                        right: 7,
                        top: 7,
                        child: Row(
                          children: [
                            _MiniBtn(
                              icon: Icons.edit_outlined,
                              color: AppColors.primary,
                              onTap: onEdit,
                            ),
                            const SizedBox(width: 5),
                            _MiniBtn(
                              icon: Icons.delete_outline_rounded,
                              color: AppColors.error,
                              onTap: onDelete,
                            ),
                          ],
                        ),
                      )
                    else
                      Positioned(
                        right: 7,
                        top: 7,
                        child: GestureDetector(
                          onTap: onBookmark,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              post.isBookmarked
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_outline_rounded,
                              size: 14,
                              color: post.isBookmarked
                                  ? AppColors.primary
                                  : gradient[1],
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 8,
                      bottom: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.82),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isBarter ? 'Barter' : 'Custom',
                          style: GoogleFonts.dmSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: isBarter
                                ? AppColors.primary
                                : AppColors.accentTeal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Author
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 0),
              child: GestureDetector(
                onTap: onAuthorTap,
                child: Row(
                  children: [
                    AvatarWidget(
                      avatarUrl: post.profile?.avatarUrl,
                      username: post.profile?.username ?? '',
                      radius: 10,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        post.profile?.fullName?.split(' ').first ??
                            post.profile?.username ??
                            'User',
                        style: GoogleFonts.dmSans(
                          color: ts,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if ((post.profile?.averageRating ?? 0) > 0) ...[
                      Icon(
                        Icons.star_rounded,
                        size: 11,
                        color: Colors.amber.shade500,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        post.profile!.averageRating.toStringAsFixed(1),
                        style: GoogleFonts.dmSans(
                          color: ts,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 5, 9, 0),
              child: Text(
                post.title,
                style: GoogleFonts.dmSans(
                  color: tp,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            // Offering / Wants strip
            Container(
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: stripBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OFFERING',
                          style: GoogleFonts.dmSans(
                            fontSize: 7.5,
                            color: tl,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 9,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                post.skillOffered,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 26,
                    color: stripDivider,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isBarter ? 'WANTS' : 'OFFERS',
                          style: GoogleFonts.dmSans(
                            fontSize: 7.5,
                            color: tl,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                isBarter
                                    ? (post.skillWanted ?? 'Open')
                                    : (post.customOffer ?? 'Custom'),
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: isBarter
                                      ? AppColors.secondary
                                      : AppColors.accentTeal,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              isBarter
                                  ? Icons.sync_alt_rounded
                                  : Icons.card_giftcard_rounded,
                              size: 9,
                              color: isBarter
                                  ? AppColors.secondary
                                  : AppColors.accentTeal,
                            ),
                          ],
                        ),
                      ],
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
//  _MiniBtn
// ─────────────────────────────────────────────────────────────────────────────
class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MiniBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
          ],
        ),
        child: Icon(icon, size: 13, color: color),
      ),
    );
  }
}
