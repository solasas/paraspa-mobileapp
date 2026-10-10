import 'package:flutter/material.dart';

/// The two-arrow "swap" glyph from the design (24-unit grid, round caps).
class SwapIcon extends StatelessWidget {
  const SwapIcon({super.key, this.size = 20, this.color = Colors.black, this.strokeWidth = 2.2});

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SwapPainter(color, strokeWidth)),
    );
  }
}

class _SwapPainter extends CustomPainter {
  _SwapPainter(this.color, this.strokeWidth);

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // M4 8h13l-3-3
    final top = Path()
      ..moveTo(4 * s, 8 * s)
      ..lineTo(17 * s, 8 * s)
      ..lineTo(14 * s, 5 * s);
    // M20 16H7l3 3
    final bottom = Path()
      ..moveTo(20 * s, 16 * s)
      ..lineTo(7 * s, 16 * s)
      ..lineTo(10 * s, 19 * s);
    canvas.drawPath(top, paint);
    canvas.drawPath(bottom, paint);
  }

  @override
  bool shouldRepaint(_SwapPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
