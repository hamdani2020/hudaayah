import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Amber streak pill — `secondary-fixed/50` background with a flame icon and a
/// "[days]d Streak" label (design-mapping §3, screens 04/08).
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.secondaryFixed.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 16,
            color: AppTheme.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            '${days}d Streak',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.onSecondaryFixedVariant,
                  letterSpacing: 0,
                ),
          ),
        ],
      ),
    );
  }
}

/// Small `surface-container-low` count pill with a star — e.g. "3/5"
/// (design-mapping §3, screen 05).
class CountChip extends StatelessWidget {
  const CountChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rate, size: 16, color: AppTheme.secondaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppTheme.onSurface, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}
