import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_version_label.dart';
import '../../core/widgets/brand_mark.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          Center(child: BrandMark(size: 72, background: AppColors.ink)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 36,
            child: SafeArea(
              child: AppVersionLabel(color: AppColors.onDarkTertiary),
            ),
          ),
        ],
      ),
    );
  }
}
