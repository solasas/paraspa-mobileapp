import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/enums.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/auth_error_banner.dart';
import '../../core/widgets/day_picker.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/swap_icon.dart';
import '../../models/session.dart';
import '../../models/skill_exchange.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/exchanges_provider.dart';
import '../../providers/sessions_provider.dart';

class ExchangeDetailScreen extends ConsumerStatefulWidget {
  const ExchangeDetailScreen({super.key, required this.exchangeId});

  final int exchangeId;

  @override
  ConsumerState<ExchangeDetailScreen> createState() => _ExchangeDetailScreenState();
}

class _ExchangeDetailScreenState extends ConsumerState<ExchangeDetailScreen> {
  bool _acting = false;

  Future<void> _act(Future<SkillExchange> Function() action) async {
    setState(() => _acting = true);
    try {
      await action();
      invalidateExchanges(ref);
      ref.invalidate(exchangeDetailProvider(widget.exchangeId));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exchangeAsync = ref.watch(exchangeDetailProvider(widget.exchangeId));
    final myId = ref.watch(authProvider).userId;
    final top = MediaQuery.of(context).padding.top + 8;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: AsyncValueWidget<SkillExchange>(
        value: exchangeAsync,
        onRetry: () => ref.invalidate(exchangeDetailProvider(widget.exchangeId)),
        showBack: true,
        data: (exchange) => _buildBody(context, exchange, myId, top),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SkillExchange exchange, int? myId, double top) {
    final isReceiver = exchange.receiver.id == myId;
    final isParticipant = isReceiver || exchange.requester.id == myId;
    final other = isReceiver ? exchange.requester : exchange.receiver;
    final repo = ref.read(exchangesRepositoryProvider);
    final canSchedule = isParticipant &&
        (exchange.status == ExchangeStatus.accepted ||
            exchange.status == ExchangeStatus.completed);
    final message = exchange.message?.trim() ?? '';

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(exchangeDetailProvider(widget.exchangeId));
        ref.invalidate(exchangeSessionsProvider(widget.exchangeId));
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, top, 20, 40),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const BackSquareButton(),
              StatusPill.exchange(exchange.status),
              Semantics(
                button: true,
                label: 'Chat with ${other.name}',
                child: Material(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push('/messages/${other.id}'),
                    child: const SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 20,
                        color: AppColors.paper,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Your exchange with ${other.name}',
            style: AppText.body(14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            children: [
              Text(exchange.offeredSkill.name, style: AppText.detailTitle().copyWith(fontSize: 32)),
              const SwapIcon(size: 26, color: AppColors.ink, strokeWidth: 2.4),
              Text(exchange.wantedSkill.name, style: AppText.detailTitle().copyWith(fontSize: 32)),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 16),
            AppCard(
              radius: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MESSAGE', style: AppText.overline()),
                  const SizedBox(height: 6),
                  Text('“$message”', style: AppText.body(15, height: 1.5, color: AppColors.ink)),
                ],
              ),
            ),
          ],
          if (isReceiver && exchange.status == ExchangeStatus.pending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InlineButton(
                    label: 'Decline',
                    onPressed: _acting ? null : () => _act(() => repo.reject(exchange.id)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InlineButton(
                    label: 'Accept',
                    filled: true,
                    onPressed: _acting ? null : () => _act(() => repo.accept(exchange.id)),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Text('Sessions', style: AppText.cardHeading()),
          const SizedBox(height: 10),
          Consumer(
            builder: (context, ref, _) {
              final sessionsAsync = ref.watch(exchangeSessionsProvider(exchange.id));
              return AsyncValueWidget<List<Session>>(
                value: sessionsAsync,
                onRetry: () => ref.invalidate(exchangeSessionsProvider(exchange.id)),
                loadingBuilder: (_) => const SizedBox(
                  height: 60,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                ),
                data: (sessions) => _SessionList(sessions: sessions),
              );
            },
          ),
          if (canSchedule) ...[
            const SizedBox(height: 18),
            _ScheduleCard(exchangeId: exchange.id, partnerName: other.name),
          ],
          if (isParticipant && exchange.status == ExchangeStatus.accepted) ...[
            const SizedBox(height: 18),
            SecondaryButton(
              label: 'Mark whole swap as complete',
              dashed: true,
              height: 50,
              foreground: AppColors.textBody,
              onPressed: _acting ? null : () => _act(() => repo.complete(exchange.id)),
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({required this.sessions});

  final List<Session> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No sessions scheduled yet.',
          style: AppText.body(14, color: AppColors.textSecondary),
        ),
      );
    }
    final now = DateTime.now();
    final upcoming = sessions
        .where((s) => s.status == SessionStatus.scheduled && s.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final nextId = upcoming.isEmpty ? null : upcoming.first.id;
    final ordered = [...sessions]..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return Column(
      children: [
        for (final s in ordered) ...[
          _SessionRow(session: s, highlight: s.id == nextId),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.highlight});

  final Session session;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final d = session.dateTime;
    final where = session.mode == SessionMode.online
        ? (session.meetLink?.isNotEmpty ?? false ? 'Online · link added' : 'Online')
        : (session.location?.isNotEmpty ?? false
            ? 'In person · ${session.location}'
            : 'In person');
    final fg = highlight ? AppColors.onDarkPrimary : AppColors.ink;
    final sub = highlight ? AppColors.onDarkSecondary : AppColors.textSecondary;

    Widget trailing;
    if (highlight) {
      trailing = Text(
        'UPCOMING',
        style: AppText.body(11, weight: FontWeight.w700, color: AppColors.accent),
      );
    } else if (session.status == SessionStatus.completed) {
      trailing = GestureDetector(
        onTap: () => context.push('/sessions/${session.id}/rate'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.lilac,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('Rate', style: AppText.body(13, weight: FontWeight.w700, color: AppColors.ink)),
        ),
      );
    } else {
      trailing = StatusPill.session(session.status);
    }

    return Material(
      color: highlight ? AppColors.ink : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/sessions/${session.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: highlight ? null : Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 50,
                decoration: BoxDecoration(
                  color: highlight ? AppColors.accent : AppColors.sunken,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekdayShort(d),
                      style: AppText.body(
                        10,
                        weight: FontWeight.w700,
                        color: highlight ? AppColors.ink : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      dayNum(d, pad: true),
                      style: AppText.display(19, height: 1, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hhmm(d)}, ${session.durationMinutes} min',
                      style: AppText.body(15, weight: FontWeight.w700, color: fg),
                    ),
                    Text(
                      where,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(13, color: sub),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends ConsumerStatefulWidget {
  const _ScheduleCard({required this.exchangeId, required this.partnerName});

  final int exchangeId;
  final String partnerName;

  @override
  ConsumerState<_ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends ConsumerState<_ScheduleCard> {
  late final List<DateTime> _days;
  int _dayIndex = 0;
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  int _durationIndex = 1;
  SessionMode _mode = SessionMode.online;
  final _linkController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  bool _submitting = false;
  String? _error;

  static const _durations = [30, 60, 90];

  @override
  void initState() {
    super.initState();
    _days = DayPicker.upcoming();
  }

  @override
  void dispose() {
    _linkController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (_mode == SessionMode.online && _linkController.text.trim().isEmpty) {
      setState(() => _error = 'Add a meeting link for an online session.');
      return;
    }
    if (_mode == SessionMode.offline && _locationController.text.trim().isEmpty) {
      setState(() => _error = 'Add a location for an in-person session.');
      return;
    }
    final day = _days[_dayIndex];
    final dateTime = DateTime(day.year, day.month, day.day, _time.hour, _time.minute);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(sessionsRepositoryProvider).createSession(
            exchangeId: widget.exchangeId,
            dateTime: dateTime,
            durationMinutes: _durations[_durationIndex],
            mode: _mode,
            meetLink: _mode == SessionMode.online ? _linkController.text.trim() : null,
            location: _mode == SessionMode.offline ? _locationController.text.trim() : null,
            notes: _notesController.text.trim(),
          );
      ref.invalidate(exchangeSessionsProvider(widget.exchangeId));
      ref.invalidate(mySessionsProvider);
      if (mounted) {
        _notesController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session scheduled — ${firstName(widget.partnerName)} notified')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schedule next session', style: AppText.h2().copyWith(letterSpacing: -0.3)),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('START', style: AppText.overline()),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.sunken,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          _time.format(context),
                          style: AppText.body(14, weight: FontWeight.w700, color: AppColors.ink),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LENGTH · MIN', style: AppText.overline()),
                    const SizedBox(height: 8),
                    SegmentedTabs(
                      labels: [for (final d in _durations) '$d'],
                      selected: _durationIndex,
                      small: true,
                      trackColor: AppColors.sunken,
                      onChanged: (i) => setState(() => _durationIndex = i),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ModeButton(
                  label: 'Online',
                  selected: _mode == SessionMode.online,
                  onTap: () => setState(() => _mode = SessionMode.online),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModeButton(
                  label: 'In person',
                  selected: _mode == SessionMode.offline,
                  onTap: () => setState(() => _mode = SessionMode.offline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_mode == SessionMode.online)
            LabeledField(
              label: 'Meeting link',
              controller: _linkController,
              keyboardType: TextInputType.url,
              hint: 'Paste a Meet or Zoom link',
            )
          else
            LabeledField(
              label: 'Where',
              controller: _locationController,
              hint: "Café, park, someone's place…",
            ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Notes',
            controller: _notesController,
            hint: "What you'll cover",
          ),
          const SizedBox(height: 16),
          Opacity(
            opacity: _submitting ? 0.7 : 1,
            child: Material(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(17),
              child: InkWell(
                borderRadius: BorderRadius.circular(17),
                onTap: _submitting ? null : _submit,
                child: SizedBox(
                  height: 56,
                  child: Center(
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.paper),
                          )
                        : Text('Schedule session', style: AppText.button()),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.lilac : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.inputBorder,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Text(label, style: AppText.body(15, weight: FontWeight.w700, color: AppColors.ink)),
      ),
    );
  }
}
