import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/way_colors.dart';
import 'fx_controller.dart';

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.g,
    required this.rot,
    required this.vr,
    required this.w,
    required this.h,
    required this.max,
    required this.color,
  });

  double x, y, vx, vy, rot;
  final double g, vr, w, h, max;
  final Color color;
  double life = 0;
}

/// Coriandoli su una sola superficie disegnata, non decine di widget:
/// il ciclo parte quando serve e si spegne da solo quando l'ultima
/// particella e' morta.
class RewardLayer extends StatefulWidget {
  const RewardLayer({super.key, required this.controller});

  final FxController controller;

  @override
  State<RewardLayer> createState() => _RewardLayerState();
}

class _RewardLayerState extends State<RewardLayer>
    with SingleTickerProviderStateMixin {
  final List<_Particle> _parts = [];
  final math.Random _rnd = math.Random();
  Ticker? _ticker;
  Duration _last = Duration.zero;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onFx);
    _ticker = createTicker(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  @override
  void didUpdateWidget(RewardLayer old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onFx);
      widget.controller.addListener(_onFx);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onFx);
    _ticker?.dispose();
    super.dispose();
  }

  void _onFx() {
    if (!widget.controller.hasPendingBursts) return;
    final bursts = widget.controller.drainBursts();
    if (_reduced) return;
    final palette = _palette();
    for (final b in bursts) {
      // Su schermi piccoli o dispositivi lenti meno particelle: l'effetto
      // regge lo stesso e il primo frame resta leggero.
      final n = b.count;
      for (var i = 0; i < n; i++) {
        final a = b.angle + (_rnd.nextDouble() - 0.5) * b.spread;
        final speed = b.power * (0.5 + _rnd.nextDouble() * 0.8);
        _parts.add(_Particle(
          x: b.origin.dx,
          y: b.origin.dy,
          vx: math.cos(a) * speed + (_rnd.nextDouble() - 0.5) * 46,
          vy: math.sin(a) * speed,
          g: (560 + _rnd.nextDouble() * 300) * b.gravity,
          rot: _rnd.nextDouble() * math.pi,
          vr: (_rnd.nextDouble() - 0.5) * 12,
          w: 3 + _rnd.nextDouble() * 3.2,
          h: 4.5 + _rnd.nextDouble() * 4,
          max: (0.6 + _rnd.nextDouble() * 0.5) * b.life,
          color: palette[_rnd.nextInt(palette.length)],
        ));
      }
    }
    if (_parts.isNotEmpty && !(_ticker?.isActive ?? false)) {
      _last = Duration.zero;
      _ticker?.start();
    }
  }

  List<Color> _palette() {
    final c = Theme.of(context).extension<WayColors>() ?? WayColors.dark;
    return [c.accent, c.accent, c.accentSoft, c.media];
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : math.min(0.034, (elapsed - _last).inMicroseconds / 1e6);
    _last = elapsed;
    final size = context.size ?? Size.zero;
    for (var i = _parts.length - 1; i >= 0; i--) {
      final p = _parts[i];
      p.life += dt;
      if (p.life >= p.max || p.y > size.height + 40) {
        _parts.removeAt(i);
        continue;
      }
      p.vy += p.g * dt;
      p.vx -= p.vx * 2.2 * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rot += p.vr * dt;
    }
    if (_parts.isEmpty) {
      _ticker?.stop();
      _last = Duration.zero;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(_parts),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.parts);

  final List<_Particle> parts;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in parts) {
      final k = p.life / p.max;
      final alpha =
          k < 0.1 ? k / 0.1 : (1 - math.pow((k - 0.1) / 0.9, 2.2)).toDouble();
      paint.color = p.color.withOpacity(alpha.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rot);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
