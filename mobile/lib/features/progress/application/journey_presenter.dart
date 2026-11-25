import '../data/progress_models.dart';

/// Visual state of a Learning Journey row.
enum JourneyTileState { completed, inProgress, upNext, locked }

/// Everything a journey tile needs, derived from [LessonProgress].
class JourneyTileData {
  const JourneyTileData({
    required this.lessonId,
    required this.title,
    required this.subtitle,
    required this.state,
    this.lockedMessage,
  });

  final int lessonId;
  final String title;
  final String subtitle;
  final JourneyTileState state;

  /// Gentle explanation shown when a locked tile is tapped.
  final String? lockedMessage;
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime d) {
  final l = d.toLocal();
  return '${l.day} ${_months[l.month - 1]} ${l.year}';
}

/// Gentle unlock wording. No failure or comparison framing.
String lockedMessageFor(LessonProgress l) {
  final prev = l.previousTitle;
  return (prev == null || prev.isEmpty)
      ? 'This lesson opens after you complete the one before it.'
      : 'Opens after you complete $prev';
}

JourneyTileData journeyTileFor(LessonProgress l) {
  final JourneyTileState state;
  final String detail;
  if (l.isCompleted) {
    state = JourneyTileState.completed;
    detail = l.completedAt != null
        ? 'Completed ${_formatDate(l.completedAt!)}'
        : 'Completed';
  } else if (l.isInProgress) {
    state = JourneyTileState.inProgress;
    detail = l.exercisesTotal > 0
        ? '${l.exercisesAnswered} of ${l.exercisesTotal} exercises'
        : 'In progress';
  } else if (l.isLocked) {
    state = JourneyTileState.locked;
    detail = lockedMessageFor(l);
  } else {
    state = JourneyTileState.upNext;
    detail = 'Word Meanings & Practice';
  }
  return JourneyTileData(
    lessonId: l.lessonId,
    title: l.displayName,
    subtitle: '${l.ayahRange} • $detail',
    state: state,
    lockedMessage: l.isLocked ? lockedMessageFor(l) : null,
  );
}

/// Home focus card rule: the in-progress lesson, else Up next, else the last
/// completed lesson (Review). Null when there are no lessons.
LessonProgress? focusLesson(List<LessonProgress> lessons) {
  LessonProgress? firstWhereOrNull(bool Function(LessonProgress) test) {
    for (final l in lessons) {
      if (test(l)) return l;
    }
    return null;
  }

  final inProgress = firstWhereOrNull((l) => l.isInProgress);
  if (inProgress != null) return inProgress;
  final upNext = firstWhereOrNull((l) => l.isUpNext);
  if (upNext != null) return upNext;
  LessonProgress? lastCompleted;
  for (final l in lessons) {
    if (l.isCompleted) lastCompleted = l;
  }
  return lastCompleted;
}

/// Ring fraction for the focus card.
double focusPercent(LessonProgress l) {
  if (l.isCompleted) return 1.0;
  if (l.isInProgress && l.exercisesTotal > 0) {
    return (l.exercisesAnswered / l.exercisesTotal).clamp(0, 1).toDouble();
  }
  return 0.0;
}
