import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/config/app_config.dart';
import '../../authentication/application/auth_controller.dart';
import '../../progress/data/progress_repository.dart';

/// Learning History & Profile — matches the Stitch profile screen structure:
/// identity header, a stats row, settings list (privacy, terms, account
/// deletion), logout, and attribution + version. Levels are dropped for pilot;
/// stats are driven by real backend data (no fabricated counts).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final summaryAsync = ref.watch(progressSummaryProvider);

    final streak = summaryAsync.valueOrNull?.streak ?? 0;
    final xp = summaryAsync.valueOrNull?.totalXp ?? 0;
    final completed = summaryAsync.valueOrNull?.lessons
            .where((l) => l.isCompleted)
            .length ??
        0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryContainer,
                  backgroundImage:
                      user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                  child: user?.avatarUrl == null
                      ? const Icon(Icons.person, size: 40, color: AppTheme.onPrimary)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  (user?.displayName.isNotEmpty ?? false) ? user!.displayName : 'Learner',
                  style: theme.textTheme.headlineSmall,
                ),
                if (user?.email != null)
                  Text(user!.email!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _StatCard(icon: Icons.local_fire_department,
                  value: '$streak', caption: 'Day streak'),
              const SizedBox(width: 12),
              _StatCard(icon: Icons.check_circle,
                  value: '$completed', caption: 'Lessons'),
              const SizedBox(width: 12),
              _StatCard(icon: Icons.star, value: '$xp', caption: 'XP'),
            ],
          ),
          const SizedBox(height: 24),
          Text('Settings', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _SettingTile(icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy', onTap: () {}),
                const Divider(height: 1),
                _SettingTile(icon: Icons.description_outlined,
                    label: 'Terms of Use', onTap: () {}),
                const Divider(height: 1),
                _SettingTile(
                  icon: Icons.delete_outline,
                  label: 'Delete account',
                  destructive: true,
                  onTap: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(AppConfig.qfAttribution, style: theme.textTheme.labelSmall),
                const SizedBox(height: 2),
                Text('Hudaayah • Built with reverence & care',
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This permanently removes your account and progress. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx), // wired to endpoint in Phase 6
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.value, required this.caption});
  final IconData icon;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.secondary),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.titleLarge),
            Text(caption, style: theme.textTheme.labelSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: theme.textTheme.bodyLarge?.copyWith(color: color)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
