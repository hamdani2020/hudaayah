import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// A single surah row in the Read tab (design-mapping §2, screen 03).
///
/// Presentational only: it renders catalog metadata (number, English name,
/// meaning, ayah count, Arabic *title*) plus a completion state derived from
/// `LessonProgress`. It never holds Quran verse text. A [completed] surah shows
/// a 100% check badge; otherwise a progress bar (honest 0 when unknown).
class SurahListTile extends StatelessWidget {
  const SurahListTile({
    super.key,
    required this.number,
    required this.name,
    required this.meaning,
    required this.ayahCount,
    required this.revelationPlace,
    required this.arabicTitle,
    required this.completed,
    required this.progress,
    required this.onTap,
  });

  final int number;
  final String name;
  final String meaning;
  final int ayahCount;
  final String revelationPlace;

  /// Arabic *name* of the surah (catalog metadata, NOT verse text).
  final String arabicTitle;

  final bool completed;

  /// 0..1 progress fraction; only `0` or `1` are used (honest — see §2).
  final double progress;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: AppTheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Khatim star + surah number.
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      size: 44,
                      color: AppTheme.primaryFixed.withValues(alpha: 0.6),
                    ),
                    Text(
                      '$number',
                      style: textTheme.titleMedium
                          ?.copyWith(color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(name, style: textTheme.titleMedium),
                        ),
                        Text(
                          arabicTitle,
                          textDirection: TextDirection.rtl,
                          style: textTheme.titleMedium
                              ?.copyWith(color: AppTheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$meaning • $ayahCount Ayahs • $revelationPlace',
                      style: textTheme.labelMedium
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    if (completed)
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: textTheme.labelSmall
                                ?.copyWith(color: AppTheme.primary),
                          ),
                        ],
                      )
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppTheme.surfaceContainerHigh,
                          valueColor: const AlwaysStoppedAnimation(
                            AppTheme.secondaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
