import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../application/whats_new_controller.dart';
import '../data/changelog.dart';

/// "New" and "Fixed" lists for one release. Presentational.
class ChangelogSections extends StatelessWidget {
  const ChangelogSections({super.key, required this.entry});

  final ChangelogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (entry.newItems.isNotEmpty)
          _Section(
            title: 'New',
            icon: Icons.auto_awesome,
            color: AppTheme.secondary,
            items: entry.newItems,
          ),
        if (entry.newItems.isNotEmpty && entry.fixedItems.isNotEmpty)
          const SizedBox(height: 16),
        if (entry.fixedItems.isNotEmpty)
          _Section(
            title: 'Fixed',
            icon: Icons.check_circle_outline,
            color: AppTheme.primary,
            items: entry.fixedItems,
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(title, style: theme.textTheme.titleSmall?.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: theme.textTheme.bodyMedium),
                Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Bottom sheet shown once after an update.
Future<void> showWhatsNewSheet(BuildContext context, ChangelogEntry entry) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppTheme.surfaceContainerLowest,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("What's new in ${entry.version}",
                    style: theme.textTheme.headlineSmall?.copyWith(color: AppTheme.primary)),
                const SizedBox(height: 4),
                Text('JazakAllahu khairan for learning with Hudaayah.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.onSurfaceVariant)),
                const SizedBox(height: 20),
                ChangelogSections(entry: entry),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Got it'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/whats-new');
                  },
                  child: const Text('See all updates'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Wraps the main shell: after the first frame, shows "What's new" if this version
/// has not been seen yet.
class WhatsNewGate extends ConsumerStatefulWidget {
  const WhatsNewGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WhatsNewGate> createState() => _WhatsNewGateState();
}

class _WhatsNewGateState extends ConsumerState<WhatsNewGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    final entry = await ref.read(whatsNewControllerProvider).takePending();
    if (entry == null || !mounted) return;
    await showWhatsNewSheet(context, entry);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
