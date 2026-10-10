import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.statusDeclinedBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.statusDeclinedText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppText.body(
                13.5,
                weight: FontWeight.w600,
                color: AppColors.statusDeclinedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
