import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// `surface-container-lowest` rounded search field with a leading search icon
/// (design-mapping §3, screen 03). Presentational — the caller filters the
/// in-memory list via [onChanged].
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.hintText = 'Search',
    this.controller,
    this.onChanged,
  });

  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
        prefixIcon: const Icon(Icons.search, color: AppTheme.onSurfaceVariant),
        filled: true,
        fillColor: AppTheme.surfaceContainerLowest,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }
}
