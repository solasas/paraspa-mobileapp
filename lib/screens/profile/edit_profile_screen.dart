import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/auth_error_banner.dart';
import '../../core/widgets/sub_page.dart';
import '../../models/user.dart';
import '../../providers/core_providers.dart';
import '../../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  bool _initialized = false;
  bool _submitting = false;
  String? _error;

  void _initFrom(User user) {
    if (_initialized) return;
    _nameController.text = user.name;
    _bioController.text = user.bio ?? '';
    _cityController.text = user.city ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).updateMe(
            name: _nameController.text.trim(),
            bio: _bioController.text.trim(),
            city: _cityController.text.trim(),
          );
      ref.invalidate(myProfileProvider);
      if (mounted) popOrGo(context, '/profile');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

    return profileAsync.when(
      loading: () => const SubPage(
        title: 'Edit profile',
        children: [
          SizedBox(height: 200, child: Center(child: CircularProgressIndicator(strokeWidth: 2.6))),
        ],
      ),
      error: (e, _) => SubPage(
        title: 'Edit profile',
        children: [
          SizedBox(
            height: 260,
            child: AsyncValueWidget<User>(
              value: AsyncError<User>(e, StackTrace.empty),
              onRetry: () => ref.invalidate(myProfileProvider),
              data: (_) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      data: (user) {
        _initFrom(user);
        return SubPage(
          title: 'Edit profile',
          bottomBar: PrimaryButton(label: 'Save', loading: _submitting, onPressed: _submit),
          children: [
            if (_error != null) ...[
              AuthErrorBanner(_error!),
              const SizedBox(height: 16),
            ],
            LabeledField(label: 'Name', controller: _nameController, fill: Colors.white),
            const SizedBox(height: 16),
            LabeledField(label: 'City', controller: _cityController, fill: Colors.white),
            const SizedBox(height: 16),
            LabeledField(
              label: 'Bio',
              controller: _bioController,
              maxLines: 4,
              fill: Colors.white,
              hint: 'What do you teach, and what do you want to learn?',
            ),
          ],
        );
      },
    );
  }
}
