import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../app/theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/api_exception.dart';
import '../application/auth_controller.dart';

/// Sign In & Authentication — matches the Stitch sign-in screen: welcome copy,
/// Google + Apple buttons, "Sacred Data Sanctuary" trust note, ToS + Privacy.
/// Email/password is intentionally out of scope. Apple wired in task 6.1.
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
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            Icon(Icons.auto_awesome,
                size: 40, color: theme.colorScheme.secondaryContainer),
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
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: isLoading
                  ? null
                  : () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
              icon: isLoading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.login),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: null, // Apple — task 6.1
              icon: const Icon(Icons.apple),
              label: const Text('Continue with Apple (coming soon)'),
            ),
            const SizedBox(height: 28),
            _TrustCard(),
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

class _TrustCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sacred Data Sanctuary', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Your data is private and your spiritual journey is sacred. '
                    'No ads, no commercial tracking.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
