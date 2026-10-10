import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Spec toggle: 50×30 track, 24 knob; on = ink track + accent knob.
class ToggleSwitch extends StatelessWidget {
  const ToggleSwitch({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 50,
      height: 30,
      padding: const EdgeInsets.all(3),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: value ? AppColors.ink : AppColors.chipBorder,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: value ? AppColors.accent : Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
