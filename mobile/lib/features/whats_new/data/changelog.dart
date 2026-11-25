import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// One release in `assets/changelog.json` (the single source of release notes,
/// also used by fastlane for the Play "What's new" text).
class ChangelogEntry {
  final String version;
  final List<String> newItems;
  final List<String> fixedItems;

  const ChangelogEntry({
    required this.version,
    required this.newItems,
    required this.fixedItems,
  });

  factory ChangelogEntry.fromJson(Map<String, dynamic> j) => ChangelogEntry(
        version: j['version'] as String? ?? '',
        newItems: _strings(j['new']),
        fixedItems: _strings(j['fixed']),
      );

  static List<String> _strings(Object? v) =>
      (v as List? ?? const []).map((e) => e.toString()).toList();

  bool get isEmpty => newItems.isEmpty && fixedItems.isEmpty;
}

const _changelogAsset = 'assets/changelog.json';

Future<List<ChangelogEntry>> loadChangelog([AssetBundle? bundle]) async {
  final raw = await (bundle ?? rootBundle).loadString(_changelogAsset);
  final entries = (jsonDecode(raw) as Map)['entries'] as List? ?? const [];
  return entries
      .map((e) => ChangelogEntry.fromJson((e as Map).cast<String, dynamic>()))
      .where((e) => e.version.isNotEmpty)
      .toList();
}

/// All releases, newest first (as written in the file).
final changelogProvider = FutureProvider<List<ChangelogEntry>>((ref) => loadChangelog());

/// The installed app's version name and build number.
final appVersionProvider = FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());
