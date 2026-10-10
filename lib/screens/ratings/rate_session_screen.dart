import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/enums.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/auth_error_banner.dart';
import '../../core/widgets/decor_rings.dart';
import '../../core/widgets/pop_in.dart';
import '../../core/widgets/star_rating.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/swap_avatar.dart';
import '../../models/session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/profile_provider.dart';
import '../../providers/sessions_provider.dart';

const _quickTags = ['Patient', 'Well prepared', 'Clear explanations', 'Fun', 'On time'];
const _words = ['Tap a star', 'Not great', 'Could be better', 'Good', 'Really good', 'Loved it'];

class RateSessionScreen extends ConsumerStatefulWidget {
  const RateSessionScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<RateSessionScreen> createState() => _RateSessionScreenState();
}

class _RateSessionScreenState extends ConsumerState<RateSessionScreen> {
  int _stars = 5;
  final Set<String> _tags = {};
  final _reviewController = TextEditingController();
  bool _submitting = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    // The API only takes stars + free text, so quick tags travel with the review.
    final tagLine = _quickTags.where(_tags.contains).join(' · ');
    final text = _reviewController.text.trim();
    final review = [if (tagLine.isNotEmpty) tagLine, if (text.isNotEmpty) text].join('\n');
    try {
      await ref.read(ratingsRepositoryProvider).rateSession(
            sessionId: widget.sessionId,
            stars: _stars,
            review: review,
          );
      if (mounted) setState(() => _done = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionDetailProvider(widget.sessionId));
    final myId = ref.watch(authProvider).userId;
    final me = ref.watch(myProfileProvider).valueOrNull;
    final inset = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: AppColors.lilac,
      body: Stack(
        children: [
          const Positioned(
            left: -15,
            top: -120,
            child: DecorRings(
              size: 420,
              radii: [200, 140, 80],
              color: Color(0xFFB9AAF7),
              strokeWidth: 1.5,
            ),
          ),
          AsyncValueWidget<Session>(
            value: sessionAsync,
            onRetry: () => ref.invalidate(sessionDetailProvider(widget.sessionId)),
            showBack: true,
            data: (session) {
              if (session.status != SessionStatus.completed) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(24, inset.top + 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BackSquareButton(translucent: true),
                      const SizedBox(height: 24),
                      Text(
                        'You can only rate a session once it has been completed.',
                        style: AppText.bodyText(color: AppColors.ink),
                      ),
                    ],
                  ),
                );
              }
              final ex = session.exchange;
              final iRequested = ex.requester.id == myId;
              final other = iRequested ? ex.receiver : ex.requester;
              final learned = iRequested ? ex.wantedSkill : ex.offeredSkill;
              final first = firstName(other.name);
              return _done
                  ? _thanks(context, session, first, me?.name, inset)
                  : _form(context, session, other.name, other.id, first, learned.name, inset);
            },
          ),
        ],
      ),
    );
  }

  Widget _form(
    BuildContext context,
    Session session,
    String otherName,
    int otherId,
    String first,
    String skill,
    EdgeInsets inset,
  ) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(20, inset.top + 8, 20, 28 + inset.bottom),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded, size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'SESSION COMPLETE',
                      style: AppText.body(
                        12,
                        weight: FontWeight.w700,
                        spacing: 0.5,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.go('/requests/${session.exchange.id}'),
                child: Text(
                  'Later',
                  style: AppText.body(15, weight: FontWeight.w600, color: AppColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              SwapAvatar.initialsOf(otherName),
              style: AppText.display(30, color: AppColors.lilac),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'How was $skill\nwith $first?',
            textAlign: TextAlign.center,
            style: AppText.display(32, spacing: -1, height: 1.05),
          ),
          const SizedBox(height: 22),
          if (_error != null) ...[
            AuthErrorBanner(_error!),
            const SizedBox(height: 16),
          ],
          StarRatingInput(value: _stars, onChanged: (v) => setState(() => _stars = v)),
          const SizedBox(height: 8),
          Text(_words[_stars], style: AppText.h2()),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _quickTags)
                GestureDetector(
                  onTap: () => setState(() => _tags.contains(t) ? _tags.remove(t) : _tags.add(t)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: _tags.contains(t) ? AppColors.ink : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: _tags.contains(t)
                          ? null
                          : Border.all(color: AppColors.ink, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          t,
                          style: AppText.body(
                            14,
                            weight: FontWeight.w600,
                            color: _tags.contains(t) ? AppColors.paper : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _reviewController,
            minLines: 3,
            maxLines: 4,
            cursorColor: AppColors.ink,
            style: AppText.body(15, height: 1.5, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'Add a short review (optional)',
              hintStyle: AppText.body(15, color: AppColors.textSecondary),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.7),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 22),
          PrimaryButton(label: 'Submit rating', loading: _submitting, onPressed: _submit),
        ],
      ),
    );
  }

  Widget _thanks(
    BuildContext context,
    Session session,
    String first,
    String? myName,
    EdgeInsets inset,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(32, 32, 32, 32 + inset.bottom),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PopIn(
            child: Container(
              width: 120,
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(42),
              ),
              child: const Icon(Icons.star_rounded, size: 64, color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            myName == null ? 'Thanks!' : 'Thanks, ${firstName(myName)}',
            textAlign: TextAlign.center,
            style: AppText.display(34, spacing: -1),
          ),
          const SizedBox(height: 10),
          Text(
            'Your $_stars-star review helps $first get found by more learners.',
            textAlign: TextAlign.center,
            style: AppText.body(16, height: 1.5, color: const Color(0xFF2A2540)),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Back to exchange',
            onPressed: () => context.go('/requests/${session.exchange.id}'),
          ),
        ],
      ),
    );
  }
}
