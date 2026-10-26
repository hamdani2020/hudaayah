/// Progress summary DTOs from `/progress/`.
class LessonProgress {
  final int lessonId;
  final String state;
  final DateTime? completedAt;

  const LessonProgress({
    required this.lessonId,
    required this.state,
    this.completedAt,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> j) => LessonProgress(
        lessonId: j['lesson_id'] as int,
        state: j['state'] as String? ?? 'not_started',
        completedAt: j['completed_at'] != null
            ? DateTime.tryParse(j['completed_at'] as String)
            : null,
      );

  bool get isCompleted => state == 'completed';
}

class DailyGoal {
  final int goalXp;
  final int earnedXp;
  final bool met;

  const DailyGoal({required this.goalXp, required this.earnedXp, required this.met});

  factory DailyGoal.fromJson(Map<String, dynamic> j) => DailyGoal(
        goalXp: j['goal_xp'] as int? ?? 0,
        earnedXp: j['earned_xp'] as int? ?? 0,
        met: j['met'] as bool? ?? false,
      );

  double get fraction => goalXp == 0 ? 0 : (earnedXp / goalXp).clamp(0, 1).toDouble();
}

class ProgressSummary {
  final int totalXp;
  final int streak;
  final DailyGoal dailyGoal;
  final List<LessonProgress> lessons;

  const ProgressSummary({
    required this.totalXp,
    required this.streak,
    required this.dailyGoal,
    required this.lessons,
  });

  factory ProgressSummary.fromJson(Map<String, dynamic> j) => ProgressSummary(
        totalXp: j['total_xp'] as int? ?? 0,
        streak: j['streak'] as int? ?? 0,
        dailyGoal:
            DailyGoal.fromJson((j['daily_goal'] as Map?)?.cast<String, dynamic>() ?? {}),
        lessons: ((j['lessons'] as List?) ?? [])
            .map((l) => LessonProgress.fromJson((l as Map).cast<String, dynamic>()))
            .toList(),
      );
}
