import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../authentication/application/auth_controller.dart';
import '../../review/data/review_repository.dart';
import '../data/progress_models.dart';
import '../data/progress_repository.dart';

/// Home Dashboard — matches the Stitch home screen (in-scope parts): greeting,
/// streak badge, "Today's Sacred Habit" card with progress + Continue, daily
/// goal, and the learning journey list. Out-of-scope widgets from the mockup
/// ("Word of the Day", Adhkar reminder) are intentionally omitted.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(progressSummaryProvider);
    final dueAsync = ref.watch(dueReviewsProvider);
    final name = ref.watch(authControllerProvider).valueOrNull?.user?.displayName ?? '';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(progressSummaryProvider);
            ref.invalidate(dueReviewsProvider);
            await ref.read(progressSummaryProvider.future);
          },
          child: summaryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => _CenteredRetry(
              onRetry: () => ref.invalidate(progressSummaryProvider),
            ),
            data: (summary) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _Header(name: name, streak: summary.streak,
                    onProfile: () => context.go('/profile')),
                const SizedBox(height: 20),
                _HabitCard(summary: summary, onContinue: () => context.go('/reader')),
                const SizedBox(height: 16),
                _DailyGoalCard(goal: summary.dailyGoal),
                const SizedBox(height: 16),
                dueAsync.maybeWhen(
                  data: (items) => items.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: OutlinedButton.icon(
                            onPressed: () => context.go('/review'),
                            icon: const Icon(Icons.schedule),
                            label: Text('Review ${items.length} word'
                                '${items.length == 1 ? '' : 's'}'),
                          ),
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
                Text('Your Learning Journey', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _JourneyList(lessons: summary.lessons),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.streak, required this.onProfile});
  final String name;
  final int streak;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _StreakBadge(streak: streak),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: onProfile,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          name.isEmpty ? 'Assalamu Alaikum' : 'Assalamu Alaikum, $name',
          style: theme.textTheme.displaySmall,
        ),
        const SizedBox(height: 4),
        Text('May your recitation bring tranquil light today.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.secondaryFixed,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department,
              size: 18, color: theme.colorScheme.secondary),
          const SizedBox(width: 6),
          Text('${streak}d streak',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.secondary)),
        ],
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.summary, required this.onContinue});
  final ProgressSummary summary;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fatiha = summary.lessons.isNotEmpty ? summary.lessons.first : null;
    final done = fatiha?.isCompleted ?? false;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Sacred Habit",
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: AppTheme.onPrimaryContainer)),
          const SizedBox(height: 6),
          Text('Surah Al-Fatihah',
              style: theme.textTheme.headlineSmall?.copyWith(color: AppTheme.onPrimary)),
          Text('Ayah 1 – 7 • The Opening',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.onPrimaryContainer)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: done ? 1.0 : 0.0,
              backgroundColor: AppTheme.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.secondaryContainer,
              foregroundColor: AppTheme.onSecondary,
            ),
            onPressed: onContinue,
            child: Text(done ? 'Review Al-Fatihah' : 'Continue'),
          ),
        ],
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.goal});
  final DailyGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's goal", style: theme.textTheme.titleMedium),
                Text('${goal.earnedXp}/${goal.goalXp} XP',
                    style: theme.textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: goal.fraction, minHeight: 8),
            ),
            const SizedBox(height: 6),
            Text(
              goal.met ? 'Goal met — baarak Allahu feek!' : 'Keep going, almost there.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyList extends StatelessWidget {
  const _JourneyList({required this.lessons});
  final List<LessonProgress> lessons;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (lessons.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Start your first lesson to begin your journey.',
              style: theme.textTheme.bodyMedium),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (final l in lessons)
            ListTile(
              leading: Icon(
                l.isCompleted ? Icons.check_circle : Icons.auto_stories,
                color: l.isCompleted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary,
              ),
              title: Text('Surah Al-Fatihah', style: theme.textTheme.titleMedium),
              subtitle: Text(l.isCompleted ? 'Completed' : 'In progress'),
            ),
        ],
      ),
    );
  }
}

class _CenteredRetry extends StatelessWidget {
  const _CenteredRetry({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Center(child: Text('Could not load your progress.')),
        const SizedBox(height: 12),
        Center(
          child: FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ],
    );
  }
}
