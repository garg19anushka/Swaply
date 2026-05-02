import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../home/main_nav_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  SignupScreen
//  Light: pure white bg, #F2F2F4 field fills
//  Dark:  #111318 bg, #1E222C field fills
//  ✦ Neutral header — no gradient band, simple back arrow + title
//  ✦ All tokens switch with theme; "Create Account" button matches Sign In
// ═══════════════════════════════════════════════════════════════════════════
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
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
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final ok = await auth.signUp(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      username: _usernameCtrl.text.trim(),
      fullName: _fullNameCtrl.text.trim(),
    );
    if (ok && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
        (r) => false,
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
              const SizedBox(height: 16),

              // Back arrow
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _tp,
                  size: 19,
                ),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),

              const SizedBox(height: 12),

              // Logo centred
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: _d ? AppColors.primaryGradient : null,
                        color: _d ? null : AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(
                              _d ? 0.30 : 0.20,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ).animate().scale(
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Create Account',
                      style: GoogleFonts.dmSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _tp,
                        letterSpacing: -0.6,
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 4),
                    Text(
                      'Join the campus skill community',
                      style: GoogleFonts.dmSans(fontSize: 13, color: _tl),
                    ).animate().fadeIn(delay: 220.ms),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Form card
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
                        children: [
                          _field(
                            _fullNameCtrl,
                            'Full Name',
                            Icons.person_outline_rounded,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 14),

                          _field(
                            _usernameCtrl,
                            'Username',
                            Icons.alternate_email_rounded,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (v.length < 3) return 'At least 3 characters';
                              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v)) {
                                return 'Only letters, numbers, underscore';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          _field(
                            _emailCtrl,
                            'College Email',
                            Icons.email_outlined,
                            type: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || !v.contains('@')) {
                                return 'Enter a valid email';
                              }
                              final e = v.trim().toLowerCase();
                              if (!e.endsWith('.edu') &&
                                  !e.endsWith('.ac.in')) {
                                return 'Please use a college email (.edu or .ac.in)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password with show/hide
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            style: GoogleFonts.dmSans(color: _tp, fontSize: 14),
                            validator: (v) => v == null || v.length < 6
                                ? 'Minimum 6 characters'
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

                          const SizedBox(height: 24),

                          // Error banner
                          Consumer<AuthService>(
                            builder: (_, auth, __) {
                              if (auth.errorMessage == null) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
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

                          // Create Account button
                          Consumer<AuthService>(
                            builder: (_, auth, __) => _AuthButton(
                              label: 'Create Account',
                              icon: Icons.person_add_rounded,
                              isLoading: auth.isLoading,
                              onTap: auth.isLoading ? null : _signup,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Sign in link
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Center(
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: _ts,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'Already have an account? ',
                                    ),
                                    TextSpan(
                                      text: 'Sign in',
                                      style: GoogleFonts.dmSans(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideY(begin: 0.1, curve: Curves.easeOutCubic),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
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
//  Auth button — gradient (dark) / solid primary (light)
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
