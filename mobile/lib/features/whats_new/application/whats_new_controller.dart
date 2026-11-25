import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/changelog.dart';

/// Decides when to show "What's new": once, on the first launch of a version the
/// learner has updated to. Fresh installs never see it (everything is new).
class WhatsNewController {
  WhatsNewController(this._ref);

  final Ref _ref;

  static const _lastSeenKey = 'whats_new.last_seen_version';

  /// Call once at startup, before the app UI. On the very first run of a version of
  /// the app that has this feature, [hasSavedSession] tells an update (the learner was
  /// already signed in) apart from a fresh install. A fresh install is marked as seen,
  /// so it shows nothing.
  static Future<void> markFreshInstall({required bool hasSavedSession}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_lastSeenKey) || hasSavedSession) return;
      final info = await PackageInfo.fromPlatform();
      await prefs.setString(_lastSeenKey, info.version);
    } catch (e) {
      debugPrint("What's new: could not check first run ($e)");
    }
  }

  /// The changelog entry to show now, or null. Marks it as seen, so it shows once.
  Future<ChangelogEntry?> takePending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final info = await _ref.read(appVersionProvider.future);
      final current = info.version;
      if (prefs.getString(_lastSeenKey) == current) return null;

      final entries = await _ref.read(changelogProvider.future);
      await prefs.setString(_lastSeenKey, current);
      for (final e in entries) {
        if (e.version == current && !e.isEmpty) return e;
      }
      return null;
    } catch (e) {
      debugPrint("What's new: could not load ($e)");
      return null;
    }
  }
}

final whatsNewControllerProvider = Provider<WhatsNewController>(WhatsNewController.new);
