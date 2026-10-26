import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Circular percentage ring drawn with [CustomPaint] for the home habit card
/// (design-mapping §3, screen 04). Shows [percent] (0..1) with an optional
/// center label. Presentational — the caller supplies the honest value.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.percent,
    this.size = 64,
    this.strokeWidth = 6,
    this.label,
  });

  /// Completion fraction, 0.0–1.0.
  final double percent;
  final double size;
  final double strokeWidth;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          percent: percent.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
          trackColor: AppTheme.primary.withValues(alpha: 0.2),
          progressColor: AppTheme.secondaryContainer,
        ),
        child: Center(
          child: Text(
            label ?? '${(percent.clamp(0.0, 1.0) * 100).round()}%',
            style: textTheme.labelMedium?.copyWith(
              color: AppTheme.onPrimary,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.percent,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  final double percent;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = progressColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.percent != percent ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}
