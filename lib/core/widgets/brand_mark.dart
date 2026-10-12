import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// The "Overlap" logo: two circles (lilac + accent) whose intersection is cut
/// out in the background colour. Drawn on a 100×100 grid.
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 56,
    this.background = AppColors.paper,
    this.tile = false,
  });

  final double size;

  /// Colour of the overlap lens; must match whatever the mark sits on.
  final Color background;

  /// Draws the mark on a rounded `inkRaised` tile (app-icon style).
  final bool tile;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: tile ? size * 0.8 : size,
      height: tile ? size * 0.8 : size,
      child: CustomPaint(
        painter: _OverlapPainter(tile ? AppColors.inkRaised : background),
      ),
    );
    if (!tile) return mark;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.inkRaised,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: mark,
    );
  }
}

class _OverlapPainter extends CustomPainter {
  _OverlapPainter(this.cutout);

  final Color cutout;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final leftCenter = Offset(38 * s, 50 * s);
    final rightCenter = Offset(62 * s, 50 * s);
    final r = 24 * s;

    canvas.drawCircle(leftCenter, r, Paint()..color = AppColors.lilac);
    canvas.drawCircle(rightCenter, r, Paint()..color = AppColors.accent);

    final lens = Path.combine(
      PathOperation.intersect,
      Path()..addOval(Rect.fromCircle(center: leftCenter, radius: r)),
      Path()..addOval(Rect.fromCircle(center: rightCenter, radius: r)),
    );
    canvas.drawPath(lens, Paint()..color = cutout);
  }

  @override
  bool shouldRepaint(_OverlapPainter old) => old.cutout != cutout;
}

/// Mark + "paraspa" wordmark.
class Wordmark extends StatelessWidget {
  const Wordmark({
    super.key,
    this.size = 24,
    this.color = AppColors.textPrimary,
    this.background = AppColors.paper,
  });

  final double size;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: size * 1.25, background: background),
        const SizedBox(width: 8),
        Text(
          'paraspa',
          style: AppText.display(size, spacing: -size * 0.025, color: color),
        ),
      ],
    );
  }
}
