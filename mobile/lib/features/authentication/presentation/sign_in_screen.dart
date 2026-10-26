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
      next.whenOrNull(error: (err, _) {
        final String message;
        if (err is ApiException) {
          message = err.message;
        } else if (err is GoogleSignInException) {
          message = 'Google sign-in: ${err.code.name}'
              '${err.description != null ? ' — ${err.description}' : ''}';
        } else {
          message = 'Sign-in failed: $err';
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      });
    });

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _TopBar(onBack: () => context.go('/onboarding')),
            const SizedBox(height: 32),
            const Center(child: _Emblem()),
            const SizedBox(height: 24),
            Text('Welcome to Hudaayah',
                style: theme.textTheme.displaySmall, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Save your reading streaks and sync your Quran learning progress '
              'seamlessly across devices.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                  : () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
            ),
            const SizedBox(height: 12),
            const AuthProviderButton(
              leading: Icon(Icons.apple, size: 22, color: AppTheme.onSurface),
              label: 'Continue with Apple (coming soon)',
              onPressed: null, // Apple — wired in a later task.
            ),
            const SizedBox(height: 28),
            const InfoCard(
              icon: Icons.lock_outline,
              title: 'Sacred Data Sanctuary',
              body: 'Your data is private and your spiritual journey is sacred. '
                  'No ads, no commercial tracking.',
            ),
            const SizedBox(height: 24),
            Text.rich(
              TextSpan(
                style: theme.textTheme.labelSmall,
                children: const [
                  TextSpan(text: "By continuing, you agree to Hudaayah's "),
                  TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: ' and acknowledge our '),
                  TextSpan(
                      text: 'Privacy Policy.',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Center(child: Text(AppConfig.qfAttribution,
                style: theme.textTheme.labelSmall)),
          ],
        ),
      ),
    );
  }
}

/// Top row: a circular back button, a centered "Account Setup" pill, and a help
/// icon (design-mapping §2 screen 02).
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _CircleButton(icon: Icons.arrow_back, onTap: onBack),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.secondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ACCOUNT SETUP',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
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

/// Stacked rotated tinted tiles behind a `surface-container-lowest` emblem tile
/// (the HTML emblem.png is not an app asset — use an [Icons.auto_awesome] glyph).
class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.18,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryFixed,
                borderRadius: BorderRadius.circular(AppTheme.radius2xl),
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.14,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.secondaryFixed,
                borderRadius: BorderRadius.circular(AppTheme.radius2xl),
              ),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome,
                size: 30, color: AppTheme.secondaryContainer),
          ),
        ],
      ),
    );
  }
}

/// Small painted Google "G" glyph stand-in, themed. Kept simple.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Text(
        'G',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

