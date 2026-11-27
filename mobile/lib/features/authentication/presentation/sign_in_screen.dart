import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../app/theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/info_card.dart';
import '../application/auth_controller.dart';

/// Sign In & Authentication — matches the Stitch sign-in screen (02): an
/// "Account Setup" pill top bar, a stacked-tile emblem, welcome copy, Google +
/// Apple provider buttons, a "Sacred Data Sanctuary" trust note, ToS + Privacy,
/// and the QF attribution. Email/password is intentionally out of scope.
/// Presentational restyle — every provider/controller call is preserved.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen(authControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (err, _) {
          final String message;
          if (err is ApiException) {
            message = err.message;
          } else if (err is GoogleSignInException) {
            message =
                'Google sign-in: ${err.code.name}'
                '${err.description != null ? ' — ${err.description}' : ''}';
          } else {
            message = 'Sign-in failed: $err';
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
      );
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/onboarding');
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _TopBar(onBack: () => context.go('/onboarding')),
              const SizedBox(height: 32),
              Text(
                'Welcome to Hudaayah',
                style: theme.textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Save your reading streaks and sync your Quran learning progress '
                'seamlessly across devices.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              AuthProviderButton(
                leading: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const _GoogleGlyph(),
                label: 'Continue with Google',
                onPressed: isLoading
                    ? null
                    : () => ref
                          .read(authControllerProvider.notifier)
                          .signInWithGoogle(),
              ),
              const SizedBox(height: 12),
              // Apple Sign-In is not built yet; hide the placeholder on Android.
              if (defaultTargetPlatform != TargetPlatform.android)
                const AuthProviderButton(
                  leading: Icon(
                    Icons.apple,
                    size: 22,
                    color: AppTheme.onSurface,
                  ),
                  label: 'Continue with Apple (coming soon)',
                  onPressed: null, // Apple — wired in a later task.
                ),
              const SizedBox(height: 28),
              const InfoCard(
                icon: Icons.lock_outline,
                title: 'Sacred Data Sanctuary',
                body:
                    'Your data is private and your spiritual journey is sacred. '
                    'No ads, no commercial tracking.',
              ),
              const SizedBox(height: 24),
              const _LegalLinks(),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  AppConfig.qfAttribution,
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "By continuing…" line with tappable Terms and Privacy Policy links. Stateful
/// only to own (and dispose) the tap recognizers.
class _LegalLinks extends StatefulWidget {
  const _LegalLinks();

  @override
  State<_LegalLinks> createState() => _LegalLinksState();
}

class _LegalLinksState extends State<_LegalLinks> {
  late final TapGestureRecognizer _terms;
  late final TapGestureRecognizer _privacy;

  @override
  void initState() {
    super.initState();
    _terms = TapGestureRecognizer()..onTap = () => context.push('/legal/terms');
    _privacy = TapGestureRecognizer()
      ..onTap = () => context.push('/legal/privacy');
  }

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    final linkStyle = style?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppTheme.primary,
      decoration: TextDecoration.underline,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          const TextSpan(text: "By continuing, you agree to Hudaayah's "),
          TextSpan(
            text: 'Terms of Service',
            style: linkStyle,
            recognizer: _terms,
          ),
          const TextSpan(text: ' and acknowledge our '),
          TextSpan(
            text: 'Privacy Policy',
            style: linkStyle,
            recognizer: _privacy,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Top row: a circular back button and a help icon.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(icon: Icons.arrow_back, onTap: onBack),
        const Spacer(),
        _CircleButton(icon: Icons.help_outline, onTap: () {}),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceContainerLow,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AppTheme.onSurface),
        ),
      ),
    );
  }
}

/// Multi-colour Google "G" (brand colours), drawn with arcs.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 22,
    height: 22,
    child: CustomPaint(painter: _GooglePainter()),
  );
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final stroke = w * 0.2;
    final c = Offset(w / 2, w / 2);
    final r = (w - stroke) / 2;
    final rect = Rect.fromCircle(center: c, radius: r);
    double rad(double d) => d * math.pi / 180;
    void arc(Color color, double start, double sweep) {
      canvas.drawArc(
        rect,
        rad(start),
        rad(sweep),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }

    arc(const Color(0xFFEA4335), 200, 115); // red, top
    arc(const Color(0xFFFBBC05), 140, 62); // yellow, left
    arc(const Color(0xFF34A853), 45, 97); // green, bottom
    arc(const Color(0xFF4285F4), 0, 47); // blue, lower right
    canvas.drawRect(
      Rect.fromLTRB(w / 2, c.dy - stroke / 2, w - 0.5, c.dy + stroke / 2),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
