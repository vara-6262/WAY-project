import 'package:flutter/material.dart';

import '../data/dates.dart';
import '../models/models.dart';
import '../theme/way_theme.dart';
import 'common.dart';

/// Editor del dominio di una task, in stile Sabus mobile: giorni della
/// settimana, tipologia (giornaliera / settimanale) e finestra oraria.
class DomainEditor extends StatelessWidget {
  const DomainEditor({
    super.key,
    required this.days,
    required this.period,
    required this.start,
    required this.end,
    required this.onToggleDay,
    required this.onPeriod,
    required this.onStart,
    required this.onEnd,
  });

  final List<int> days;
  final DomainPeriod period;
  final int start;
  final int end;
  final void Function(int index) onToggleDay;
  final void Function(DomainPeriod period) onPeriod;
  final void Function(int hour) onStart;
  final void Function(int hour) onEnd;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('GIORNI', style: WayFonts.label(color: c.inkFaint, size: 9.5)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () => onToggleDay(i),
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: days.contains(i) ? c.accent : c.surface2,
                        border: Border.all(color: days.contains(i) ? c.accent : c.line),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        Dates.dayShort[i],
                        style: WayFonts.mono(
                          size: 12,
                          weight: FontWeight.w700,
                          color: days.contains(i) ? c.onSolid : c.inkSoft,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text('TIPOLOGIA', style: WayFonts.label(color: c.inkFaint, size: 9.5)),
        const SizedBox(height: 8),
        Segmented<DomainPeriod>(
          values: DomainPeriod.values,
          labels: const ['Giornaliera', 'Settimanale'],
          selected: period,
          onChanged: onPeriod,
        ),
        const SizedBox(height: 6),
        Text(
          period == DomainPeriod.daily
              ? 'Va fatta in ogni giorno selezionato.'
              : 'Basta farla una volta, in uno dei giorni selezionati.',
          style: WayFonts.mono(size: 10, color: c.inkFaint),
        ),
        const SizedBox(height: 18),
        Text('ORARIO', style: WayFonts.label(color: c.inkFaint, size: 9.5)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _HourStepper(label: 'Dalle', value: start, onChanged: onStart)),
            const SizedBox(width: 10),
            Expanded(child: _HourStepper(label: 'Alle', value: end, onChanged: onEnd)),
          ],
        ),
      ],
    );
  }
}

class _HourStepper extends StatelessWidget {
  const _HourStepper({required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: WayFonts.label(color: c.inkFaint, size: 8.5)),
                Text('${value.toString().padLeft(2, '0')}:00',
                    style: WayFonts.display(size: 16, color: c.ink)),
              ],
            ),
          ),
          _key(context, Icons.remove_rounded,
              () => onChanged((value - 1).clamp(0, 24))),
          const SizedBox(width: 6),
          _key(context, Icons.add_rounded,
              () => onChanged((value + 1).clamp(0, 24))),
        ],
      ),
    );
  }

  Widget _key(BuildContext context, IconData icon, VoidCallback onTap) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surface3,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: c.inkSoft),
      ),
    );
  }
}
