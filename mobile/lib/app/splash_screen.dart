import 'package:flutter/material.dart';

import 'theme.dart';

/// Shown for a moment at app start while the saved session is restored, so a
/// signed-in learner goes straight to Home instead of seeing onboarding first.
/// The router leaves this screen as soon as the session check finishes.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hudaayah',
              style: theme.textTheme.headlineMedium?.copyWith(color: AppTheme.primary),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
