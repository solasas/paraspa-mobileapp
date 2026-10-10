import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/auth_error_banner.dart';
import '../../core/widgets/day_picker.dart';
import '../../core/widgets/sub_page.dart';
import '../../providers/core_providers.dart';
import '../../providers/reschedule_provider.dart';

class ProposeRescheduleScreen extends ConsumerStatefulWidget {
  const ProposeRescheduleScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<ProposeRescheduleScreen> createState() => _ProposeRescheduleScreenState();
}

class _ProposeRescheduleScreenState extends ConsumerState<ProposeRescheduleScreen> {
  final _days = DayPicker.upcoming();
  int _dayIndex = 0;
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  final _reasonController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    final day = _days[_dayIndex];
    final proposed = DateTime(day.year, day.month, day.day, _time.hour, _time.minute);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(rescheduleRepositoryProvider).proposeReschedule(
            sessionId: widget.sessionId,
            proposedDateTime: proposed,
            reason: _reasonController.text.trim(),
          );
      invalidateRescheduleProviders(ref, widget.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reschedule proposal sent')),
        );
        popOrGo(context, '/sessions/${widget.sessionId}');
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
      title: 'Propose new time',
      subtitle: 'They’ll be asked to accept or keep the original.',
      bottomBar: PrimaryButton(
        label: 'Propose reschedule',
        icon: Icons.event_repeat_rounded,
        loading: _submitting,
        onPressed: _submit,
      ),
      children: [
        if (_error != null) ...[
          AuthErrorBanner(_error!),
          const SizedBox(height: 16),
        ],
        Text('DAY', style: AppText.overline()),
        const SizedBox(height: 8),
        DayPicker(
          days: _days,
          selected: _dayIndex,
          onChanged: (i) => setState(() => _dayIndex = i),
        ),
        const SizedBox(height: 20),
        Text('START', style: AppText.overline()),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickTime,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.inputBorder, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 20, color: AppColors.ink),
                const SizedBox(width: 10),
                Text(
                  _time.format(context),
                  style: AppText.body(16, weight: FontWeight.w600, color: AppColors.ink),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        LabeledField(
          label: 'Reason (optional)',
          controller: _reasonController,
          maxLines: 3,
          fill: Colors.white,
          hint: 'Why do you need to reschedule?',
        ),
      ],
    );
  }
}
