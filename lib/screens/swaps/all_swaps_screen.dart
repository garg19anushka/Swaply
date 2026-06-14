// lib/screens/swaps/all_swaps_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/swap_model.dart';
import '../../services/auth_service.dart';
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
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SwapService>().fetchAllSwaps();
    });

    // Tick every minute to refresh expiry countdowns on pending cards
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _countdownTimer?.cancel();
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Consumer<SwapService>(
            builder: (_, ss, __) {
              // Count items that need action for the badge
              final needsAction = ss.allSwaps
                  .where(
                    (s) =>
                        s.status == 'pending' || s.status == 'awaiting_review',
                  )
                  .length;

              return TabBar(
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
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Active'),
                        if (needsAction > 0) ...[
                          const SizedBox(width: 6),
                          _ActionBadge(count: needsAction),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Completed'),
                ],
              );
            },
          ),
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

          // Active tab: pending + active + awaiting_review, sorted by urgency
          final active =
              ss.allSwaps
                  .where(
                    (s) =>
                        s.status != 'completed' &&
                        s.status != 'cancelled' &&
                        s.status != 'expired',
                  )
                  .toList()
                ..sort((a, b) => a.sortPriority.compareTo(b.sortPriority));

          // Completed tab: completed + cancelled + expired
          final completed = ss.allSwaps
              .where(
                (s) =>
                    s.status == 'completed' ||
                    s.status == 'cancelled' ||
                    s.status == 'expired',
              )
              .toList();

          return TabBarView(
            controller: _tab,
            children: [
              _SwapList(
                swaps: active,
                dark: _d,
                emptyMsg: 'No active swaps yet.',
                viewerId: context.read<AuthService>().currentUser?.id,
              ),
              _SwapList(
                swaps: completed,
                dark: _d,
                emptyMsg: 'No completed swaps yet.',
                viewerId: context.read<AuthService>().currentUser?.id,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Red dot badge for "needs action" count
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBadge extends StatelessWidget {
  final int count;
  const _ActionBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
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
  final String? viewerId;

  const _SwapList({
    required this.swaps,
    required this.dark,
    required this.emptyMsg,
    this.viewerId,
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
      itemBuilder: (_, i) =>
          _SwapTile(swap: swaps[i], dark: dark, viewerId: viewerId),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Single swap tile
// ─────────────────────────────────────────────────────────────────────────────
class _SwapTile extends StatelessWidget {
  final SwapModel swap;
  final bool dark;
  final String? viewerId;

  const _SwapTile({required this.swap, required this.dark, this.viewerId});

  Color get _cardBg => dark ? const Color(0xFF111126) : Colors.white;
  Color get _border {
    // Urgent swaps get a coloured border so they stand out
    switch (swap.swapStatus) {
      case SwapStatus.pending:
        return AppColors.warning.withOpacity(0.6);
      case SwapStatus.awaiting_review:
        return AppColors.primaryLight.withOpacity(0.6);
      default:
        return dark ? const Color(0xFF252540) : AppColors.border;
    }
  }

  Color get _tp => dark ? const Color(0xFFF0F0FF) : AppColors.textPrimary;
  Color get _ts => dark ? const Color(0xFF9090B0) : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final pct = (swap.progress * 100).round();
    final status = swap.swapStatus;
    final isCompleted = status == SwapStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: swap.needsAction ? 1.5 : 1),
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
            // ── Row 1: Title + status badge ───────────────────────────────
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
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 4),

            // ── Row 2: Partner + expiry countdown (if pending) ────────────
            Row(
              children: [
                if (swap.viewerPartnerName(viewerId) != null ||
                    swap.viewerPartnerUsername(viewerId) != null)
                  Expanded(
                    child: Text(
                      'With ${swap.viewerPartnerName(viewerId) ?? '@${swap.viewerPartnerUsername(viewerId)}'}',
                      style: GoogleFonts.dmSans(color: _ts, fontSize: 12.5),
                    ),
                  ),
                if (status == SwapStatus.pending &&
                    swap.expiryCountdown != null)
                  _ExpiryChip(countdown: swap.expiryCountdown!, dark: dark),
              ],
            ),

            // ── Skill pills (if available) ────────────────────────────────
            if (swap.offeredSkill != null || swap.wantedSkill != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (swap.offeredSkill != null)
                    _SkillPill(
                      label: swap.offeredSkill!,
                      color: AppColors.accentTeal,
                      dark: dark,
                    ),
                  if (swap.offeredSkill != null && swap.wantedSkill != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        size: 14,
                        color: _ts,
                      ),
                    ),
                  if (swap.wantedSkill != null)
                    _SkillPill(
                      label: swap.wantedSkill!,
                      color: AppColors.primary,
                      dark: dark,
                    ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // ── Progress row ──────────────────────────────────────────────
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

            // ── Progress bar ──────────────────────────────────────────────
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

            // ── Session dots ──────────────────────────────────────────────
            Row(
              children: List.generate(swap.totalSessions, (i) {
                final done = i < swap.doneSessions;
                final activeDot = i == swap.doneSessions;
                Color c;
                if (done)
                  c = AppColors.accentTeal;
                else if (activeDot)
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

            // ── Footer: next session + action button ──────────────────────
            Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    swap.nextSessionLabel,
                    style: GoogleFonts.dmSans(color: _ts, fontSize: 12),
                  ),
                ),
                // Contextual CTA based on status
                if (status == SwapStatus.awaiting_review)
                  _ActionButton(
                    label: '⭐  Rate Swap',
                    color: AppColors.primary,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/rate_swap',
                      arguments: swap.id,
                    ),
                  ),
                if (status == SwapStatus.pending) ...[
                  // Only the responder sees Confirm/Decline.
                  // If requesterId/responderId are null (old row), fall
                  // back to "Awaiting reply" so no one sees stray buttons.
                  if (viewerId != null &&
                      swap.responderId != null &&
                      viewerId == swap.responderId) ...[
                    _ActionButton(
                      label: '✗  Decline',
                      color: AppColors.error,
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: dark
                                ? const Color(0xFF1A1930)
                                : Colors.white,
                            title: Text(
                              'Decline swap?',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            content: Text(
                              'The requester will be notified.',
                              style: GoogleFonts.dmSans(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.dmSans(),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'Decline',
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await context.read<SwapService>().declineSwap(
                            swap.id,
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: '✓  Confirm',
                      color: AppColors.accentTeal,
                      onTap: () async {
                        await context.read<SwapService>().confirmSwap(swap.id);
                      },
                    ),
                  ] else
                    // Requester OR unidentified role → show awaiting chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '⏳ Awaiting reply',
                        style: GoogleFonts.dmSans(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
//  Status badge pill
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final SwapStatus status;
  const _StatusBadge({required this.status});

  Color get _bg {
    switch (status) {
      case SwapStatus.pending:
        return AppColors.warning.withOpacity(0.14);
      case SwapStatus.active:
        return AppColors.primary.withOpacity(0.12);
      case SwapStatus.awaiting_review:
        return AppColors.primaryLight.withOpacity(0.14);
      case SwapStatus.completed:
        return AppColors.accentTeal.withOpacity(0.12);
      case SwapStatus.cancelled:
        return AppColors.error.withOpacity(0.10);
      case SwapStatus.expired:
        return Colors.grey.withOpacity(0.12);
    }
  }

  Color get _fg {
    switch (status) {
      case SwapStatus.pending:
        return const Color(0xFF997A00);
      case SwapStatus.active:
        return AppColors.primary;
      case SwapStatus.awaiting_review:
        return AppColors.primaryLight;
      case SwapStatus.completed:
        return AppColors.accentTeal;
      case SwapStatus.cancelled:
        return AppColors.error;
      case SwapStatus.expired:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${status.emoji}  ${status.label}',
        style: GoogleFonts.dmSans(
          color: _fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Expiry countdown chip (amber, shown on pending swaps)
// ─────────────────────────────────────────────────────────────────────────────
class _ExpiryChip extends StatelessWidget {
  final String countdown;
  final bool dark;
  const _ExpiryChip({required this.countdown, required this.dark});

  @override
  Widget build(BuildContext context) {
    final isExpiringSoon = countdown.contains('m') && !countdown.contains('h');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isExpiringSoon ? AppColors.error : AppColors.warning)
            .withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 11,
            color: isExpiringSoon ? AppColors.error : AppColors.warning,
          ),
          const SizedBox(width: 3),
          Text(
            countdown,
            style: GoogleFonts.dmSans(
              color: isExpiringSoon ? AppColors.error : AppColors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Skill pill (offered / wanted)
// ─────────────────────────────────────────────────────────────────────────────
class _SkillPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool dark;
  const _SkillPill({
    required this.label,
    required this.color,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Small contextual action button (Confirm / Rate)
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
