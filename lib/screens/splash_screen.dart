import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/swaply_logo.dart';
import 'auth/login_screen.dart';
import 'home/main_nav_screen.dart';

// ── Palette shared with LoginScreen ──────────────────────────────────────────
const _bg        = Color(0xFF0D0E17);
const _purple    = Color(0xFF5B5BD6);
const _textMain  = Color(0xFFFFFFFF);
const _textSub   = Color(0xFF8E90A8);
const _textLight = Color(0xFF545670);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _init();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final auth = context.read<AuthService>();
    if (auth.isLoggedIn) {
      await auth.fetchProfile();
      if (!mounted) return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a1, __) =>
            auth.isLoggedIn ? const MainNavScreen() : const LoginScreen(),
        transitionsBuilder: (_, a1, __, child) =>
            FadeTransition(opacity: a1, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle radial glows
          Positioned(
            top: -120, right: -80,
            child: Container(
              width: 360, height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _purple.withOpacity(0.10),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -100, left: -60,
            child: Container(
              width: 320, height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF3D4FD6).withOpacity(0.08),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo ───────────────────────────────────────────────────
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, child) => Transform.scale(
                    scale: 1.0 + _pulseCtrl.value * 0.025,
                    child: child,
                  ),
                  child: SwaplyLogoWidget(size: 96),
                )
                .animate()
                .scale(
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                  begin: const Offset(0.6, 0.6),
                )
                .fadeIn(),

                const SizedBox(height: 22),

                Text(
                  'Swaply',
                  style: GoogleFonts.dmSans(
                    color: _textMain,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                )
                .animate()
                .fadeIn(delay: 280.ms)
                .slideY(begin: 0.25, curve: Curves.easeOutCubic),

                const SizedBox(height: 6),

                Text(
                  'Campus Skill Barter',
                  style: GoogleFonts.dmSans(
                    color: _textSub,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ).animate().fadeIn(delay: 380.ms),

                const SizedBox(height: 64),

                // Loading dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _purple.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                      delay: Duration(milliseconds: 500 + i * 150),
                      duration: 600.ms,
                      begin: 0.5,
                      end: 1.2,
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .fadeIn();
                  }),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),

          // Version tag
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Center(
              child: Text(
                'v2.0',
                style: GoogleFonts.dmSans(color: _textLight, fontSize: 11),
              ).animate().fadeIn(delay: 800.ms),
            ),
          ),
        ],
      ),
    );
  }
}


// (Logo painter lives in lib/widgets/swaply_logo.dart — use SwaplyLogoWidget)