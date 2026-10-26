import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../review/data/review_repository.dart';
import '../data/progress_repository.dart';

/// Daily habit hub: streak, daily goal, XP, and entry points to the lesson and
/// due reviews. This is the day-2/day-7 return driver (product steering).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(progressSummaryProvider);
    final dueAsync = ref.watch(dueReviewsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hudaayah'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(progressSummaryProvider);
          ref.invalidate(dueReviewsProvider);
          await ref.read(progressSummaryProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            summaryAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
              error: (_, _) => const Text('Could not load your progress.'),
              data: (s) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _StatChip(icon: Icons.local_fire_department,
                          label: '${s.streak}d', caption: 'Streak'),
                      const SizedBox(width: 12),
                      _StatChip(icon: Icons.star,
                          label: '${s.totalXp}', caption: 'XP'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text("Today's goal", style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: s.dailyGoal.fraction),
                  const SizedBox(height: 4),
                  Text(
                    s.dailyGoal.met
                        ? 'Goal met — baarak Allahu feek!'
                        : '${s.dailyGoal.earnedXp}/${s.dailyGoal.goalXp} XP today',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/reader/1'),
              icon: const Icon(Icons.menu_book),
              label: const Text('Continue Al-Fatihah'),
            ),
            const SizedBox(height: 12),
            dueAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (items) => items.isEmpty
                  ? const SizedBox.shrink()
                  : OutlinedButton.icon(
                      onPressed: () => context.go('/review'),
                      icon: const Icon(Icons.schedule),
                      label: Text('Review ${items.length} word'
                          '${items.length == 1 ? '' : 's'}'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.caption});
  final IconData icon;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(label, style: theme.textTheme.titleLarge),
            Text(caption, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
