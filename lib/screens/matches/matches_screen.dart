import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/enums.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/decor_rings.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/star_text.dart';
import '../../core/widgets/swap_avatar.dart';
import '../../core/widgets/swap_icon.dart';
import '../../models/match_result.dart';
import '../../models/skill.dart';
import '../../providers/exchanges_provider.dart';
import '../../providers/matches_provider.dart';
import '../../providers/profile_provider.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  int _tab = 0;

  Future<void> _refresh() async {
    ref.invalidate(allMatchesProvider);
    ref.invalidate(mutualMatchesProvider);
    await ref.read(allMatchesProvider.future).catchError((_) => <MatchResult>[]);
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allMatchesProvider);
    final mutualAsync = ref.watch(mutualMatchesProvider);
    final me = ref.watch(myProfileProvider).valueOrNull;
    final pendingIncoming = ref.watch(receivedExchangesProvider).maybeWhen(
          data: (l) => l.where((e) => e.status == ExchangeStatus.pending).length,
          orElse: () => 0,
        );
    final top = MediaQuery.of(context).padding.top + 8;

    final allMatches = allAsync.valueOrNull ?? const <MatchResult>[];
    final mutual = mutualAsync.maybeWhen(
      data: (l) => l,
      orElse: () => allMatches.where((m) => m.isMutual).toList(),
    );
    final hero = mutual.isNotEmpty ? mutual.first : null;
    final bestTab = _tab == 1;
    final source = bestTab ? mutual : allMatches;
    final list = source.where((m) => hero == null || m.user.id != hero.user.id).toList();

    final children = <Widget>[
      _Header(
        name: me?.name,
        hasPending: pendingIncoming > 0,
        onBell: () => context.go('/requests'),
        onAvatar: () => context.go('/profile'),
      ),
      const SizedBox(height: 20),
      SegmentedTabs(
        labels: ['For you', 'Best matches · ${mutual.length}'],
        selected: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
      const SizedBox(height: 20),
    ];

    if (allAsync.isLoading && allMatches.isEmpty) {
      children.add(const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.6)),
      ));
    } else if (allAsync.hasError && allMatches.isEmpty) {
      children.add(SizedBox(
        height: 300,
        child: AsyncValueWidget<List<MatchResult>>(
          value: allAsync,
          onRetry: _refresh,
          data: (_) => const SizedBox.shrink(),
        ),
      ));
    } else if (hero == null && list.isEmpty) {
      children.add(const SizedBox(
        height: 320,
        child: EmptyState(
          icon: Icons.people_outline_rounded,
          message: 'No matches yet. Add more skills to your profile\nto find people to swap with.',
        ),
      ));
    } else {
      if (hero != null) {
        children
          ..add(_HeroCard(match: hero))
          ..add(const SizedBox(height: 20));
      }
      children.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              bestTab ? 'Swaps that work both ways' : 'More people for you',
              style: AppText.h2(),
            ),
            GestureDetector(
              onTap: () => context.go('/search'),
              child: Text(
                'Filter',
                style: AppText.body(14, weight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
      children.add(const SizedBox(height: 12));
      if (list.isEmpty) {
        children.add(Text(
          'No one else here yet — check back soon.',
          style: AppText.bodyText(color: AppColors.textSecondary),
        ));
      } else {
        for (var i = 0; i < list.length; i++) {
          if (i > 0) children.add(const SizedBox(height: 12));
          children.add(_MatchCard(match: list[i]));
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenX,
            top,
            AppSpacing.screenX,
            AppSpacing.scrollBottom,
          ),
          children: children,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.hasPending,
    required this.onBell,
    required this.onAvatar,
  });

  final String? name;
  final bool hasPending;
  final VoidCallback onBell;
  final VoidCallback onAvatar;

  @override
  Widget build(BuildContext context) {
    final greeting = name == null
        ? greetingFor(DateTime.now())
        : '${greetingFor(DateTime.now())}, ${firstName(name!)}';
    final initials = SwapAvatar.initialsOf(name ?? '');
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text('Discover', style: AppText.h1()),
            ],
          ),
        ),
        IconSquareButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Requests',
          badge: hasPending,
          onPressed: onBell,
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: 'My profile',
          child: GestureDetector(
            onTap: onAvatar,
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                initials,
                style: AppText.body(15, weight: FontWeight.w700, color: AppColors.accent),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _skillsLabel(List<Skill> skills) {
  if (skills.isEmpty) return '';
  if (skills.length == 1) return skills.first.name;
  return '${skills.first.name} +${skills.length - 1}';
}

String _ratingMeta(MatchResult m) {
  final u = m.user;
  final parts = <String>[];
  final total = u.totalRatings ?? 0;
  parts.add(total > 0 ? '★ ${(u.averageRating ?? 0).toStringAsFixed(1)}' : 'New');
  if (u.city != null && u.city!.isNotEmpty) parts.add(u.city!);
  return parts.join(' · ');
}

String _heroMeta(MatchResult m) {
  final total = m.user.totalRatings ?? 0;
  if (total == 0) return 'New to skillswap';
  return '${(m.user.averageRating ?? 0).toStringAsFixed(1)} · $total ${total == 1 ? 'review' : 'reviews'}';
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.match});

  final MatchResult match;

  @override
  Widget build(BuildContext context) {
    final u = match.user;
    final first = firstName(u.name);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.heroCard),
      child: Container(
        color: AppColors.ink,
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            const Positioned(
              right: -90,
              top: -90,
              child: DecorRings(
                size: 220,
                radii: [100, 66],
                color: AppColors.inkDecorLine,
                strokeWidth: 1,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SwapIcon(size: 13, color: AppColors.ink, strokeWidth: 2.6),
                          const SizedBox(width: 6),
                          Text(
                            'MUTUAL MATCH',
                            style: AppText.body(
                              12,
                              weight: FontWeight.w700,
                              spacing: 0.3,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (u.city != null && u.city!.isNotEmpty)
                      Text(u.city!, style: AppText.body(13, color: AppColors.onDarkTertiary)),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    SwapAvatar(name: u.name, seed: u.id, size: 60),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.display(
                              24,
                              weight: FontWeight.w700,
                              spacing: -0.5,
                              color: AppColors.onDarkPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if ((u.totalRatings ?? 0) > 0) ...[
                                const Icon(Icons.star_rounded, size: 15, color: AppColors.starOnDark),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  _heroMeta(match),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body(14, color: AppColors.onDarkSecondary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _SwapTile(
                        caption: '$first teaches you',
                        value: _skillsLabel(match.skillsTheyCanTeachYou),
                        valueColor: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.inkBorder, width: 1.5),
                      ),
                      child: const SwapIcon(size: 16, color: AppColors.onDarkPrimary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SwapTile(
                        caption: 'You teach $first',
                        value: _skillsLabel(match.skillsYouCanTeachThem),
                        valueColor: AppColors.lilac,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SecondaryButton(
                  label: 'View profile & swap',
                  icon: Icons.arrow_forward_rounded,
                  height: 52,
                  foreground: AppColors.ink,
                  fill: AppColors.paper,
                  onPressed: () => context.push('/matches/${u.id}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwapTile extends StatelessWidget {
  const _SwapTile({required this.caption, required this.value, required this.valueColor});

  final String caption;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.inkRaised,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(12, color: AppColors.onDarkTertiary),
          ),
          const SizedBox(height: 3),
          Text(
            value.isEmpty ? '—' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(17, weight: FontWeight.w700, color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final MatchResult match;

  @override
  Widget build(BuildContext context) {
    final u = match.user;
    final teach = _skillsLabel(match.skillsTheyCanTeachYou);
    final learn = _skillsLabel(match.skillsYouCanTeachThem);
    return AppCard(
      onTap: () => context.push('/matches/${u.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SwapAvatar(name: u.name, seed: u.id, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.personName(),
                    ),
                    const SizedBox(height: 2),
                    StarText(
                      _ratingMeta(match),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.meta(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              match.isMutual ? const MutualBadge() : const OneWayBadge(),
            ],
          ),
          if (teach.isNotEmpty || learn.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (teach.isNotEmpty) SkillTag(prefix: 'Teaches you', name: teach, teach: true),
                if (learn.isNotEmpty) SkillTag(prefix: 'Learns your', name: learn, teach: false),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
