import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Tonal card with a leading icon tile, a title, and a body paragraph
/// (design-mapping §3, screens 02/03/04/07): trust note, daily wisdom, etc.
/// Presentational — colors default to a soft `surface-container-low` tile.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.backgroundColor,
    this.iconTileColor,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color? backgroundColor;
  final Color? iconTileColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconTileColor ?? AppTheme.primaryFixed,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Icon(icon, size: 20, color: iconColor ?? AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
