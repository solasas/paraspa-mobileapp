import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_field.dart';
import '../../core/widgets/auth_error_banner.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/segmented_tabs.dart';
import '../../providers/auth_provider.dart';

/// Combined Log in / Sign up screen: dark header with a slowly spinning orbit,
/// paper sheet below with a two-tab switch.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.startOnSignup = false});

  final bool startOnSignup;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late bool _signup = widget.startOnSignup;
  bool _obscure = true;
  String? _nameError;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 60));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    String? name, email, password;
    if (_signup && _nameController.text.trim().isEmpty) name = 'Name is required';
    final e = _emailController.text.trim();
    if (e.isEmpty) {
      email = 'Email is required';
    } else if (!e.contains('@')) {
      email = 'Enter a valid email';
    }
    final p = _passwordController.text;
    if (p.isEmpty) {
      password = 'Password is required';
    } else if (_signup && p.length < 6) {
      password = 'Use at least 6 characters';
    }
    setState(() {
      _nameError = name;
      _emailError = email;
      _passwordError = password;
    });
    return name == null && email == null && password == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    final notifier = ref.read(authProvider.notifier);
    final success = _signup
        ? await notifier.register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
        : await notifier.login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    if (success && mounted) context.go('/matches');
  }

  void _setMode(bool signup) {
    if (signup == _signup) return;
    ref.read(authProvider.notifier).clearError();
    setState(() {
      _signup = signup;
      _nameError = _emailError = _passwordError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth.status == AuthStatus.authenticating;
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    right: -90,
                    top: -40,
                    child: RotationTransition(
                      turns: _spin,
                      child: const SizedBox(
                        width: 300,
                        height: 300,
                        child: CustomPaint(painter: _OrbitPainter()),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, media.padding.top + 8, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BackSquare(onPressed: () => context.go('/welcome')),
                            Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.inkRaised,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const BrandMark(size: 38, background: AppColors.inkRaised),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          _signup ? 'Join the swap.' : 'Welcome back.',
                          style: AppText.loginHeading(),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _signup
                              ? 'Takes 30 seconds. Then pick your skills.'
                              : 'Your matches missed you.',
                          style: AppText.body(15, color: AppColors.onDarkSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(0, media.size.height - 250 - media.viewInsets.bottom),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedTabs(
                      labels: const ['Log in', 'Sign up'],
                      selected: _signup ? 1 : 0,
                      onChanged: (i) => _setMode(i == 1),
                    ),
                    const SizedBox(height: 16),
                    if (auth.errorMessage != null) ...[
                      AuthErrorBanner(auth.errorMessage!),
                      const SizedBox(height: 12),
                    ],
                    if (_signup) ...[
                      LabeledField(
                        label: 'Full name',
                        uppercase: false,
                        height: 54,
                        fill: Colors.white,
                        controller: _nameController,
                        hint: 'Your name',
                        errorText: _nameError,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                    ],
                    LabeledField(
                      label: 'Email',
                      uppercase: false,
                      height: 54,
                      fill: Colors.white,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      hint: 'you@example.com',
                      errorText: _emailError,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    LabeledField(
                      label: 'Password',
                      uppercase: false,
                      height: 54,
                      fill: Colors.white,
                      controller: _passwordController,
                      obscure: _obscure,
                      trailingLabel: _signup ? 'At least 6 characters' : null,
                      errorText: _passwordError,
                      autofillHints: [
                        _signup ? AutofillHints.newPassword : AutofillHints.password,
                      ],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      suffix: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: _signup ? 'Create account' : 'Log in',
                      icon: Icons.arrow_forward_rounded,
                      loading: isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _signup
                          ? 'By signing up you agree to our Terms and Privacy Policy.'
                          : 'New here? Switch to Sign up above — it’s free.',
                      textAlign: TextAlign.center,
                      style: AppText.body(13, height: 1.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 46pt `inkRaised` back button for the dark auth header.
class BackSquare extends StatelessWidget {
  const BackSquare({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconSquareButton(
      icon: Icons.chevron_left_rounded,
      onDark: true,
      tooltip: 'Back',
      onPressed: onPressed,
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final ring = Paint()
      ..color = AppColors.inkDecorLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(c, 140, ring);
    // Dashed inner ring: 3 on / 6 off.
    const r = 95.0;
    final count = (2 * math.pi * r / 9).floor();
    for (var i = 0; i < count; i++) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), i * 9 / r, 3 / r, false, ring);
    }
    canvas.drawCircle(const Offset(150, 10), 7, Paint()..color = AppColors.accent);
    canvas.drawCircle(const Offset(245, 150), 6, Paint()..color = AppColors.lilac);
    canvas.drawCircle(const Offset(55, 150), 5, Paint()..color = AppColors.peach);
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => false;
}
