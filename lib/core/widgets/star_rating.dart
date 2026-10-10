import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Read-only star display.
class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({
    super.key,
    required this.stars,
    this.size = 18,
    this.color = AppColors.starOnLight,
  });

  final double stars;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < stars.round();
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: color,
        );
      }),
    );
  }
}

/// Interactive 1-5 star picker (56pt tap target, 46pt star, accent fill with
/// a 1.6 ink outline) used on the rate-session screen.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starIndex = i + 1;
        final filled = starIndex <= value;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
          child: Semantics(
            button: true,
            label: '$starIndex ${starIndex == 1 ? 'star' : 'stars'}',
            selected: value == starIndex,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(starIndex),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child: CustomPaint(
                    size: const Size(46, 46),
                    painter: _StarPainter(filled),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.filled);

  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    // m12 2.5 2.9 6.1 6.6.8-4.9 4.5 1.3 6.6L12 17.3l-5.9 3.2 1.3-6.6-4.9-4.5 6.6-.8z
    final p = Path()
      ..moveTo(12 * s, 2.5 * s)
      ..lineTo(14.9 * s, 8.6 * s)
      ..lineTo(21.5 * s, 9.4 * s)
      ..lineTo(16.6 * s, 13.9 * s)
      ..lineTo(17.9 * s, 20.5 * s)
      ..lineTo(12 * s, 17.3 * s)
      ..lineTo(6.1 * s, 20.5 * s)
      ..lineTo(7.4 * s, 13.9 * s)
      ..lineTo(2.5 * s, 9.4 * s)
      ..lineTo(9.1 * s, 8.6 * s)
      ..close();
    if (filled) {
      canvas.drawPath(p, Paint()..color = AppColors.accent);
    }
    canvas.drawPath(
      p,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * s
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.filled != filled;
}
