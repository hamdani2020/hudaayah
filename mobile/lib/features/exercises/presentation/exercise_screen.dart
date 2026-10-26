import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../../quran_reader/data/lesson_models.dart';
import '../application/exercise_session_controller.dart';
import '../data/exercise_models.dart';
import 'listening_recall_widget.dart';
import 'multiple_choice_widget.dart';
import 'word_order_widget.dart';

/// Walks the learner through a lesson's exercises, one at a time, then shows a
/// gentle completion summary. All grading is server-side.
class ExerciseScreen extends ConsumerWidget {
  const ExerciseScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = (lessonId: lesson.id, exercises: lesson.exercises);
    final sessionAsync = ref.watch(exerciseSessionProvider(arg));
    final controller = ref.read(exerciseSessionProvider(arg).notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(err is ApiException ? err.message : 'Could not start practice.'),
        ),
        data: (session) {
          if (session.isComplete) {
            return _CompletionView(summary: session.summary!);
          }
          final exercise = session.current;
          if (exercise == null) {
            return const Center(child: Text('No exercises for this lesson yet.'));
          }
          return _ExerciseBody(
            lesson: lesson,
            session: session,
            exercise: exercise,
            onSubmit: controller.submit,
            onNext: controller.next,
          );
        },
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
  });

  final Lesson lesson;
  final ExerciseSession session;
  final Exercise exercise;
  final void Function(Map<String, dynamic>) onSubmit;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answered = session.lastResult != null;
    // Disable inputs after an answer is graded (until "Continue").
    final enabled = !answered && !session.submitting;

    return Column(
      children: [
        LinearProgressIndicator(
          value: (session.index + (answered ? 1 : 0)) / session.exercises.length,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _renderExercise(enabled),
          ),
        ),
        if (answered) _Feedback(result: session.lastResult!, onNext: onNext),
        if (session.error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(session.error!,
                style: TextStyle(color: theme.colorScheme.error)),
          ),
      ],
    );
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
            exercise: exercise, ayahs: lesson.ayahs, enabled: enabled, onSubmit: onSubmit);
      case ExerciseType.unknown:
        return const Text('Unsupported exercise.');
    }
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.result, required this.onNext});

  final GradeResult result;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correct = result.correct;
    final color = correct ? theme.colorScheme.primary : theme.colorScheme.secondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: color.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(correct ? Icons.check_circle : Icons.favorite, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(result.feedback,
                  style: theme.textTheme.bodyLarge)),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onNext, child: const Text('Continue')),
        ],
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correct = summary['correct'] ?? 0;
    final total = summary['total'] ?? 0;
    final xp = summary['xp_earned'] ?? 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Alhamdulillah!',
                style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('You recalled $correct of $total. +$xp XP',
                style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Keep going — a little each day builds a lasting habit.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
