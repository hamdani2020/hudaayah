import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/hudaayah_top_bar.dart';
import '../../authentication/application/auth_controller.dart';
import '../../review/data/review_repository.dart';
import '../data/progress_models.dart';
import '../data/progress_repository.dart';
import 'widgets/habit_card.dart';
import 'widgets/lesson_journey_tile.dart';

/// Home Dashboard — matches the Stitch home screen (04): fixed top bar + streak
/// chip, greeting, the "Today's Sacred Habit" card with an honest progress ring
/// and "Continue Reading", the learning journey list, and the QF attribution.
/// Out-of-scope mockup widgets with no data source ("Word of the Day", live
/// Hijri date, Adhkar reminder) are intentionally omitted. Presentational: all
/// provider/controller wiring is preserved.
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
        child: summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _CenteredRetry(
            onRetry: () => ref.invalidate(progressSummaryProvider),
          ),
          data: (summary) => Column(
            children: [
              HudaayahTopBar(tab: 'Home', streakDays: summary.streak),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(progressSummaryProvider);
                    ref.invalidate(dueReviewsProvider);
                    await ref.read(progressSummaryProvider.future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    children: [
                      _Greeting(name: name),
                      const SizedBox(height: 20),
                      _buildHabitCard(context, summary),
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
                      Text('Your Learning Journey',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(color: AppTheme.primary)),
                      const SizedBox(height: 10),
                      _JourneyList(lessons: summary.lessons),
                      const SizedBox(height: 24),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Today's habit card targets the next lesson to work on: the first lesson
  /// that isn't completed, else the first lesson. Title/subtitle come from the
  /// lesson's own data (not a hardcoded surah), so Al-Baqarah shows correctly.
  Widget _buildHabitCard(BuildContext context, ProgressSummary summary) {
    final lessons = summary.lessons;
    if (lessons.isEmpty) {
      return HabitCard(
        title: 'Start Learning',
        subtitle: 'Begin your first lesson',
        percent: 0,
        buttonLabel: 'Start',
        onContinue: () => context.go('/surah'),
      );
    }

    final focus = lessons.firstWhere(
      (l) => !l.isCompleted,
      orElse: () => lessons.first,
    );
    final name =
        focus.surahNameEn.isNotEmpty ? focus.surahNameEn : focus.title;
    final subtitle = focus.surahMeaning.isNotEmpty
        ? '${focus.ayahRange} • ${focus.surahMeaning}'
        : focus.ayahRange;

    return HabitCard(
      title: 'Surah $name',
      subtitle: subtitle,
      percent: focus.isCompleted ? 1.0 : 0.0,
      buttonLabel: focus.isCompleted ? 'Review $name' : 'Continue Reading',
      onContinue: () => context.go('/reader/${focus.lessonId}'),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isEmpty ? 'Assalamu Alaikum' : 'Assalamu Alaikum, $name',
          style: theme.textTheme.displaySmall?.copyWith(color: AppTheme.primary),
        ),
        const SizedBox(height: 4),
        Text('May your recitation bring tranquil light today.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
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
    return Column(
      children: [
        for (final l in lessons) ...[
          Builder(builder: (_) {
            final name = l.surahNameEn.isNotEmpty ? l.surahNameEn : l.title;
            return LessonJourneyTile(
              title: 'Surah $name',
              subtitle: l.isCompleted
                  ? '${l.ayahRange} • Completed'
                  : '${l.ayahRange} • Word Meanings & Practice',
              completed: l.isCompleted,
            );
          }),
          const SizedBox(height: 8),
        ],
      ],
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
