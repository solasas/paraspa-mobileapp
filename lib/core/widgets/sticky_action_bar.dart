import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Bottom action bar: translucent paper, 1px top border, spec padding
/// `14 20 (26 + safeAreaBottom)`. Use as `Scaffold.bottomNavigationBar`.
class StickyActionBar extends StatelessWidget {
  const StickyActionBar({super.key, required this.child, this.opacity = 0.94});

  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 26 + bottom),
      decoration: BoxDecoration(
        color: AppColors.paper.withValues(alpha: opacity),
        border: const Border(top: BorderSide(color: AppColors.barBorder)),
      ),
      child: child,
    );
  }
}
