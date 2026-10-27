import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// A settings row on the profile screen (design-mapping §2, screen 08): a
/// leading icon tile, a title + optional subtitle, and a trailing control —
/// either a chevron (navigational), a [Switch] (local toggle), or a custom
/// [trailing] widget. Purely presentational; the caller owns all state and
/// handlers.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleColor = destructive ? AppTheme.error : AppTheme.onSurface;
    final iconColor = destructive ? AppTheme.error : AppTheme.primary;
    final tileColor =
        destructive ? AppTheme.errorContainer : AppTheme.surfaceContainerHigh;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: textTheme.titleMedium
                            ?.copyWith(color: titleColor)),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: textTheme.labelSmall
                            ?.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(Icons.chevron_right,
                      color: AppTheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
