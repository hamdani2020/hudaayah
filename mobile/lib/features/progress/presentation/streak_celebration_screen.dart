import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../data/progress_models.dart';
import 'widgets/day_slot.dart';

/// Attempt ids whose streak celebration was already shown this session, so a
/// rebuild or re-entry never shows it twice for one attempt.
final Set<int> _shownStreakAttempts = <int>{};

/// True (and records it) the first time it is called for [attemptId].
bool markStreakCelebrationShown(int attemptId) =>
    _shownStreakAttempts.add(attemptId);

/// Full-screen streak celebration (route `/lesson/:id/streak`), shown after a
/// lesson only when the server reports `streak.increased`. Renders server
/// values from the completion [summary]; Continue goes to the completion
/// screen with the same summary. Gentle wording, no comparison with others.
class StreakCelebrationScreen extends StatelessWidget {
  const StreakCelebrationScreen({
    super.key,
    required this.lessonId,
    required this.summary,
  });

  final int lessonId;
  final Map<String, dynamic>? summary;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  void _continue(BuildContext context) {
    context.pushReplacement('/lesson/$lessonId/complete', extra: summary);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streak = StreakChange.fromSummary(summary);
    final week = StreakChange.weekFromSummary(summary);
    final days = streak?.current ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _continue(context);
      },
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (context, t, child) => Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Transform.scale(scale: t, child: child),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    size: 112,
                    color: AppTheme.secondaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$days',
                  style: theme.textTheme.displayLarge
                      ?.copyWith(color: AppTheme.primary),
                ),
                Text(
                  days == 1 ? 'day in a row' : 'days in a row',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Alḥamdulillāh, you showed up for the Qur’an today. '
                  'Every day counts, whenever you return.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                if (week.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < 7; i++)
                          DaySlot(
                            label: _days[i],
                            active: i < week.length && week[i].active,
                            isToday: i < week.length && week[i].isToday,
                          ),
                      ],
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _continue(context),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
