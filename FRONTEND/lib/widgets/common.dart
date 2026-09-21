import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fx/fx_controller.dart';

import '../models/models.dart';
import '../theme/way_theme.dart';

/// Coppia colore/sfondo della difficolta'. Verde facile, giallo media,
/// rosso difficile: la codifica e' la stessa ovunque compaia una task.
({Color fg, Color bg}) difficultyColors(BuildContext context, Difficulty d) {
  final c = context.c;
  return switch (d) {
    Difficulty.easy => (fg: c.easy, bg: c.easyTint),
    Difficulty.media => (fg: c.media, bg: c.mediaTint),
    Difficulty.hard => (fg: c.hard, bg: c.hardTint),
  };
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.fg, this.bg});

  final String text;
  final Color? fg;
  final Color? bg;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg ?? c.surface2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: WayFonts.mono(
          size: 9.5,
          weight: FontWeight.w600,
          color: fg ?? c.inkFaint,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

class DifficultyPill extends StatelessWidget {
  const DifficultyPill(this.difficulty, {super.key});

  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final colors = difficultyColors(context, difficulty);
    return Pill(difficulty.label, fg: colors.fg, bg: colors.bg);
  }
}

/// Intestazione di schermata: occhiello mono sopra, titolo display sotto.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow.toUpperCase(), style: WayFonts.label(color: c.inkFaint)),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: WayFonts.display(size: 27, color: c.ink, letterSpacing: -0.8),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: WayFonts.label(color: context.c.inkFaint, size: 10.5),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.foreground,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final enabled = onPressed != null;
    final bg = color ?? c.accent;
    final fg = foreground ?? c.accentInk;
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: WayFonts.ui(size: 14, weight: FontWeight.w600, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.foreground,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = foreground ?? c.ink;
    return Material(
      color: c.surface2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: WayFonts.ui(size: 13.5, weight: FontWeight.w600, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottone tratteggiato per le azioni di creazione: dice "qui si aggiunge"
/// senza pesare come un bottone pieno.
class DashedActionButton extends StatelessWidget {
  const DashedActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.add,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return CustomPaint(
      painter: DashedBorderPainter(color: c.accentSoft, radius: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: c.accent),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: WayFonts.ui(size: 14, weight: FontWeight.w600, color: c.accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    this.radius = 14,
    this.strokeWidth = 1.4,
    this.dash = 5,
    this.gap = 4,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// Selettore a segmenti, usato per periodo del grafico e viste dei criteri.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(values[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: values[i] == selected ? c.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: values[i] == selected
                        ? [
                            BoxShadow(
                              color: c.ink.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: WayFonts.ui(
                      size: 11.5,
                      weight: FontWeight.w600,
                      color: values[i] == selected ? c.ink : c.inkFaint,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EmptyStateBox extends StatelessWidget {
  const EmptyStateBox({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: c.line),
            ),
            child: Icon(icon, size: 22, color: c.inkFaint),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: WayFonts.display(size: 16, weight: FontWeight.w600, color: c.inkSoft),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: WayFonts.ui(size: 12.5, color: c.inkFaint),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un'unica porta per le notifiche interne: la capsula in cima allo
/// schermo. Non serve avere un ref a portata di mano, il contenitore di
/// Riverpod si trova dal contesto.
void showToast(BuildContext context, String message, [String sub = '']) {
  final container = ProviderScope.containerOf(context, listen: false);
  container.read(fxProvider).notify(
        FxNotification(title: message, sub: sub),
      );
}

/// Decorazione comune dei campi di testo.
InputDecoration fieldDecoration(BuildContext context, String hint) {
  final c = context.c;
  return InputDecoration(
    hintText: hint,
    hintStyle: WayFonts.ui(size: 14, color: c.inkFaint),
    filled: true,
    fillColor: c.surface2,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c.accent),
    ),
  );
}

/// Numeri: mezzo punto quando serve, interi quando basta.
String fmtNum(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

extension CapitalizeX on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

/// Barra della quantita' con la tacca della soglia minima.
class MeasureBar extends StatelessWidget {
  const MeasureBar({
    super.key,
    required this.percent,
    required this.color,
  });

  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: 6,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surface3,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                width: width * (percent.clamp(0, 100) / 100),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CheckButton extends StatelessWidget {
  const CheckButton({super.key, required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? c.accent : Colors.transparent,
          border: Border.all(color: on ? c.accent : c.line, width: 1.6),
          boxShadow: on
              ? [BoxShadow(color: c.accentTint, blurRadius: 0, spreadRadius: 4)]
              : null,
        ),
        child: Icon(
          Icons.check_rounded,
          size: 19,
          color: on ? c.accentInk : Colors.transparent,
        ),
      ),
    );
  }
}

class StepperControl extends StatelessWidget {
  const StepperControl({
    super.key,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final double value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.surface3,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _key(context, Icons.remove_rounded, onMinus),
          SizedBox(
            width: 34,
            child: Text(
              fmtNum(value),
              textAlign: TextAlign.center,
              style: WayFonts.mono(
                size: 13,
                weight: FontWeight.w700,
                color: c.ink,
              ),
            ),
          ),
          _key(context, Icons.add_rounded, onPlus),
        ],
      ),
    );
  }

  Widget _key(BuildContext context, IconData icon, VoidCallback onTap) {
    final c = context.c;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: 17, color: c.inkSoft),
        ),
      ),
    );
  }
}

/// Card di scelta: la card e' il comando, non un blocco informativo.
/// La spiegazione e gli esempi stanno dentro l'opzione, cosi' non serve
/// una pagina di teoria prima della domanda.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    required this.body,
    required this.onTap,
    this.icon,
    this.leading,
    this.tags = const [],
    this.selected = false,
  });

  final String title;
  final String body;
  final VoidCallback onTap;
  final IconData? icon;

  /// Alternativa all'icona: un disegno, per esempio la curva di ricompensa.
  final Widget? leading;
  final List<String> tags;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? c.accentTint : c.surface2,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 15, 13, 15),
            decoration: BoxDecoration(
              border: Border.all(color: selected ? c.accent : c.line),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null)
                  leading!
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.surface3,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, size: 20, color: c.accent),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: WayFonts.ui(
                          size: 13.5,
                          weight: FontWeight.w800,
                          color: c.ink,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: WayFonts.ui(size: 11.5, color: c.inkSoft),
                      ),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            for (final t in tags)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: c.surface3,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  t,
                                  style: WayFonts.mono(
                                    size: 9,
                                    color: c.inkFaint,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 20, color: c.inkFaint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastiglia di scorciatoia (tutti i giorni, solo feriali...).
class ShortcutChip extends StatelessWidget {
  const ShortcutChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.accentTint : c.surface2,
            border: Border.all(color: selected ? c.accentSoft : c.line),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: WayFonts.ui(
              size: 12,
              weight: FontWeight.w700,
              color: selected ? c.accent : c.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
