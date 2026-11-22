import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifications/reminder_service.dart';

/// The learner's daily reminder setting. Stored on the device only.
class ReminderSettings {
  final bool enabled;
  final TimeOfDay time;

  const ReminderSettings({required this.enabled, required this.time});

  /// Default: off, at 8:00 PM.
  static const ReminderSettings initial =
      ReminderSettings(enabled: false, time: TimeOfDay(hour: 20, minute: 0));

  ReminderSettings copyWith({bool? enabled, TimeOfDay? time}) =>
      ReminderSettings(enabled: enabled ?? this.enabled, time: time ?? this.time);
}

enum ReminderChangeResult { ok, permissionDenied, failed }

class ReminderController extends AsyncNotifier<ReminderSettings> {
  static const _kEnabled = 'reminder.enabled';
  static const _kHour = 'reminder.hour';
  static const _kMinute = 'reminder.minute';

  ReminderService get _service => ref.read(reminderServiceProvider);

  @override
  Future<ReminderSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = ReminderSettings(
      enabled: prefs.getBool(_kEnabled) ?? ReminderSettings.initial.enabled,
      time: TimeOfDay(
        hour: prefs.getInt(_kHour) ?? ReminderSettings.initial.time.hour,
        minute: prefs.getInt(_kMinute) ?? ReminderSettings.initial.time.minute,
      ),
    );
    if (settings.enabled) {
      // Re-schedule on start so the reminder follows time-zone changes and app updates.
      try {
        await _service.scheduleDaily(settings.time);
      } catch (e) {
        debugPrint('Reminder: re-schedule failed ($e)');
      }
    }
    return settings;
  }

  Future<ReminderChangeResult> setEnabled(bool enabled) async {
    final current = state.valueOrNull ?? ReminderSettings.initial;
    try {
      if (enabled) {
        final granted = await _service.requestPermission();
        if (!granted) return ReminderChangeResult.permissionDenied;
        await _service.scheduleDaily(current.time);
      } else {
        await _service.cancel();
      }
    } catch (e) {
      debugPrint('Reminder: change failed ($e)');
      return ReminderChangeResult.failed;
    }
    final next = current.copyWith(enabled: enabled);
    await _save(next);
    state = AsyncValue.data(next);
    return ReminderChangeResult.ok;
  }

  Future<ReminderChangeResult> setTime(TimeOfDay time) async {
    final current = state.valueOrNull ?? ReminderSettings.initial;
    try {
      if (current.enabled) await _service.scheduleDaily(time);
    } catch (e) {
      debugPrint('Reminder: re-schedule failed ($e)');
      return ReminderChangeResult.failed;
    }
    final next = current.copyWith(time: time);
    await _save(next);
    state = AsyncValue.data(next);
    return ReminderChangeResult.ok;
  }

  Future<void> _save(ReminderSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, s.enabled);
    await prefs.setInt(_kHour, s.time.hour);
    await prefs.setInt(_kMinute, s.time.minute);
  }
}

final reminderControllerProvider =
    AsyncNotifierProvider<ReminderController, ReminderSettings>(ReminderController.new);
