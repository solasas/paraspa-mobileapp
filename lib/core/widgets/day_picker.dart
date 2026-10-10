import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Five-column date strip (cell h62, r15). Selected = ink bg + accent text.
class DayPicker extends StatelessWidget {
  const DayPicker({
    super.key,
    required this.days,
    required this.selected,
    required this.onChanged,
  });

  final List<DateTime> days;
  final int selected;
  final ValueChanged<int> onChanged;

  /// The next [count] days starting tomorrow.
  static List<DateTime> upcoming({int count = 5, DateTime? from}) {
    final t = from ?? DateTime.now();
    return [for (var i = 1; i <= count; i++) DateTime(t.year, t.month, t.day + i)];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: _cell(days[i], i == selected, () => onChanged(i))),
        ],
      ],
    );
  }

  Widget _cell(DateTime date, bool on, VoidCallback onTap) {
    return Semantics(
      button: true,
      selected: on,
      label: DateFormat('EEEE d MMMM').format(date),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 62,
          decoration: BoxDecoration(
            color: on ? AppColors.ink : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: on ? null : Border.all(color: AppColors.inputBorder, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('EEE').format(date),
                style: AppText.body(
                  11,
                  weight: FontWeight.w600,
                  color: on ? AppColors.accent : AppColors.ink,
                ),
              ),
              Text(
                '${date.day}',
                style: AppText.body(
                  18,
                  weight: FontWeight.w800,
                  color: on ? AppColors.accent : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
