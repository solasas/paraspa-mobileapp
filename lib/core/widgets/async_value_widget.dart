import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'app_buttons.dart';
import 'sub_page.dart';

/// Renders a Riverpod AsyncValue with consistent loading/error/data states
/// and a pull-to-refresh-friendly retry action.
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loadingBuilder,
    this.showBack = false,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final WidgetBuilder? loadingBuilder;

  /// Overlay a back button on the loading/error states (full-screen detail
  /// pages, where there is no app bar to leave from).
  final bool showBack;

  Widget _withBack(BuildContext context, Widget child) {
    if (!showBack) return child;
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          left: 20,
          top: MediaQuery.of(context).padding.top + 8,
          child: const BackSquareButton(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => _withBack(
        context,
        loadingBuilder?.call(context) ??
            const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.ink),
              ),
            ),
      ),
      error: (error, stack) {
        if (error is! ApiException) {
          debugPrint('AsyncValueWidget<$T> error: $error\n$stack');
        }
        return _withBack(context, _ErrorView(error: error, onRetry: onRetry));
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final err = error;
    final message = err is ApiException ? err.message : 'Something went wrong.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.statusDeclinedBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.priority_high_rounded, size: 30, color: AppColors.danger),
            ),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center, style: AppText.bodyText()),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: 160,
                child: SecondaryButton(label: 'Retry', onPressed: onRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
