import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/enums.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/auth_error_banner.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/swap_avatar.dart';
import '../../models/match_result.dart';
import '../../models/skill.dart';
import '../../models/user_skill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/exchanges_provider.dart';
import '../../providers/matches_provider.dart';
import '../../providers/profile_provider.dart';

/// "Request a swap": paper bottom-sheet look over an ink backdrop, with a
/// full-screen success state once the request is sent.
class SendRequestScreen extends ConsumerStatefulWidget {
  const SendRequestScreen({super.key, required this.userId});

  final int userId;

  @override
  ConsumerState<SendRequestScreen> createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends ConsumerState<SendRequestScreen> {
  int? _offeredSkillId;
  int? _wantedSkillId;
  final _messageController = TextEditingController();
  bool _submitting = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit({required int offeredId, required int wantedId}) async {
    final myId = ref.read(authProvider).userId;
    if (myId == widget.userId) {
      setState(() => _error = "You can't send a swap request to yourself.");
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(exchangesRepositoryProvider).createExchange(
            receiverId: widget.userId,
            offeredSkillId: offeredId,
            wantedSkillId: wantedId,
            message: _messageController.text.trim(),
          );
      invalidateExchanges(ref);
      if (mounted) setState(() => _sent = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mySkillsAsync = ref.watch(mySkillsProvider);
    final matchAsync = ref.watch(matchDetailProvider(widget.userId));
    final inset = MediaQuery.of(context).padding;
    final sheetTop = inset.top + 12;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Stack(
        children: [
          // Faux "previous sheet" peeking behind.
          Positioned(
            left: 14,
            right: 14,
            top: sheetTop - 12,
            height: 30,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.inkBorder,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: sheetTop,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: AsyncValueWidget<List<UserSkill>>(
                value: mySkillsAsync,
                onRetry: () => ref.invalidate(mySkillsProvider),
                data: (mySkills) => AsyncValueWidget<MatchResult>(
                  value: matchAsync,
                  onRetry: () => ref.invalidate(matchDetailProvider(widget.userId)),
                  data: (match) => _buildSheet(context, mySkills, match),
                ),
              ),
            ),
          ),
          if (_sent) _buildSuccess(context),
        ],
      ),
    );
  }

  /// Offered/wanted selection with sensible defaults (the skill the partner
  /// wants from you; first of their skills you want).
  ({List<UserSkill> offers, List<Skill> wants, int? offeredId, int? wantedId}) _resolve(
    List<UserSkill> mySkills,
    MatchResult match,
  ) {
    final teach = mySkills.where((s) => s.type.name == 'teach').toList();
    final offers = teach.isNotEmpty ? teach : mySkills;
    final wants = match.skillsTheyCanTeachYou.isNotEmpty
        ? match.skillsTheyCanTeachYou
        : match.skillsYouCanTeachThem;
    final theyWant = match.skillsYouCanTeachThem.map((s) => s.id).toSet();

    int? defaultOffer;
    for (final o in offers) {
      if (theyWant.contains(o.skill.id)) {
        defaultOffer = o.skill.id;
        break;
      }
    }
    defaultOffer ??= offers.isNotEmpty ? offers.first.skill.id : null;
    return (
      offers: offers,
      wants: wants,
      offeredId: _offeredSkillId ?? defaultOffer,
      wantedId: _wantedSkillId ?? (wants.isNotEmpty ? wants.first.id : null),
    );
  }

  Widget _buildSheet(BuildContext context, List<UserSkill> mySkills, MatchResult match) {
    final r = _resolve(mySkills, match);
    final u = match.user;
    final first = firstName(u.name);
    final myName = ref.watch(myProfileProvider).valueOrNull?.name ?? 'You';
    final theyWant = match.skillsYouCanTeachThem.map((s) => s.id).toSet();
    final offerName = r.offers.where((o) => o.skill.id == r.offeredId).firstOrNull?.skill.name;
    final wantName = r.wants.where((s) => s.id == r.wantedId).firstOrNull?.name;
    final canSend = r.offeredId != null && r.wantedId != null && !_submitting;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFD6D3CB),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Request a swap', style: AppText.sheetTitle()),
                  Semantics(
                    button: true,
                    label: 'Close',
                    child: GestureDetector(
                      onTap: () => popOrGo(context, '/matches/${widget.userId}'),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.trackBg,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: AppColors.ink),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ExchangeStrip(
                myName: myName,
                partnerName: u.name,
                partnerId: u.id,
                offer: offerName,
                want: wantName,
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                AuthErrorBanner(_error!),
                const SizedBox(height: 16),
              ],
              Text("YOU'LL TEACH", style: AppText.fieldLabel(color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              if (r.offers.isEmpty)
                Text(
                  'Add a skill to your profile first.',
                  style: AppText.body(14, color: AppColors.textSecondary),
                )
              else
                for (final o in r.offers) ...[
                  _OfferCard(
                    label: o.skill.name,
                    detail: theyWant.contains(o.skill.id)
                        ? '${o.level.label} · $first wants this'
                        : o.level.label,
                    selected: o.skill.id == r.offeredId,
                    onTap: () => setState(() => _offeredSkillId = o.skill.id),
                  ),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 10),
              Text(
                "YOU'LL LEARN FROM ${first.toUpperCase()}",
                style: AppText.fieldLabel(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              if (r.wants.isEmpty)
                Text(
                  'No listed skills to choose from.',
                  style: AppText.body(14, color: AppColors.textSecondary),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in r.wants)
                      _WantPill(
                        label: s.name,
                        selected: s.id == r.wantedId,
                        onTap: () => setState(() => _wantedSkillId = s.id),
                      ),
                  ],
                ),
              const SizedBox(height: 22),
              LabeledField(
                label: 'Message (optional)',
                controller: _messageController,
                maxLines: 3,
                fill: Colors.white,
                hint: 'Introduce yourself or suggest a time…',
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 26 + bottomInset),
          decoration: BoxDecoration(
            color: AppColors.paper.withValues(alpha: 0.95),
            border: const Border(top: BorderSide(color: AppColors.barBorder)),
          ),
          child: PrimaryButton(
            label: 'Send request',
            icon: Icons.send_rounded,
            loading: _submitting,
            onPressed: canSend
                ? () => _submit(offeredId: r.offeredId!, wantedId: r.wantedId!)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final match = ref.read(matchDetailProvider(widget.userId)).valueOrNull;
    final first = match == null ? 'them' : firstName(match.user.name);
    return Positioned.fill(
      child: Container(
        color: AppColors.ink,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PopIn(
              child: Container(
                width: 112,
                height: 112,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(Icons.check_rounded, size: 56, color: AppColors.ink),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Request sent',
              textAlign: TextAlign.center,
              style: AppText.display(32, spacing: -1, color: AppColors.onDarkPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              "We'll ping you when $first responds.",
              textAlign: TextAlign.center,
              style: AppText.body(16, height: 1.5, color: AppColors.onDarkSecondary),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: Material(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => context.go('/requests'),
                  child: Center(
                    child: Text(
                      'Track in My exchanges',
                      style: AppText.button(color: AppColors.ink),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Keep discovering',
              onDark: true,
              radius: 18,
              onPressed: () => context.go('/matches'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExchangeStrip extends StatelessWidget {
  const _ExchangeStrip({
    required this.myName,
    required this.partnerName,
    required this.partnerId,
    required this.offer,
    required this.want,
  });

  final String myName;
  final String partnerName;
  final int partnerId;
  final String? offer;
  final String? want;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 66,
              height: 66,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                SwapAvatar.initialsOf(myName),
                style: AppText.display(22, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 6),
            Text('You', style: AppText.body(13, weight: FontWeight.w600, color: AppColors.ink)),
          ],
        ),
        SizedBox(
          width: 120,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              children: [
                _FlowChip(text: offer ?? '—', bg: AppColors.accent, arrowAfter: true),
                const SizedBox(height: 4),
                const SizedBox(
                  height: 10,
                  width: 110,
                  child: CustomPaint(painter: _DashPainter()),
                ),
                const SizedBox(height: 4),
                _FlowChip(text: want ?? '—', bg: AppColors.lilac, arrowBefore: true),
              ],
            ),
          ),
        ),
        Column(
          children: [
            SizedBox(
              width: 66,
              height: 66,
              child: SwapAvatar(name: partnerName, seed: partnerId, size: 66),
            ),
            const SizedBox(height: 6),
            Text(
              firstName(partnerName),
              style: AppText.body(13, weight: FontWeight.w600, color: AppColors.ink),
            ),
          ],
        ),
      ],
    );
  }
}

class _FlowChip extends StatelessWidget {
  const _FlowChip({
    required this.text,
    required this.bg,
    this.arrowBefore = false,
    this.arrowAfter = false,
  });

  final String text;
  final Color bg;
  final bool arrowBefore;
  final bool arrowAfter;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (arrowBefore) ...[
            const Icon(Icons.arrow_back_rounded, size: 14, color: AppColors.ink),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(12, weight: FontWeight.w700, color: AppColors.ink),
            ),
          ),
          if (arrowAfter) ...[
            const SizedBox(width: 3),
            const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.ink),
          ],
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (double x = 2; x < size.width - 2; x += 7) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(x + 3, size.height / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $detail',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.inputBorder,
              width: selected ? 2 : 1.5,
            ),
            boxShadow: selected
                ? const [BoxShadow(color: AppColors.ink, offset: Offset(4, 4))]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppText.body(16, weight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: AppText.body(13, color: AppColors.ink.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.accent : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.ink : const Color(0xFFC9C6BE),
                    width: selected ? 7 : 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WantPill extends StatelessWidget {
  const _WantPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: selected ? AppColors.lilac : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: selected ? null : Border.all(color: AppColors.chipBorder, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppText.body(15, weight: FontWeight.w700, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
