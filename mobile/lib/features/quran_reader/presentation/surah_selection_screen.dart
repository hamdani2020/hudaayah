import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/filter_chip_bar.dart';
import '../../../core/widgets/hudaayah_top_bar.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/search_field.dart';
import '../../progress/data/progress_models.dart';
import '../../progress/data/progress_repository.dart';
import '../data/lesson_models.dart';
import '../data/lesson_repository.dart';
import 'widgets/resume_banner.dart';
import 'widgets/surah_list_tile.dart';

/// The **Read** tab (route `/surah`, design-mapping §2 screen 03). Lists the
/// published lessons fetched from `GET /lessons/` (fully backend-driven — no
/// hardcoded surah metadata), joined with the learner's real `LessonProgress`,
/// routing each tap to `/reader/<lessonId>`.
///
/// Adding a surah on the backend makes it appear here with no app change.
/// Presentational only — no Quran verse text.
class SurahSelectionScreen extends ConsumerStatefulWidget {
  const SurahSelectionScreen({super.key});

  @override
  ConsumerState<SurahSelectionScreen> createState() =>
      _SurahSelectionScreenState();
}

class _SurahSelectionScreenState extends ConsumerState<SurahSelectionScreen> {
  static const _filters = ['All', 'Makki', 'Madani', 'Bookmarked', 'Juz'];

  int _selectedFilter = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final summaryAsync = ref.watch(progressSummaryProvider);
    final lessonsAsync = ref.watch(lessonsListProvider);
    final streak = summaryAsync.valueOrNull?.streak;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HudaayahTopBar(tab: 'Read', streakDays: streak),
            Expanded(
              child: lessonsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => _CatalogError(
                  onRetry: () => ref.invalidate(lessonsListProvider),
                ),
                data: (catalog) => RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(lessonsListProvider);
                    ref.invalidate(progressSummaryProvider);
                    await ref.read(lessonsListProvider.future);
                  },
                  child: _buildList(
                    context,
                    textTheme,
                    catalog,
                    summaryAsync.valueOrNull?.lessons ?? const [],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Progress lookup keyed by lessonId.
  Map<int, LessonProgress> _progressByLesson(List<LessonProgress> lessons) => {
        for (final l in lessons) l.lessonId: l,
      };

  Widget _buildList(
    BuildContext context,
    TextTheme textTheme,
    List<LessonSummary> catalog,
    List<LessonProgress> lessons,
  ) {
    final progress = _progressByLesson(lessons);

    // Search + revelation-place filter on backend-provided metadata.
    final query = _query.trim().toLowerCase();
    final filter = _filters[_selectedFilter];
    final visible = catalog.where((s) {
      final matchesQuery = query.isEmpty ||
          s.surahNameEn.toLowerCase().contains(query) ||
          s.surahMeaning.toLowerCase().contains(query);
      final matchesFilter = switch (filter) {
        'Makki' => s.revelationPlace == 'Makki',
        'Madani' => s.revelationPlace == 'Madani',
        _ => true, // All / Bookmarked / Juz — no local data, so show all.
      };
      return matchesQuery && matchesFilter;
    }).toList();

    // Resume banner: the first in-progress (not completed) lesson, by catalog order.
    LessonSummary? resumeEntry;
    for (final s in catalog) {
      final p = progress[s.id];
      if (p != null && !p.isCompleted && p.state != 'not_started') {
        resumeEntry = s;
        break;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SearchField(
          hintText: 'Search surahs',
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: FilterChipBar(
            labels: _filters,
            selectedIndex: _selectedFilter,
            onSelected: (i) => setState(() => _selectedFilter = i),
          ),
        ),
        const SizedBox(height: 16),
        if (resumeEntry != null) ...[
          ResumeBanner(
            surahName: resumeEntry.displayName,
            subtitle: '${resumeEntry.surahMeaning} • '
                '${resumeEntry.surahAyahCount} Ayahs',
            onTap: () => context.go('/reader/${resumeEntry!.id}'),
          ),
          const SizedBox(height: 16),
        ],
        Text('Sacred Chapters', style: textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No surahs match your search.',
                  style: textTheme.bodyMedium),
            ),
          ),
        for (final s in visible) ...[
          Builder(builder: (_) {
            final p = progress[s.id];
            final completed = p?.isCompleted ?? false;
            return SurahListTile(
              number: s.surah,
              name: s.surahNameEn.isNotEmpty ? s.surahNameEn : s.title,
              meaning: s.surahMeaning,
              ayahCount: s.surahAyahCount,
              revelationPlace: s.revelationPlace,
              arabicTitle: s.surahNameAr,
              completed: completed,
              progress: completed ? 1 : 0,
              onTap: () => context.go('/reader/${s.id}'),
            );
          }),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        const InfoCard(
          icon: Icons.lightbulb_outline,
          title: 'Daily Wisdom',
          body:
              'A little every day keeps the heart connected. Return often, and '
              'let each visit be gentle.',
        ),
      ],
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Center(child: Text('Could not load the surah list.')),
        const SizedBox(height: 12),
        Center(
          child: FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ],
    );
  }
}
