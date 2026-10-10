import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/decor_rings.dart';

const _pairs = [
  ['Guitar', 'Spanish'],
  ['Python', 'Yoga'],
  ['Chess', 'Design'],
  ['Baking', 'Piano'],
];

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _seconds = ValueNotifier(0);
  Timer? _cycle;
  int _teachIndex = 0;
  int _learnIndex = 0;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) => _seconds.value = elapsed.inMicroseconds / 1e6);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce == _reduceMotion && (_ticker.isActive || reduce)) return;
    _reduceMotion = reduce;
    _cycle?.cancel();
    if (reduce) {
      _ticker.stop();
    } else {
      if (!_ticker.isActive) _ticker.start();
      _cycle = Timer.periodic(const Duration(milliseconds: 2600), (_) {
        if (!mounted) return;
        final next = (_teachIndex + 1) % _pairs.length;
        setState(() => _teachIndex = next);
        // Second word enters 0.12s after the first.
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) setState(() => _learnIndex = next);
        });
      });
    }
  }

  @override
  void dispose() {
    _cycle?.cancel();
    _ticker.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, topInset + 8, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Wordmark(
                          size: 21,
                          color: AppColors.onDarkPrimary,
                          background: AppColors.ink,
                        ),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.inkBorder, width: 1.5),
                            ),
                            child: Text(
                              'Log in',
                              style: AppText.body(
                                14,
                                weight: FontWeight.w600,
                                color: AppColors.onDarkPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 372,
                    width: double.infinity,
                    child: ValueListenableBuilder<double>(
                      valueListenable: _seconds,
                      builder: (context, t, _) => _OrbitArea(seconds: t),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 38),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Headline(teachIndex: _teachIndex, learnIndex: _learnIndex),
                          const SizedBox(height: 14),
                          Text(
                            'Swap skills one-for-one with real people. No fees, no courses — '
                            'just your time for theirs.',
                            style: AppText.body(16, height: 1.45, color: AppColors.onDarkSecondary),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              for (var k = 0; k < _pairs.length; k++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(right: 6),
                                  height: 5,
                                  width: k == _teachIndex ? 26 : 8,
                                  decoration: BoxDecoration(
                                    color: k == _teachIndex ? AppColors.accent : AppColors.inkBorder,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          PrimaryButton(
                            label: "Start swapping — it's free",
                            icon: Icons.arrow_forward_rounded,
                            onDark: true,
                            onPressed: () => context.go('/register'),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Pick 1 skill to teach, 1 to learn. Matches in seconds.',
                            textAlign: TextAlign.center,
                            style: AppText.body(13, color: AppColors.onDarkTertiary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.teachIndex, required this.learnIndex});

  final int teachIndex;
  final int learnIndex;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Teach ${_pairs[teachIndex][0]}, learn ${_pairs[learnIndex][1]}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WordRow(label: 'Teach', word: _pairs[teachIndex][0], fill: AppColors.accent),
            const SizedBox(height: 6),
            _WordRow(label: 'learn', word: _pairs[learnIndex][1], fill: AppColors.lilac),
          ],
        ),
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({required this.label, required this.word, required this.fill});

  final String label;
  final String word;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          Text(label, style: AppText.welcomeHero()),
          const SizedBox(width: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 550),
            switchInCurve: const Cubic(.2, .8, .2, 1),
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, .6), end: Offset.zero).animate(anim),
                child: RotationTransition(
                  turns: Tween(begin: -0.012, end: 0.0).animate(anim),
                  child: child,
                ),
              ),
            ),
            child: Container(
              key: ValueKey(word),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(16)),
              child: Text(word, style: AppText.welcomeHero(color: AppColors.ink)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitArea extends StatelessWidget {
  const _OrbitArea({required this.seconds});

  final double seconds;

  static const _outer = [
    ('Guitar', AppColors.accent, AppColors.ink, false),
    ('Python', AppColors.paper, AppColors.ink, false),
    ('Spanish', AppColors.lilac, AppColors.ink, false),
    ('Photography', AppColors.peach, AppColors.ink, false),
    ('UI Design', AppColors.ink, Color(0xFFD9D8E0), true),
    ('Yoga', AppColors.mint, AppColors.ink, false),
  ];

  static const _inner = [
    ('AM', AppColors.lilac),
    ('PN', AppColors.paper),
    ('RK', AppColors.peach),
  ];

  @override
  Widget build(BuildContext context) {
    final outerTheta = seconds / 46 * 2 * math.pi; // clockwise, 46s
    final innerTheta = -seconds / 30 * 2 * math.pi; // reverse, 30s

    Offset onCircle(double radius, double baseDeg, double theta) {
      final a = baseDeg * math.pi / 180 + theta;
      return Offset(radius * math.cos(a), radius * math.sin(a));
    }

    // Pulse rings: scale 1 → 1.9 while fading, two rings 1.2s apart.
    Widget pulse(double offset) {
      final p = ((seconds + offset) % 2.4) / 2.4;
      final eased = Curves.easeOut.transform(p);
      return Transform.scale(
        scale: 1 + 0.9 * eased,
        child: Opacity(
          opacity: (0.28 * (1 - p) * (1 - p)).clamp(0.0, 1.0),
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      );
    }

    final breathe = 1 + 0.08 * (0.5 - 0.5 * math.cos(2 * math.pi * seconds / 6.4));

    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft accent glow behind the logo.
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.13),
                AppColors.accent.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        const DecorRings(
          size: 300,
          radii: [145, 82],
          color: AppColors.inkDecorLine,
          dashedIndexes: {1},
        ),
        for (var k = 0; k < _outer.length; k++)
          Transform.translate(
            offset: onCircle(145, -90 + k * 60, outerTheta),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _outer[k].$2,
                borderRadius: BorderRadius.circular(999),
                border: _outer[k].$4 ? Border.all(color: AppColors.inkBorder, width: 1.5) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                _outer[k].$1,
                style: AppText.body(13, weight: FontWeight.w700, color: _outer[k].$3),
              ),
            ),
          ),
        for (var k = 0; k < _inner.length; k++)
          Transform.translate(
            offset: onCircle(82, -90 + k * 120, innerTheta),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _inner[k].$2,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.ink, width: 3),
              ),
              child: Text(
                _inner[k].$1,
                style: AppText.body(13, weight: FontWeight.w700, color: AppColors.ink),
              ),
            ),
          ),
        pulse(0),
        pulse(1.2),
        Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.inkRaised,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.inkBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 40,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Transform.scale(
            scale: breathe,
            child: const BrandMark(size: 68, background: AppColors.inkRaised),
          ),
        ),
      ],
    );
  }
}
