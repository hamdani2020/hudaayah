import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/errors/api_exception.dart';

/// Backend error code returned (HTTP 403) for a lesson that is not open yet.
const lessonLockedCode = 'lesson_locked';

/// Gentle wording shown instead of a generic error. No failure framing.
const lessonLockedMessage =
    'This lesson opens after you complete the one before it.';

/// True when [err] is the backend's `lesson_locked` error.
bool isLessonLocked(Object? err) =>
    err is ApiException && err.code == lessonLockedCode;

/// Calm full-area notice for a locked lesson, with a way back to the Read tab.
class LessonLockedNotice extends StatelessWidget {
  const LessonLockedNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline,
                size: 40, color: AppTheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              lessonLockedMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/surah'),
              child: const Text('Back to lessons'),
            ),
          ],
        ),
      ),
    );
  }
}
