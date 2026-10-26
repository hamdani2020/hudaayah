import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/api_exception.dart';
import '../application/auth_controller.dart';

/// Sign-in screen. Google now; Apple is added in task 6.1 (iOS requirement).
/// Email/password is intentionally out of scope per the UI spec.
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
            message = 'Google sign-in: ${err.code.name}'
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

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text('Welcome to Hudaayah',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Sign in to begin your daily Quran habit.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
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
              // Apple Sign-In placeholder — wired in task 6.1.
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.apple),
                label: const Text('Continue with Apple (coming soon)'),
              ),
              const SizedBox(height: 24),
              Text(
                AppConfig.qfAttribution,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
