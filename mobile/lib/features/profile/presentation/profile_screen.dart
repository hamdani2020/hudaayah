import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/hudaayah_top_bar.dart';
import '../../../core/widgets/stat_card.dart';
import '../../authentication/application/auth_controller.dart';
import '../../progress/data/progress_models.dart';
import '../../progress/data/progress_repository.dart';
import 'widgets/history_tile.dart';
import 'widgets/settings_tile.dart';

/// Learning History & Profile (design-mapping §2, screen 08). Identity header,
/// a 3-up metrics row, a simplified weekly rhythm, recent reflections, a
/// settings list, logout and account deletion, and QF attribution. All stats
/// are driven by real backend data — no fabricated counts or per-day figures.
///
/// Local-only toggles (Reminders / Night-mode) hold widget state only; they do
/// not persist or call any API (design-mapping §8.4).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _reminders = true;
  bool _nightMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final summary = ref.watch(progressSummaryProvider).valueOrNull;

    final streak = summary?.streak ?? 0;
    final xp = summary?.totalXp ?? 0;
    final completedLessons =
        summary?.lessons.where((l) => l.isCompleted).toList() ?? const [];
    final completed = completedLessons.length;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            HudaayahTopBar(tab: 'Profile', streakDays: streak),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _ProfileCard(
                    user: user,
                    streak: streak,
                    completed: completed,
                    xp: xp,
                  ),
                  const SizedBox(height: 20),
                  _WeeklyRhythm(streak: streak),
                  const SizedBox(height: 20),
                  Text('Recent Reflections', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (completedLessons.isEmpty)
                    Text(
                      'Your completed lessons will appear here as you learn.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    )
                  else
                    for (final l in completedLessons) ...[
                      HistoryTile(
                        title: 'Lesson ${l.lessonId}',
                        subtitle: _completedSubtitle(l),
                        completed: true,
                      ),
                      const SizedBox(height: 8),
                    ],
                  const SizedBox(height: 12),
                  Text('Settings', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        const SettingsTile(
                          icon: Icons.language,
                          title: 'Script Style',
                          subtitle: 'Uthmani (KFGQPC)',
                        ),
                        const SettingsTile(
                          icon: Icons.translate,
                          title: 'Translation',
                          subtitle: 'Saheeh International',
                        ),
                        const SettingsTile(
                          icon: Icons.record_voice_over,
                          title: 'Reciter',
                          subtitle: 'Mishary Rashid Alafasy',
                        ),
                        SettingsTile(
                          icon: Icons.notifications,
                          title: 'Daily Reminders',
                          trailing: Switch(
                            value: _reminders,
                            onChanged: (v) =>
                                setState(() => _reminders = v),
                          ),
                        ),
                        SettingsTile(
                          icon: Icons.dark_mode,
                          title: 'Night Mode',
                          trailing: Switch(
                            value: _nightMode,
                            onChanged: (v) =>
                                setState(() => _nightMode = v),
                          ),
                        ),
                        SettingsTile(
                          icon: Icons.security,
                          title: 'Privacy Policy',
                          onTap: () {},
                        ),
                        SettingsTile(
                          icon: Icons.description_outlined,
                          title: 'Terms of Use',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        SettingsTile(
                          icon: Icons.manage_accounts,
                          title: 'Manage Account',
                          onTap: () {},
                        ),
                        SettingsTile(
                          icon: Icons.logout,
                          title: 'Sign Out',
                          onTap: () => ref
                              .read(authControllerProvider.notifier)
                              .logout(),
                        ),
                        SettingsTile(
                          icon: Icons.delete_forever,
                          title: 'Delete Account',
                          destructive: true,
                          onTap: () => _confirmDelete(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          AppConfig.qfAttribution,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: AppTheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hudaayah • Built with reverence & care',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _completedSubtitle(LessonProgress l) {
    final at = l.completedAt;
    if (at == null) return 'Completed';
    final d = at.toLocal();
    return 'Completed ${d.year}-${_two(d.month)}-${_two(d.day)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This permanently removes your account and progress. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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

/// Identity card with avatar + verified pip, name, a neutral member line, and a
/// 3-up metrics row (real data only).
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.streak,
    required this.completed,
    required this.xp,
  });

  final dynamic user;
  final int streak;
  final int completed;
  final int xp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (user?.displayName as String?)?.isNotEmpty ?? false
        ? user.displayName as String
        : 'Learner';
    final avatarUrl = user?.avatarUrl as String?;
    final memberLine = (user?.email as String?) ?? 'Welcome to your journey';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person,
                            size: 32, color: AppTheme.onSurfaceVariant)
                        : null,
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.secondaryFixed,
                      ),
                      child: const Icon(Icons.verified,
                          size: 14, color: AppTheme.secondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(color: AppTheme.primary)),
                    const SizedBox(height: 2),
                    Text(
                      memberLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Row(
              children: [
                Expanded(
                  child: MetricCell(
                    icon: Icons.local_fire_department,
                    value: '$streak',
                    caption: 'Current Streak',
                  ),
                ),
                Expanded(
                  child: MetricCell(
                    icon: Icons.auto_stories,
                    value: '$completed',
                    caption: 'Lessons',
                  ),
                ),
                Expanded(
                  child: MetricCell(
                    icon: Icons.star,
                    value: '$xp',
                    caption: 'XP',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simplified 7-slot weekly rhythm derived from the streak (fills the last
/// `min(streak, 7)` days). Honest: no fabricated per-day minutes
/// (design-mapping §2 screen 08 / §8.4).
class _WeeklyRhythm extends StatelessWidget {
  const _WeeklyRhythm({required this.streak});

  final int streak;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = streak.clamp(0, 7);
    // Fill the most recent `filled` slots (right-aligned in the week).
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Discipline',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: AppTheme.primary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                _DaySlot(label: _days[i], active: i >= 7 - filled),
            ],
          ),
        ],
      ),
    );
  }
}

class _DaySlot extends StatelessWidget {
  const _DaySlot({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? AppTheme.primaryContainer
                : AppTheme.surfaceContainerHigh,
          ),
          child: Icon(
            Icons.star,
            size: 16,
            color: active ? AppTheme.tertiaryFixedDim : AppTheme.outlineVariant,
          ),
        ),
      ],
    );
  }
}
