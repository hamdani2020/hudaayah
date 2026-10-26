import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// "Continue Recitation" banner on the Read tab (design-mapping §2, screen 03).
///
/// Presentational: the caller derives the most-recent in-progress surah from
/// `ProgressSummary` and hides this banner entirely when none exists. Carries
/// only catalog metadata (surah name), never verse text.
class ResumeBanner extends StatelessWidget {
  const ResumeBanner({
    super.key,
    required this.surahName,
    required this.subtitle,
    required this.onTap,
  });

  final String surahName;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: AppTheme.primaryContainer,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.onPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: AppTheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue Recitation',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppTheme.onPrimaryContainer,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      surahName,
                      style: textTheme.titleMedium
                          ?.copyWith(color: AppTheme.onPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.labelMedium
                          ?.copyWith(color: AppTheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                color: AppTheme.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
