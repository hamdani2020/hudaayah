import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';

/// Phase-1 onboarding placeholder, styled from the Sacred Serenity theme and
/// the Stitch welcome screen. Presentational only — no progression logic.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Hudaayah', style: theme.textTheme.headlineMedium),
              const Spacer(),
              Text(
                'Build a Heartfelt, Daily Connection with the Quran',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Short, gentle daily lessons for Surah Al-Fatihah.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/auth'),
                  child: const Text("Get Started — It's Free"),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  AppConfig.qfAttribution,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
