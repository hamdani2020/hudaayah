import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/reminder_controller.dart';

/// Shared reminder actions used by the Profile screen and the reminder sheet,
/// so both surfaces behave and word their messages identically.
Future<void> setReminderEnabled(
  BuildContext context,
  WidgetRef ref,
  bool enabled,
) async {
  final result = await ref
      .read(reminderControllerProvider.notifier)
      .setEnabled(enabled);
  if (!context.mounted) return;
  showReminderResult(
    context,
    result,
    okMessage: enabled ? 'Daily reminder is on.' : 'Daily reminder is off.',
  );
}

Future<void> pickReminderTime(
  BuildContext context,
  WidgetRef ref,
  ReminderSettings current,
) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: current.time,
    helpText: 'Daily reminder time',
  );
  if (picked == null || !context.mounted) return;
  final controller = ref.read(reminderControllerProvider.notifier);
  var result = await controller.setTime(picked);
  // Choosing a time is a clear sign the learner wants the reminder.
  if (result == ReminderChangeResult.ok && !current.enabled) {
    result = await controller.setEnabled(true);
  }
  if (!context.mounted) return;
  showReminderResult(
    context,
    result,
    okMessage: 'Daily reminder set for ${picked.format(context)}.',
  );
}

void showReminderResult(
  BuildContext context,
  ReminderChangeResult result, {
  required String okMessage,
}) {
  final message = switch (result) {
    ReminderChangeResult.ok => okMessage,
    ReminderChangeResult.permissionDenied =>
      'Notifications are off for Hudaayah. You can allow them in your phone settings.',
    ReminderChangeResult.failed =>
      'We could not set the reminder. Please try again.',
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
