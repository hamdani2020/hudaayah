import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// A single row in the "Your Learning Journey" list (design-mapping §2 screen
/// 04). Completed lessons show a `primary-fixed` check tile + "Completed" chip;
/// in-progress lessons show a `secondary-fixed` tile + an amber "In Progress"
/// chip. Presentational — the caller maps real `LessonProgress` into these.
class LessonJourneyTile extends StatelessWidget {
  const LessonJourneyTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.completed,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final bool completed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed
                      ? AppTheme.primaryFixed
                      : AppTheme.secondaryFixed,
                ),
                child: Icon(
                  completed ? Icons.check_circle : Icons.auto_stories,
                  size: 20,
                  color: completed
                      ? AppTheme.primary
                      : AppTheme.onSecondaryFixed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StateChip(completed: completed),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.completed});
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: completed
            ? AppTheme.surfaceContainerHigh
            : AppTheme.secondaryFixed.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        completed ? 'Completed' : 'In Progress',
        style: theme.textTheme.labelSmall?.copyWith(
          color: completed ? AppTheme.onSurfaceVariant : AppTheme.secondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
