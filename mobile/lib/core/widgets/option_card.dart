import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Multiple-choice answer card (design-mapping §3, screen 05): a leading
/// letter badge (A/B/C/D), the option text, and a trailing check indicator.
/// Selected = `primary-fixed` fill + `primaryContainer` letter badge +
/// `tertiary-fixed` check. Purely presentational — the exercise widget owns the
/// selection id and submission; this only reflects [selected] and reports
/// [onTap].
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.letter,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Single-character badge, e.g. "A".
  final String letter;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bg = selected ? AppTheme.primaryFixed : AppTheme.surfaceContainerLowest;
    final badgeBg =
        selected ? AppTheme.primaryContainer : AppTheme.surfaceContainerHigh;
    final badgeFg = selected ? AppTheme.onPrimary : AppTheme.onSurfaceVariant;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Text(
                  letter,
                  style: textTheme.titleMedium?.copyWith(color: badgeFg),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodyLarge?.copyWith(
                    color: selected ? AppTheme.onPrimaryFixed : AppTheme.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color:
                    selected ? AppTheme.tertiaryFixedDim : AppTheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
