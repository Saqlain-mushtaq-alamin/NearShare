import 'dart:math' as math;

import 'package:flutter/material.dart';

/// NearShare mark: two interlocking arrows — one leaving, one arriving.
///
/// Drawn with a [CustomPainter] so it scales crisply anywhere and needs no
/// asset pipeline.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 48,
    this.foregroundColor = Colors.white,
    this.background,
    this.padding = 10,
  });

  final double size;
  final Color foregroundColor;

  /// When set, the mark sits on a filled rounded square of this colour.
  final Color? background;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(
      size: Size.square(size - padding * 2),
      painter: _ShareArrowsPainter(color: foregroundColor),
    );

    if (background == null) return SizedBox.square(dimension: size, child: mark);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: mark,
    );
  }
}

class _ShareArrowsPainter extends CustomPainter {
  const _ShareArrowsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.13;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Arrow leaving toward the top-right.
    final pathA = Path()
      ..moveTo(w * 0.14, h * 0.70)
      ..lineTo(w * 0.70, h * 0.14);
    canvas.drawPath(pathA, paint);
    _drawArrowHead(
      canvas,
      tip: Offset(w * 0.82, h * 0.12),
      angle: -math.pi / 4,
      wing: w * 0.30,
      paint: paint,
    );

    // Second arrow, mirrored, drawn with a gap so the two never collide.
    final pathB = Path()
      ..moveTo(w * 0.86, h * 0.30)
      ..lineTo(w * 0.30, h * 0.86);
    canvas.drawPath(pathB, paint);
    _drawArrowHead(
      canvas,
      tip: Offset(w * 0.18, h * 0.88),
      angle: 3 * math.pi / 4,
      wing: w * 0.30,
      paint: paint,
    );
  }

  /// Chevron arrowhead anchored at [tip], pointing along [angle] (radians).
  void _drawArrowHead(
    Canvas canvas, {
    required Offset tip,
    required double angle,
    required double wing,
    required Paint paint,
  }) {
    const wingAngle = 0.5;

    Offset wingAt(double sign) {
      final a = angle + math.pi + sign * wingAngle;
      return Offset(tip.dx + wing * math.cos(a), tip.dy + wing * math.sin(a));
    }

    final head = Path()
      ..moveTo(wingAt(-1).dx, wingAt(-1).dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(wingAt(1).dx, wingAt(1).dy);
    canvas.drawPath(head, paint);
  }

  @override
  bool shouldRepaint(_ShareArrowsPainter oldDelegate) =>
      oldDelegate.color != color;
}
