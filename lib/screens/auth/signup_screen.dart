import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/swaply_logo.dart';

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

  final _nameFocus     = FocusNode();
  final _usernameFocus = FocusNode();
  final _emailFocus    = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscure  = true;
  bool _loading  = false;
  String? _authError;

  // Per-field errors
  String? _nameError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;

  // ── Palette ─────────────────────────────────────────────────────────────
  static const _bg        = Color(0xFF0D0E17);
  static const _cardBg    = Color(0xFF161824);
  static const _inputBg   = Color(0xFF13141F);
  static const _border    = Color(0xFF2E3048);
  static const _purple    = Color(0xFF6C63FF);
  static const _headerTop = Color(0xFF7B72FF);
  static const _headerBot = Color(0xFF5A4EE0);
  static const _textMain  = Color(0xFFFFFFFF);
  static const _textSub   = Color(0xFF8E90A8);
  static const _textHint  = Color(0xFF545670);
  static const _errorRed  = Color(0xFFFF5C6A);

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(()     => setState(() {}));
    _usernameFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(()    => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _usernameCtrl.dispose();
    _emailCtrl.dispose(); _passwordCtrl.dispose();
    _nameFocus.dispose(); _usernameFocus.dispose();
    _emailFocus.dispose(); _passwordFocus.dispose();
    super.dispose();
  }

  // ── Validation ───────────────────────────────────────────────────────────
  bool _validate() {
    bool ok = true;
    setState(() {
      _nameError = _usernameError = _emailError = _passwordError = _authError = null;

      if (_nameCtrl.text.trim().isEmpty) {
        _nameError = 'Please enter your full name';
        ok = false;
      } else if (_nameCtrl.text.trim().length < 2) {
        _nameError = 'Name must be at least 2 characters';
        ok = false;
      }

      final username = _usernameCtrl.text.trim();
      if (username.isEmpty) {
        _usernameError = 'Please enter a username';
        ok = false;
      } else if (username.length < 3) {
        _usernameError = 'Username must be at least 3 characters';
        ok = false;
      } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
        _usernameError = 'Only letters, numbers and underscores allowed';
        ok = false;
      }

      final email = _emailCtrl.text.trim();
      if (email.isEmpty) {
        _emailError = 'Please enter your email';
        ok = false;
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
        _emailError = 'Enter a valid email address';
        ok = false;
      }

      if (_passwordCtrl.text.isEmpty) {
        _passwordError = 'Please enter a password';
        ok = false;
      } else if (_passwordCtrl.text.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
        ok = false;
      }
    });
    return ok;
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() { _loading = true; _authError = null; });
    try {
      await context.read<AuthService>().signUp(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        username: _usernameCtrl.text.trim(),
        fullName: _nameCtrl.text.trim(),
      );
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
    if (raw.contains('already') || raw.contains('exists') || raw.contains('taken'))
      return 'This email or username is already registered.';
    if (raw.contains('network') || raw.contains('socket'))
      return 'No internet connection. Please check your network.';
    if (raw.contains('weak') || raw.contains('password'))
      return 'Password is too weak. Please choose a stronger one.';
    return 'Account creation failed. Please try again.';
  }

  // ── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
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
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                child: _buildCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topPad + 14, left: 20, right: 20, bottom: 26),
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const SwaplyLogoWidget(size: 44),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create Account',
                    style: GoogleFonts.dmSans(
                      color: Colors.white, fontSize: 24,
                      fontWeight: FontWeight.w800, letterSpacing: -0.5,
                    )),
                  Text('Join the campus skill community',
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withOpacity(0.75), fontSize: 13,
                    )),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card ─────────────────────────────────────────────────────────────────
  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        children: [
          _field(
            ctrl: _nameCtrl, focus: _nameFocus,
            hint: 'Full Name', icon: Icons.person_outline_rounded,
            error: _nameError,
            onChanged: (_) { if (_nameError != null) setState(() => _nameError = null); },
          ),
          const SizedBox(height: 12),

          _field(
            ctrl: _usernameCtrl, focus: _usernameFocus,
            hint: 'Username', icon: Icons.alternate_email_rounded,
            error: _usernameError,
            onChanged: (_) { if (_usernameError != null) setState(() => _usernameError = null); },
          ),
          const SizedBox(height: 12),

          _field(
            ctrl: _emailCtrl, focus: _emailFocus,
            hint: 'Email', icon: Icons.mail_outline_rounded,
            type: TextInputType.emailAddress,
            error: _emailError,
            onChanged: (_) { if (_emailError != null) setState(() => _emailError = null); },
          ),
          const SizedBox(height: 12),

          _field(
            ctrl: _passwordCtrl, focus: _passwordFocus,
            hint: 'Password', icon: Icons.lock_outline_rounded,
            obscure: _obscure,
            error: _passwordError,
            onChanged: (_) { if (_passwordError != null) setState(() => _passwordError = null); },
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

          // Auth-level error
          if (_authError != null) ...[
            _errorBanner(_authError!),
            const SizedBox(height: 14),
          ],

          _buildCreateBtn(),
        ],
      ),
    );
  }

  // ── Input field ───────────────────────────────────────────────────────────
  Widget _field({
    required TextEditingController ctrl,
    required FocusNode focus,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? type,
    String? error,
    ValueChanged<String>? onChanged,
  }) {
    final focused  = focus.hasFocus;
    final hasError = error != null;

    Color borderColor;
    if (hasError)     borderColor = _errorRed;
    else if (focused) borderColor = _purple;
    else              borderColor = _border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 54,
          decoration: BoxDecoration(
            color: _inputBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: hasError || focused ? 1.6 : 1.2,
            ),
            boxShadow: focused ? [
              BoxShadow(color: _purple.withOpacity(0.12), blurRadius: 8),
            ] : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 16),
              Icon(icon,
                color: hasError ? _errorRed : (focused ? _purple : _textHint),
                size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    textSelectionTheme: TextSelectionThemeData(
                      selectionColor: _purple.withOpacity(0.30),
                      cursorColor: _purple,
                      selectionHandleColor: _purple,
                    ),
                  ),
                  child: TextField(
                    controller: ctrl,
                    focusNode: focus,
                    obscureText: obscure,
                    keyboardType: type,
                    onChanged: onChanged,
                    autocorrect: false,
                    autofillHints: const [],
                    enableIMEPersonalizedLearning: false,
                    style: GoogleFonts.dmSans(
                      color: _textMain, fontSize: 15, fontWeight: FontWeight.w400,
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
                      filled: true,
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
              if (suffix != null) suffix,
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
                Expanded(
                  child: Text(error,
                    style: GoogleFonts.dmSans(
                      color: _errorRed, fontSize: 12, fontWeight: FontWeight.w500,
                    )),
                ),
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

  // ── Create button ─────────────────────────────────────────────────────────
  Widget _buildCreateBtn() {
    return SizedBox(
      width: double.infinity,
      height: 54,
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
              blurRadius: 18, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : _createAccount,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text('Create Account',
                  style: GoogleFonts.dmSans(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
                  )),
        ),
      ),
    );
  }
}