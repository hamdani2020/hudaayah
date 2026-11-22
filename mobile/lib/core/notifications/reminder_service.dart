import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the single daily reminder as a local notification on the device.
///
/// Nothing is sent to the server. Timing is inexact (Android may deliver it a few
/// minutes late to save battery), so the app needs no exact-alarm permission.
class ReminderService {
  static const int _reminderId = 1001;
  static const String _channelId = 'daily_reminder';

  // Gentle, adab-respecting copy: an invitation, never a warning about streaks.
  static const String _title = 'Hudaayah';
  static const String _body = 'A few minutes with the Quran today?';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(local.identifier));
    } catch (e) {
      debugPrint('Reminder: could not read device time zone, using UTC ($e)');
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_hudaayah'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  /// Asks for permission to show notifications (Android 13+ / iOS).
  /// Returns false if the user declines.
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true; // null on Android 12 and below: no runtime permission.
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted =
          await ios?.requestPermissions(alert: true, badge: false, sound: true);
      return granted ?? false;
    }
    return false;
  }

  /// Replaces any existing reminder with one that repeats every day at [time].
  Future<void> scheduleDaily(TimeOfDay time) async {
    await _ensureInitialized();
    await _plugin.cancel(id: _reminderId);
    await _plugin.zonedSchedule(
      id: _reminderId,
      title: _title,
      body: _body,
      scheduledDate: _nextInstanceOf(time),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Daily reminder',
          channelDescription: 'A gentle daily reminder to spend time with the Quran.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Color(0xFF0F3E36),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // Repeat daily at this wall-clock time.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel() async {
    await _ensureInitialized();
    await _plugin.cancel(id: _reminderId);
  }

  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next;
  }
}

final reminderServiceProvider = Provider<ReminderService>((ref) => ReminderService());
