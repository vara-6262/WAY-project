import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/way_theme.dart';

/// Anello della giornata. Oltre il 100% disegna un secondo arco sopra il
/// primo, cosi' il superamento si vede invece di essere tagliato.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.percent, this.size = 104});

  final int percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              percent: percent,
              track: c.surface3,
              base: c.accent,
              overflow: c.easy,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent',
                style: WayFonts.display(
                  size: 27,
                  color: c.ink,
                  letterSpacing: -1.1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '% GIORNO',
                style: WayFonts.mono(size: 9, color: c.inkFaint, letterSpacing: 1.2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.percent,
    required this.track,
    required this.base,
    required this.overflow,
  });

  final int percent;
  final Color track;
  final Color base;
  final Color overflow;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.085;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - stroke) / 2,
    );

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(rect.center, rect.width / 2, trackPaint);

    const start = -math.pi / 2;
    final basePaint = Paint()
      ..color = base
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final baseSweep = (percent.clamp(0, 100) / 100) * 2 * math.pi;
    if (baseSweep > 0) canvas.drawArc(rect, start, baseSweep, false, basePaint);

    final extra = (percent - 100).clamp(0, 100);
    if (extra > 0) {
      final overPaint = Paint()
        ..color = overflow
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, (extra / 100) * 2 * math.pi, false, overPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.percent != percent || old.base != base || old.track != track;
}
