import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/auth_error_banner.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/toggle_switch.dart';
import '../../models/skill.dart';
import '../../providers/core_providers.dart';
import '../../providers/profile_provider.dart';
import '../../providers/skills_provider.dart';

class AddSkillScreen extends ConsumerStatefulWidget {
  const AddSkillScreen({super.key});

  @override
  ConsumerState<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends ConsumerState<AddSkillScreen> {
  SkillCategory? _filterCategory;
  int? _selectedSkillId;
  SkillType _type = SkillType.teach;
  SkillLevel _level = SkillLevel.beginner;
  bool _creatingNew = false;

  final _newSkillNameController = TextEditingController();
  final _newSkillDescController = TextEditingController();
  SkillCategory _newSkillCategory = SkillCategory.other;

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _newSkillNameController.dispose();
    _newSkillDescController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      int skillId;
      if (_creatingNew) {
        if (_newSkillNameController.text.trim().isEmpty) {
          setState(() {
            _error = 'Enter a name for the new skill.';
            _submitting = false;
          });
          return;
        }
        final created = await ref
            .read(skillsRepositoryProvider)
            .createSkill(
              name: _newSkillNameController.text.trim(),
              category: _newSkillCategory,
              description: _newSkillDescController.text.trim(),
            );
        skillId = created.id;
      } else {
        if (_selectedSkillId == null) {
          setState(() {
            _error = 'Choose a skill.';
            _submitting = false;
          });
          return;
        }
        skillId = _selectedSkillId!;
      }

      await ref
          .read(profileRepositoryProvider)
          .addSkill(skillId: skillId, type: _type, level: _level);
      ref.invalidate(mySkillsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Skill added!')));
        popOrGo(context, '/profile');
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skillsAsync = ref.watch(skillsByCategoryProvider(_filterCategory));

    return SubPage(
      title: 'Add a skill',
      bottomBar: PrimaryButton(
        label: 'Add skill',
        icon: Icons.add_rounded,
        loading: _submitting,
        onPressed: _submit,
      ),
      children: [
        if (_error != null) ...[
          AuthErrorBanner(_error!),
          const SizedBox(height: 16),
        ],
        Text('I WANT TO…', style: AppText.overline()),
        const SizedBox(height: 8),
        SegmentedTabs(
          labels: const ['Teach it', 'Learn it'],
          selected: _type == SkillType.teach ? 0 : 1,
          onChanged: (i) => setState(
            () => _type = i == 0 ? SkillType.teach : SkillType.learn,
          ),
        ),
        const SizedBox(height: 20),
        Text('MY LEVEL', style: AppText.overline()),
        const SizedBox(height: 8),
        SegmentedTabs(
          labels: [for (final l in SkillLevel.values) l.label],
          selected: SkillLevel.values.indexOf(_level),
          small: true,
          onChanged: (i) => setState(() => _level = SkillLevel.values[i]),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _creatingNew = !_creatingNew),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create a new skill',
                      style: AppText.body(15, weight: FontWeight.w600, color: AppColors.ink),
                    ),
                    Text(
                      "Turn on if it's not in the list",
                      style: AppText.body(13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ToggleSwitch(value: _creatingNew),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_creatingNew) ...[
          LabeledField(
            label: 'Skill name',
            controller: _newSkillNameController,
            fill: Colors.white,
          ),
          const SizedBox(height: 16),
          Text('CATEGORY', style: AppText.overline()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in SkillCategory.values)
                FilterChipPill(
                  label: c.label,
                  selected: _newSkillCategory == c,
                  onTap: () => setState(() => _newSkillCategory = c),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Description (optional)',
            controller: _newSkillDescController,
            maxLines: 2,
            fill: Colors.white,
          ),
        ] else ...[
          Text('CATEGORY', style: AppText.overline()),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                FilterChipPill(
                  label: 'All',
                  selected: _filterCategory == null,
                  onTap: () => setState(() {
                    _filterCategory = null;
                    _selectedSkillId = null;
                  }),
                ),
                for (final c in SkillCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChipPill(
                      label: c.label,
                      selected: _filterCategory == c,
                      onTap: () => setState(() {
                        _filterCategory = c;
                        _selectedSkillId = null;
                      }),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('SKILL', style: AppText.overline()),
          const SizedBox(height: 8),
          AsyncValueWidget<List<Skill>>(
            value: skillsAsync,
            onRetry: () => ref.invalidate(skillsByCategoryProvider(_filterCategory)),
            loadingBuilder: (_) => const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
            ),
            data: (skills) {
              if (skills.isEmpty) {
                return Text(
                  'No skills in this category yet — create a new one above.',
                  style: AppText.body(14, color: AppColors.textSecondary),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in skills)
                    FilterChipPill(
                      label: s.name,
                      selected: _selectedSkillId == s.id,
                      onTap: () => setState(() => _selectedSkillId = s.id),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
