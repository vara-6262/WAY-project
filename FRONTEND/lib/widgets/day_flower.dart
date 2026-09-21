import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/dates.dart';
import '../theme/way_theme.dart';

/// Selettore a fiore: sette sfere in cerchio, una per giorno, e al centro
/// il pulsante che li prende o li libera tutti insieme.
class DayFlower extends StatelessWidget {
  const DayFlower({
    super.key,
    required this.selected,
    required this.onToggle,
    required this.onToggleAll,
    this.diameter = 216,
  });

  final List<int> selected;
  final ValueChanged<int> onToggle;
  final VoidCallback onToggleAll;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    const petal = 46.0;
    final center = diameter / 2;
    final radius = center - petal / 2 - 8;
    final all = selected.length == 7;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(diameter, diameter),
            painter: _SpokesPainter(color: c.line, radius: radius),
          ),
          for (var i = 0; i < 7; i++)
            _petalAt(context, i, center, radius, petal),
          Positioned(
            left: center - 32,
            top: center - 32,
            child: GestureDetector(
              onTap: onToggleAll,
              child: CustomPaint(
                foregroundPainter:
                    all ? null : DashedCirclePainter(color: c.accentSoft),
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: all ? c.accentTint : c.surface,
                    border: all ? Border.all(color: c.accent, width: 1.5) : null,
                  ),
                  child: Text(
                    all ? 'TUTTI\nI GIORNI' : 'SELEZIONA\nTUTTI',
                    textAlign: TextAlign.center,
                    style: WayFonts.mono(
                      size: 8.5,
                      weight: FontWeight.w600,
                      color: c.accent,
                      height: 1.3,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _petalAt(
    BuildContext context,
    int index,
    double center,
    double radius,
    double petal,
  ) {
    final c = context.c;
    final angle = (-90 + index * (360 / 7)) * math.pi / 180;
    final dx = center + math.cos(angle) * radius - petal / 2;
    final dy = center + math.sin(angle) * radius - petal / 2;
    final on = selected.contains(index);

    return Positioned(
      left: dx,
      top: dy,
      child: Semantics(
        label: Dates.dayLong[index],
        selected: on,
        button: true,
        child: GestureDetector(
          onTap: () => onToggle(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: petal,
            height: petal,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? c.accent : c.surface2,
              border: Border.all(color: on ? c.accent : c.line),
            ),
            child: Text(
              Dates.dayShort[index],
              style: WayFonts.display(
                size: 15,
                weight: FontWeight.w600,
                color: on ? c.accentInk : c.inkSoft,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpokesPainter extends CustomPainter {
  const _SpokesPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var i = 0; i < 7; i++) {
      final angle = (-90 + i * (360 / 7)) * math.pi / 180;
      canvas.drawLine(
        center,
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpokesPainter old) => old.color != color;
}

class DashedCirclePainter extends CustomPainter {
  const DashedCirclePainter({required this.color, this.strokeWidth = 1.5});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final path = Path()
      ..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 5;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + 4;
      }
    }
  }

  @override
  bool shouldRepaint(DashedCirclePainter old) => old.color != color;
}
