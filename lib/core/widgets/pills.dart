import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../utils/enums.dart';

/// Small uppercase status label, coloured from the status tokens.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.bg, required this.fg});

  factory StatusPill.exchange(ExchangeStatus status, {Key? key}) {
    switch (status) {
      case ExchangeStatus.pending:
        return StatusPill(
          key: key,
          label: 'PENDING',
          bg: AppColors.statusPendingBg,
          fg: AppColors.statusPendingText,
        );
      case ExchangeStatus.accepted:
        return StatusPill(
          key: key,
          label: 'ACCEPTED',
          bg: AppColors.statusAcceptedBg,
          fg: AppColors.statusAcceptedText,
        );
      case ExchangeStatus.rejected:
        return StatusPill(
          key: key,
          label: 'DECLINED',
          bg: AppColors.statusDeclinedBg,
          fg: AppColors.statusDeclinedText,
        );
      case ExchangeStatus.completed:
        return StatusPill(
          key: key,
          label: 'COMPLETED',
          bg: AppColors.statusDoneBg,
          fg: AppColors.statusDoneText,
        );
    }
  }

  factory StatusPill.session(SessionStatus status, {Key? key}) {
    switch (status) {
      case SessionStatus.scheduled:
        return StatusPill(
          key: key,
          label: 'SCHEDULED',
          bg: AppColors.statusAcceptedBg,
          fg: AppColors.statusAcceptedText,
        );
      case SessionStatus.completed:
        return StatusPill(
          key: key,
          label: 'COMPLETED',
          bg: AppColors.statusDoneBg,
          fg: AppColors.statusDoneText,
        );
      case SessionStatus.cancelled:
        return StatusPill(
          key: key,
          label: 'CANCELLED',
          bg: AppColors.statusDeclinedBg,
          fg: AppColors.statusDeclinedText,
        );
    }
  }

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: AppText.badge(color: fg)),
    );
  }
}

/// "Teaches you · Guitar" / "Learns your · Java" tag.
class SkillTag extends StatelessWidget {
  const SkillTag({super.key, required this.prefix, required this.name, required this.teach});

  final String prefix;
  final String name;

  /// true → lime teach tint, false → lilac learn tint.
  final bool teach;

  @override
  Widget build(BuildContext context) {
    final bg = teach ? AppColors.teachTintBg : AppColors.learnTintBg;
    final fg = teach ? AppColors.teachTintText : AppColors.learnTintText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$prefix  ', style: AppText.body(13, color: fg)),
            TextSpan(
              text: name,
              style: AppText.body(13, weight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ink "Mutual" badge with accent text.
class MutualBadge extends StatelessWidget {
  const MutualBadge({super.key, this.label = 'Mutual'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: AppText.body(12, weight: FontWeight.w700, color: AppColors.accent)),
    );
  }
}

/// Outlined "One-way" badge for non-mutual matches.
class OneWayBadge extends StatelessWidget {
  const OneWayBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD6D3CB), width: 1.5),
      ),
      child: Text(
        'One-way',
        style: AppText.body(12, weight: FontWeight.w700, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Filter chip (h40): ink when selected, 1.5 outline otherwise.
class FilterChipPill extends StatelessWidget {
  const FilterChipPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.height = 40,
    this.selectedColor = AppColors.ink,
    this.selectedTextColor = AppColors.paper,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;
  final Color selectedColor;
  final Color selectedTextColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: selected ? null : Border.all(color: AppColors.chipBorder, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppText.body(
                14,
                weight: FontWeight.w600,
                color: selected ? selectedTextColor : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
