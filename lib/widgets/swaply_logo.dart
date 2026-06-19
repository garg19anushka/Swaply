import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  SwaplyLogoWidget  —  the official app icon rendered in Flutter.
//
//  Matches the physical app icon exactly:
//   • Rounded-square container with blue→purple gradient
//   • White S-shape (two arcs, thick stroke)
//   • Top arrow pointing RIGHT piercing through upper S
//   • Bottom arrow pointing LEFT piercing through lower S
//   • Square stroke-caps on arrow shafts, sharp chevron heads
//
//  Usage:
//    SwaplyLogoWidget(size: 88)
// ═══════════════════════════════════════════════════════════════════════════
class SwaplyLogoWidget extends StatelessWidget {
  final double size;
  const SwaplyLogoWidget({super.key, this.size = 88});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.27;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3D4FD6).withOpacity(0.45),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/images/swaply_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3D4FD6), Color(0xFF6B5BE2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CustomPaint(painter: _SwaplyLogoPainter()),
          ),
        ),
      ),
    );
  }
}

class _SwaplyLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sw = w * 0.115; // stroke width for S body

    final sPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.round;

    // ── S SHAPE — top arc ────────────────────────────────────────────────
    final topArc = Path();
    topArc.moveTo(w * 0.73, h * 0.245);
    topArc.cubicTo(w * 0.73, h * 0.10, w * 0.25, h * 0.10, w * 0.25, h * 0.295);
    topArc.cubicTo(
      w * 0.25,
      h * 0.435,
      w * 0.73,
      h * 0.435,
      w * 0.73,
      h * 0.500,
    );
    canvas.drawPath(topArc, sPaint);

    // ── S SHAPE — bottom arc ─────────────────────────────────────────────
    final botArc = Path();
    botArc.moveTo(w * 0.27, h * 0.755);
    botArc.cubicTo(w * 0.27, h * 0.90, w * 0.75, h * 0.90, w * 0.75, h * 0.705);
    botArc.cubicTo(
      w * 0.75,
      h * 0.565,
      w * 0.27,
      h * 0.565,
      w * 0.27,
      h * 0.500,
    );
    canvas.drawPath(botArc, sPaint);

    // ── ARROWS — drawn on top of S ───────────────────────────────────────
    final arrowSw = sw * 0.88;
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = arrowSw
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final headSz = h * 0.095;

    // Top arrow → pointing RIGHT
    final topY = h * 0.335;
    canvas.drawLine(Offset(w * 0.08, topY), Offset(w * 0.87, topY), arrowPaint);
    final headR = Path();
    headR.moveTo(w * 0.87 - headSz * 0.3, topY - headSz);
    headR.lineTo(w * 0.87 + headSz * 0.15, topY);
    headR.lineTo(w * 0.87 - headSz * 0.3, topY + headSz);
    canvas.drawPath(headR, arrowPaint);

    // Bottom arrow ← pointing LEFT
    final botY = h * 0.665;
    canvas.drawLine(Offset(w * 0.92, botY), Offset(w * 0.13, botY), arrowPaint);
    final headL = Path();
    headL.moveTo(w * 0.13 + headSz * 0.3, botY - headSz);
    headL.lineTo(w * 0.13 - headSz * 0.15, botY);
    headL.lineTo(w * 0.13 + headSz * 0.3, botY + headSz);
    canvas.drawPath(headL, arrowPaint);
  }

  @override
  bool shouldRepaint(_SwaplyLogoPainter old) => false;
}
