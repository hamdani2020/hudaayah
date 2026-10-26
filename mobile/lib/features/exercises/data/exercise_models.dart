/// Exercise DTOs. The server never sends the answer key; the client submits an
/// answer and receives `{correct, feedback}` after grading.
enum ExerciseType { multipleChoice, wordOrder, listeningRecall, unknown }

ExerciseType _parseType(String? s) {
  switch (s) {
    case 'multiple_choice':
      return ExerciseType.multipleChoice;
    case 'word_order':
      return ExerciseType.wordOrder;
    case 'listening_recall':
      return ExerciseType.listeningRecall;
    default:
      return ExerciseType.unknown;
  }
}

class Exercise {
  final int id;
  final ExerciseType type;
  final int position;
  final Map<String, dynamic> config;
  final Map<String, dynamic> contentReferences;

  const Exercise({
    required this.id,
    required this.type,
    required this.position,
    required this.config,
    required this.contentReferences,
  });

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        id: j['id'] as int,
        type: _parseType(j['type'] as String?),
        position: j['position'] as int? ?? 0,
        config: (j['config'] as Map?)?.cast<String, dynamic>() ?? {},
        contentReferences:
            (j['content_references'] as Map?)?.cast<String, dynamic>() ?? {},
      );

  String get prompt => config['prompt'] as String? ?? '';
}

/// Result of submitting one answer.
class GradeResult {
  final bool correct;
  final String feedback;
  const GradeResult({required this.correct, required this.feedback});

  factory GradeResult.fromJson(Map<String, dynamic> j) => GradeResult(
        correct: j['correct'] as bool? ?? false,
        feedback: j['feedback'] as String? ?? '',
      );
}
