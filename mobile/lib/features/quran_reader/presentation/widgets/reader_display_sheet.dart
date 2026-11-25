import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/reader_settings.dart';

/// Short names for each reading view, shared by the sheet and Profile.
String readerDisplayModeLabel(ReaderDisplayMode mode) => switch (mode) {
  ReaderDisplayMode.arabicOnly => 'Arabic only',
  ReaderDisplayMode.arabicTranslation => 'Arabic + translation',
  ReaderDisplayMode.full => 'Full',
};

String _description(ReaderDisplayMode mode) => switch (mode) {
  ReaderDisplayMode.arabicOnly => 'The ayah in Arabic, nothing else.',
  ReaderDisplayMode.arabicTranslation => 'Arabic with its translation below.',
  ReaderDisplayMode.full =>
    'Arabic, word-by-word meanings and the translation.',
};

/// Opens the "Reading view" bottom sheet. Used by the reader and by Profile.
Future<void> showReaderDisplaySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Size to the content (scrolls on short screens) instead of 9/16 height.
    isScrollControlled: true,
    builder: (_) => const ReaderDisplaySheet(),
  );
}

/// Radio list of the three reading views; the choice is saved on the device.
class ReaderDisplaySheet extends ConsumerWidget {
  const ReaderDisplaySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final current =
        ref.watch(readerDisplayModeProvider).valueOrNull ??
        ReaderDisplayMode.full;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Text('Reading view', style: theme.textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Choose what to see while you read. You can change this any time.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            RadioGroup<ReaderDisplayMode>(
              groupValue: current,
              onChanged: (mode) {
                if (mode == null) return;
                ref.read(readerDisplayModeProvider.notifier).setMode(mode);
              },
              child: Column(
                children: [
                  for (final mode in ReaderDisplayMode.values)
                    RadioListTile<ReaderDisplayMode>(
                      key: Key('reader_view_${mode.name}'),
                      value: mode,
                      title: Text(readerDisplayModeLabel(mode)),
                      subtitle: Text(_description(mode)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
