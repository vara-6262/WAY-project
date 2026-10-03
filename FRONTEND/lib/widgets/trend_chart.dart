import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/way_colors.dart';
import '../theme/way_theme.dart';

/// Curva del periodo: linea smussata, area sfumata sotto, riga del 100%
/// e un cursore che segue il dito per leggere il valore esatto.
class TrendChart extends StatefulWidget {
  const TrendChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 112,
  });

  /// Null = giornata senza task previste, non giornata a zero.
  final List<int?> values;
  final List<String> labels;
  final double height;

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int? _active;

  void _pick(Offset local, double width) {
    if (widget.values.isEmpty) return;
    final n = widget.values.length;
    final step = n == 1 ? width : width / (n - 1);
    var i = (local.dx / step).round().clamp(0, n - 1);
    // Salto i punti senza dato: non hanno niente da raccontare.
    if (widget.values[i] == null) {
      final alt = _nearestWithValue(i);
      if (alt == null) return;
      i = alt;
    }
    if (i != _active) setState(() => _active = i);
  }

  int? _nearestWithValue(int from) {
    for (var d = 1; d < widget.values.length; d++) {
      if (from - d >= 0 && widget.values[from - d] != null) return from - d;
      if (from + d < widget.values.length && widget.values[from + d] != null) {
        return from + d;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final maxValue = [
      120,
      ...widget.values.map((v) => v ?? 0),
    ].reduce(math.max).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _pick(d.localPosition, constraints.maxWidth),
                onHorizontalDragUpdate: (d) =>
                    _pick(d.localPosition, constraints.maxWidth),
                onHorizontalDragEnd: (_) => setState(() => _active = null),
                onTapUp: (_) => setState(() => _active = null),
                child: CustomPaint(
                  painter: _TrendPainter(
                    values: widget.values,
                    maxValue: maxValue,
                    active: _active,
                    colors: c,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < widget.labels.length; i++)
              Expanded(
                child: Text(
                  widget.labels[i],
                  textAlign: TextAlign.center,
                  style: WayFonts.mono(
                    size: 9,
                    color: i == _active ? c.accent : c.inkFaint,
                    letterSpacing: 0,
                  ),
                ),
              ),
          ],
        ),
        if (_active != null && widget.values[_active!] != null) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              '${widget.labels.length > _active! && widget.labels[_active!].isNotEmpty ? '${widget.labels[_active!]} · ' : ''}'
              '${widget.values[_active!]}%',
              style: WayFonts.mono(
                size: 10.5,
                weight: FontWeight.w700,
                color: c.accent,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.values,
    required this.maxValue,
    required this.active,
    required this.colors,
  });

  final List<int?> values;
  final double maxValue;
  final int? active;
  final WayColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const padTop = 8.0;
    const padBottom = 6.0;
    final usable = size.height - padTop - padBottom;

    Offset pointAt(int i) {
      final x = values.length == 1
          ? size.width / 2
          : i * (size.width / (values.length - 1));
      final v = (values[i] ?? 0).toDouble();
      return Offset(x, padTop + (maxValue - v) / maxValue * usable);
    }

    final pts = [for (var i = 0; i < values.length; i++) pointAt(i)];

    // Linea del 100%: il riferimento contro cui si legge tutto il resto.
    final limitY = padTop + (maxValue - 100) / maxValue * usable;
    final dash = Paint()
      ..color = colors.line
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, limitY), Offset(x + 3, limitY), dash);
    }

    // Curva smussata con maniglie orizzontali, come nel prototipo.
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p1 = pts[i], p2 = pts[i + 1];
      final handle = (p2.dx - p1.dx) * 0.38;
      path.cubicTo(p1.dx + handle, p1.dy, p2.dx - handle, p2.dy, p2.dx, p2.dy);
    }

    final area = Path.from(path)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.accent.withValues(alpha: 0.28), colors.accent.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = colors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Punti solo dove c'e' un'etichetta o sull'ultimo dato: con 30 giorni
    // una pallina per giorno diventa rumore.
    final dot = Paint()..color = colors.accent;
    for (var i = 0; i < pts.length; i++) {
      if (values[i] == null) continue;
      final show = values.length <= 12 || i == pts.length - 1;
      if (!show) continue;
      canvas.drawCircle(pts[i], 3, dot);
    }

    if (active != null && active! < pts.length && values[active!] != null) {
      final p = pts[active!];
      canvas.drawLine(
        Offset(p.dx, 0),
        Offset(p.dx, size.height),
        Paint()
          ..color = colors.accent.withValues(alpha: 0.35)
          ..strokeWidth = 1,
      );
      canvas.drawCircle(p, 6, Paint()..color = colors.accent.withValues(alpha: 0.22));
      canvas.drawCircle(p, 4, dot);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.active != active ||
      old.maxValue != maxValue ||
      !identical(old.values, values);
}
