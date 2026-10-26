import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';

/// Welcome & Onboarding — matches the Stitch "Welcome & Onboarding" screen:
/// hero headline, three value cards, "Get Started" CTA, QF attribution.
/// Presentational only.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const _pillars = [
    (
      icon: Icons.timer_outlined,
      tag: '10 mins / day',
      title: 'Daily Micro-Habits',
      body: 'Gentle, soothing daily pauses that fit your morning or evening routine.',
    ),
    (
      icon: Icons.auto_stories_outlined,
      tag: 'Spaced repetition',
      title: 'Quranic Vocabulary',
      body: 'Learn the most recurring root words with spaced-repetition memory cards.',
    ),
    (
      icon: Icons.record_voice_over_outlined,
      tag: 'Audio & meaning',
      title: 'Word-by-Word Recitation',
      body: 'Follow gentle, synchronized recitation with word-by-word meaning.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.secondaryContainer),
                const SizedBox(width: 8),
                Text('Hudaayah', style: theme.textTheme.headlineSmall),
              ],
            ),
            const SizedBox(height: 32),
            // Decorative Basmala accent (not a lesson; clearly ornamental).
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: const Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'UthmanicHafs', fontSize: 24, height: 1.8),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Build a Heartfelt, Daily Connection with the Quran',
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Short, gentle daily lessons for Surah Al-Fatihah.',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            Text("What you'll cultivate", style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final p in _pillars) ...[
              _PillarCard(icon: p.icon, tag: p.tag, title: p.title, body: p.body),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/auth'),
              child: const Text("Get Started — It's Free"),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                AppConfig.qfAttribution,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.icon,
    required this.tag,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String tag;
  final String title;
  final String body;

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
                color: AppTheme.secondaryFixed,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Icon(icon, color: theme.colorScheme.secondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tag.toUpperCase(), style: theme.textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(body,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
