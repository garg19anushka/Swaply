import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/swaply_logo.dart';
import 'signup_screen.dart';
import '../home/main_nav_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscure = true;
  bool _loading = false;

  // Per-field validation errors
  String? _emailError;
  String? _passwordError;
  // Auth-level error (wrong credentials etc.)
  String? _authError;

  // ── Palette ─────────────────────────────────────────────────────────────
  static const _bg = Color(0xFF0D0E17);
  static const _cardBg = Color(0xFF161824);
  static const _inputBg = Color(0xFF13141F);
  static const _border = Color(0xFF2E3048);
  static const _purple = Color(0xFF6C63FF);
  static const _textMain = Color(0xFFFFFFFF);
  static const _textSub = Color(0xFF8E90A8);
  static const _textHint = Color(0xFF545670);
  static const _errorRed = Color(0xFFFF5C6A);

  // Sign In button uses a different color (kept from image 2)
  static const _btnColor = Color(0xFF5B52E8);

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
      _emailError = null;
      _passwordError = null;
      _authError = null;

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

    setState(() {
      _loading = true;
      _authError = null;
    });
    try {
      final success = await context.read<AuthService>().signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (success) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, a1, __) => const MainNavScreen(),
            transitionsBuilder: (_, a1, __, child) =>
                FadeTransition(opacity: a1, child: child),
            transitionDuration: const Duration(milliseconds: 350),
          ),
          (route) => false,
        );
      } else {
        if (mounted) {
          final errMsg = context.read<AuthService>().errorMessage;
          setState(() {
            _authError = errMsg != null
                ? _friendlyError(errMsg)
                : 'Sign in failed. Please try again.';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _authError = _friendlyError(e.toString());
          _loading = false;
        });
      }
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('invalid') ||
        raw.contains('credentials') ||
        raw.contains('password'))
      return 'Invalid email or password. Please try again.';
    if (raw.contains('network') || raw.contains('socket'))
      return 'No internet connection. Please check your network.';
    if (raw.contains('too many'))
      return 'Too many attempts. Please wait a moment and try again.';
    return 'Sign in failed. Please try again.';
  }

  // ── Forgot password bottom sheet ─────────────────────────────────────────
  void _showForgotPasswordSheet() {
    final resetEmailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    String? sheetError;
    bool sheetLoading = false;
    bool sheetSent = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> sendReset() async {
              final email = resetEmailCtrl.text.trim();
              if (email.isEmpty ||
                  !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
                setSheetState(
                  () => sheetError = 'Please enter a valid email address.',
                );
                return;
              }
              setSheetState(() {
                sheetLoading = true;
                sheetError = null;
              });
              try {
                final ok = await context.read<AuthService>().resetPassword(
                  email,
                );
                if (ok) {
                  setSheetState(() {
                    sheetSent = true;
                    sheetLoading = false;
                  });
                } else {
                  setSheetState(() {
                    sheetError =
                        'Could not send reset email. Please try again.';
                    sheetLoading = false;
                  });
                }
              } catch (e) {
                setSheetState(() {
                  sheetError = 'Something went wrong. Please try again.';
                  sheetLoading = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _border, width: 1),
                ),
                child: sheetSent
                    ? _resetSuccessView(ctx, resetEmailCtrl.text.trim())
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle bar
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: _border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          // Icon
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _purple.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: _purple,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            'Reset password',
                            style: GoogleFonts.dmSans(
                              color: _textMain,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Enter the email linked to your account and we\'ll send you a reset link.',
                            style: GoogleFonts.dmSans(
                              color: _textSub,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Email input
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 56,
                            decoration: BoxDecoration(
                              color: _inputBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: sheetError != null ? _errorRed : _border,
                                width: sheetError != null ? 1.6 : 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.mail_outline_rounded,
                                  color: sheetError != null
                                      ? _errorRed
                                      : _textHint,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Theme(
                                    data: Theme.of(ctx).copyWith(
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      textSelectionTheme:
                                          TextSelectionThemeData(
                                            selectionColor: _purple.withOpacity(
                                              0.30,
                                            ),
                                            cursorColor: _purple,
                                            selectionHandleColor: _purple,
                                          ),
                                    ),
                                    child: TextField(
                                      controller: resetEmailCtrl,
                                      keyboardType: TextInputType.emailAddress,
                                      autocorrect: false,
                                      autofillHints: const [],
                                      enableIMEPersonalizedLearning: false,
                                      onChanged: (_) {
                                        if (sheetError != null)
                                          setSheetState(
                                            () => sheetError = null,
                                          );
                                      },
                                      style: GoogleFonts.dmSans(
                                        color: _textMain,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      cursorColor: _purple,
                                      decoration: InputDecoration(
                                        hintText: 'Email address',
                                        hintStyle: GoogleFonts.dmSans(
                                          color: _textHint,
                                          fontSize: 15,
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
                                const SizedBox(width: 16),
                              ],
                            ),
                          ),

                          // Inline error
                          if (sheetError != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: _errorRed,
                                  size: 13,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    sheetError!,
                                    style: GoogleFonts.dmSans(
                                      color: _errorRed,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 22),

                          // Send button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _purple,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _purple.withOpacity(0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: sheetLoading ? null : sendReset,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: sheetLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        'Send reset link',
                                        style: GoogleFonts.dmSans(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Cancel
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.dmSans(
                                  color: _textSub,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _resetSuccessView(BuildContext ctx, String email) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle bar
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: _border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Success icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: Color(0xFF22C55E),
            size: 36,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Check your inbox',
          style: GoogleFonts.dmSans(
            color: _textMain,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'We\'ve sent a password reset link to\n$email',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(color: _textSub, fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 8),
        Text(
          'Didn\'t receive it? Check your spam folder.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(color: _textHint, fontSize: 12),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _purple,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _purple.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Back to Sign In',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0D0E17),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF0D0E17),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
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
        Text(
          'Swaply',
          style: GoogleFonts.dmSans(
            color: _textMain,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Campus Skill Swap',
          style: GoogleFonts.dmSans(color: _textSub, fontSize: 14),
        ),
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
          Text(
            'Welcome back',
            style: GoogleFonts.dmSans(
              color: _textMain,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to your account',
            style: GoogleFonts.dmSans(color: _textSub, fontSize: 14),
          ),
          const SizedBox(height: 22),

          // Email field
          _inputField(
            ctrl: _emailCtrl,
            focus: _emailFocus,
            hint: 'Email',
            icon: Icons.mail_outline_rounded,
            type: TextInputType.emailAddress,
            error: _emailError,
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
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
            onChanged: (_) {
              if (_passwordError != null) setState(() => _passwordError = null);
            },
            trailing: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _textHint,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordSheet,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot password?',
                style: GoogleFonts.dmSans(
                  color: _purple,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
    if (hasError)
      borderColor = _errorRed;
    else if (focused)
      borderColor = _purple;
    else
      borderColor = _border;

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
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: _purple.withOpacity(0.15),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 16),
              Icon(
                icon,
                color: hasError ? _errorRed : (focused ? _purple : _textHint),
                size: 20,
              ),
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
                      color: _textMain,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    cursorColor: _purple,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: GoogleFonts.dmSans(
                        color: _textHint,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
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
                Text(
                  error,
                  style: GoogleFonts.dmSans(
                    color: _errorRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
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
            child: Text(
              msg,
              style: GoogleFonts.dmSans(
                color: _errorRed,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
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
          // Kept from image 2 — solid color instead of gradient
          color: _btnColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _btnColor.withOpacity(0.40),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : _signIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sign In',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
        Text(
          "Don't have an account? ",
          style: GoogleFonts.dmSans(color: _textSub, fontSize: 14),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SignupScreen()),
          ),
          child: Text(
            'Sign up',
            style: GoogleFonts.dmSans(
              color: _purple,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
