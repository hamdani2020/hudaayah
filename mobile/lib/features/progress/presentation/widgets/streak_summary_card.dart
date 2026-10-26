import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Celebration streak card on the lesson-completion screen (design-mapping §2,
/// screen 07): the current streak, a "+1 today" chip, an optional "+XP" chip,
/// and a 7-day check row. Presentational — the caller passes real values from
/// the session summary + `progressSummaryProvider`; nothing is fabricated.
class StreakSummaryCard extends StatelessWidget {
  const StreakSummaryCard({
    super.key,
    required this.streakDays,
    this.xpEarned,
  });

  final int streakDays;

  /// XP earned this session; the "+XP" chip is omitted when null.
  final int? xpEarned;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final filled = streakDays.clamp(0, 7);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: AppTheme.secondaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                '$streakDays day streak',
                style: textTheme.titleMedium,
              ),
              const Spacer(),
              _Chip(
                label: '+1 today',
                background: AppTheme.secondaryFixed.withValues(alpha: 0.5),
                foreground: AppTheme.onSecondaryFixedVariant,
              ),
              if (xpEarned != null) ...[
                const SizedBox(width: 8),
                _Chip(
                  label: '+$xpEarned XP',
                  background: AppTheme.primaryFixed,
                  foreground: AppTheme.onPrimaryFixed,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                _DayDot(filled: i < filled),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: foreground, letterSpacing: 0),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppTheme.primaryFixed : AppTheme.surfaceContainerHigh,
      ),
      child: Icon(
        Icons.check,
        size: 16,
        color: filled ? AppTheme.primary : AppTheme.outlineVariant,
      ),
    );
  }
}
