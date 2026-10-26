import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/filter_chip_bar.dart';
import '../../../core/widgets/hudaayah_top_bar.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/search_field.dart';
import '../../progress/data/progress_models.dart';
import '../../progress/data/progress_repository.dart';
import 'widgets/resume_banner.dart';
import 'widgets/surah_list_tile.dart';

/// Catalog metadata for a surah. This is NOT Quran verse text — only the name,
/// number, meaning, ayah count, revelation place, and the Arabic *title*. It is
/// keyed by the app's lesson id so the list joins onto `LessonProgress`.
///
/// Pilot scope (QF pre-live) is Al-Fatihah and Al-Baqarah; the catalog stays
/// small and honest. Expand only as lessons are added.
class _SurahEntry {
  const _SurahEntry({
    required this.lessonId,
    required this.number,
    required this.name,
    required this.meaning,
    required this.ayahCount,
    required this.revelationPlace,
    required this.arabicTitle,
  });

  final int lessonId;
  final int number;
  final String name;
  final String meaning;
  final int ayahCount;
  final String revelationPlace; // 'Makki' | 'Madani'
  final String arabicTitle;
}

const List<_SurahEntry> _surahCatalog = [
  _SurahEntry(
    lessonId: 1,
    number: 1,
    name: 'Al-Fatihah',
    meaning: 'The Opening',
    ayahCount: 7,
    revelationPlace: 'Makki',
    arabicTitle: 'الفاتحة',
  ),
  _SurahEntry(
    lessonId: 2,
    number: 2,
    name: 'Al-Baqarah',
    meaning: 'The Cow',
    ayahCount: 286,
    revelationPlace: 'Madani',
    arabicTitle: 'البقرة',
  ),
];

/// The **Read** tab (route `/surah`, design-mapping §2 screen 03). Lists the
/// surahs available in the pilot, joining static catalog metadata with the
/// learner's real `LessonProgress`, and routes each tap to `/reader/<lessonId>`.
/// Entirely presentational — no new provider/API, no Quran verse text.
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
    final streak = summaryAsync.valueOrNull?.streak;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HudaayahTopBar(tab: 'Read', streakDays: streak),
            Expanded(
              child: summaryAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => _buildList(context, textTheme, const []),
                data: (summary) =>
                    _buildList(context, textTheme, summary.lessons),
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
    List<LessonProgress> lessons,
  ) {
    final progress = _progressByLesson(lessons);

    // Apply the search + revelation-place filter to catalog metadata only.
    final query = _query.trim().toLowerCase();
    final filter = _filters[_selectedFilter];
    final visible = _surahCatalog.where((s) {
      final matchesQuery = query.isEmpty ||
          s.name.toLowerCase().contains(query) ||
          s.meaning.toLowerCase().contains(query);
      final matchesFilter = switch (filter) {
        'Makki' => s.revelationPlace == 'Makki',
        'Madani' => s.revelationPlace == 'Madani',
        _ => true, // All / Bookmarked / Juz — no local data, so show all.
      };
      return matchesQuery && matchesFilter;
    }).toList();

    // Most-recent in-progress lesson drives the resume banner (metadata only).
    _SurahEntry? resumeEntry;
    for (final s in _surahCatalog) {
      final p = progress[s.lessonId];
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
        // FilterChipBar manages its own horizontal padding; cancel the list pad.
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
            surahName: 'Surah ${resumeEntry.name}',
            subtitle: '${resumeEntry.meaning} • ${resumeEntry.ayahCount} Ayahs',
            onTap: () => context.go('/reader/${resumeEntry!.lessonId}'),
          ),
          const SizedBox(height: 16),
        ],
        Text('Sacred Chapters', style: textTheme.headlineSmall),
        const SizedBox(height: 12),
        for (final s in visible) ...[
          Builder(builder: (_) {
            final p = progress[s.lessonId];
            final completed = p?.isCompleted ?? false;
            return SurahListTile(
              number: s.number,
              name: s.name,
              meaning: s.meaning,
              ayahCount: s.ayahCount,
              revelationPlace: s.revelationPlace,
              arabicTitle: s.arabicTitle,
              completed: completed,
              progress: completed ? 1 : 0,
              onTap: () => context.go('/reader/${s.lessonId}'),
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
