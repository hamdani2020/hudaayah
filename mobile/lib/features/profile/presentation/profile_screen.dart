import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../authentication/application/auth_controller.dart';

/// Minimal profile showing the authenticated user's own data from `/me/`,
/// plus logout. Stats/settings land in later phases.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull?.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null) ...[
              Text(user.displayName.isEmpty ? 'Learner' : user.displayName,
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              if (user.email != null)
                Text(user.email!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('Signed in with ${user.provider}',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ] else
              const Text('Not signed in.'),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => context.go('/reader/1'),
              icon: const Icon(Icons.menu_book),
              label: const Text('Open Al-Fatihah'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}
