import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Post-submission result card for the quiz (design-mapping §3, screen 05):
/// a top gradient hairline, a gentle correct/encourage chip, an optional "+XP"
/// amber chip, a "Linguistic Reflection" note, and a Continue button.
///
/// Presentational — the exercise screen passes the server-graded [correct]
/// flag, the gentle [message] and [reflection] (from `GradeResult.feedback`),
/// and an optional [xpLabel] (omitted when the server did not return one; never
/// fabricated). Feedback copy stays gentle — never "you failed".
class FeedbackDrawer extends StatelessWidget {
  const FeedbackDrawer({
    super.key,
    required this.correct,
    required this.message,
    this.reflection,
    this.xpLabel,
    required this.onContinue,
    this.continueLabel = 'Continue',
  });

  final bool correct;
  final String message;
  final String? reflection;
  final String? xpLabel;
  final VoidCallback onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chipBg = correct ? AppTheme.primaryFixed : AppTheme.secondaryFixed;
    final chipFg =
        correct ? AppTheme.onPrimaryFixed : AppTheme.onSecondaryFixedVariant;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top gradient hairline.
          Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryFixed, AppTheme.tertiaryFixedDim],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            correct ? Icons.check_circle : Icons.auto_awesome,
                            size: 16,
                            color: chipFg,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            message,
                            style: textTheme.titleMedium?.copyWith(color: chipFg),
                          ),
                        ],
                      ),
                    ),
                    if (xpLabel != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryFixed.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          xpLabel!,
                          style: textTheme.labelMedium?.copyWith(
                            color: AppTheme.onSecondaryFixedVariant,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (reflection != null && reflection!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Linguistic Reflection',
                    style: textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reflection!,
                    style: textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onContinue,
                    child: Text(continueLabel),
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
