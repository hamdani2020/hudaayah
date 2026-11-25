import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// One day of the week: a short label above a circle. Filled when the learner
/// completed a lesson that day; today is outlined. Presentational. Shared by
/// the profile weekly rhythm and the streak celebration.
class DaySlot extends StatelessWidget {
  const DaySlot({
    super.key,
    required this.label,
    required this.active,
    required this.isToday,
  });

  final String label;
  final bool active;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isToday ? AppTheme.primary : AppTheme.onSurfaceVariant,
            fontWeight: isToday ? FontWeight.w700 : null,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? AppTheme.primaryContainer
                : AppTheme.surfaceContainerHigh,
            border: isToday
                ? Border.all(color: AppTheme.secondaryContainer, width: 2)
                : null,
          ),
          child: Icon(
            Icons.star,
            size: 16,
            color: active ? AppTheme.tertiaryFixedDim : AppTheme.outlineVariant,
          ),
        ),
      ],
    );
  }
}
