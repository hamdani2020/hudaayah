import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/feedback_drawer.dart';
import '../../../core/widgets/segmented_progress_bar.dart';
import '../../quran_reader/data/lesson_models.dart';
import '../application/exercise_session_controller.dart';
import '../data/exercise_models.dart';
import 'listening_recall_widget.dart';
import 'multiple_choice_widget.dart';
import 'word_order_widget.dart';

/// Walks the learner through a lesson's exercises, one at a time (design-mapping
/// §2, screen 05). All grading is server-side via [exerciseSessionProvider];
/// this screen only sequences the UI and, on completion, routes to the
/// lesson-completion celebration with the session summary.
class ExerciseScreen extends ConsumerWidget {
  const ExerciseScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = (lessonId: lesson.id, exercises: lesson.exercises);
    final sessionAsync = ref.watch(exerciseSessionProvider(arg));
    final controller = ref.read(exerciseSessionProvider(arg).notifier);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: sessionAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
                err is ApiException ? err.message : 'Could not start practice.'),
          ),
          data: (session) {
            // On completion, hand off to the celebration screen with the summary.
            if (session.isComplete) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go('/lesson/${lesson.id}/complete',
                      extra: session.summary);
                }
              });
              return const Center(child: CircularProgressIndicator());
            }
            final exercise = session.current;
            if (exercise == null) {
              return const Center(
                  child: Text('No exercises for this lesson yet.'));
            }
            return _ExerciseBody(
              lesson: lesson,
              session: session,
              exercise: exercise,
              onSubmit: controller.submit,
              onNext: controller.next,
              onExit: () => context.go('/home'),
            );
          },
        ),
      ),
    );
  }
}

class _ExerciseBody extends StatelessWidget {
  const _ExerciseBody({
    required this.lesson,
    required this.session,
    required this.exercise,
    required this.onSubmit,
    required this.onNext,
    required this.onExit,
  });

  final Lesson lesson;
  final ExerciseSession session;
  final Exercise exercise;
  final void Function(Map<String, dynamic>) onSubmit;
  final VoidCallback onNext;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = session.exercises.length;
    final answered = session.lastResult != null;
    // Disable inputs after an answer is graded (until "Continue").
    final enabled = !answered && !session.submitting;

    // Optional section label / root, only when the exercise config provides it
    // (never fabricated — see design-mapping §0 / §2 screen 05).
    final sectionLabel = exercise.config['section_label'] as String?;
    final rootLabel = exercise.config['root'] as String?;

    return Column(
      children: [
        // Top bar: exit + segmented progress + count chip.
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                color: AppTheme.onSurfaceVariant,
                onPressed: onExit,
              ),
              Expanded(
                child: SegmentedProgressBar(
                  total: total,
                  current: session.index + (answered ? 1 : 0),
                ),
              ),
              const SizedBox(width: 12),
              CountChip(label: '${session.index + 1}/$total'),
            ],
          ),
        ),
        if (sectionLabel != null || rootLabel != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (sectionLabel != null)
                  Text(
                    sectionLabel.toUpperCase(),
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: AppTheme.onSurfaceVariant),
                  ),
                if (rootLabel != null)
                  Text(
                    rootLabel,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: AppTheme.secondary),
                  ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _renderExercise(enabled),
          ),
        ),
        if (session.error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(session.error!,
                style: TextStyle(color: theme.colorScheme.error)),
          ),
        if (answered)
          FeedbackDrawer(
            correct: session.lastResult!.correct,
            message: session.lastResult!.correct
                ? 'Mā shā’ Allāh! Correct'
                : 'Keep going — you’re learning',
            reflection: session.lastResult!.feedback,
            xpLabel: _xpLabel(session),
            onContinue: onNext,
            continueLabel: 'Continue',
          ),
      ],
    );
  }

  /// A "+XP" label only when the server returned an xp value; never invented.
  String? _xpLabel(ExerciseSession session) {
    final xp = session.summary?['xp_earned'];
    if (xp is num && xp > 0) return '+$xp XP';
    return null;
  }

  Widget _renderExercise(bool enabled) {
    switch (exercise.type) {
      case ExerciseType.multipleChoice:
        return MultipleChoiceWidget(
            exercise: exercise, enabled: enabled, onSubmit: onSubmit);
      case ExerciseType.wordOrder:
        return WordOrderWidget(
            exercise: exercise, enabled: enabled, onSubmit: onSubmit);
      case ExerciseType.listeningRecall:
        return ListeningRecallWidget(
            exercise: exercise,
            ayahs: lesson.ayahs,
            enabled: enabled,
            onSubmit: onSubmit);
      case ExerciseType.unknown:
        return const Text('Unsupported exercise.');
    }
  }
}
