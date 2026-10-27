import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// A single "Recent Reflections" row on the profile screen (design-mapping §2,
/// screen 08): an icon tile, a title, and a state/time subtitle. Purely
/// presentational — the caller supplies real values only (no mock rows).
class HistoryTile extends StatelessWidget {
  const HistoryTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.history_edu,
    this.completed = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tileColor =
        completed ? AppTheme.primaryFixed : AppTheme.surfaceContainerHigh;
    final iconColor = completed ? AppTheme.primary : AppTheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tileColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.labelSmall
                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (completed)
            const Icon(Icons.check_circle,
                size: 20, color: AppTheme.primary),
        ],
      ),
    );
  }
}
