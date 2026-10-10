import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/enums.dart';
import '../models/user.dart';
import 'core_providers.dart';

part 'search_provider.freezed.dart';

@freezed
class UserSearchFilters with _$UserSearchFilters {
  const factory UserSearchFilters({
    String? skillName,
    String? city,
    SkillLevel? level,
    double? minRating,
    bool? availableOnly,
  }) = _UserSearchFilters;
}

final userSearchFiltersProvider = StateProvider<UserSearchFilters>((ref) {
  return const UserSearchFilters();
});

/// Selected category chip on the Search screen. The users/search endpoint has
/// no category parameter, so a category is resolved client-side by searching
/// each skill in that category and merging the results.
final searchCategoryProvider = StateProvider<SkillCategory?>((ref) => null);

final userSearchResultsProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final filters = ref.watch(userSearchFiltersProvider);
  final category = ref.watch(searchCategoryProvider);
  final users = ref.watch(usersRepositoryProvider);

  Future<List<User>> search(String? skillName) => users.search(
        skillName: skillName,
        city: filters.city,
        level: filters.level,
        minRating: filters.minRating,
        availableOnly: filters.availableOnly,
      );

  final typed = filters.skillName;
  if (category == null || (typed != null && typed.isNotEmpty)) {
    return search(typed);
  }

  final skills = await ref.watch(skillsRepositoryProvider).getSkills(category: category);
  if (skills.isEmpty) return const <User>[];
  final batches = await Future.wait(skills.take(12).map((s) => search(s.name)));
  final seen = <int>{};
  return [
    for (final batch in batches)
      for (final user in batch)
        if (seen.add(user.id)) user,
  ];
});
