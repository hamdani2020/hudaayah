import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exercise_models.dart';
import '../data/exercise_repository.dart';

/// Drives one lesson's exercise session: start attempt, submit each answer,
/// then complete. The server grades and owns scoring; this only sequences UI.
class ExerciseSession {
  final int lessonId;
  final List<Exercise> exercises;
  final int? attemptId;
  final int index;
  final GradeResult? lastResult;
  final bool submitting;
  final Map<String, dynamic>? summary; // set when completed
  final String? error;

  const ExerciseSession({
    required this.lessonId,
    required this.exercises,
    this.attemptId,
    this.index = 0,
    this.lastResult,
    this.submitting = false,
    this.summary,
    this.error,
  });

  Exercise? get current =>
      index < exercises.length ? exercises[index] : null;
  bool get isComplete => summary != null;

  ExerciseSession copyWith({
    int? attemptId,
    int? index,
    GradeResult? lastResult,
    bool? submitting,
    Map<String, dynamic>? summary,
    String? error,
    bool clearResult = false,
    bool clearError = false,
  }) =>
      ExerciseSession(
        lessonId: lessonId,
        exercises: exercises,
        attemptId: attemptId ?? this.attemptId,
        index: index ?? this.index,
        lastResult: clearResult ? null : (lastResult ?? this.lastResult),
        submitting: submitting ?? this.submitting,
        summary: summary ?? this.summary,
        error: clearError ? null : (error ?? this.error),
      );
}

class ExerciseSessionController
    extends FamilyAsyncNotifier<ExerciseSession, ({int lessonId, List<Exercise> exercises})> {
  ExerciseRepository get _repo => ref.read(exerciseRepositoryProvider);

  @override
  Future<ExerciseSession> build(({int lessonId, List<Exercise> exercises}) arg) async {
    final attemptId = await _repo.startAttempt(arg.lessonId);
    return ExerciseSession(
      lessonId: arg.lessonId,
      exercises: arg.exercises,
      attemptId: attemptId,
    );
  }

  Future<void> submit(Map<String, dynamic> submitted) async {
    final session = state.valueOrNull;
    if (session == null || session.current == null || session.attemptId == null) {
      return;
    }
    state = AsyncData(session.copyWith(submitting: true, clearError: true));
    try {
      final result = await _repo.submitAnswer(
        attemptId: session.attemptId!,
        exerciseId: session.current!.id,
        submitted: submitted,
      );
      state = AsyncData(session.copyWith(submitting: false, lastResult: result));
    } catch (e) {
      state = AsyncData(session.copyWith(
          submitting: false, error: 'Could not submit your answer.'));
    }
  }

  /// Advance to the next exercise; if none remain, complete the attempt.
  Future<void> next() async {
    final session = state.valueOrNull;
    if (session == null || session.attemptId == null) return;

    final nextIndex = session.index + 1;
    if (nextIndex < session.exercises.length) {
      state = AsyncData(session.copyWith(index: nextIndex, clearResult: true));
      return;
    }
    // Complete — idempotency key is stable per attempt so retries never double-award.
    try {
      final summary = await _repo.complete(
        attemptId: session.attemptId!,
        idempotencyKey: 'attempt-${session.attemptId}',
      );
      state = AsyncData(session.copyWith(summary: summary, clearResult: true));
    } catch (e) {
      state = AsyncData(session.copyWith(error: 'Could not finish the lesson.'));
    }
  }
}

final exerciseSessionProvider = AsyncNotifierProvider.family<
    ExerciseSessionController,
    ExerciseSession,
    ({int lessonId, List<Exercise> exercises})>(ExerciseSessionController.new);
