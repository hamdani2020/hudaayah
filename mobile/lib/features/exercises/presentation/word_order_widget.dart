import 'package:flutter/material.dart';

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
        Text(widget.exercise.prompt, style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        // Chosen sequence.
        Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
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
  const _Chip({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontFamily: 'UthmanicHafs', fontSize: 22),
      ),
      onPressed: onTap,
    );
  }
}
