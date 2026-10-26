import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/stat_card.dart';
import '../data/progress_repository.dart';
import 'widgets/streak_summary_card.dart';

/// Lesson-completion celebration (design-mapping §2, screen 07; route
/// `/lesson/:id/complete`, top-level outside the shell). Driven by the session
/// `summary` map (`{correct,total,xp_earned}`) passed via GoRouter `extra` and
/// `progressSummaryProvider` for the streak. No new provider/API.
///
/// Adab: encouraging copy only — never "you failed". The "Ayah of
/// Encouragement" card is intentionally omitted here: this screen receives no
/// content/ayah from the backend, so rendering Arabic would mean hardcoding
/// verse text (forbidden). Instead we show our own gentle UI sentence.
class LessonCompletionScreen extends ConsumerWidget {
  const LessonCompletionScreen({
    super.key,
    required this.lessonId,
    this.summary,
  });

  final int lessonId;

  /// `{correct, total, xp_earned}` — any key may be absent; counts are rendered
  /// only when present (never fabricated).
  final Map<String, dynamic>? summary;

  int? _asInt(Object? v) => v is int ? v : (v is num ? v.toInt() : null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final streak = ref.watch(progressSummaryProvider).valueOrNull?.streak ?? 0;

    final correct = _asInt(summary?['correct']);
    final total = _asInt(summary?['total']);
    final xp = _asInt(summary?['xp_earned']);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: AppTheme.onSurfaceVariant,
                    onPressed: () => context.go('/home'),
                  ),
                  const Spacer(),
                  Text('Session Complete', style: textTheme.titleMedium),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  const SizedBox(height: 8),
                  const Center(child: _CheckMedallion()),
                  const SizedBox(height: 24),
                  Text(
                    'Alhamdulillah!',
                    textAlign: TextAlign.center,
                    style: textTheme.displaySmall
                        ?.copyWith(color: AppTheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You showed up for your journey today. Every verse brings '
                    'the heart a little closer.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  StreakSummaryCard(streakDays: streak, xpEarned: xp),
                  if (correct != null && total != null) ...[
                    const SizedBox(height: 16),
                    StatCard(
                      icon: Icons.stars,
                      value: '$correct / $total',
                      caption: 'Vocabulary recalled this session',
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryPillButton(
                    label: 'Continue to Dashboard',
                    trailingIcon: null,
                    onPressed: () => context.go('/home'),
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Review Lesson Notes',
                    onPressed: () => context.go('/reader/$lessonId'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppConfig.qfAttribution,
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall
                        ?.copyWith(color: AppTheme.onSurfaceVariant),
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

/// Decorative geometric check medallion built from theme tints (design-mapping
/// §2, screen 07). Purely presentational.
class _CheckMedallion extends StatelessWidget {
  const _CheckMedallion();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryFixed.withValues(alpha: 0.5),
      ),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primaryContainer,
        ),
        child: const Icon(
          Icons.check,
          size: 40,
          color: AppTheme.onPrimary,
        ),
      ),
    );
  }
}
