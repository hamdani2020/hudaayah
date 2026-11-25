import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Floating control pill at the bottom of the reader (design-mapping §2 screen
/// 06): A-/A+ font-size steppers, a "View" button (opens the reading-view
/// sheet), and a `tune` settings button.
///
/// Presentational only — these forward to the reader; no controller/API is
/// involved.
class ReaderFloatingControls extends StatelessWidget {
  const ReaderFloatingControls({
    super.key,
    required this.onDecreaseFont,
    required this.onIncreaseFont,
    required this.onOpenView,
    this.onTune,
  });

  final VoidCallback onDecreaseFont;
  final VoidCallback onIncreaseFont;

  /// Opens the "Reading view" sheet.
  final VoidCallback onOpenView;
  final VoidCallback? onTune;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppTheme.surfaceContainerLowest.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(999),
      elevation: 6,
      shadowColor: AppTheme.primary.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FontButton(label: 'A-', onTap: onDecreaseFont),
                  Container(width: 1, height: 14, color: AppTheme.outlineVariant),
                  _FontButton(label: 'A+', onTap: onIncreaseFont),
                ],
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onOpenView,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.visibility,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text('View',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: AppTheme.primary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: AppTheme.primaryContainer,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTune,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.tune, size: 18, color: AppTheme.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FontButton extends StatelessWidget {
  const _FontButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: Text(label,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: AppTheme.primary)),
        ),
      ),
    );
  }
}
