import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'chips.dart';

/// Fixed-height app header shared by the tabbed screens (design-mapping §3,
/// screens 03/04/08): a "هد" primary-container avatar, the "Hudaayah" wordmark
/// with the current [tab] label beneath it, an optional [StreakChip], and a
/// notifications bell. Purely presentational — callers wire [onBellTap].
class HudaayahTopBar extends StatelessWidget {
  const HudaayahTopBar({
    super.key,
    required this.tab,
    this.streakDays,
    this.onBellTap,
  });

  /// Tab label rendered under the wordmark (e.g. "Home", "Read", "Profile").
  final String tab;

  /// When non-null a [StreakChip] is shown with this many days.
  final int? streakDays;

  final VoidCallback? onBellTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: 64,
      color: AppTheme.surface.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Text(
              'هد',
              style: textTheme.titleMedium?.copyWith(color: AppTheme.onPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Hudaayah',
                style: textTheme.titleMedium?.copyWith(color: AppTheme.primary),
              ),
              Text(
                tab,
                style: textTheme.labelSmall,
              ),
            ],
          ),
          const Spacer(),
          if (streakDays != null) ...[
            StreakChip(days: streakDays!),
            const SizedBox(width: 8),
          ],
          IconButton(
            onPressed: onBellTap,
            icon: const Icon(Icons.notifications_none),
            color: AppTheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
