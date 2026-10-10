import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/enums.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/swap_icon.dart';
import '../../models/reschedule_request.dart';
import '../../models/session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/reschedule_provider.dart';
import '../../providers/sessions_provider.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  bool _acting = false;

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _run(Future<dynamic> Function() action) async {
    setState(() => _acting = true);
    try {
      await action();
      invalidateRescheduleProviders(ref, widget.sessionId);
      ref.invalidate(mySessionsProvider);
      return true;
    } on ApiException catch (e) {
      _toast(e.message);
      return false;
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _confirmCancel(Session session) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this session?'),
        content: const Text('The other person will be notified.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel session', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => ref.read(sessionsRepositoryProvider).cancel(session.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionDetailProvider(widget.sessionId));
    final myId = ref.watch(authProvider).userId;
    final requestsAsync = ref.watch(sessionRescheduleRequestsProvider(widget.sessionId));
    final requests = requestsAsync.valueOrNull ?? const <RescheduleRequest>[];
    final top = MediaQuery.of(context).padding.top + 8;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: AsyncValueWidget<Session>(
        value: sessionAsync,
        onRetry: () => ref.invalidate(sessionDetailProvider(widget.sessionId)),
        showBack: true,
        data: (session) => _buildBody(context, session, myId, requests, top),
      ),
      bottomNavigationBar: sessionAsync.maybeWhen(
        data: (s) => _buildBar(context, s, myId, requests),
        orElse: () => null,
      ),
    );
  }

  RescheduleRequest? _pending(List<RescheduleRequest> requests) {
    for (final r in requests) {
      if (r.status == RescheduleStatus.pending) return r;
    }
    return null;
  }

  Widget? _buildBar(
    BuildContext context,
    Session session,
    int? myId,
    List<RescheduleRequest> requests,
  ) {
    final ex = session.exchange;
    final isParticipant = ex.requester.id == myId || ex.receiver.id == myId;
    if (!isParticipant) return null;
    final isScheduler = session.scheduledBy.id == myId;
    final hasPending = _pending(requests) != null;
    final bottom = MediaQuery.of(context).padding.bottom;

    Widget? content;
    if (session.status == SessionStatus.scheduled) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (!hasPending) ...[
                Expanded(
                  child: SecondaryButton(
                    label: 'Propose new time',
                    radius: 16,
                    foreground: AppColors.ink,
                    fill: Colors.white,
                    onPressed: _acting
                        ? null
                        : () => context.push('/sessions/${session.id}/reschedule'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Opacity(
                  opacity: _acting ? 0.5 : 1,
                  child: Material(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _acting
                          ? null
                          : () async {
                              final ok = await _run(
                                () => ref.read(sessionsRepositoryProvider).complete(session.id),
                              );
                              if (ok && context.mounted) {
                                context.push('/sessions/${session.id}/rate');
                              }
                            },
                      child: SizedBox(
                        height: 52,
                        child: Center(
                          child: Text(
                            'Mark as done',
                            style: AppText.body(15, weight: FontWeight.w700, color: AppColors.paper),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isScheduler) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: TextButton(
                onPressed: _acting ? null : () => _confirmCancel(session),
                child: Text(
                  'Cancel session',
                  style: AppText.body(14, weight: FontWeight.w600, color: AppColors.danger),
                ),
              ),
            ),
          ],
        ],
      );
    } else if (session.status == SessionStatus.completed) {
      content = PrimaryButton(
        label: 'Rate this session',
        icon: Icons.star_rounded,
        onPressed: () => context.push('/sessions/${session.id}/rate'),
      );
    }
    if (content == null) return null;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 26 + bottom),
      decoration: BoxDecoration(
        color: AppColors.paper.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppColors.barBorder)),
      ),
      child: content,
    );
  }

  Widget _buildBody(
    BuildContext context,
    Session session,
    int? myId,
    List<RescheduleRequest> requests,
    double top,
  ) {
    final ex = session.exchange;
    final other = ex.requester.id == myId ? ex.receiver : ex.requester;
    final d = session.dateTime;
    final pending = _pending(requests);
    final rescheduleRepo = ref.read(rescheduleRepositoryProvider);
    final hasLink = session.mode == SessionMode.online && (session.meetLink?.isNotEmpty ?? false);
    final notes = session.notes?.trim() ?? '';
    final location = session.location?.trim() ?? '';

    final history = <({String title, DateTime? at})>[
      for (final r in requests)
        (
          title: switch (r.status) {
            RescheduleStatus.pending =>
              '${firstName(r.requestedBy.name)} proposed ${slotLabel(r.proposedDateTime)}',
            RescheduleStatus.accepted => 'Moved to ${slotLabel(r.proposedDateTime)}',
            RescheduleStatus.rejected => 'Declined ${slotLabel(r.proposedDateTime)}',
          },
          at: r.createdAt,
        ),
      (
        title: '${firstName(session.scheduledBy.name)} scheduled ${slotLabel(d)}',
        at: session.createdAt,
      ),
    ]..sort((a, b) => (b.at ?? DateTime(1970)).compareTo(a.at ?? DateTime(1970)));

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(20, top, 20, 24),
          decoration: const BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackSquareButton(onDark: true),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.inkBorder, width: 1.5),
                    ),
                    child: Text(
                      session.status.label.toUpperCase(),
                      style: AppText.body(
                        11,
                        weight: FontWeight.w700,
                        spacing: 0.5,
                        color: const Color(0xFFD9D8E0),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      ex.offeredSkill.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(14, color: AppColors.onDarkTertiary),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const SwapIcon(size: 14, color: AppColors.onDarkTertiary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${ex.wantedSkill.name} · with ${firstName(other.name)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(14, color: AppColors.onDarkTertiary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(hhmm(d), style: AppText.sessionTime(color: AppColors.accent)),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      DateFormat('EEE, d MMM').format(d),
                      style: AppText.body(16, weight: FontWeight.w600, color: AppColors.onDarkPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: _InfoTile(caption: 'LENGTH', value: '${session.durationMinutes} min')),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoTile(
                      caption: 'WHERE',
                      value: session.mode == SessionMode.online ? 'Online' : 'In person',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _InfoTile(
                      caption: 'SET BY',
                      value: firstName(session.scheduledBy.name),
                    ),
                  ),
                ],
              ),
              if (hasLink) ...[
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'Copy meeting link',
                  icon: Icons.videocam_outlined,
                  onDark: true,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: session.meetLink!));
                    _toast('Meeting link copied');
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (pending != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _ReschedulePendingCard(
              request: pending,
              session: session,
              myId: myId,
              acting: _acting,
              onAccept: () => _run(
                () => rescheduleRepo.acceptReschedule(
                  sessionId: session.id,
                  requestId: pending.id,
                ),
              ),
              onReject: () => _run(
                () => rescheduleRepo.rejectReschedule(
                  sessionId: session.id,
                  requestId: pending.id,
                ),
              ),
            ),
          ),
        if (location.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: AppCard(
              radius: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LOCATION', style: AppText.overline()),
                  const SizedBox(height: 6),
                  Text(location, style: AppText.body(15, height: 1.5, color: AppColors.ink)),
                ],
              ),
            ),
          ),
        if (notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: AppCard(
              radius: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOTES FROM ${firstName(session.scheduledBy.name).toUpperCase()}',
                    style: AppText.overline(),
                  ),
                  const SizedBox(height: 6),
                  Text(notes, style: AppText.body(15, height: 1.5, color: AppColors.ink)),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('History', style: AppText.cardHeading()),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Column(
                  children: [
                    for (var i = 0; i < history.length; i++)
                      _TimelineItem(
                        title: history[i].title,
                        when: history[i].at == null ? '' : relativeTime(history[i].at!),
                        first: i == 0,
                        last: i == history.length - 1,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.caption, required this.value});

  final String caption;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.inkRaised,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(caption, style: AppText.body(11, color: AppColors.onDarkTertiary)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(15, weight: FontWeight.w700, color: AppColors.onDarkPrimary),
          ),
        ],
      ),
    );
  }
}

