import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl     = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;
  String? _error;

  // ── Colors matching image 2 exactly ────────────────────────────────────
  static const _bg         = Color(0xFF0D0E17); // body bg — dark navy
  static const _cardBg     = Color(0xFF161824); // card bg
  static const _inputBg    = Color(0xFF1C1D2A); // input bg
  static const _border     = Color(0xFF2E3048); // input border
  static const _purple     = Color(0xFF6C63FF);
  static const _headerTop  = Color(0xFF7B72FF); // header gradient top
  static const _headerBot  = Color(0xFF5A4EE0); // header gradient bottom
  static const _textMain   = Color(0xFFFFFFFF);
  static const _textSub    = Color(0xFFD0CFFF); // white/lavender on purple header
  static const _textHint   = Color(0xFF545670);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_nameCtrl.text.trim().isEmpty ||
        _usernameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthService>().signUp(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        username: _usernameCtrl.text.trim(),
        fullName: _nameCtrl.text.trim(),
      );
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        // Header is purple — use light icons on top of it
        statusBarColor:              Color(0xFF7B72FF),
        statusBarIconBrightness:     Brightness.light,
        statusBarBrightness:         Brightness.dark,
        systemNavigationBarColor:    Color(0xFF0D0E17),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            // ── Purple header (extends under status bar) ───────────────
            _buildHeader(context),

            // ── Scrollable card + content ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  HEADER — purple gradient, extends under status bar
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPad + 14,
        left: 20, right: 20, bottom: 26,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_headerTop, _headerBot],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white, size: 24,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Create Account',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Join the campus skill community',
            style: GoogleFonts.dmSans(
              color: Colors.white.withOpacity(0.75),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  CARD
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        children: [
          const SizedBox(height: 4),

          _field(ctrl: _nameCtrl,     hint: 'Full Name', icon: Icons.person_outline_rounded),
          const SizedBox(height: 10),
          _field(ctrl: _usernameCtrl, hint: 'Username',  icon: Icons.alternate_email_rounded),
          const SizedBox(height: 10),
          _field(ctrl: _emailCtrl,    hint: 'Email',     icon: Icons.mail_outline_rounded, type: TextInputType.emailAddress),
          const SizedBox(height: 10),

          // Password with toggle
          _field(
            ctrl: _passwordCtrl,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            suffix: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: _textHint, size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Error banner
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.25)),
              ),
              child: Text(
                _error!,
                style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 12),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Create Account button
          _buildCreateBtn(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  INPUT FIELD — fixed height 54, no overflow, proper alignment
  // ════════════════════════════════════════════════════════════════════════
  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? type,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 16),
          Icon(icon, color: _textHint, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: ctrl,
              obscureText: obscure,
              keyboardType: type,
              style: GoogleFonts.dmSans(
                color: _textMain, fontSize: 15, fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.dmSans(
                  color: _textHint, fontSize: 15, fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (suffix != null) suffix,
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  CREATE ACCOUNT BUTTON
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildCreateBtn() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B6CF6), Color(0xFF6657E8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : _createAccount,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor:     Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  'Create Account',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}