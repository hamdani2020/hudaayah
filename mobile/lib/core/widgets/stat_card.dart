import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Small stat tile: an icon, a value, and a caption (design-mapping §3, screens
/// 05/07/08). Presentational — the caller supplies real values only.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.caption,
    this.iconColor,
  });

  final IconData icon;
  final String value;
  final String caption;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? AppTheme.secondaryContainer),
          const SizedBox(height: 12),
          Text(value, style: textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(caption, style: textTheme.labelMedium),
        ],
      ),
    );
  }
}

/// Icon + value + caption cell for the profile/completion metric rows
/// (design-mapping §3, screens 07/08). Centered, borderless — meant to sit in a
/// shared row/container. Presentational.
class MetricCell extends StatelessWidget {
  const MetricCell({
    super.key,
    required this.icon,
    required this.value,
    required this.caption,
    this.iconColor,
  });

  final IconData icon;
  final String value;
  final String caption;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor ?? AppTheme.secondaryContainer),
        const SizedBox(height: 8),
        Text(value, style: textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: textTheme.labelSmall,
        ),
      ],
    );
  }
}
