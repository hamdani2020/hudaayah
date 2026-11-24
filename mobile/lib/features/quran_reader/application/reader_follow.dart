import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Whether the reader list follows the recitation. On by default; a manual
/// scroll turns it off (the UI then offers "Follow recitation"), and starting
/// play-all or tapping that button turns it back on.
class ReaderFollow extends AutoDisposeNotifier<bool> {
  @override
  bool build() => true;

  void userScrolled() => state = false;

  void resume() => state = true;
}

final readerFollowProvider =
    AutoDisposeNotifierProvider<ReaderFollow, bool>(ReaderFollow.new);

/// Decides whether the list must scroll to [index] when the recited ayah changes.
///
/// Play-all: only while following, and unless the ayah is already fully on
/// screen. Single ayah: only if no part of it is on screen.
bool shouldScrollToAyah({
  required bool playAll,
  required bool following,
  required int index,
  required Iterable<ItemPosition> visible,
}) {
  if (index < 0) return false;
  ItemPosition? pos;
  for (final p in visible) {
    if (p.index == index) pos = p;
  }
  if (playAll) {
    if (!following) return false;
    return pos == null || pos.itemLeadingEdge < 0 || pos.itemTrailingEdge > 1;
  }
  return pos == null ||
      pos.itemTrailingEdge <= 0 ||
      pos.itemLeadingEdge >= 1;
}
