import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/enums.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../core/widgets/swap_avatar.dart';
import '../../core/widgets/swap_icon.dart';
import '../../models/session.dart';
import '../../models/skill_exchange.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/exchanges_provider.dart';
import '../../providers/sessions_provider.dart';

class ExchangesScreen extends ConsumerStatefulWidget {
  const ExchangesScreen({super.key});

  @override
  ConsumerState<ExchangesScreen> createState() => _ExchangesScreenState();
}

class _ExchangesScreenState extends ConsumerState<ExchangesScreen> {
  int _tab = 0;
  final Set<int> _acting = {};

  Future<void> _refresh() async {
    ref.invalidate(receivedExchangesProvider);
    ref.invalidate(sentExchangesProvider);
    ref.invalidate(mySessionsProvider);
  }

  Future<void> _decide(SkillExchange e, {required bool accept}) async {
    setState(() => _acting.add(e.id));
    try {
      final repo = ref.read(exchangesRepositoryProvider);
      if (accept) {
        await repo.accept(e.id);
      } else {
        await repo.reject(e.id);
      }
      invalidateExchanges(ref);
    } on ApiException catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.message)));
      }
    } finally {
      if (mounted) setState(() => _acting.remove(e.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(authProvider).userId;
    final received = ref.watch(receivedExchangesProvider);
    final sent = ref.watch(sentExchangesProvider);
    final sessions = ref.watch(mySessionsProvider).valueOrNull ?? const <Session>[];
    final top = MediaQuery.of(context).padding.top + 8;

    final incoming = [...(received.valueOrNull ?? const <SkillExchange>[])];
    final outgoing = [...(sent.valueOrNull ?? const <SkillExchange>[])];
    int byDate(SkillExchange a, SkillExchange b) => (b.createdAt ?? DateTime(1970))
        .compareTo(a.createdAt ?? DateTime(1970));
    incoming.sort(byDate);
    outgoing.sort(byDate);
    final all = [...incoming, ...outgoing]..sort(byDate);
    final pendingIn = incoming.where((e) => e.status == ExchangeStatus.pending).length;

    final shown = switch (_tab) { 0 => incoming, 1 => outgoing, _ => all };
    final loading = (received.isLoading || sent.isLoading) && all.isEmpty;
    final failed = received.hasError && sent.hasError;

    final now = DateTime.now();
    final upcoming = sessions
        .where((s) => s.status == SessionStatus.scheduled && s.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final next = upcoming.isEmpty ? null : upcoming.first;

    final emptyMessage = switch (_tab) {
      0 => 'No requests received yet.',
      1 => "You haven't sent any requests yet.",
      _ => 'No swaps yet. Find someone in Discover.',
    };

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenX,
            top,
            AppSpacing.screenX,
            AppSpacing.scrollBottom,
          ),
          children: [
            const SizedBox(height: 4),
            Text('Exchanges', style: AppText.h1()),
            const SizedBox(height: 18),
            if (next != null) ...[
              _NextSessionBanner(session: next, myId: myId),
              const SizedBox(height: 18),
            ],
            SegmentedTabs(
              labels: const ['Incoming', 'Sent', 'All'],
              counts: [pendingIn, outgoing.length, all.length],
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 18),
            if (loading)
              const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.6)),
              )
            else if (failed)
              SizedBox(
                height: 280,
                child: AsyncValueWidget<List<SkillExchange>>(
                  value: received,
                  onRetry: _refresh,
                  data: (_) => const SizedBox.shrink(),
                ),
              )
            else if (shown.isEmpty)
              SizedBox(
                height: 280,
                child: EmptyState(icon: Icons.inbox_outlined, message: emptyMessage),
              )
            else
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _ExchangeCard(
                  exchange: shown[i],
                  myId: myId,
                  busy: _acting.contains(shown[i].id),
                  onAccept: () => _decide(shown[i], accept: true),
                  onDecline: () => _decide(shown[i], accept: false),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _NextSessionBanner extends StatelessWidget {
  const _NextSessionBanner({required this.session, required this.myId});

  final Session session;
  final int? myId;

  @override
  Widget build(BuildContext context) {
    final ex = session.exchange;
    final other = ex.requester.id == myId ? ex.receiver : ex.requester;
    final d = session.dateTime;
    return Material(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.push('/sessions/${session.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      monthShort(d),
                      style: AppText.body(
                        11,
                        weight: FontWeight.w700,
                        spacing: 0.6,
                        color: AppColors.accent,
                      ),
                    ),
                    Text(
                      dayNum(d),
                      style: AppText.display(22, height: 1, color: AppColors.onDarkPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXT SESSION · ${weekdayShort(d)} ${hhmm(d)}',
                      style: AppText.body(12, weight: FontWeight.w700, spacing: 0.5, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Session with ${firstName(other.name)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(16, weight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${session.mode.label} · ${session.durationMinutes} min',
                      style: AppText.body(13, color: AppColors.teachTintText),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 24, color: AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExchangeCard extends StatelessWidget {
  const _ExchangeCard({
    required this.exchange,
    required this.myId,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final SkillExchange exchange;
  final int? myId;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final iRequested = exchange.requester.id == myId;
    final other = iRequested ? exchange.receiver : exchange.requester;
    final give = iRequested ? exchange.offeredSkill : exchange.wantedSkill;
    final get = iRequested ? exchange.wantedSkill : exchange.offeredSkill;
    final when = exchange.createdAt == null ? '' : ' · ${relativeTime(exchange.createdAt!)}';
    final canAct = !iRequested && exchange.status == ExchangeStatus.pending;
    final canOpen = exchange.status == ExchangeStatus.accepted;
    final message = exchange.message?.trim() ?? '';

    return AppCard(
      onTap: () => context.push('/requests/${exchange.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SwapAvatar(name: other.name, seed: other.id, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      other.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.personName(),
                    ),
                    const SizedBox(height: 2),
                    Text('${iRequested ? 'Sent' : 'Received'}$when', style: AppText.meta()),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill.exchange(exchange.status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _SkillTile(caption: 'YOU TEACH', name: give.name)),
              const SizedBox(width: 6),
              const SizedBox(
                width: 28,
                child: Center(child: SwapIcon(size: 20, color: AppColors.ink)),
              ),
              const SizedBox(width: 6),
              Expanded(child: _SkillTile(caption: 'YOU LEARN', name: get.name)),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('“$message”', style: AppText.body(14, height: 1.45, color: AppColors.textBody)),
          ],
          if (canAct) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CardButton(label: 'Decline', onTap: busy ? null : onDecline),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CardButton(label: 'Accept', filled: true, onTap: busy ? null : onAccept),
                ),
              ],
            ),
          ],
          if (canOpen) ...[
            const SizedBox(height: 14),
            _CardButton(
              label: 'Open & schedule sessions',
              filled: true,
              icon: Icons.calendar_month_outlined,
              onTap: () => context.push('/requests/${exchange.id}'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile({required this.caption, required this.name});

  final String caption;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption,
            style: AppText.body(11, weight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 1),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(15, weight: FontWeight.w700, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({required this.label, required this.onTap, this.filled = false, this.icon});

  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: filled ? AppColors.ink : Colors.white,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: filled ? null : Border.all(color: AppColors.chipBorder, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: AppText.body(
                    15,
                    weight: FontWeight.w700,
                    color: filled ? AppColors.paper : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
