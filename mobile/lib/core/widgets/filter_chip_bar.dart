import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Horizontally scrolling row of selectable pills (design-mapping §3, screen
/// 03). Selected pill = `primary` / `onPrimary`; unselected =
/// `surface-container-lowest` / `on-surface-variant`. Selection state is owned
/// by the caller via [selectedIndex] + [onSelected] (presentational).
class FilterChipBar extends StatelessWidget {
  const FilterChipBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _Pill(
              label: labels[i],
              selected: i == selectedIndex,
              textTheme: textTheme,
              onTap: () => onSelected(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.textTheme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.primary : AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: selected ? AppTheme.onPrimary : AppTheme.onSurfaceVariant,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
