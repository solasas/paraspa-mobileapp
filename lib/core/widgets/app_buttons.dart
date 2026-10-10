import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

/// Full-width primary action (h58, r18). Ink on light surfaces; pass
/// [onDark] for the accent-on-ink variant used over dark headers/sheets.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.leading,
    this.loading = false,
    this.onDark = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Custom leading widget (e.g. the swap glyph); takes precedence over [icon].
  final Widget? leading;
  final bool loading;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bg = onDark ? AppColors.accent : AppColors.ink;
    final fg = onDark ? AppColors.ink : AppColors.paper;
    final iconColor = onDark ? AppColors.ink : AppColors.accent;
    final enabled = onPressed != null && !loading;

    return Opacity(
      opacity: onPressed == null && !loading ? 0.5 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.buttonPrimary),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.buttonPrimary),
          onTap: enabled ? onPressed : null,
          child: Container(
            height: 58,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: onDark
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      AppRadius.buttonPrimary,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.18),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  )
                : null,
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: fg,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 10),
                      ] else if (icon != null) ...[
                        Icon(icon, size: 20, color: iconColor),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.button(color: fg),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Outlined secondary action (h52 by default, 1.5 border).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.onDark = false,
    this.height = 52,
    this.radius = AppRadius.buttonSecondary,
    this.foreground,
    this.dashed = false,
    this.fill,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool onDark;
  final double height;
  final Color? fill;
  final double radius;
  final Color? foreground;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? (onDark ? AppColors.onDarkPrimary : AppColors.ink);
    final border = onDark
        ? AppColors.inkBorder
        : (dashed ? AppColors.dashedBorder : AppColors.chipBorder);

    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        color: fill ?? Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onPressed,
          child: CustomPaint(
            foregroundPainter: dashed
                ? _DashedBorderPainter(color: border, radius: radius)
                : null,
            child: Container(
              height: height,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: fill != null || dashed
                    ? null
                    : Border.all(color: border, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.buttonSmall(color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 1.5px dashed rounded-rect border (6 on / 5 off).
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
        d += 11;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// Small inline action used in pairs (Accept / Decline): h46, r14.
class InlineButton extends StatelessWidget {
  const InlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.paper : AppColors.ink;
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        color: filled ? AppColors.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.buttonInline),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.buttonInline),
          onTap: onPressed,
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.buttonInline),
              border: filled
                  ? null
                  : Border.all(color: AppColors.chipBorder, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: filled ? AppColors.accent : fg),
                  const SizedBox(width: 6),
                ],
                Text(label, style: AppText.buttonSmall(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 46×46 square icon button (r16). White with a border on light screens,
/// `inkRaised` on dark headers.
class IconSquareButton extends StatelessWidget {
  const IconSquareButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.onDark = false,
    this.tooltip,
    this.badge = false,
    this.size = 46,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool onDark;
  final String? tooltip;
  final bool badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: onDark ? AppColors.inkRaised : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: onDark
                ? null
                : Border.all(color: AppColors.inputBorder, width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: onDark ? AppColors.onDarkPrimary : AppColors.ink,
              ),
              if (badge)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.notify,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (tooltip != null) button = Tooltip(message: tooltip!, child: button);
    return button;
  }
}
