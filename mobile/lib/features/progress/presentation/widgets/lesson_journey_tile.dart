import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../application/journey_presenter.dart';

/// A single row in the "Your Learning Journey" list. Shows one of four states:
/// completed, in progress, up next (Start) or locked (muted, lock icon).
/// Presentational: [data] is derived by `journeyTileFor`.
class LessonJourneyTile extends StatelessWidget {
  const LessonJourneyTile({
    super.key,
    required this.data,
    this.onTap,
  });

  final JourneyTileData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = data.state == JourneyTileState.locked;
    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _Leading(state: data.state),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title,
                    style:
                        theme.textTheme.titleMedium?.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(data.subtitle, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StateChip(state: data.state),
        ],
      ),
    );
    return Material(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        onTap: onTap,
        child: locked ? Opacity(opacity: 0.65, child: content) : content,
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({required this.state});
  final JourneyTileState state;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color bg, Color fg) = switch (state) {
      JourneyTileState.completed => (
          Icons.check_circle,
          AppTheme.primaryFixed,
          AppTheme.primary
        ),
      JourneyTileState.locked => (
          Icons.lock_outline,
          AppTheme.surfaceContainerHigh,
          AppTheme.onSurfaceVariant
        ),
      _ => (
          Icons.auto_stories,
          AppTheme.secondaryFixed,
          AppTheme.onSecondaryFixed
        ),
    };
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      child: Icon(icon, size: 20, color: fg),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});
  final JourneyTileState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (String label, Color bg, Color fg) = switch (state) {
      JourneyTileState.completed => (
          'Completed',
          AppTheme.surfaceContainerHigh,
          AppTheme.onSurfaceVariant
        ),
      JourneyTileState.inProgress => (
          'In Progress',
          AppTheme.secondaryFixed.withValues(alpha: 0.5),
          AppTheme.secondary
        ),
      JourneyTileState.upNext => (
          'Start',
          AppTheme.primaryFixed,
          AppTheme.primary
        ),
      JourneyTileState.locked => (
          'Locked',
          AppTheme.surfaceContainerHigh,
          AppTheme.onSurfaceVariant
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}
