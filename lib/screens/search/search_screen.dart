import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/enums.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/star_text.dart';
import '../../core/widgets/swap_avatar.dart';
import '../../core/widgets/toggle_switch.dart';
import '../../models/user.dart';
import '../../providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _searchController;
  late final TextEditingController _cityController;
  Timer? _debounce;
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    final f = ref.read(userSearchFiltersProvider);
    _searchController = TextEditingController(text: f.skillName ?? '');
    _cityController = TextEditingController(text: f.city ?? '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _update(UserSearchFilters Function(UserSearchFilters f) change) {
    final n = ref.read(userSearchFiltersProvider.notifier);
    n.state = change(n.state);
  }

  void _debounced(UserSearchFilters Function(UserSearchFilters f) change) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _update(change);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(userSearchFiltersProvider);
    final category = ref.watch(searchCategoryProvider);
    final results = ref.watch(userSearchResultsProvider);
    final top = MediaQuery.of(context).padding.top + 8;

    final titleBase = (filters.skillName != null && filters.skillName!.isNotEmpty)
        ? '${filters.skillName} teachers'
        : category != null
            ? '${category.label} teachers'
            : 'People to swap with';
    final title = (filters.city != null && filters.city!.isNotEmpty)
        ? '$titleBase in ${filters.city}'
        : titleBase;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(userSearchResultsProvider),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenX,
            top,
            AppSpacing.screenX,
            AppSpacing.scrollBottom,
          ),
          children: [
            const SizedBox(height: 4),
            Text('Search', style: AppText.h1()),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.inputLarge),
                      border: Border.all(color: AppColors.ink, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 20, color: AppColors.ink),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            cursorColor: AppColors.ink,
                            style: AppText.body(16, weight: FontWeight.w600, color: AppColors.ink),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              hintText: 'Skills, people, cities',
                              hintStyle: AppText.body(16, color: AppColors.textSecondary),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (q) => _debounced(
                              (f) => f.copyWith(skillName: q.trim().isEmpty ? null : q.trim()),
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              _update((f) => f.copyWith(skillName: null));
                              setState(() {});
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Semantics(
                  button: true,
                  label: 'Filters',
                  child: GestureDetector(
                    onTap: () => setState(() => _showFilters = !_showFilters),
                    child: Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(AppRadius.inputLarge),
                      ),
                      child: const Icon(Icons.tune_rounded, size: 21, color: AppColors.accent),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  FilterChipPill(
                    label: 'All',
                    selected: category == null,
                    onTap: () => ref.read(searchCategoryProvider.notifier).state = null,
                  ),
                  for (final c in SkillCategory.values)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChipPill(
                        label: c.label,
                        selected: category == c,
                        onTap: () => ref.read(searchCategoryProvider.notifier).state = c,
                      ),
                    ),
                ],
              ),
            ),
            if (_showFilters) ...[
              const SizedBox(height: 18),
              _FilterCard(
                filters: filters,
                cityController: _cityController,
                onCity: (v) => _debounced((f) => f.copyWith(city: v.trim().isEmpty ? null : v.trim())),
                onMinRating: (v) => _update((f) => f.copyWith(minRating: v)),
                onLevel: (v) => _update((f) => f.copyWith(level: v)),
                onAvailable: (v) => _update((f) => f.copyWith(availableOnly: v ? true : null)),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.h2(),
                  ),
                ),
                if (results.hasValue)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '${results.value!.length} found',
                      style: AppText.body(14, color: AppColors.textSecondary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              child: results.when(
                data: (users) {
                  if (users.isEmpty) {
                    return const SizedBox(
                      height: 260,
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        message: 'No one matches these filters yet.',
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < users.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _UserCard(user: users[i]),
                      ],
                    ],
                  );
                },
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.6)),
                ),
                error: (e, _) => SizedBox(
                  height: 260,
                  child: AsyncValueWidget<List<User>>(
                    value: AsyncError<List<User>>(e, StackTrace.empty),
                    onRetry: () => ref.invalidate(userSearchResultsProvider),
                    data: (_) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.filters,
    required this.cityController,
    required this.onCity,
    required this.onMinRating,
    required this.onLevel,
    required this.onAvailable,
  });

  final UserSearchFilters filters;
  final TextEditingController cityController;
  final ValueChanged<String> onCity;
  final ValueChanged<double?> onMinRating;
  final ValueChanged<SkillLevel?> onLevel;
  final ValueChanged<bool> onAvailable;

  static const _ratingOptions = <double?>[null, 3.0, 3.5, 4.0, 4.5];

  @override
  Widget build(BuildContext context) {
    final levels = SkillLevel.values;
    final selectedLevel = filters.level == null ? -1 : levels.indexOf(filters.level!);
    final rating = filters.minRating;
    final available = filters.availableOnly == true;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _FieldBlock(
                  label: 'CITY',
                  child: TextField(
                    controller: cityController,
                    onChanged: onCity,
                    cursorColor: AppColors.ink,
                    style: AppText.body(15, weight: FontWeight.w600, color: AppColors.ink),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Any city',
                      hintStyle: AppText.body(15, color: AppColors.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      fillColor: AppColors.fieldBg,
                      border: _border(AppColors.inputBorder),
                      enabledBorder: _border(AppColors.inputBorder),
                      focusedBorder: _border(AppColors.ink),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FieldBlock(
                  label: 'MIN RATING',
                  child: PopupMenuButton<double?>(
                    tooltip: 'Minimum rating',
                    initialValue: rating,
                    onSelected: onMinRating,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    itemBuilder: (_) => [
                      for (final o in _ratingOptions)
                        PopupMenuItem<double?>(
                          value: o,
                          child: StarText(
                            o == null ? 'Any rating' : '★ ${o.toStringAsFixed(1)}+',
                            style: AppText.body(15, weight: FontWeight.w600, color: AppColors.ink),
                          ),
                        ),
                    ],
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.fieldBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.inputBorder, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StarText(
                            rating == null ? 'Any' : '★ ${rating.toStringAsFixed(1)}+',
                            style: AppText.body(15, weight: FontWeight.w600, color: AppColors.ink),
                          ),
                          const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.ink),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FieldBlock(
            label: 'LEVEL',
            child: SegmentedTabs(
              labels: [for (final l in levels) l.label],
              selected: selectedLevel,
              small: true,
              trackColor: AppColors.sunken,
              onChanged: (i) => onLevel(selectedLevel == i ? null : levels[i]),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onAvailable(!available),
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Has open slots this week',
                    style: AppText.body(15, weight: FontWeight.w600, color: AppColors.ink),
                  ),
                  ToggleSwitch(value: available),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: 1.5),
      );
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.body(12, weight: FontWeight.w600, spacing: 0.4, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final rated = (user.totalRatings ?? 0) > 0;
    final meta = <String>[
      if (rated) '★ ${(user.averageRating ?? 0).toStringAsFixed(1)} (${user.totalRatings})' else 'No ratings yet',
      if (user.city != null && user.city!.isNotEmpty) user.city!,
    ].join(' · ');
    return AppCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('/matches/${user.id}'),
      child: Row(
        children: [
          SwapAvatar(name: user.name, seed: user.id, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.personName(),
                ),
                const SizedBox(height: 4),
                StarText(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.meta()),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF9A99A3)),
        ],
      ),
    );
  }
}
