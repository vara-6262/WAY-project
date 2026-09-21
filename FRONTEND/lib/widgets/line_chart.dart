import 'package:flutter/material.dart';

import '../theme/way_theme.dart';

/// Grafico a linea smussato (Catmull-Rom → Bézier) con area, guida opzionale
/// e selezione al tocco/trascinamento che mostra il valore del punto.
/// null in `values` = giorno senza dato (linea interrotta).
class SmoothLineChart extends StatefulWidget {
  const SmoothLineChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 140,
    this.guide,
    this.format,
    this.color,
  });

  final List<double?> values;
  final List<String> labels;
  final double height;
  final double? guide; // linea tratteggiata di riferimento (es. 100 o il target)
  final String Function(double v)? format;
  final Color? color;

  @override
  State<SmoothLineChart> createState() => _SmoothLineChartState();
}

class _SmoothLineChartState extends State<SmoothLineChart> {
  int? _sel;

  int _indexAt(double x, double w) {
    final n = widget.values.length;
    if (n <= 1) return 0;
    return ((x / w).clamp(0.0, 1.0) * (n - 1)).round();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final line = widget.color ?? c.accent;
    final fmt = widget.format ?? ((v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1));
    final nums = widget.values.whereType<double>().toList();
    final maxData = nums.isEmpty ? 1.0 : nums.reduce((a, b) => a > b ? a : b);
    final maxV = [
      widget.guide ?? 0,
      maxData,
      1.0,
    ].reduce((a, b) => a > b ? a : b) * 1.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, cons) {
              final w = cons.maxWidth;
              return GestureDetector(
                onTapDown: (d) => setState(() => _sel = _indexAt(d.localPosition.dx, w)),
                onTapUp: (_) => setState(() => _sel = null),
                onTapCancel: () => setState(() => _sel = null),
                onPanUpdate: (d) => setState(() => _sel = _indexAt(d.localPosition.dx, w)),
                onPanEnd: (_) => setState(() => _sel = null),
                child: CustomPaint(
                  size: Size(w, widget.height),
                  painter: _LinePainter(
                    values: widget.values,
                    maxV: maxV,
                    guide: widget.guide,
                    sel: _sel,
                    fmt: fmt,
                    line: line,
                    fill: line.withOpacity(0.12),
                    grid: c.line,
                    surface: c.surface,
                    ink: c.ink,
                    faint: c.inkFaint,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            for (var i = 0; i < widget.labels.length; i++)
              Expanded(
                child: Text(
                  widget.labels[i],
                  textAlign: TextAlign.center,
                  style: WayFonts.mono(size: 8.5, color: c.inkFaint, letterSpacing: 0),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.maxV,
    required this.guide,
    required this.sel,
    required this.fmt,
    required this.line,
    required this.fill,
    required this.grid,
    required this.surface,
    required this.ink,
    required this.faint,
  });

  final List<double?> values;
  final double maxV;
  final double? guide;
  final int? sel;
  final String Function(double) fmt;
  final Color line, fill, grid, surface, ink, faint;

  @override
  void paint(Canvas canvas, Size size) {
    const padTop = 10.0, padBottom = 4.0;
    final h = size.height - padTop - padBottom;
    final n = values.length;
    double xAt(int i) => n <= 1 ? size.width / 2 : i * size.width / (n - 1);
    double yAt(double v) => padTop + h - (v / maxV) * h;

    if (guide != null) {
      final gy = yAt(guide!);
      final gp = Paint()..color = grid..strokeWidth = 1;
      var gx = 0.0;
      while (gx < size.width) {
        canvas.drawLine(Offset(gx, gy), Offset(gx + 3, gy), gp);
        gx += 6;
      }
    }

    final pts = <Offset?>[];
    for (var i = 0; i < n; i++) {
      final v = values[i];
      pts.add(v == null ? null : Offset(xAt(i), yAt(v)));
    }

    final segments = <List<Offset>>[];
    var cur = <Offset>[];
    for (final p in pts) {
      if (p == null) {
        if (cur.isNotEmpty) { segments.add(cur); cur = <Offset>[]; }
      } else {
        cur.add(p);
      }
    }
    if (cur.isNotEmpty) segments.add(cur);

    final linePaint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()..color = fill..style = PaintingStyle.fill;

    for (final s in segments) {
      final p = Path();
      _smooth(p, s);
      final f = Path()..addPath(p, Offset.zero);
      f.lineTo(s.last.dx, padTop + h);
      f.lineTo(s.first.dx, padTop + h);
      f.close();
      canvas.drawPath(f, fillPaint);
      canvas.drawPath(p, linePaint);
    }
    for (final p in pts) {
      if (p != null) canvas.drawCircle(p, 2.2, Paint()..color = line);
    }

    final i = sel;
    if (i != null && i >= 0 && i < n && values[i] != null) {
      final px = xAt(i);
      final py = yAt(values[i]!);
      canvas.drawLine(Offset(px, padTop), Offset(px, padTop + h),
          Paint()..color = faint..strokeWidth = 1);
      canvas.drawCircle(Offset(px, py), 4, Paint()..color = surface);
      canvas.drawCircle(Offset(px, py), 4,
          Paint()..color = line..style = PaintingStyle.stroke..strokeWidth = 2);
      final tp = TextPainter(
        text: TextSpan(
          text: fmt(values[i]!),
          style: TextStyle(color: surface, fontSize: 11, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final bw = tp.width + 12, bh = tp.height + 8;
      final bx = (px - bw / 2).clamp(0.0, size.width - bw).toDouble();
      final by = (py - bh - 8).clamp(0.0, size.height - bh).toDouble();
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(6)),
        Paint()..color = ink,
      );
      tp.paint(canvas, Offset(bx + 6, by + 4));
    }
  }

  void _smooth(Path path, List<Offset> pts) {
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      path.addOval(Rect.fromCircle(center: pts.first, radius: 0.1));
      return;
    }
    path.moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[0] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      final c1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final c2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values || old.sel != sel || old.maxV != maxV;
}
