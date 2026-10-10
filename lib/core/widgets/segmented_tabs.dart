import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Pill-track segmented control. [small] is the Profile / Search-level
/// variant; [ink] fills the active tab with ink (Profile skill tabs).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.counts,
    this.small = false,
    this.ink = false,
    this.trackColor,
    this.expand = true,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  /// Optional per-tab count badge (Exchanges: Incoming / Sent / All).
  final List<int>? counts;
  final bool small;
  final bool ink;
  final Color? trackColor;

  /// Tabs share the width equally. When false the control hugs its content.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final pad = small ? 4.0 : 5.0;
    final gap = small ? 4.0 : 6.0;
    final trackRadius = small ? 13.0 : 18.0;
    final tabRadius = small ? 10.0 : 14.0;
    final tabHeight = small ? 38.0 : 44.0;

    final tabs = <Widget>[];
    for (var i = 0; i < labels.length; i++) {
      final on = i == selected;
      final fg = on ? (ink ? AppColors.paper : AppColors.ink) : AppColors.textSecondary;
      final tab = Semantics(
        button: true,
        selected: on,
        label: labels[i],
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: tabHeight,
            padding: EdgeInsets.symmetric(horizontal: small && expand ? 4 : (small ? 12 : 8)),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? (ink ? AppColors.ink : Colors.white) : Colors.transparent,
              borderRadius: BorderRadius.circular(tabRadius),
              boxShadow: on && !ink
                  ? [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      small ? 13.5 : (counts != null ? 14 : 15),
                      weight: on ? FontWeight.w700 : FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
                if (counts != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on ? AppColors.ink : AppColors.chipBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${counts![i]}',
                      style: AppText.body(
                        11,
                        weight: FontWeight.w700,
                        color: on ? AppColors.paper : AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
      tabs.add(expand ? Expanded(child: tab) : tab);
      if (i < labels.length - 1) tabs.add(SizedBox(width: gap));
    }

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: trackColor ?? AppColors.trackBg,
        borderRadius: BorderRadius.circular(trackRadius),
      ),
      child: Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, children: tabs),
    );
  }
}
