import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'app_buttons.dart';

/// Pops if possible, otherwise goes to [fallback]. Detail routes can be
/// opened cold (deep link), so a bare `pop()` is not always safe.
void popOrGo(BuildContext context, [String fallback = '/matches']) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

/// Square back button used by every detail screen.
class BackSquareButton extends StatelessWidget {
  const BackSquareButton({super.key, this.onDark = false, this.onPressed, this.translucent = false});

  final bool onDark;
  final VoidCallback? onPressed;

  /// Lilac match header uses a translucent-white button.
  final bool translucent;

  @override
  Widget build(BuildContext context) {
    final action = onPressed ?? () => popOrGo(context);
    if (translucent) {
      return Material(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: action,
          child: const SizedBox(
            width: 46,
            height: 46,
            child: Icon(Icons.chevron_left_rounded, size: 26, color: AppColors.ink),
          ),
        ),
      );
    }
    return IconSquareButton(
      icon: Icons.chevron_left_rounded,
      onDark: onDark,
      tooltip: 'Back',
      onPressed: action,
    );
  }
}

/// Standard detail/form page: back button, title, scrolling body and an
/// optional sticky bottom bar. Body is padded 20 and clears the bar.
class SubPage extends StatelessWidget {
  const SubPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.trailing,
    this.bottomBar,
    this.onRefresh,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final Widget? bottomBar;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 8;
    final list = ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenX,
        top,
        AppSpacing.screenX,
        bottomBar != null ? 32 : 40,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const BackSquareButton(),
            ?trailing,
          ],
        ),
        const SizedBox(height: 18),
        Text(title, style: AppText.h1()),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: AppText.body(14, color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 18),
        ...children,
      ],
    );
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list),
      bottomNavigationBar: bottomBar == null
          ? null
          : _BarWrapper(child: bottomBar!),
    );
  }
}

class _BarWrapper extends StatelessWidget {
  const _BarWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 26 + bottom),
      decoration: BoxDecoration(
        color: AppColors.paper.withValues(alpha: 0.94),
        border: const Border(top: BorderSide(color: AppColors.barBorder)),
      ),
      child: child,
    );
  }
}
