/// Progress summary DTOs from `/progress/`.
class LessonProgress {
  final int lessonId;
  final String title;
  final int surah;
  final int ayahStart;
  final int ayahEnd;
  final int order;
  final String surahNameEn;
  final String surahNameAr;
  final String surahMeaning;
  final String state;
  final DateTime? completedAt;

  /// Published exercises in the lesson (0 when the server did not send it).
  final int exercisesTotal;

  /// Distinct exercises answered in the current attempt.
  final int exercisesAnswered;

  /// Title of the lesson before this one; used in the locked message.
  final String? previousTitle;

  const LessonProgress({
    required this.lessonId,
    required this.title,
    required this.surah,
    required this.ayahStart,
    required this.ayahEnd,
    required this.order,
    required this.surahNameEn,
    required this.surahNameAr,
    required this.surahMeaning,
    required this.state,
    this.completedAt,
    this.exercisesTotal = 0,
    this.exercisesAnswered = 0,
    this.previousTitle,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> j) => LessonProgress(
        lessonId: (j['lesson_id'] as num?)?.toInt() ?? 0,
        title: j['title'] as String? ?? '',
        surah: (j['surah'] as num?)?.toInt() ?? 0,
        ayahStart: (j['ayah_start'] as num?)?.toInt() ?? 0,
        ayahEnd: (j['ayah_end'] as num?)?.toInt() ?? 0,
        order: (j['order'] as num?)?.toInt() ?? 0,
        surahNameEn: j['surah_name_en'] as String? ?? '',
        surahNameAr: j['surah_name_ar'] as String? ?? '',
        surahMeaning: j['surah_meaning'] as String? ?? '',
        state: j['state'] as String? ?? 'not_started',
        completedAt: j['completed_at'] != null
            ? DateTime.tryParse(j['completed_at'] as String)
            : null,
        exercisesTotal: (j['exercises_total'] as num?)?.toInt() ?? 0,
        exercisesAnswered: (j['exercises_answered'] as num?)?.toInt() ?? 0,
        previousTitle: j['previous_title'] as String?,
      );

  bool get isCompleted => state == 'completed';
  bool get isInProgress => state == 'in_progress';
  bool get isLocked => state == 'locked';

  /// Next lesson to start: unlocked but not begun.
  bool get isUpNext => state == 'available';

  /// Display name, preferring the seeded English surah name.
  String get displayName =>
      surahNameEn.isNotEmpty ? 'Surah $surahNameEn' : title;

  /// e.g. "Ayah 1–7" (or "Ayah 3" for a single-ayah lesson).
  String get ayahRange =>
      ayahStart == ayahEnd ? 'Ayah $ayahStart' : 'Ayah $ayahStart–$ayahEnd';
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

/// One day of the current calendar week (Mon–Sun), from the server.
class WeekDay {
  final DateTime date;
  final bool active;
  final bool isToday;

  const WeekDay({required this.date, required this.active, required this.isToday});

  factory WeekDay.fromJson(Map<String, dynamic> j) => WeekDay(
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime(1970),
        active: j['active'] as bool? ?? false,
        isToday: j['is_today'] as bool? ?? false,
      );
}

class ProgressSummary {
  final int totalXp;
  final int streak;
  final DailyGoal dailyGoal;
  final List<LessonProgress> lessons;

  /// Current calendar week, Monday first. Empty if the server did not send it.
  final List<WeekDay> week;

  const ProgressSummary({
    required this.totalXp,
    required this.streak,
    required this.dailyGoal,
    required this.lessons,
    this.week = const [],
  });

  factory ProgressSummary.fromJson(Map<String, dynamic> j) => ProgressSummary(
        totalXp: j['total_xp'] as int? ?? 0,
        streak: j['streak'] as int? ?? 0,
        dailyGoal:
            DailyGoal.fromJson((j['daily_goal'] as Map?)?.cast<String, dynamic>() ?? {}),
        lessons: ((j['lessons'] as List?) ?? [])
            .map((l) => LessonProgress.fromJson((l as Map).cast<String, dynamic>()))
            .toList(),
        week: ((j['week'] as List?) ?? [])
            .map((d) => WeekDay.fromJson((d as Map).cast<String, dynamic>()))
            .toList(),
      );
}

/// Streak change returned by the completion response (`streak` block).
/// Server-owned: the app only renders it.
class StreakChange {
  final int current;
  final int previous;
  final bool increased;

  const StreakChange({
    required this.current,
    required this.previous,
    required this.increased,
  });

  factory StreakChange.fromJson(Map<String, dynamic> j) => StreakChange(
        current: (j['current'] as num?)?.toInt() ?? 0,
        previous: (j['previous'] as num?)?.toInt() ?? 0,
        increased: j['increased'] as bool? ?? false,
      );

  /// Parses the `streak` block of a completion summary; null when absent
  /// (older backend) so no celebration is shown.
  static StreakChange? fromSummary(Map<String, dynamic>? summary) {
    final raw = summary?['streak'];
    if (raw is! Map) return null;
    return StreakChange.fromJson(raw.cast<String, dynamic>());
  }

  /// Week days from a completion summary (`week`), Monday first.
  static List<WeekDay> weekFromSummary(Map<String, dynamic>? summary) {
    final raw = summary?['week'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((d) => WeekDay.fromJson(d.cast<String, dynamic>()))
        .toList();
  }
}
