import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/enums.dart';
import '../../core/widgets/swap_icon.dart';
import '../../providers/exchanges_provider.dart';
import '../../providers/messages_provider.dart';

/// Hosts the five tab branches with the floating ink bottom navigation:
/// Discover · Search · Swaps · Chats · Me.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).maybeWhen(
          data: (count) => count > 0 ? count : 0,
          orElse: () => 0,
        );
    final pendingIncoming = ref.watch(receivedExchangesProvider).maybeWhen(
          data: (list) => list.where((e) => e.status == ExchangeStatus.pending).length,
          orElse: () => 0,
        );
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final current = navigationShell.currentIndex;

    void go(int index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20 + bottomInset,
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.28),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavItem(
                    label: 'Discover',
                    active: current == 0,
                    onTap: () => go(0),
                    iconBuilder: (c, s) => Icon(Icons.explore_outlined, size: s, color: c),
                  ),
                  _NavItem(
                    label: 'Search',
                    active: current == 1,
                    onTap: () => go(1),
                    iconBuilder: (c, s) => Icon(Icons.search_rounded, size: s, color: c),
                  ),
                  _NavItem(
                    label: 'Swaps',
                    active: current == 2,
                    onTap: () => go(2),
                    showDot: pendingIncoming > 0,
                    iconBuilder: (c, s) => SwapIcon(size: s, color: c, strokeWidth: 2.2),
                  ),
                  _NavItem(
                    label: 'Chats',
                    active: current == 3,
                    onTap: () => go(3),
                    badgeCount: unread,
                    iconBuilder: (c, s) =>
                        Icon(Icons.chat_bubble_outline_rounded, size: s, color: c),
                  ),
                  _NavItem(
                    label: 'Me',
                    active: current == 4,
                    onTap: () => go(4),
                    iconBuilder: (c, s) => Icon(Icons.person_outline_rounded, size: s, color: c),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.active,
    required this.onTap,
    required this.iconBuilder,
    this.showDot = false,
    this.badgeCount = 0,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final Widget Function(Color color, double size) iconBuilder;
  final bool showDot;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.ink : AppColors.onDarkTertiary;
    return Semantics(
      button: true,
      selected: active,
      label: badgeCount > 0 ? '$label, $badgeCount unread' : label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 48,
          constraints: const BoxConstraints(minWidth: 48),
          padding: EdgeInsets.symmetric(horizontal: active ? 16 : 0),
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconBuilder(color, active ? 21 : 22),
                  if (active) ...[
                    const SizedBox(width: 8),
                    Text(label, style: AppText.navLabel()),
                  ],
                ],
              ),
              if (showDot && !active)
                Positioned(
                  top: 9,
                  right: 9,
                  child: const _Dot(),
                ),
              if (badgeCount > 0 && !active)
                Positioned(
                  top: 5,
                  right: 3,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.notify,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: AppText.body(11, weight: FontWeight.w700, color: AppColors.ink),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(color: AppColors.notify, shape: BoxShape.circle),
    );
  }
}
