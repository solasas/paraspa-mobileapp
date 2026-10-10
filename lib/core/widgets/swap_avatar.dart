import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Rounded-square avatar with initials. Fill rotates through the pastel set
/// based on [seed] (typically the user id) so a person keeps their colour.
class SwapAvatar extends StatelessWidget {
  const SwapAvatar({
    super.key,
    required this.name,
    this.seed,
    this.size = 48,
    this.online,
    this.ringColor,
    this.borderColor = AppColors.paper,
  });

  final String name;
  final int? seed;
  final double size;

  /// Shows the green presence dot when true.
  final bool? online;

  /// Optional ring drawn around the avatar (inbox "active now" row).
  final Color? ringColor;

  /// Colour of the border around the online dot; match the background.
  final Color borderColor;

  /// Corner radius per the spec: 46→16, 48→17, 52→18, 60→22, 66→24,
  /// 80→28, 84/88→30. Anything else scales proportionally.
  static double radiusFor(double size) {
    if (size <= 46) return 16;
    if (size <= 48) return 17;
    if (size <= 52) return 18;
    if (size <= 60) return 22;
    if (size <= 66) return 24;
    if (size <= 80) return 28;
    return 30;
  }

  static Color fillFor(int? seed, String name) {
    final key = seed ?? name.hashCode;
    return AppColors.avatarFills[key.abs() % AppColors.avatarFills.length];
  }

  @override
  Widget build(BuildContext context) {
    final initials = initialsOf(name);
    final radius = radiusFor(size);

    Widget avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fillFor(seed, name),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        initials,
        style: AppText.body(size * 0.36, weight: FontWeight.w700, color: AppColors.ink),
      ),
    );

    if (ringColor != null) {
      avatar = Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius + 3),
          border: Border.all(color: ringColor!, width: 2),
        ),
        child: avatar,
      );
    }

    if (online != true) return avatar;

    final dot = size >= 60 ? 14.0 : 12.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: AppColors.online,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2.5),
            ),
          ),
        ),
      ],
    );
  }

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
