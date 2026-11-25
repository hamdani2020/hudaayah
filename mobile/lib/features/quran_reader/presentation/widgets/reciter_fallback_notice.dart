import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../profile/data/reciter_repository.dart';
import '../../data/lesson_audio.dart';

/// Tells the learner when their chosen reciter has no audio for this lesson and
/// the default reciter is playing instead. Renders nothing otherwise.
class ReciterFallbackNotice extends ConsumerWidget {
  const ReciterFallbackNotice({super.key, required this.audio});

  final LessonAudio? audio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final from = audio?.fallbackFrom;
    if (audio == null || from == null) return const SizedBox.shrink();
    final reciters = ref.watch(recitersProvider).valueOrNull ?? const [];
    final chosen = reciters.where((r) => r.id == from).firstOrNull?.name;
    return Container(
      key: const ValueKey('reciter-fallback-notice'),
      width: double.infinity,
      color: AppTheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '${chosen ?? 'Your chosen reciter'} is not available for this lesson. '
        'Playing the default reciter, ${audio!.reciter.name}.',
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: AppTheme.onSurfaceVariant),
      ),
    );
  }
}
