import 'package:flutter/material.dart';

import '../data/exercise_models.dart';

/// Renders a prompt + options. Submits the selected option id. No answer key is
/// present client-side; correctness comes from the server after submit.
class MultipleChoiceWidget extends StatefulWidget {
  const MultipleChoiceWidget({
    super.key,
    required this.exercise,
    required this.enabled,
    required this.onSubmit,
  });

  final Exercise exercise;
  final bool enabled;
  final void Function(Map<String, dynamic> submitted) onSubmit;

  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = (widget.exercise.config['options'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.exercise.prompt, style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        for (final opt in options.cast<Map>())
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OptionTile(
              label: opt['text'] as String? ?? '',
              selected: _selected == opt['id'],
              enabled: widget.enabled,
              onTap: () => setState(() => _selected = opt['id'] as String?),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: (widget.enabled && _selected != null)
              ? () => widget.onSubmit({'selected_option_id': _selected})
              : null,
          child: const Text('Check'),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.06)
              : null,
        ),
        child: Text(label, style: theme.textTheme.bodyLarge),
      ),
    );
  }
}
