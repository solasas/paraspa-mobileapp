import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/enums.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_version_label.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/decor_rings.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/star_text.dart';
import '../../core/widgets/swap_avatar.dart';
import '../../models/user.dart';
import '../../models/user_skill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/availability_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/exchanges_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/sessions_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myProfileProvider);
          ref.invalidate(mySkillsProvider);
          ref.invalidate(myAvailabilityProvider);
          ref.invalidate(myRatingsProvider);
        },
        child: AsyncValueWidget<User>(
          value: profileAsync,
          onRetry: () => ref.invalidate(myProfileProvider),
          data: (user) => _ProfileBody(user: user),
        ),
      ),
    );
  }
}

Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('You will need to sign in again to continue.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Log out', style: TextStyle(color: AppColors.danger)),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await ref.read(authProvider.notifier).logout();
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.user});

  final User user;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  int _skillTab = 0;

  Future<void> _removeSkill(UserSkill us) async {
    try {
      await ref.read(profileRepositoryProvider).deleteSkill(us.id);
      ref.invalidate(mySkillsProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final top = MediaQuery.of(context).padding.top + 8;
    final skills = ref.watch(mySkillsProvider);
    final availability = ref.watch(myAvailabilityProvider).valueOrNull ?? const [];
    final reviewCount = ref.watch(myRatingsProvider).valueOrNull?.length ?? user.totalRatings ?? 0;
    final sessionsCount = ref.watch(mySessionsProvider).valueOrNull?.length;
    final swapsCount = _swaps(ref);

    final teach = _skillTab == 0;
    final shownSkills = (skills.valueOrNull ?? const <UserSkill>[])
        .where((s) => (s.type == SkillType.teach) == teach)
        .toList();

    final ratingValue = (user.totalRatings ?? 0) > 0
        ? (user.averageRating ?? 0).toStringAsFixed(1)
        : '—';
    final meta = [
      if (user.city != null && user.city!.isNotEmpty) user.city!,
      if ((user.totalRatings ?? 0) > 0)
        '★ $ratingValue from ${user.totalRatings} ${user.totalRatings == 1 ? 'review' : 'reviews'}'
      else
        'No reviews yet',
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.scrollBottom),
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.headerBottom)),
          child: Container(
            color: AppColors.ink,
            padding: EdgeInsets.fromLTRB(20, top, 20, 22),
            child: Stack(
              children: [
                const Positioned(
                  right: -110,
                  top: -68,
                  child: DecorRings(
                    size: 260,
                    radii: [120, 80],
                    color: AppColors.inkDecorLine,
                    strokeWidth: 1,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconSquareButton(
                        icon: Icons.edit_outlined,
                        onDark: true,
                        tooltip: 'Edit profile',
                        onPressed: () => context.push('/profile/edit'),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Text(
                            SwapAvatar.initialsOf(user.name),
                            style: AppText.display(30, color: AppColors.ink),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.display(
                                  28,
                                  spacing: -0.8,
                                  color: AppColors.onDarkPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              StarText(
                                meta,
                                starColor: AppColors.starOnDark,
                                style: AppText.body(14, color: AppColors.onDarkSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        user.bio!.trim(),
                        style: AppText.body(15, height: 1.5, color: const Color(0xFFD9D8E0)),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: _Stat(value: '${swapsCount ?? '–'}', label: 'Swaps')),
                        const SizedBox(width: 8),
                        Expanded(child: _Stat(value: '${sessionsCount ?? '–'}', label: 'Sessions')),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Stat(value: ratingValue, label: 'Rating', accent: true),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My skills', style: AppText.h2()),
                  SegmentedTabs(
                    labels: const ['I teach', 'I learn'],
                    selected: _skillTab,
                    small: true,
                    ink: true,
                    expand: false,
                    onChanged: (i) => setState(() => _skillTab = i),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (skills.isLoading && shownSkills.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                )
              else
                for (final us in shownSkills) ...[
                  _SkillRow(userSkill: us, onRemove: () => _removeSkill(us)),
                  const SizedBox(height: 8),
                ],
              if (!skills.isLoading && shownSkills.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    teach ? 'Nothing here yet — add what you can teach.' : 'Nothing here yet — add what you want to learn.',
                    style: AppText.body(14, color: AppColors.textSecondary),
                  ),
                ),
              SecondaryButton(
                label: 'Add a skill',
                icon: Icons.add_rounded,
                dashed: true,
                height: 52,
                radius: 18,
                onPressed: () => context.push('/profile/skills/add'),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weekly availability', style: AppText.h2()),
                  TextButton(
                    onPressed: () => context.push('/profile/availability'),
                    style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                    child: Text(
                      availability.isEmpty ? 'Add slot' : 'Manage',
                      style: AppText.body(14, weight: FontWeight.w700, color: AppColors.ink).copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (availability.isEmpty)
                Text(
                  'No availability set yet.',
                  style: AppText.body(14, color: AppColors.textSecondary),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in availability)
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              a.dayOfWeek.label.substring(0, 3),
                              style: AppText.body(14, weight: FontWeight.w700, color: AppColors.accent),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${trimTime(a.startTime)}–${trimTime(a.endTime)}',
                              style: AppText.body(14, color: AppColors.paper),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 18),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _AccountRow(
                      label: "Reviews I've received",
                      trailing: '$reviewCount',
                      onTap: () => context.push('/users/${user.id}/ratings'),
                    ),
                    _AccountRow(
                      label: 'Edit profile',
                      onTap: () => context.push('/profile/edit'),
                    ),
                    _AccountRow(
                      label: 'Change password',
                      onTap: () => context.push('/profile/change-password'),
                    ),
                    _AccountRow(
                      label: 'Log out',
                      danger: true,
                      last: true,
                      onTap: () => _confirmLogout(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Center(child: AppVersionLabel()),
            ],
          ),
        ),
      ],
    );
  }

  /// Accepted/completed swaps across both directions.
  int? _swaps(WidgetRef ref) {
    final received = ref.watch(receivedExchangesProvider).valueOrNull;
    final sent = ref.watch(sentExchangesProvider).valueOrNull;
    if (received == null && sent == null) return null;
    bool active(ExchangeStatus s) => s == ExchangeStatus.accepted || s == ExchangeStatus.completed;
    return [...?received, ...?sent].where((e) => active(e.status)).length;
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.accent = false});

  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inkRaised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppText.stat(color: accent ? AppColors.accent : AppColors.onDarkPrimary),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppText.body(12, color: AppColors.onDarkTertiary)),
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.userSkill, required this.onRemove});

  final UserSkill userSkill;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final teach = userSkill.type == SkillType.teach;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: teach ? AppColors.teachDot : AppColors.violetStrong,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userSkill.skill.name,
                  style: AppText.body(15, weight: FontWeight.w700, color: AppColors.ink),
                ),
                Text(
                  '${userSkill.skill.category.label} · ${userSkill.level.label}',
                  style: AppText.body(13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove skill',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 17, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.label,
    required this.onTap,
    this.trailing,
    this.danger = false,
    this.last = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final bool danger;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: AppColors.sunken)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppText.body(
                  15,
                  weight: FontWeight.w600,
                  color: danger ? AppColors.danger : AppColors.ink,
                ),
              ),
            ),
            if (trailing != null)
              Text(trailing!, style: AppText.body(15, color: AppColors.textSecondary)),
            if (!danger) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF9A99A3)),
            ],
          ],
        ),
      ),
    );
  }
}
