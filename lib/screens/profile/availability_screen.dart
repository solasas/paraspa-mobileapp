import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/enums.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/sub_page.dart';
import '../../models/availability.dart';
import '../../providers/availability_provider.dart';
import '../../providers/core_providers.dart';

class AvailabilityScreen extends ConsumerWidget {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(myAvailabilityProvider);

    return SubPage(
      title: 'My availability',
      subtitle: 'People see these slots when they request a swap.',
      onRefresh: () async => ref.invalidate(myAvailabilityProvider),
      bottomBar: PrimaryButton(
        label: 'Add slot',
        icon: Icons.add_rounded,
        onPressed: () => _showAddSlotSheet(context, ref),
      ),
      children: [
        AsyncValueWidget<List<Availability>>(
          value: slotsAsync,
          onRetry: () => ref.invalidate(myAvailabilityProvider),
          loadingBuilder: (_) => const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.6)),
          ),
          data: (slots) {
            if (slots.isEmpty) {
              return const SizedBox(
                height: 280,
                child: EmptyState(
                  icon: Icons.schedule_rounded,
                  message: 'No availability set yet.\nAdd a slot so partners know when you’re free.',
                ),
              );
            }
            return Column(
              children: [
                for (final day in WeekDay.values)
                  ..._daySection(context, ref, day, slots.where((s) => s.dayOfWeek == day).toList()),
              ],
            );
          },
        ),
      ],
    );
  }

  List<Widget> _daySection(BuildContext context, WidgetRef ref, WeekDay day, List<Availability> slots) {
    if (slots.isEmpty) return const [];
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 8),
          child: Text(day.label, style: AppText.cardHeading()),
        ),
      ),
      for (final slot in slots) ...[
        _SlotRow(slot: slot, onDelete: () => _deleteSlot(context, ref, slot.id)),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 8),
    ];
  }

  Future<void> _deleteSlot(BuildContext context, WidgetRef ref, int id) async {
    try {
      await ref.read(availabilityRepositoryProvider).removeAvailability(id);
      ref.invalidate(myAvailabilityProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability slot removed')),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _showAddSlotSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) => _AddSlotSheet(
        onAdd: (dayOfWeek, startTime, endTime) async {
          try {
            await ref.read(availabilityRepositoryProvider).addAvailability(
                  dayOfWeek: dayOfWeek,
                  startTime: startTime,
                  endTime: endTime,
                );
            ref.invalidate(myAvailabilityProvider);
            if (sheetContext.mounted) {
              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Availability added')),
              );
            }
          } on ApiException catch (e) {
            if (sheetContext.mounted) {
              ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(e.message)));
            }
          }
        },
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot, required this.onDelete});

  final Availability slot;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${trimTime(slot.startTime)} – ${trimTime(slot.endTime)}',
              style: AppText.body(15, weight: FontWeight.w700, color: AppColors.ink),
            ),
          ),
          IconButton(
            tooltip: 'Remove slot',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: onDelete,
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AddSlotSheet extends StatefulWidget {
  const _AddSlotSheet({required this.onAdd});

  final Future<void> Function(WeekDay, TimeOfDay, TimeOfDay) onAdd;

  @override
  State<_AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends State<_AddSlotSheet> {
  WeekDay _day = WeekDay.monday;
  TimeOfDay _start = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 20, minute: 0);
  bool _submitting = false;

  Future<void> _pick(bool start) async {
    final picked = await showTimePicker(context: context, initialTime: start ? _start : _end);
    if (picked != null) setState(() => start ? _start = picked : _end = picked);
  }

  Future<void> _submit() async {
    final startM = _start.hour * 60 + _start.minute;
    final endM = _end.hour * 60 + _end.minute;
    if (startM >= endM) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start time must be before end time')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onAdd(_day, _start, _end);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6D3CB),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Add a slot', style: AppText.sheetTitle()),
            const SizedBox(height: 18),
            Text('DAY', style: AppText.overline()),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < WeekDay.values.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _day = WeekDay.values[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _day == WeekDay.values[i] ? AppColors.ink : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: _day == WeekDay.values[i]
                              ? null
                              : Border.all(color: AppColors.inputBorder, width: 1.5),
                        ),
                        child: Text(
                          WeekDay.values[i].label.substring(0, 2),
                          style: AppText.body(
                            13,
                            weight: FontWeight.w700,
                            color: _day == WeekDay.values[i] ? AppColors.accent : AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _TimeField(label: 'START', time: _start, onTap: () => _pick(true))),
                const SizedBox(width: 10),
                Expanded(child: _TimeField(label: 'END', time: _end, onTap: () => _pick(false))),
              ],
            ),
            const SizedBox(height: 22),
            PrimaryButton(label: 'Add availability', loading: _submitting, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({required this.label, required this.time, required this.onTap});

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.overline()),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.fieldBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.inputBorder, width: 1.5),
            ),
            child: Text(
              time.format(context),
              style: AppText.body(15, weight: FontWeight.w600, color: AppColors.ink),
            ),
          ),
        ),
      ],
    );
  }
}
