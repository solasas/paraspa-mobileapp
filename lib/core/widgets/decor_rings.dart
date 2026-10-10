import 'package:flutter/material.dart';

/// Concentric decorative rings used in hero/headers. Draws circles centred in
/// a [size]×[size] box; position it with `Positioned` and let the parent clip.
class DecorRings extends StatelessWidget {
  const DecorRings({
    super.key,
    required this.size,
    required this.radii,
    required this.color,
    this.strokeWidth = 1.2,
    this.dashedIndexes = const {},
  });

  final double size;
  final List<double> radii;
  final Color color;
  final double strokeWidth;

  /// Indexes into [radii] drawn as 3-on / 6-off dashes.
  final Set<int> dashedIndexes;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _RingsPainter(radii, color, strokeWidth, dashedIndexes)),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.radii, this.color, this.strokeWidth, this.dashed);

  final List<double> radii;
  final Color color;
  final double strokeWidth;
  final Set<int> dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (var i = 0; i < radii.length; i++) {
      final r = radii[i];
      if (!dashed.contains(i)) {
        canvas.drawCircle(c, r, paint);
        continue;
      }
      final circumference = 2 * 3.141592653589793 * r;
      const on = 3.0, off = 6.0;
      final count = (circumference / (on + off)).floor();
      for (var k = 0; k < count; k++) {
        final start = k * (on + off) / r;
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, on / r, false, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.color != color || old.radii != radii || old.strokeWidth != strokeWidth;
}
