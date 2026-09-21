import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/way_theme.dart';

/// Anteprima della curva di ricompensa. Serve a far vedere la differenza
/// tra lineare ed esponenziale prima di sceglierla, non a fare da grafico.
class RewardCurvePreview extends StatelessWidget {
  const RewardCurvePreview({
    super.key,
    required this.curve,
    required this.target,
  });

  final RewardCurve curve;
  final double target;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 76,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, double.infinity),
        painter: _CurvePainter(
          exponential: curve == RewardCurve.exponential,
          line: c.accent,
          guide: c.line,
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  const _CurvePainter({
    required this.exponential,
    required this.line,
    required this.guide,
  });

  final bool exponential;
  final Color line;
  final Color guide;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = guide
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      axis,
    );

    final path = Path();
    for (var i = 0; i <= 40; i++) {
      final x = i / 40;
      final value = exponential ? math.pow(x, 2.2).toDouble() : x;
      final point = Offset(x * size.width, size.height - value * size.height);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.exponential != exponential ||
      old.line != line;
}
