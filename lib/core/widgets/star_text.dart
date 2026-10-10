import 'package:flutter/material.dart';

/// Text that swaps every "★" for an inline star icon. DM Sans has no ★ glyph,
/// so it would otherwise render as a missing-glyph box.
class StarText extends StatelessWidget {
  const StarText(
    this.text, {
    super.key,
    required this.style,
    this.starColor = const Color(0xFFF2A900),
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle style;
  final Color starColor;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final size = (style.fontSize ?? 14) + 1;
    final parts = text.split('★');
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(Icons.star_rounded, size: size, color: starColor),
            ),
          ),
        );
      }
      if (parts[i].isNotEmpty) spans.add(TextSpan(text: parts[i]));
    }
    return Text.rich(
      TextSpan(children: spans, style: style),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
