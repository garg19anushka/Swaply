// lib/screens/swaps/all_swaps_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/swap_model.dart';
import '../../services/swap_service.dart';
import '../../utils/app_theme.dart';

class AllSwapsScreen extends StatefulWidget {
  const AllSwapsScreen({super.key});

  @override
  State<AllSwapsScreen> createState() => _AllSwapsScreenState();
}

class _AllSwapsScreenState extends State<AllSwapsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SwapService>().fetchAllSwaps();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  bool get _d => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _d ? const Color(0xFF0A0A14) : Colors.white;
  Color get _sf => _d ? const Color(0xFF0E0E1C) : Colors.white;
  Color get _tp => _d ? AppColors.darkTextPrimary : AppColors.textPrimary;
  Color get _ts => _d ? AppColors.darkTextSecondary : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _sf,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _tp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Swaps',
          style: GoogleFonts.dmSans(
            color: _tp,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: _ts,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.dmSans(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Consumer<SwapService>(
        builder: (_, ss, __) {
          if (ss.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            );
          }

          final active = ss.allSwaps
              .where((s) => s.status == 'active')
              .toList();
          final completed = ss.allSwaps
              .where((s) => s.status == 'completed')
              .toList();

          return TabBarView(
            controller: _tab,
            children: [
              _SwapList(
                swaps: active,
                dark: _d,
                emptyMsg: 'No active swaps yet.',
              ),
              _SwapList(
                swaps: completed,
                dark: _d,
                emptyMsg: 'No completed swaps yet.',
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Swap list
// ─────────────────────────────────────────────────────────────────────────────
class _SwapList extends StatelessWidget {
  final List<SwapModel> swaps;
  final bool dark;
  final String emptyMsg;

  const _SwapList({
    required this.swaps,
    required this.dark,
    required this.emptyMsg,
  });

  @override
  Widget build(BuildContext context) {
    if (swaps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              size: 48,
              color: AppColors.primary.withOpacity(0.35),
            ),
            const SizedBox(height: 14),
            Text(
              emptyMsg,
              style: GoogleFonts.dmSans(
                color: dark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: swaps.length,
      itemBuilder: (_, i) => _SwapTile(swap: swaps[i], dark: dark),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Single swap tile
// ─────────────────────────────────────────────────────────────────────────────
class _SwapTile extends StatelessWidget {
  final SwapModel swap;
  final bool dark;

  const _SwapTile({required this.swap, required this.dark});

  Color get _cardBg => dark ? const Color(0xFF111126) : Colors.white;
  Color get _border => dark ? const Color(0xFF252540) : AppColors.border;
  Color get _tp => dark ? const Color(0xFFF0F0FF) : AppColors.textPrimary;
  Color get _ts => dark ? const Color(0xFF9090B0) : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final pct = (swap.progress * 100).round();
    final isCompleted = swap.status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: dark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    swap.swapTitle,
                    style: GoogleFonts.dmSans(
                      color: _tp,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.accentTeal.withOpacity(0.12)
                        : AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCompleted ? 'Completed ✓' : 'Active 🔄',
                    style: GoogleFonts.dmSans(
                      color: isCompleted
                          ? AppColors.accentTeal
                          : AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Partner
            if (swap.partnerName != null || swap.partnerUsername != null)
              Text(
                'With ${swap.partnerName ?? '@${swap.partnerUsername}'}',
                style: GoogleFonts.dmSans(color: _ts, fontSize: 12.5),
              ),
            const SizedBox(height: 12),

            // Progress row
            Row(
              children: [
                Expanded(
                  child: Text(
                    swap.progressLabel,
                    style: GoogleFonts.dmSans(color: _ts, fontSize: 12),
                  ),
                ),
                Text(
                  '$pct%',
                  style: GoogleFonts.dmSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),

            // Progress bar
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF2A2A3E) : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: swap.progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCompleted
                          ? [AppColors.accentTeal, const Color(0xFF4CC9F0)]
                          : [const Color(0xFF00E5FF), const Color(0xFF7C5CFC)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Session dots
            Row(
              children: List.generate(swap.totalSessions, (i) {
                final done = i < swap.doneSessions;
                final active = i == swap.doneSessions;
                Color c;
                if (done)
                  c = AppColors.accentTeal;
                else if (active)
                  c = AppColors.primary;
                else
                  c = dark ? const Color(0xFF2A2A3E) : const Color(0xFFEEEEEE);
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: i < swap.totalSessions - 1 ? 5 : 0,
                    ),
                    height: 4,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),

            // Next session
            Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Text(
                  swap.nextSessionLabel,
                  style: GoogleFonts.dmSans(color: _ts, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
