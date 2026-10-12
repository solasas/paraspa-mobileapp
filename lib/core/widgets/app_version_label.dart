import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_info_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Small "paraspa v1.0.2" caption. Renders nothing until the version
/// has been read (or if it can't be).
class AppVersionLabel extends ConsumerWidget {
  const AppVersionLabel({super.key, this.color = AppColors.textSecondary});

  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).valueOrNull;
    if (version == null) return const SizedBox.shrink();
    return Text(
      'paraspa v$version',
      textAlign: TextAlign.center,
      style: AppText.meta(color: color),
    );
  }
}
