import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which layers the reader shows for each ayah. Stored on the device only.
enum ReaderDisplayMode {
  /// Arabic text only.
  arabicOnly,

  /// Arabic text and translation.
  arabicTranslation,

  /// Arabic text, translation and word-by-word chips.
  full;

  /// Parses a stored value; unknown or missing values give [full].
  static ReaderDisplayMode fromStored(String? value) {
    for (final mode in ReaderDisplayMode.values) {
      if (mode.name == value) return mode;
    }
    return ReaderDisplayMode.full;
  }
}

class ReaderDisplayModeNotifier extends AsyncNotifier<ReaderDisplayMode> {
  static const prefsKey = 'reader.display_mode';

  @override
  Future<ReaderDisplayMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    return ReaderDisplayMode.fromStored(prefs.getString(prefsKey));
  }

  Future<void> setMode(ReaderDisplayMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, mode.name);
    state = AsyncValue.data(mode);
  }
}

final readerDisplayModeProvider =
    AsyncNotifierProvider<ReaderDisplayModeNotifier, ReaderDisplayMode>(
  ReaderDisplayModeNotifier.new,
);
