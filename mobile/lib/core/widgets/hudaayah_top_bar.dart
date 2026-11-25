import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../features/profile/application/reminder_controller.dart';
import '../../features/profile/presentation/widgets/reminder_sheet.dart';
import 'chips.dart';

/// Fixed-height app header shared by the tabbed screens (design-mapping §3,
/// screens 03/04/08): a "هد" primary-container avatar, the "Hudaayah" wordmark
/// with the current [tab] label beneath it, an optional [StreakChip], and a
/// notifications bell. The bell opens the daily [ReminderSheet] and shows an
/// active icon when the reminder is on; [onBellTap] overrides that default.
class HudaayahTopBar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final enabled =
        ref.watch(reminderControllerProvider).valueOrNull?.enabled ?? false;
    return Container(
      height: 64,
      color: AppTheme.surface.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Image.asset(
              'assets/images/logo.png',
              width: 40,
              height: 40,
              semanticLabel: 'Hudaayah',
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
              Text(tab, style: textTheme.labelSmall),
            ],
          ),
          const Spacer(),
          if (streakDays != null) ...[
            StreakChip(days: streakDays!),
            const SizedBox(width: 8),
          ],
          IconButton(
            onPressed: onBellTap ?? () => ReminderSheet.show(context),
            tooltip: 'Daily reminder',
            icon: Icon(
              enabled ? Icons.notifications_active : Icons.notifications_none,
            ),
            color: AppTheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
