import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../home/main_nav_screen.dart';
import 'signup_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  LoginScreen
//  Light : pure white bg  |  Dark : deep charcoal #111318 bg
//  ✦ Logo icon always uses primaryGradient (brand, looks intentional on both)
//  ✦ Form card, fields, button all switch colour tokens with theme
//  ✦ Sign In button: gradient in dark, solid primary in light
// ═══════════════════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  // ── theme shortcuts ──────────────────────────────────────────────────────
  bool get _d => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _d ? const Color(0xFF111318) : Colors.white;
  Color get _sf => _d ? const Color(0xFF1A1D24) : Colors.white;
  Color get _fv => _d ? const Color(0xFF1E222C) : const Color(0xFFF2F2F4);
  Color get _bd => _d ? const Color(0xFF2A2D36) : const Color(0xFFE5E5E5);
  Color get _tp => _d ? const Color(0xFFF2F2F4) : const Color(0xFF0A0A0A);
  Color get _ts => _d ? const Color(0xFF8E9099) : const Color(0xFF6E6E6E);
  Color get _tl => _d ? const Color(0xFF555862) : const Color(0xFFAAAAAA);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final ok = await auth.signIn(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (ok && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 52),

              // ── Logo + brand ─────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    // Logo icon — gradient in dark (brand), solid primary surface in light
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: _d ? AppColors.primaryGradient : null,
                        color: _d ? null : AppColors.primary,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(
                              _d ? 0.30 : 0.20,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ).animate().scale(
                      duration: 550.ms,
                      curve: Curves.elasticOut,
                    ),

                    const SizedBox(height: 14),

                    Text(
                      'Swaply',
                      style: GoogleFonts.dmSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _tp,
                        letterSpacing: -0.8,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 4),

                    Text(
                      'Campus Skill Barter',
                      style: GoogleFonts.dmSans(fontSize: 13, color: _tl),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // ── Form card ────────────────────────────────────────────────
              Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _sf,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: _bd, width: 1),
                      boxShadow: _d
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : AppShadows.card,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Heading
                          Text(
                            'Welcome back',
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _tp,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sign in to your account',
                            style: GoogleFonts.dmSans(fontSize: 13, color: _ts),
                          ),
                          const SizedBox(height: 24),

                          // Email field
                          _field(
                            controller: _emailCtrl,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            type: TextInputType.emailAddress,
                            validator: (v) => v == null || !v.contains('@')
                                ? 'Enter a valid email'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Password field
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            style: GoogleFonts.dmSans(color: _tp, fontSize: 14),
                            validator: (v) => v == null || v.length < 6
                                ? 'Min 6 characters'
                                : null,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: GoogleFonts.dmSans(
                                color: _ts,
                                fontSize: 13.5,
                              ),
                              filled: true,
                              fillColor: _fv,
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                size: 20,
                                color: _ts,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                  color: _tl,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: BorderSide(color: _bd, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: BorderSide(color: _bd, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot password?',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Error banner
                          Consumer<AuthService>(
                            builder: (_, auth, __) {
                              if (auth.errorMessage == null) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  border: Border.all(
                                    color: AppColors.error.withOpacity(0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppColors.error,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        auth.errorMessage!,
                                        style: GoogleFonts.dmSans(
                                          color: AppColors.error,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Sign In button
                          Consumer<AuthService>(
                            builder: (_, auth, __) => _AuthButton(
                              label: 'Sign In',
                              icon: Icons.login_rounded,
                              isLoading: auth.isLoading,
                              onTap: auth.isLoading ? null : _login,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 150.ms)
                  .slideY(begin: 0.1, curve: Curves.easeOutCubic),

              const SizedBox(height: 28),

              // Sign up link
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.dmSans(fontSize: 14, color: _ts),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign up',
                          style: GoogleFonts.dmSans(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      style: GoogleFonts.dmSans(color: _tp, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmSans(color: _ts, fontSize: 13.5),
        filled: true,
        fillColor: _fv,
        prefixIcon: Icon(icon, size: 20, color: _ts),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: _bd, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: _bd, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared auth button — gradient (dark) / solid primary (light)
// ─────────────────────────────────────────────────────────────────────────────
class _AuthButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onTap;

  const _AuthButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    reverseDuration: const Duration(milliseconds: 200),
    lowerBound: 0.96,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always read theme directly from context so it reacts to theme changes
    final dark = Theme.of(context).brightness == Brightness.dark;
    final enabled = widget.onTap != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: enabled ? (_) => _ctrl.reverse() : null,
      onTapUp: enabled
          ? (_) {
              _ctrl.forward();
              widget.onTap!();
            }
          : null,
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            // Dark: black-grey (#1C1E26) | Light: clean white with border
            gradient: null,
            color: enabled
                ? (dark
                      ? const Color(0xFF1C1E26) // near-black charcoal
                      : Colors.white) // crisp white
                : (dark ? const Color(0xFF16181F) : const Color(0xFFF0F0F0)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? (dark
                        ? const Color(0xFF2E3140) // subtle dark border
                        : const Color(0xFFE0E0E0)) // light grey border
                  : (dark ? const Color(0xFF252830) : const Color(0xFFDDDDDD)),
              width: 1,
            ),
            boxShadow: enabled
                ? [
                    if (dark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    if (!dark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    if (!dark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: dark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.icon,
                        color: enabled
                            ? (dark ? Colors.white : const Color(0xFF1A1A2E))
                            : (dark
                                  ? const Color(0xFF454858)
                                  : const Color(0xFFBBBBBB)),
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: GoogleFonts.dmSans(
                          color: enabled
                              ? (dark ? Colors.white : const Color(0xFF1A1A2E))
                              : (dark
                                    ? const Color(0xFF454858)
                                    : const Color(0xFFBBBBBB)),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
