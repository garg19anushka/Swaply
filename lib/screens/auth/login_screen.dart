import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/swaply_logo.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus    = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscure  = true;
  bool _loading  = false;

  // Per-field validation errors
  String? _emailError;
  String? _passwordError;
  // Auth-level error (wrong credentials etc.)
  String? _authError;

  // ── Palette ─────────────────────────────────────────────────────────────
  static const _bg       = Color(0xFF0D0E17);
  static const _cardBg   = Color(0xFF161824);
  static const _inputBg  = Color(0xFF1C1D2A);
  static const _border   = Color(0xFF2E3048);
  static const _purple   = Color(0xFF6C63FF);
  static const _textMain = Color(0xFFFFFFFF);
  static const _textSub  = Color(0xFF8E90A8);
  static const _textHint = Color(0xFF545670);
  static const _errorRed = Color(0xFFFF5C6A);

  @override
  void initState() {
    super.initState();
    // Rebuild on focus change so border colour updates live
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Validation ───────────────────────────────────────────────────────────
  bool _validate() {
    bool ok = true;
    setState(() {
      _emailError    = null;
      _passwordError = null;
      _authError     = null;

      final email = _emailCtrl.text.trim();
      if (email.isEmpty) {
        _emailError = 'Please enter your email';
        ok = false;
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
        _emailError = 'Enter a valid email address';
        ok = false;
      }

      if (_passwordCtrl.text.isEmpty) {
        _passwordError = 'Please enter your password';
        ok = false;
      } else if (_passwordCtrl.text.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
        ok = false;
      }
    });
    return ok;
  }

  Future<void> _signIn() async {
    // Clear keyboard
    FocusScope.of(context).unfocus();

    if (!_validate()) return;

    setState(() { _loading = true; _authError = null; });
    try {
      await context.read<AuthService>().signIn(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      // Navigation handled by AuthService listener — no pop needed here
    } catch (e) {
      if (mounted) {
        setState(() {
          _authError = _friendlyError(e.toString());
          _loading   = false;
        });
      }
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('invalid') || raw.contains('credentials') || raw.contains('password'))
      return 'Invalid email or password. Please try again.';
    if (raw.contains('network') || raw.contains('socket'))
      return 'No internet connection. Please check your network.';
    if (raw.contains('too many'))
      return 'Too many attempts. Please wait a moment and try again.';
    return 'Sign in failed. Please try again.';
  }

  // ── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor:                    Color(0xFF0D0E17),
        statusBarIconBrightness:           Brightness.light,
        statusBarBrightness:               Brightness.dark,
        systemNavigationBarColor:          Color(0xFF0D0E17),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height
                    - MediaQuery.of(context).padding.top
                    - MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 52),
                    _buildLogo(),
                    const SizedBox(height: 36),
                    _buildCard(),
                    const Spacer(),
                    _buildSignupLink(),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo ─────────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Column(
      children: [
        const SwaplyLogoWidget(size: 88),
        const SizedBox(height: 16),
        Text('Swaply',
          style: GoogleFonts.dmSans(
            color: _textMain, fontSize: 28,
            fontWeight: FontWeight.w800, letterSpacing: -0.5,
          )),
        const SizedBox(height: 4),
        Text('Campus Skill Barter',
          style: GoogleFonts.dmSans(color: _textSub, fontSize: 14)),
      ],
    );
  }

  // ── Card ─────────────────────────────────────────────────────────────────
  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back',
            style: GoogleFonts.dmSans(
              color: _textMain, fontSize: 22,
              fontWeight: FontWeight.w800, letterSpacing: -0.3,
            )),
          const SizedBox(height: 4),
          Text('Sign in to your account',
            style: GoogleFonts.dmSans(color: _textSub, fontSize: 14)),
          const SizedBox(height: 22),

          // Email field
          _inputField(
            ctrl: _emailCtrl,
            focus: _emailFocus,
            hint: 'Email',
            icon: Icons.mail_outline_rounded,
            type: TextInputType.emailAddress,
            error: _emailError,
            onChanged: (_) { if (_emailError != null) setState(() => _emailError = null); },
          ),
          const SizedBox(height: 14),

          // Password field
          _inputField(
            ctrl: _passwordCtrl,
            focus: _passwordFocus,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            error: _passwordError,
            onChanged: (_) { if (_passwordError != null) setState(() => _passwordError = null); },
            trailing: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: _textHint, size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Forgot password?',
                style: GoogleFonts.dmSans(
                  color: _purple, fontSize: 13, fontWeight: FontWeight.w600,
                )),
            ),
          ),
          const SizedBox(height: 16),

          // Auth-level error banner
          if (_authError != null) ...[
            _errorBanner(_authError!),
            const SizedBox(height: 14),
          ],

          _buildSignInBtn(),
        ],
      ),
    );
  }

  // ── Input field ───────────────────────────────────────────────────────────
  Widget _inputField({
    required TextEditingController ctrl,
    required FocusNode focus,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? trailing,
    TextInputType? type,
    String? error,
    ValueChanged<String>? onChanged,
  }) {
    final focused = focus.hasFocus;
    final hasError = error != null;

    Color borderColor;
    if (hasError)       borderColor = _errorRed;
    else if (focused)   borderColor = _purple;
    else                borderColor = _border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 56,
          decoration: BoxDecoration(
            color: _inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: hasError || focused ? 1.6 : 1.2,
            ),
            boxShadow: focused ? [
              BoxShadow(
                color: _purple.withOpacity(0.15),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ] : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 16),
              Icon(icon,
                color: hasError ? _errorRed : (focused ? _purple : _textHint),
                size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  focusNode: focus,
                  obscureText: obscure,
                  keyboardType: type,
                  onChanged: onChanged,
                  style: GoogleFonts.dmSans(
                    color: _textMain, fontSize: 15, fontWeight: FontWeight.w500,
                  ),
                  cursorColor: _purple,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.dmSans(
                      color: _textHint, fontSize: 15, fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: _errorRed, size: 13),
                const SizedBox(width: 4),
                Text(error,
                  style: GoogleFonts.dmSans(
                    color: _errorRed, fontSize: 12, fontWeight: FontWeight.w500,
                  )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Error banner ──────────────────────────────────────────────────────────
  Widget _errorBanner(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _errorRed.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _errorRed.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _errorRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
              style: GoogleFonts.dmSans(
                color: _errorRed, fontSize: 13, fontWeight: FontWeight.w500,
              )),
          ),
        ],
      ),
    );
  }

  // ── Sign In button ────────────────────────────────────────────────────────
  Widget _buildSignInBtn() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B6CF6), Color(0xFF5A4EE0)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.40),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : _signIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor:     Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.login_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Sign In',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w700,
                      )),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Sign up link ──────────────────────────────────────────────────────────
  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ",
          style: GoogleFonts.dmSans(color: _textSub, fontSize: 14)),
        GestureDetector(
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SignupScreen())),
          child: Text('Sign up',
            style: GoogleFonts.dmSans(
              color: _purple, fontSize: 14, fontWeight: FontWeight.w700,
            )),
        ),
      ],
    );
  }
}