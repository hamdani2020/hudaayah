import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../data/exercise_models.dart';

/// Tap tokens to build an order, then submit the ordered token ids. Arabic
/// tokens render RTL. Correctness is decided by the server.
class WordOrderWidget extends StatefulWidget {
  const WordOrderWidget({
    super.key,
    required this.exercise,
    required this.enabled,
    required this.onSubmit,
  });

  final Exercise exercise;
  final bool enabled;
  final void Function(Map<String, dynamic> submitted) onSubmit;

  @override
  State<WordOrderWidget> createState() => _WordOrderWidgetState();
}

class _WordOrderWidgetState extends State<WordOrderWidget> {
  final List<Map> _chosen = [];
  late List<Map> _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = List<Map>.from(
      ((widget.exercise.config['tokens'] as List?) ?? []).cast<Map>(),
    );
  }

  void _pick(Map token) {
    setState(() {
      _chosen.add(token);
      _remaining.remove(token);
    });
  }

  void _unpick(Map token) {
    setState(() {
      _remaining.add(token);
      _chosen.remove(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.exercise.prompt, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        // Chosen sequence.
        Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _chosen)
                  _Chip(
                    label: t['text'] as String? ?? '',
                    selected: true,
                    onTap: widget.enabled ? () => _unpick(t) : null,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Available tokens.
        Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _remaining)
                _Chip(
                  label: t['text'] as String? ?? '',
                  selected: false,
                  onTap: widget.enabled ? () => _pick(t) : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: (widget.enabled && _remaining.isEmpty && _chosen.isNotEmpty)
              ? () => widget.onSubmit({
                    'ordered_token_ids': [for (final t in _chosen) t['id']],
                  })
              : null,
          child: const Text('Check'),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppTheme.primaryFixed : AppTheme.surfaceContainerLowest;
    final fg = selected ? AppTheme.onPrimaryFixed : AppTheme.onSurface;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          // Arabic token keeps the UthmanicHafs family (graceful fallback).
          child: Text(
            label,
            style: TextStyle(
                fontFamily: 'UthmanicHafs', fontSize: 22, color: fg),
          ),
        ),
      ),
    );
  }
}
