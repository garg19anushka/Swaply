import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class HomeHeroCard extends StatefulWidget {
  final VoidCallback onBrowse;
  final VoidCallback onPostSkill;
  final int matchCount;
  final int activeSwaps;
  final String? campus;

  const HomeHeroCard({
    super.key,
    required this.onBrowse,
    required this.onPostSkill,
    this.matchCount = 3,
    this.activeSwaps = 24,
    this.campus,
  });

  @override
  State<HomeHeroCard> createState() => _HomeHeroCardState();
}

class _HomeHeroCardState extends State<HomeHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.35,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthService>();

    final firstName =
        auth.currentProfile?.fullName?.split(' ').first ??
        auth.currentProfile?.username ??
        'there';

    final campus = widget.campus ?? auth.currentProfile?.campus ?? 'MRU';

    final hour = DateTime.now().hour;
    final String greeting;
    final String greetEmoji;
    if (hour < 12) {
      greeting = 'Good morning';
      greetEmoji = '👋';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
      greetEmoji = '☀️';
    } else {
      greeting = 'Good evening';
      greetEmoji = '🌙';
    }

    final cardBg = isDark ? const Color(0xFF0D0B24) : const Color(0xFFEDE9FF);
    final cardBorder = isDark
        ? const Color(0xFF7C5CFC).withOpacity(0.22)
        : const Color(0xFF7C5CFC).withOpacity(0.14);
    final nameColor = isDark ? Colors.white : AppColors.primary;
    final greetColor = isDark
        ? Colors.white.withOpacity(0.48)
        : AppColors.textSecondary;
    final subtitleColor = isDark
        ? Colors.white.withOpacity(0.40)
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child:
          Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF7C5CFC,
                      ).withOpacity(isDark ? 0.18 : 0.09),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Radial glow top-right
                      Positioned(
                        top: -55,
                        right: -55,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(
                                  0xFF7C5CFC,
                                ).withOpacity(isDark ? 0.30 : 0.12),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Cyan glow bottom-left
                      Positioned(
                        bottom: -40,
                        left: -20,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(
                                  0xFF00E5FF,
                                ).withOpacity(isDark ? 0.10 : 0.05),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Orb 1 🎨
                      Positioned(
                        top: 18,
                        right: 70,
                        child: _FloatingOrb(
                          emoji: '🎨',
                          size: 40,
                          color: const Color(0xFFFF4D7D),
                          phase: 0,
                        ).animate().fadeIn(delay: 300.ms),
                      ),
                      // Orb 2 ⚡
                      Positioned(
                        bottom: 18,
                        right: 18,
                        child: _FloatingOrb(
                          emoji: '⚡',
                          size: 36,
                          color: const Color(0xFF00E5FF),
                          phase: math.pi,
                        ).animate().fadeIn(delay: 450.ms),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 90, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CampusBadge(
                                  campus: campus,
                                  pulseAnim: _pulseAnim,
                                  isDark: isDark,
                                )
                                .animate()
                                .fadeIn(duration: 320.ms)
                                .slideX(begin: -0.08),
                            const SizedBox(height: 14),
                            Text(
                              '$greeting $greetEmoji',
                              style: GoogleFonts.dmSans(
                                color: greetColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ).animate().fadeIn(delay: 80.ms),
                            const SizedBox(height: 2),
                            Text(
                                  firstName,
                                  style: GoogleFonts.dmSans(
                                    color: nameColor,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.2,
                                    height: 1.0,
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 120.ms)
                                .slideY(
                                  begin: 0.14,
                                  curve: Curves.easeOutCubic,
                                ),
                            const SizedBox(height: 7),
                            Text(
                              '${widget.matchCount} new matches found · '
                              '${widget.activeSwaps} active swaps at $campus',
                              style: GoogleFonts.dmSans(
                                color: subtitleColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                              ),
                            ).animate().fadeIn(delay: 160.ms),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _HeroButton(
                                      label: 'Browse Swaps',
                                      icon: Icons.search_rounded,
                                      isGradient: true,
                                      isDark: isDark,
                                      onTap: widget.onBrowse,
                                    )
                                    .animate()
                                    .fadeIn(delay: 220.ms)
                                    .slideY(begin: 0.18),
                                _HeroButton(
                                      label: 'Post Skill',
                                      icon: Icons.add_rounded,
                                      isGradient: false,
                                      isDark: isDark,
                                      onTap: widget.onPostSkill,
                                    )
                                    .animate()
                                    .fadeIn(delay: 280.ms)
                                    .slideY(begin: 0.18),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.06, curve: Curves.easeOutCubic),
    );
  }
}

class _CampusBadge extends StatelessWidget {
  final String campus;
  final Animation<double> pulseAnim;
  final bool isDark;
  const _CampusBadge({
    required this.campus,
    required this.pulseAnim,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF7C5CFC).withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7C5CFC).withOpacity(isDark ? 0.28 : 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, __) => Opacity(
              opacity: pulseAnim.value,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF7C5CFC),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$campus Campus Live',
            style: GoogleFonts.dmSans(
              color: const Color(0xFF9B7BFF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingOrb extends StatefulWidget {
  final String emoji;
  final double size;
  final Color color;
  final double phase;
  const _FloatingOrb({
    required this.emoji,
    required this.size,
    required this.color,
    this.phase = 0,
  });

  @override
  State<_FloatingOrb> createState() => _FloatingOrbState();
}

class _FloatingOrbState extends State<_FloatingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, math.sin(_anim.value * math.pi + widget.phase) * -7),
        child: child,
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(widget.size * 0.30),
          border: Border.all(color: widget.color.withOpacity(0.22)),
        ),
        child: Center(
          child: Text(
            widget.emoji,
            style: TextStyle(fontSize: widget.size * 0.46),
          ),
        ),
      ),
    );
  }
}

class _HeroButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isGradient;
  final bool isDark;
  final VoidCallback onTap;
  const _HeroButton({
    required this.label,
    required this.icon,
    required this.isGradient,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: widget.isGradient ? _grad() : _ghost(),
      ),
    );
  }

  Widget _grad() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFF4B4ACF),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF4B4ACF).withOpacity(0.40),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(widget.icon, color: Colors.white, size: 13),
        const SizedBox(width: 6),
        Text(
          widget.label,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );

  Widget _ghost() {
    final bg = widget.isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFF7C5CFC).withOpacity(0.08);
    final fg = widget.isDark
        ? Colors.white.withOpacity(0.75)
        : const Color(0xFF7C5CFC);
    final border = widget.isDark
        ? Colors.white.withOpacity(0.13)
        : const Color(0xFF7C5CFC).withOpacity(0.22);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, color: fg, size: 13),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: GoogleFonts.dmSans(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
