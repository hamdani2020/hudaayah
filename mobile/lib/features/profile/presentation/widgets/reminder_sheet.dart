import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../application/reminder_controller.dart';
import '../reminder_actions.dart';

/// Bottom sheet for the daily reminder: an on/off switch and a "Time" row that
/// opens the time picker. Backed by [reminderControllerProvider], so changes
/// show up on the Profile screen too.
class ReminderSheet extends ConsumerWidget {
  const ReminderSheet({super.key});

  /// Opens the sheet from [context].
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const ReminderSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reminder = ref.watch(reminderControllerProvider).valueOrNull;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Reminder', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Remind me every day'),
              value: reminder?.enabled ?? false,
              onChanged: reminder == null
                  ? null
                  : (v) => setReminderEnabled(context, ref, v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Time'),
              trailing: Text(
                reminder == null ? '' : reminder.time.format(context),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              enabled: reminder != null,
              onTap: reminder == null
                  ? null
                  : () => pickReminderTime(context, ref, reminder),
            ),
          ],
        ),
      ),
    );
  }
}