class _ReschedulePendingCard extends StatelessWidget {
  const _ReschedulePendingCard({
    required this.request,
    required this.session,
    required this.myId,
    required this.acting,
    required this.onAccept,
    required this.onReject,
  });

  final RescheduleRequest request;
  final Session session;
  final int? myId;
  final bool acting;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final byMe = request.requestedBy.id == myId;
    final reason = request.reason?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusPendingBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.schedule_rounded, size: 18, color: AppColors.statusPendingBg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      byMe
                          ? 'You asked to move this'
                          : '${firstName(request.requestedBy.name)} wants to move this',
                      style: AppText.body(15, weight: FontWeight.w700, color: AppColors.ink),
                    ),
                    if (request.createdAt != null)
                      Text(
                        'Proposed ${relativeTime(request.createdAt!)}',
                        style: AppText.body(13, color: AppColors.statusPendingText),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(
                child: Text(
                  slotLabel(session.dateTime),
                  style: AppText.body(15, color: const Color(0xFF6B5810)).copyWith(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.ink),
              ),
              Flexible(
                child: Text(
                  slotLabel(request.proposedDateTime),
                  style: AppText.body(15, weight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
            ],
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '“$reason”',
              style: AppText.body(14, height: 1.45, color: const Color(0xFF3B2E00)),
            ),
          ],
          const SizedBox(height: 12),
          if (byMe)
            Text(
              'Waiting for ${firstName(session.exchange.requester.id == myId ? session.exchange.receiver.name : session.exchange.requester.name)} to respond',
              style: AppText.body(14, weight: FontWeight.w600, color: AppColors.statusPendingText),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _PendingButton(label: 'Keep original', onTap: acting ? null : onReject),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PendingButton(
                    label: 'Accept new time',
                    filled: true,
                    onTap: acting ? null : onAccept,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PendingButton extends StatelessWidget {
  const _PendingButton({required this.label, required this.onTap, this.filled = false});

  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: filled ? AppColors.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: filled ? null : Border.all(color: AppColors.ink, width: 1.5),
            ),
            child: Text(
              label,
              style: AppText.body(
                15,
                weight: FontWeight.w700,
                color: filled ? AppColors.paper : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.when,
    required this.first,
    required this.last,
  });

  final String title;
  final String when;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 10,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: first ? AppColors.ink : const Color(0xFFC9C6BE),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!last)
                  Expanded(child: Container(width: 2, color: AppColors.chipBorder)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body(14, weight: FontWeight.w600, color: AppColors.ink),
                  ),
                  if (when.isNotEmpty)
                    Text(when, style: AppText.body(13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
