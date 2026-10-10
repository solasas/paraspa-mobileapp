import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/star_rating.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/swap_avatar.dart';
import '../../models/rating.dart';
import '../../providers/ratings_provider.dart';

class UserRatingsScreen extends ConsumerWidget {
  const UserRatingsScreen({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(userRatingSummaryProvider(userId));
    final ratingsAsync = ref.watch(userRatingsProvider(userId));

    return SubPage(
      title: 'Reputation',
      onRefresh: () async {
        ref.invalidate(userRatingSummaryProvider(userId));
        ref.invalidate(userRatingsProvider(userId));
      },
      children: [
        summaryAsync.when(
          data: (summary) => AppCard(
            radius: 26,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(summary.averageStars.toStringAsFixed(1), style: AppText.ratingAverage()),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StarRatingDisplay(stars: summary.averageStars, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.totalRatings} rating${summary.totalRatings == 1 ? '' : 's'}',
                      style: AppText.body(13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.6)),
          ),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 18),
        AsyncValueWidget<List<Rating>>(
          value: ratingsAsync,
          onRetry: () => ref.invalidate(userRatingsProvider(userId)),
          loadingBuilder: (_) => const SizedBox.shrink(),
          data: (ratings) {
            if (ratings.isEmpty) {
              return const SizedBox(
                height: 240,
                child: EmptyState(icon: Icons.star_border_rounded, message: 'No reviews yet.'),
              );
            }
            return Column(
              children: [
                for (final r in ratings) ...[
                  _ReviewCard(rating: r),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.rating});

  final Rating rating;

  @override
  Widget build(BuildContext context) {
    final r = rating;
    final review = r.review?.trim() ?? '';
    return AppCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SwapAvatar(name: r.ratedBy.name, seed: r.ratedBy.id, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.ratedBy.name,
                      style: AppText.body(14, weight: FontWeight.w700, color: AppColors.ink),
                    ),
                    if (r.createdAt != null)
                      Text(
                        DateFormat.yMMMd().format(r.createdAt!),
                        style: AppText.body(12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              StarRatingDisplay(stars: r.stars.toDouble(), size: 15),
            ],
          ),
          if (review.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review, style: AppText.body(14, height: 1.5, color: AppColors.textBody)),
          ],
        ],
      ),
    );
  }
}
