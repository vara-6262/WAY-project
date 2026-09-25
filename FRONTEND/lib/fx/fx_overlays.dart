import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/glyphs.dart';
import '../theme/way_colors.dart';
import '../theme/way_theme.dart';
import 'fx_controller.dart';

/// La capsula delle notifiche interne.
///
/// Sul telefono vero la Dynamic Island e' un'area di sistema: un'app
/// Flutter non puo' disegnarci dentro. Questa e' la sua controparte
/// onesta, una capsula che nasce sotto la barra di stato con la stessa
/// forma e lo stesso comportamento. Per la vera Live Activity servirebbe
/// ActivityKit dietro un platform channel, indicato nel README.
class IslandBanner extends StatelessWidget {
  const IslandBanner({super.key, required this.notification});

  final FxNotification? notification;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final open = notification != null;
    final top = MediaQuery.of(context).padding.top;
    final maxW = math.min(MediaQuery.of(context).size.width - 40, 320.0);

    return Positioned(
      top: top + 6,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            scale: open ? 1 : 0.7,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: open ? 1 : 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 460),
                curve: Curves.easeOutBack,
                width: open ? maxW : 118,
                height: open ? 58 : 34,
                padding: const EdgeInsets.fromLTRB(13, 0, 15, 0),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(open ? 29 : 17),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.55),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: open ? _content(context, c) : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WayColors c) {
    final n = notification!;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
          child: Icon(
            n.iconKey == null ? Icons.check_rounded : taskIcon(n.iconKey!),
            size: 17,
            color: c.accentInk,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                n.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: WayFonts.ui(
                  size: 12.5,
                  weight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.22,
                ),
              ),
              if (n.sub.isNotEmpty)
                Text(
                  n.sub.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WayFonts.mono(
                    size: 8.5,
                    weight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.52),
                    letterSpacing: 1.3,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Cartellino di riconoscimento con fondo fluido: tre masse sfocate che
/// vanno alla deriva su cicli mai sincronizzati.
class RewardCardView extends StatefulWidget {
  const RewardCardView({super.key, required this.card, this.onDismiss});

  final FxCard? card;
  final VoidCallback? onDismiss;

  @override
  State<RewardCardView> createState() => _RewardCardViewState();
}

class _RewardCardViewState extends State<RewardCardView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final c = context.c;
    final visible = card != null;

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            offset: Offset(0, visible ? 0.18 : 0.26),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 460),
              curve: Curves.easeOutBack,
              scale: visible ? 1 : 0.82,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 260),
                opacity: visible ? 1 : 0,
                child: visible ? _card(context, c, card) : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, WayColors c, FxCard card) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300, minWidth: 252),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.accent.withOpacity(0.34)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 48,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _drift,
                  builder: (_, __) => CustomPaint(
                    painter: _BlobPainter(
                      t: _drift.value,
                      a: c.accent,
                      b: c.media,
                      d: c.accentSoft,
                      scrim: c.surface,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 17),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      card.eyebrow.toUpperCase(),
                      style: WayFonts.mono(
                        size: 8.5,
                        weight: FontWeight.w700,
                        color: c.accent,
                        letterSpacing: 1.7,
                      ),
                    ),
                    const SizedBox(height: 7),
                    if (card.kind == FxCardKind.day)
                      _bigNumber(c, card)
                    else
                      _levelSwap(c, card),
                    const SizedBox(height: 9),
                    Text(
                      card.title,
                      textAlign: TextAlign.center,
                      style: WayFonts.display(size: 16, color: c.ink),
                    ),
                    if (card.stats.isNotEmpty) ...[
                      const SizedBox(height: 11),
                      Container(
                        padding: const EdgeInsets.only(top: 11),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: c.ink.withOpacity(0.12)),
                          ),
                        ),
                        child: Text(
                          card.stats.join('  ·  ').toUpperCase(),
                          textAlign: TextAlign.center,
                          style: WayFonts.mono(
                            size: 9.5,
                            color: c.inkFaint,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigNumber(WayColors c, FxCard card) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.bigValue ?? '',
          style: WayFonts.display(
            size: 52,
            weight: FontWeight.w800,
            color: c.ink,
            height: 0.9,
            letterSpacing: -2.6,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            card.bigSuffix ?? '',
            style: WayFonts.display(size: 22, color: c.accent),
          ),
        ),
      ],
    );
  }

  Widget _levelSwap(WayColors c, FxCard card) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          card.fromLevel ?? '',
          style: WayFonts.display(size: 24, color: c.inkFaint),
        ),
        const SizedBox(width: 10),
        Icon(Icons.arrow_forward_rounded, size: 16, color: c.accent),
        const SizedBox(width: 10),
        Text(
          card.toLevel ?? '',
          style: WayFonts.display(
            size: 46,
            weight: FontWeight.w800,
            color: c.accent,
            height: 0.9,
            letterSpacing: -2.2,
          ),
        ),
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  const _BlobPainter({
    required this.t,
    required this.a,
    required this.b,
    required this.d,
    required this.scrim,
  });

  final double t;
  final Color a, b, d, scrim;

  @override
  void paint(Canvas canvas, Size size) {
    void blob(Color color, double opacity, Offset base, double r, double phase) {
      final k = (t + phase) % 1.0;
      final dx = math.sin(k * math.pi * 2) * 22;
      final dy = math.cos(k * math.pi * 2 * 0.7) * 18;
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);
      canvas.drawCircle(base + Offset(dx, dy), r, paint);
    }

    blob(a, 0.78, Offset(size.width * 0.12, size.height * 0.05), 92, 0);
    blob(b, 0.6, Offset(size.width * 0.95, size.height * 0.2), 84, 0.33);
    blob(d, 0.52, Offset(size.width * 0.45, size.height * 1.02), 96, 0.66);

    // Velo sopra le masse: senza, il testo non regge il contrasto.
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scrim.withOpacity(0.54),
            scrim.withOpacity(0.84),
            scrim.withOpacity(0.92),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}
