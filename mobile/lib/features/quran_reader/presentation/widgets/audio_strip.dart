import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// The reader's audio strip (design-mapping §2 screen 06): a round
/// `primary-container` play/pause button, the surah + reciter label, a 1.0x
/// speed chip, a repeat toggle, and a static scrub track.
///
/// Presentational only. [playing]/[looping] are driven by the real
/// `AudioController` state; [onPlayPause]/[onToggleLoop] forward to it. The
/// `AudioController` exposes no playback position, so the scrub track is a
/// static affordance — no fabricated progress or timer.
class AudioStrip extends StatelessWidget {
  const AudioStrip({
    super.key,
    required this.surahTitle,
    required this.reciterLabel,
    required this.playing,
    required this.loading,
    required this.looping,
    required this.onPlayPause,
    required this.onToggleLoop,
  });

  final String surahTitle;
  final String reciterLabel;
  final bool playing;
  final bool loading;
  final bool looping;

  /// Null disables the main play button (e.g. no ayah has audio).
  final VoidCallback? onPlayPause;
  final VoidCallback onToggleLoop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: AppTheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              _PlayButton(
                playing: playing,
                loading: loading,
                onPressed: onPlayPause,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surahTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: AppTheme.primary),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.mic, size: 14, color: AppTheme.secondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            reciterLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Text('1.0x', style: theme.textTheme.labelMedium),
              ),
              const SizedBox(width: 6),
              _RepeatButton(looping: looping, onPressed: onToggleLoop),
            ],
          ),
          const SizedBox(height: 10),
          // Static scrub track — no live position is available (honest).
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.playing,
    required this.loading,
    required this.onPressed,
  });

  final bool playing;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primaryContainer,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: loading ? null : onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.onPrimary,
                  ),
                )
              : Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                  size: 26,
                  color: AppTheme.onPrimary,
                ),
        ),
      ),
    );
  }
}

class _RepeatButton extends StatelessWidget {
  const _RepeatButton({required this.looping, required this.onPressed});
  final bool looping;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: looping
          ? AppTheme.secondaryFixed
          : AppTheme.surfaceContainer,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            looping ? Icons.repeat_one : Icons.repeat,
            size: 20,
            color: looping ? AppTheme.secondary : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
