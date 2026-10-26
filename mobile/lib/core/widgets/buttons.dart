import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Full-width rounded-full primary CTA pill (design-mapping §3, screens 01/07):
/// `primaryContainer` fill, `onPrimary` label, optional trailing icon
/// (defaults to a forward arrow).
class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon = Icons.arrow_forward,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryContainer,
          foregroundColor: AppTheme.onPrimary,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: textTheme.titleMedium?.copyWith(color: AppTheme.onPrimary),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-width h-56 `rounded-2xl` `surface-container-lowest` card used for the
/// social sign-in buttons (design-mapping §3, screen 02): a leading glyph
/// widget + centered label, soft shadow. Disabled when [onPressed] is null.
class AuthProviderButton extends StatelessWidget {
  const AuthProviderButton({
    super.key,
    required this.leading,
    required this.label,
    required this.onPressed,
  });

  final Widget leading;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        elevation: 1,
        shadowColor: AppTheme.primary.withValues(alpha: 0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius2xl),
          onTap: onPressed,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                leading,
                const SizedBox(width: 12),
                Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(color: AppTheme.onSurface),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width `surface-container-lowest` secondary button with `primary`
/// foreground and rounded-lg corners (design-mapping §3, screen 07).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.surfaceContainerLowest,
          foregroundColor: AppTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: textTheme.titleMedium?.copyWith(color: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
