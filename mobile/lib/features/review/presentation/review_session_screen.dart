import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/review_models.dart';
import '../data/review_repository.dart';

/// Walks through due vocab review items. Each item is self-marked gently
/// ("I remembered" / "Still learning") — no pass/fail pressure (adab).
class ReviewSessionScreen extends ConsumerStatefulWidget {
  const ReviewSessionScreen({super.key});

  @override
  ConsumerState<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends ConsumerState<ReviewSessionScreen> {
  int _index = 0;
  bool _submitting = false;

  Future<void> _mark(ReviewItem item, bool correct) async {
    setState(() => _submitting = true);
    try {
      await ref.read(reviewRepositoryProvider).submit(itemId: item.id, correct: correct);
      setState(() => _index++);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save your review.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueAsync = ref.watch(dueReviewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: dueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load reviews.')),
        data: (items) {
          if (items.isEmpty || _index >= items.length) {
            return _Done(onBack: () {
              ref.invalidate(dueReviewsProvider);
              context.go('/home');
            });
          }
          final item = items[_index];
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(value: _index / items.length),
                const Spacer(),
                Text(item.prompt,
                    style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Recall its meaning, then mark how you did.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting ? null : () => _mark(item, false),
                        child: const Text('Still learning'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitting ? null : () => _mark(item, true),
                        child: const Text('I remembered'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('All caught up', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('No more reviews due right now. Come back tomorrow, in sha Allah.',
                style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onBack, child: const Text('Back to home')),
          ],
        ),
      ),
    );
  }
}
