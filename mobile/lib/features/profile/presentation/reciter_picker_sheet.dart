import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../data/reciter_repository.dart';

/// Opens the reciter picker as a modal bottom sheet.
Future<void> showReciterPicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppTheme.surface,
    builder: (_) => const ReciterPickerSheet(),
  );
}

/// Lists every reciter (name, style, word-timing badge) with the current one
/// ticked. Tapping one saves it to the account and closes the sheet.
class ReciterPickerSheet extends ConsumerStatefulWidget {
  const ReciterPickerSheet({super.key});

  @override
  ConsumerState<ReciterPickerSheet> createState() => _ReciterPickerSheetState();
}

class _ReciterPickerSheetState extends ConsumerState<ReciterPickerSheet> {
  int? _saving;
  String? _error;

  Future<void> _choose(Reciter r) async {
    setState(() {
      _saving = r.id;
      _error = null;
    });
    try {
      await ref.read(selectedReciterProvider.notifier).select(r.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = null;
          _error = 'We could not save your choice. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reciters = ref.watch(recitersProvider);
    final selected =
        ref.watch(selectedReciterProvider).valueOrNull ?? defaultReciterId;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reciter', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Used in the reader and in listening exercises.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style: const TextStyle(color: AppTheme.error)),
              ),
            reciters.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Could not load reciters.'),
                    TextButton(
                      onPressed: () => ref.invalidate(recitersProvider),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
              data: (list) => Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final r in list)
                      ListTile(
                        key: ValueKey('reciter-${r.id}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(r.name),
                        subtitle: Text([
                          if (r.style.isNotEmpty) r.style,
                          if (r.hasTimings) 'Word highlighting',
                        ].join(' · ')),
                        trailing: _saving == r.id
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : r.id == selected
                                ? const Icon(Icons.check,
                                    color: AppTheme.primary)
                                : null,
                        onTap: _saving == null ? () => _choose(r) : null,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
