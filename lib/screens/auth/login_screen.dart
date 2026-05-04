import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure  = true;
  bool _loading  = false;
  String? _error;

  static const _bg       = Color(0xFF0D0E17);
  static const _cardBg   = Color(0xFF161824);
  static const _inputBg  = Color(0xFF1C1D2A);
  static const _border   = Color(0xFF2E3048);
  static const _purple   = Color(0xFF6C63FF);
  static const _textMain = Color(0xFFFFFFFF);
  static const _textSub  = Color(0xFF8E90A8);
  static const _textHint = Color(0xFF545670);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await context.read<AuthService>().signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

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

  // ════════════════════════════════════════════════════════════════════════
  //  LOGO — S with swap arrows, blue-purple gradient matching the image
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3D5AFE), Color(0xFF6C63FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3D5AFE).withOpacity(0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: SizedBox(
              width: 52, height: 52,
              child: CustomPaint(painter: _SwaplyLogoPainter()),
            ),
          ),
        ),
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
          'Campus Skill Barter',
          style: GoogleFonts.dmSans(
            color: _textSub,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  CARD
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
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
              color: _textMain, fontSize: 22,
              fontWeight: FontWeight.w800, letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sign in to your account',
            style: GoogleFonts.dmSans(color: _textSub, fontSize: 14),
          ),
          const SizedBox(height: 22),

          _inputField(
            ctrl: _emailCtrl,
            hint: 'Email',
            icon: Icons.mail_outline_rounded,
            type: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          _inputField(
            ctrl: _passwordCtrl,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscure,
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

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot password?',
                style: GoogleFonts.dmSans(
                  color: _purple, fontSize: 13, fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Error
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.25)),
              ),
              child: Text(_error!, style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 12)),
            ),
            const SizedBox(height: 14),
          ],

          _buildSignInBtn(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  INPUT FIELD — fixed, clean, no overflow
  // ════════════════════════════════════════════════════════════════════════
  Widget _inputField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? trailing,
    TextInputType? type,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 16),
          Icon(icon, color: _textHint, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: ctrl,
              obscureText: obscure,
              keyboardType: type,
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
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  //  SIGN IN BUTTON — gradient unchanged, login icon added
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildSignInBtn() {
    return SizedBox(
      width: double.infinity,
      height: 56,
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
          onPressed: _loading ? null : _signIn,
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
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.login_rounded, color: Colors.white, size: 20),
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

  // ════════════════════════════════════════════════════════════════════════
  //  SIGN UP LINK
  // ════════════════════════════════════════════════════════════════════════
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
              color: _purple, fontSize: 14, fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  CUSTOM PAINTER — draws the S + double swap arrows logo
//  Matches the image: stylized S body with a right arrow (top)
//  and left arrow (bottom) piercing through it
// ══════════════════════════════════════════════════════════════════════════
class _SwaplyLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // ── S body ────────────────────────────────────────────────────────────
    // Top arc of S (curves right-to-left at top)
    final topPath = Path();
    topPath.moveTo(w * 0.72, h * 0.18);
    topPath.cubicTo(
      w * 0.72, h * 0.06,
      w * 0.28, h * 0.06,
      w * 0.28, h * 0.28,
    );
    topPath.cubicTo(
      w * 0.28, h * 0.44,
      w * 0.72, h * 0.44,
      w * 0.72, h * 0.50,
    );
    canvas.drawPath(topPath, paint);

    // Bottom arc of S (curves left-to-right at bottom)
    final bottomPath = Path();
    bottomPath.moveTo(w * 0.28, h * 0.82);
    bottomPath.cubicTo(
      w * 0.28, h * 0.94,
      w * 0.72, h * 0.94,
      w * 0.72, h * 0.72,
    );
    bottomPath.cubicTo(
      w * 0.72, h * 0.56,
      w * 0.28, h * 0.56,
      w * 0.28, h * 0.50,
    );
    canvas.drawPath(bottomPath, paint);

    // ── Top right arrow (pointing right, at ~35% height) ──────────────────
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Arrow shaft — horizontal line going right through top of S
    canvas.drawLine(
      Offset(w * 0.10, h * 0.32),
      Offset(w * 0.82, h * 0.32),
      arrowPaint,
    );
    // Arrowhead pointing right
    final arrowHeadR = Path();
    arrowHeadR.moveTo(w * 0.76, h * 0.20);
    arrowHeadR.lineTo(w * 0.90, h * 0.32);
    arrowHeadR.lineTo(w * 0.76, h * 0.44);
    canvas.drawPath(arrowHeadR, arrowPaint);

    // ── Bottom left arrow (pointing left, at ~68% height) ─────────────────
    // Arrow shaft — horizontal line going left through bottom of S
    canvas.drawLine(
      Offset(w * 0.90, h * 0.68),
      Offset(w * 0.18, h * 0.68),
      arrowPaint,
    );
    // Arrowhead pointing left
    final arrowHeadL = Path();
    arrowHeadL.moveTo(w * 0.24, h * 0.56);
    arrowHeadL.lineTo(w * 0.10, h * 0.68);
    arrowHeadL.lineTo(w * 0.24, h * 0.80);
    canvas.drawPath(arrowHeadL, arrowPaint);
  }

  @override
  bool shouldRepaint(_SwaplyLogoPainter oldDelegate) => false;
}