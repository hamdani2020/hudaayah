import 'package:flutter/material.dart';

import '../../../core/widgets/option_card.dart';
import '../data/exercise_models.dart';

/// Renders a prompt + options as answer cards. Submits the selected option id.
/// No answer key is present client-side; correctness comes from the server
/// after submit (design-mapping §2, screen 05).
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

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = ((widget.exercise.config['options'] as List?) ?? []).cast<Map>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.exercise.prompt, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OptionCard(
              letter: i < _letters.length ? _letters[i] : '${i + 1}',
              label: options[i]['text'] as String? ?? '',
              selected: _selected == options[i]['id'],
              onTap: widget.enabled
                  ? () => setState(() => _selected = options[i]['id'] as String?)
                  : null,
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
