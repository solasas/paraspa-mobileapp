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
import '../../core/widgets/star_rating.dart';
import '../../core/widgets/sticky_action_bar.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/swap_avatar.dart';
import '../../core/widgets/swap_icon.dart';
import '../../models/availability.dart';
import '../../models/match_result.dart';
import '../../models/rating.dart';
import '../../providers/availability_provider.dart';
import '../../providers/matches_provider.dart';
import '../../providers/ratings_provider.dart';

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailProvider(userId));
    final name = matchAsync.valueOrNull?.user.name;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: AsyncValueWidget<MatchResult>(
        value: matchAsync,
        onRetry: () => ref.invalidate(matchDetailProvider(userId)),
        showBack: true,
        data: (match) => _MatchDetailBody(match: match),
      ),
      bottomNavigationBar: matchAsync.hasValue
          ? StickyActionBar(
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Message ${name ?? ''}',
                    child: GestureDetector(
                      onTap: () => context.push('/messages/$userId'),
                      child: Container(
                        width: 58,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 22,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Request swap',
                      leading: const SwapIcon(size: 20, color: AppColors.accent, strokeWidth: 2.4),
                      onPressed: () => context.push('/matches/$userId/request'),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _MatchDetailBody extends ConsumerWidget {
  const _MatchDetailBody({required this.match});

  final MatchResult match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = match.user;
    final first = firstName(u.name);
    final summary = ref.watch(userRatingSummaryProvider(u.id)).valueOrNull;
    final ratings = ref.watch(userRatingsProvider(u.id)).valueOrNull ?? const <Rating>[];
    final availability = ref.watch(userAvailabilityProvider(u.id));

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _Header(match: match),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenX),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SwapCard(match: match, first: first),
              const SizedBox(height: 16),
              _RatingCard(
                average: summary?.averageStars ?? u.averageRating ?? 0,
                total: summary?.totalRatings ?? u.totalRatings ?? 0,
                ratings: ratings,
              ),
              const SizedBox(height: 16),
              _AvailabilitySection(first: first, slots: availability),
              if (ratings.isNotEmpty) ...[
                const SizedBox(height: 16),
                _LatestReview(rating: _latest(ratings), userId: u.id, count: ratings.length),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static Rating _latest(List<Rating> list) {
    final sorted = [...list]..sort((a, b) {
        final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    return sorted.first;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.match});

  final MatchResult match;

  @override
  Widget build(BuildContext context) {
    final u = match.user;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.headerBottom)),
      child: Container(
        color: AppColors.lilac,
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 8, 20, 26),
        child: Stack(
          children: [
            const Positioned(
              right: -130,
              top: -48,
              child: DecorRings(
                size: 300,
                radii: [140, 95, 50],
                color: Color(0xFFB5A5F5),
                strokeWidth: 1.5,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const BackSquareButton(translucent: true),
                    Material(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/users/${u.id}/ratings'),
                        child: const SizedBox(
                          width: 46,
                          height: 46,
                          child: Icon(Icons.star_outline_rounded, size: 22, color: AppColors.ink),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        SwapAvatar.initialsOf(u.name),
                        style: AppText.display(32, color: AppColors.lilac),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (match.isMutual) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.ink,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'MUTUAL MATCH',
                                  style: AppText.badge(color: AppColors.accent),
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              u.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.detailTitle(),
                            ),
                            if (u.city != null && u.city!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                u.city!,
                                style: AppText.body(14, color: const Color(0xFF3A3550)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (u.bio != null && u.bio!.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    u.bio!,
                    style: AppText.body(15, height: 1.5, color: const Color(0xFF2A2540)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SwapCard extends StatelessWidget {
  const _SwapCard({required this.match, required this.first});

  final MatchResult match;
  final String first;

  @override
  Widget build(BuildContext context) {
    final teach = match.skillsTheyCanTeachYou;
    final learn = match.skillsYouCanTeachThem;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.sectionCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your swap with $first', style: AppText.cardHeading(color: AppColors.onDarkPrimary)),
          const SizedBox(height: 14),
          if (teach.isEmpty && learn.isEmpty)
            Text(
              'No overlapping skills yet.',
              style: AppText.body(14, color: AppColors.onDarkTertiary),
            ),
          for (final s in teach)
            _SwapRow(
              icon: Icons.arrow_downward_rounded,
              iconBg: AppColors.accent,
              caption: '$first can teach you',
              name: s.name,
            ),
          if (teach.isNotEmpty && learn.isNotEmpty) const SizedBox(height: 8),
          for (final s in learn)
            _SwapRow(
              icon: Icons.arrow_upward_rounded,
              iconBg: AppColors.lilac,
              caption: 'You can teach $first',
              name: s.name,
            ),
        ],
      ),
    );
  }
}

class _SwapRow extends StatelessWidget {
  const _SwapRow({
    required this.icon,
    required this.iconBg,
    required this.caption,
    required this.name,
  });

  final IconData icon;
  final Color iconBg;
  final String caption;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inkRaised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, size: 18, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(caption, style: AppText.body(12, color: AppColors.onDarkTertiary)),
                Text(
                  name,
                  style: AppText.body(16, weight: FontWeight.w700, color: AppColors.onDarkPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.average, required this.total, required this.ratings});

  final double average;
  final int total;
  final List<Rating> ratings;

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return AppCard(
        radius: AppRadius.sectionCard,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.star_border_rounded, size: 26, color: AppColors.starOnLight),
            const SizedBox(width: 12),
            Text('No ratings yet', style: AppText.body(15, weight: FontWeight.w600, color: AppColors.ink)),
          ],
        ),
      );
    }
    final counts = {for (var s = 1; s <= 5; s++) s: 0};
    for (final r in ratings) {
      counts[r.stars.clamp(1, 5)] = counts[r.stars.clamp(1, 5)]! + 1;
    }
    final denom = ratings.isEmpty ? 1 : ratings.length;
    return AppCard(
      radius: AppRadius.sectionCard,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Column(
              children: [
                Text(average.toStringAsFixed(1), style: AppText.ratingAverage()),
                const SizedBox(height: 4),
                StarRatingDisplay(stars: average, size: 15),
                const SizedBox(height: 4),
                Text(
                  '$total ${total == 1 ? 'review' : 'reviews'}',
                  style: AppText.body(12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                for (var s = 5; s >= 1; s--)
                  Padding(
                    padding: EdgeInsets.only(bottom: s == 1 ? 0 : 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 8,
                          child: Text('$s', style: AppText.body(12, color: AppColors.textSecondary)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              height: 7,
                              color: AppColors.sunken,
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: counts[s]! / denom,
                                child: Container(color: AppColors.ink),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 18,
                          child: Text(
                            '${counts[s]}',
                            textAlign: TextAlign.right,
                            style: AppText.body(12, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilitySection extends StatelessWidget {
  const _AvailabilitySection({required this.first, required this.slots});

  final String first;
  final AsyncValue<List<Availability>> slots;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("When $first's free", style: AppText.cardHeading()),
        const SizedBox(height: 10),
        slots.when(
          data: (list) {
            if (list.isEmpty) {
              return Text(
                'No availability listed',
                style: AppText.body(14, color: AppColors.textSecondary),
              );
            }
            return Row(
              children: [
                for (var i = 0; i < WeekDay.values.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(child: _DayCell(day: WeekDay.values[i], slots: list)),
                ],
              ],
            );
          },
          loading: () => const SizedBox(height: 58),
          error: (_, _) => Text(
            'Couldn’t load availability',
            style: AppText.body(13, color: AppColors.danger),
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.slots});

  final WeekDay day;
  final List<Availability> slots;

  @override
  Widget build(BuildContext context) {
    final mine = slots.where((s) => s.dayOfWeek == day).toList();
    final free = mine.isNotEmpty;
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: free ? AppColors.accent : AppColors.busyCell,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day.label.substring(0, 2),
            style: AppText.body(
              12,
              weight: FontWeight.w600,
              color: free ? AppColors.ink : AppColors.busyCellText,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              free ? compactRange(mine.first.startTime, mine.first.endTime) : '—',
              style: AppText.body(11, color: free ? AppColors.ink : AppColors.busyCellText),
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestReview extends StatelessWidget {
  const _LatestReview({required this.rating, required this.userId, required this.count});

  final Rating rating;
  final int userId;
  final int count;

  @override
  Widget build(BuildContext context) {
    final by = rating.ratedBy;
    final parts = by.name.trim().split(RegExp(r'\s+'));
    final shortName = parts.length > 1 ? '${parts.first} ${parts.last[0]}.' : parts.first;
    final session = rating.session;
    return AppCard(
      radius: 22,
      onTap: () => context.push('/users/$userId/ratings'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SwapAvatar(name: by.name, seed: by.id, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shortName,
                      style: AppText.body(14, weight: FontWeight.w700, color: AppColors.ink),
                    ),
                    if (session != null)
                      Text(
                        'Swapped ${session.exchange.offeredSkill.name} for ${session.exchange.wantedSkill.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(12, color: AppColors.textSecondary),
                      )
                    else
                      Text(
                        count > 1 ? 'Latest of $count reviews' : 'Latest review',
                        style: AppText.body(12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              StarRatingDisplay(stars: rating.stars.toDouble(), size: 13),
            ],
          ),
          if (rating.review != null && rating.review!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '“${rating.review}”',
              style: AppText.body(14, height: 1.5, color: AppColors.textBody),
            ),
          ],
        ],
      ),
    );
  }
}
