import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/progress_ring.dart';

/// "Today's Sacred Habit" card (design-mapping §2 screen 04): a
/// `primary-container` card with the current surah, a transliteration subtitle,
/// an honest completion ring, and a "Continue Reading" button. Presentational —
/// [percent] and [onContinue] are supplied by the caller (home screen).
class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.percent,
    required this.buttonLabel,
    required this.onContinue,
  });

  final String title;
  final String subtitle;

  /// Honest completion fraction (0..1) from real lesson progress.
  final double percent;
  final String buttonLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Tag(label: "Today's Sacred Habit"),
                    const SizedBox(height: 8),
                    Text(title,
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(color: AppTheme.onPrimary)),
                    const SizedBox(height: 2),
                    // Transliteration-style subtitle (educational label, not
                    // Quran text) rendered distinct from the Arabic layer.
                    Text(
                      subtitle,
                      style: AppTextStyles.transliteration
                          .copyWith(color: AppTheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ProgressRing(percent: percent, size: 56, strokeWidth: 4),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.surfaceContainerLowest,
                foregroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
              ),
              onPressed: onContinue,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(buttonLabel,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: AppTheme.primary)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.secondaryFixed,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppTheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}
