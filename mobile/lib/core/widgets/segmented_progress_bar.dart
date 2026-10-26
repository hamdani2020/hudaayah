import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// A row of [total] equal segments filled up to [current] (design-mapping §3,
/// screen 05). Filled = `secondaryContainer`, empty = `surfaceContainerHigh`.
/// Presentational — the exercise screen drives it from
/// `session.index` / `session.exercises.length`.
class SegmentedProgressBar extends StatelessWidget {
  const SegmentedProgressBar({
    super.key,
    required this.total,
    required this.current,
  });

  /// Number of segments.
  final int total;

  /// How many segments are filled (clamped to 0..total).
  final int current;

  @override
  Widget build(BuildContext context) {
    final filled = current.clamp(0, total);
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: i < filled
                    ? AppTheme.secondaryContainer
                    : AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
