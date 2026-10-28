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
  });

  factory LessonProgress.fromJson(Map<String, dynamic> j) => LessonProgress(
        lessonId: j['lesson_id'] as int,
        title: j['title'] as String? ?? '',
        surah: j['surah'] as int? ?? 0,
        ayahStart: j['ayah_start'] as int? ?? 0,
        ayahEnd: j['ayah_end'] as int? ?? 0,
        order: j['order'] as int? ?? 0,
        surahNameEn: j['surah_name_en'] as String? ?? '',
        surahNameAr: j['surah_name_ar'] as String? ?? '',
        surahMeaning: j['surah_meaning'] as String? ?? '',
        state: j['state'] as String? ?? 'not_started',
        completedAt: j['completed_at'] != null
            ? DateTime.tryParse(j['completed_at'] as String)
            : null,
      );

  bool get isCompleted => state == 'completed';

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
