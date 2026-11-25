import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../data/changelog.dart';
import 'whats_new_widgets.dart';

/// Full release history (Profile → What's new), newest first.
class ChangelogScreen extends ConsumerWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final changelog = ref.watch(changelogProvider);
    final installed = ref.watch(appVersionProvider).valueOrNull?.version;

    return Scaffold(
      appBar: AppBar(
        title: Text("What's new",
            style: theme.textTheme.headlineSmall?.copyWith(color: AppTheme.primary)),
      ),
      body: changelog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load the updates.')),
        data: (entries) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final e = entries[i];
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Version ${e.version}',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: AppTheme.primary)),
                      if (e.version == installed) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryFixed,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('Installed', style: theme.textTheme.labelSmall),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  ChangelogSections(entry: e),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
