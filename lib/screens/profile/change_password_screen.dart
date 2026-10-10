import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/auth_error_banner.dart';
import '../../core/widgets/sub_page.dart';
import '../../providers/core_providers.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentPasswordController.text.trim();
    final next = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    String? problem;
    if (current.isEmpty) {
      problem = 'Current password is required.';
    } else if (next.trim().isEmpty) {
      problem = 'New password is required.';
    } else if (confirm.trim().isEmpty) {
      problem = 'Confirm password is required.';
    } else if (next.length < 6) {
      problem = 'New password must be at least 6 characters.';
    } else if (next != confirm) {
      problem = 'New passwords do not match.';
    } else if (next.trim() == current) {
      problem = 'New password must be different from the current password.';
    }
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).changePassword(
            currentPassword: current,
            newPassword: next.trim(),
          );
      if (mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed.')),
        );
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
    return SubPage(
      title: 'Change password',
      bottomBar: PrimaryButton(
        label: 'Change password',
        loading: _submitting,
        onPressed: _submit,
      ),
      children: [
        if (_error != null) ...[
          AuthErrorBanner(_error!),
          const SizedBox(height: 16),
        ],
        LabeledField(
          label: 'Current password',
          controller: _currentPasswordController,
          obscure: true,
          enabled: !_submitting,
          fill: Colors.white,
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'New password',
          controller: _newPasswordController,
          obscure: true,
          enabled: !_submitting,
          fill: Colors.white,
          trailingLabel: 'At least 6 characters',
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Confirm new password',
          controller: _confirmPasswordController,
          obscure: true,
          enabled: !_submitting,
          fill: Colors.white,
        ),
      ],
    );
  }
}
