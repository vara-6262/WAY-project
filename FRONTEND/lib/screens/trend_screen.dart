import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dates.dart';
import '../models/app_data.dart';
import '../models/models.dart';
import '../models/sabus_scoring.dart';
import '../state/providers.dart';
import '../theme/way_theme.dart';
import '../widgets/common.dart';
import '../widgets/line_chart.dart';

/// Trend: il monitoraggio lungo. Percentuale Sabus nel tempo, streak reali,
/// e analisi separata di ogni task "number" con filtri (task + periodo).
class TrendScreen extends ConsumerStatefulWidget {
  const TrendScreen({super.key});

  @override
  ConsumerState<TrendScreen> createState() => _TrendScreenState();
}

class _TrendScreenState extends ConsumerState<TrendScreen> {
  String? _numberTaskId;

  List<DateTime> _daysBack(int n, DateTime today) =>
      [for (var i = n - 1; i >= 0; i--) Dates.addDays(today, -i)];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final data = ref.watch(appProvider);
    final today = Dates.today();

    // ---- serie percentuale Sabus ----
    final (pctValues, pctLabels) = _percentSeries(data, data.range, today);
    final valid = pctValues.whereType<double>().toList();
    final average = valid.isEmpty ? 0 : (valid.reduce((a, b) => a + b) / valid.length).round();
    final over = valid.where((v) => v >= 100).length;

    final pts = data.dayPoints(today);
    final bonusPct = (data.dayBonusFraction(today) * 100).round();
    final percentToday = data.dayPercentSabus(today);

    // ---- streak in corso ----
    final streaks = <({Task task, int streak})>[];
    for (final t in data.tasks) {
      final s = data.derivedStreak(t);
      if (s > 0) streaks.add((task: t, streak: s));
    }
    streaks.sort((a, b) => b.streak.compareTo(a.streak));
    final maxStreak = streaks.isEmpty ? 1 : (streaks.first.streak == 0 ? 1 : streaks.first.streak);

    // ---- forti / da curare ----
    final scored = [for (final t in data.tasks) (task: t, s: data.taskStrength(t))];
    final strong = [...scored]..sort((a, b) => b.s.compareTo(a.s));
    final weak = [...scored]..sort((a, b) => a.s.compareTo(b.s));

    // ---- analisi number ----
    final numberTasks = data.tasks.where((t) => t.kind == TaskKind.measure).toList();
    final sel = _numberTaskId != null
        ? data.taskById(_numberTaskId!)
        : (numberTasks.isNotEmpty ? numberTasks.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ScreenHeader(eyebrow: 'Monitoraggio', title: 'Trend'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            children: [
              // riepilogo di oggi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.accentTint,
                  border: Border.all(color: c.accentSoft),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    _metric(context, 'PUNTI OGGI', pts.toStringAsFixed(1)),
                    _sep(context),
                    _metric(context, 'COMPLETAMENTO',
                        percentToday == null ? '—' : '$percentToday%'),
                    _sep(context),
                    _metric(context, 'BONUS', '+$bonusPct%'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // andamento percentuale
              const SectionLabel('Andamento'),
              const SizedBox(height: 8),
              Segmented<TrendRange>(
                values: TrendRange.values,
                labels: TrendRange.values.map((r) => r.label).toList(),
                selected: data.range,
                onChanged: (r) => ref.read(appProvider.notifier).setRange(r),
              ),
              const SizedBox(height: 10),
              _panel(context, [
                SmoothLineChart(values: pctValues, labels: pctLabels, guide: 100,
                    format: (v) => '${v.round()}%'),
                const SizedBox(height: 10),
                _footRow(context, 'MEDIA', '$average%', 'GIORNI ≥ 100%', '$over/${valid.length}'),
              ]),
              const SizedBox(height: 22),

              // streak in corso
              const SectionLabel('Streak in corso'),
              const SizedBox(height: 8),
              if (streaks.isEmpty)
                const EmptyStateBox(
                  icon: Icons.local_fire_department_outlined,
                  title: 'Nessuna streak attiva',
                  body: 'Completa le task nei loro giorni: qui le costanze crescono.',
                )
              else
                _panel(context, [
                  for (final e in streaks)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(e.task.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: WayFonts.ui(size: 13, color: c.ink)),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: e.streak / maxStreak,
                                minHeight: 7,
                                backgroundColor: c.surface3,
                                valueColor: AlwaysStoppedAnimation(c.accent),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${e.streak}', style: WayFonts.mono(size: 11, color: c.inkSoft)),
                        ],
                      ),
                    ),
                ]),
              const SizedBox(height: 22),

              // forti / da curare
              const SectionLabel('Salute delle abitudini'),
              const SizedBox(height: 8),
              _panel(context, [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _rankCol(context, 'IN SALUTE', strong.take(4).toList())),
                    const SizedBox(width: 16),
                    Expanded(child: _rankCol(context, 'DA CURARE', weak.take(4).toList())),
                  ],
                ),
              ]),
              const SizedBox(height: 22),

              // analisi number
              const SectionLabel('Analisi number'),
              const SizedBox(height: 8),
              if (numberTasks.isEmpty)
                const EmptyStateBox(
                  icon: Icons.query_stats_outlined,
                  title: 'Nessuna task a quantità',
                  body: 'Le task di tipo "misura" appariranno qui, tracciabili nel tempo.',
                )
              else ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in numberTasks)
                      _chip(context, t.name, identical(t, sel),
                          () => setState(() => _numberTaskId = t.id)),
                  ],
                ),
                const SizedBox(height: 10),
                if (sel != null) _numberPanel(context, data, sel),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _numberPanel(BuildContext context, AppData data, Task task) {
    final c = context.c;
    final today = Dates.today();
    final (values, labels) = _numberSeries(data, task, data.range, today);
    final present = values.whereType<double>().toList();
    final avg = present.isEmpty ? 0.0 : present.reduce((a, b) => a + b) / present.length;
    final peak = present.isEmpty ? 0.0 : present.reduce((a, b) => a > b ? a : b);
    return _panel(context, [
      SmoothLineChart(
        values: values,
        labels: labels,
        guide: task.target,
        color: c.media,
        format: (v) => _num(v),
      ),
      const SizedBox(height: 10),
      _footRow(context, 'MEDIA', _num(avg), 'MASSIMO', _num(peak)),
      const SizedBox(height: 4),
      Text('Linea tratteggiata = target (${_num(task.target)}).',
          style: WayFonts.mono(size: 9, color: c.inkFaint)),
    ]);
  }

  // ---------- helpers serie ----------
  (List<double?>, List<String>) _percentSeries(AppData data, TrendRange range, DateTime today) {
    switch (range) {
      case TrendRange.week:
        final days = _daysBack(7, today);
        return (
          [for (final d in days) data.dayPercentSabus(d)?.toDouble()],
          [for (final d in days) Dates.dayShort[Dates.weekdayIndex(d)]],
        );
      case TrendRange.month:
        final days = _daysBack(30, today);
        return (
          [for (final d in days) data.dayPercentSabus(d)?.toDouble()],
          [for (var i = 0; i < days.length; i++) i % 7 == 0 ? '${days[i].day}' : ''],
        );
      case TrendRange.year:
        return _monthly(today, (d) => data.dayPercentSabus(d)?.toDouble());
    }
  }

  (List<double?>, List<String>) _numberSeries(AppData data, Task task, TrendRange range, DateTime today) {
    double? val(DateTime d) => task.activeOn(d) ? data.valueOf(task, d) : null;
    switch (range) {
      case TrendRange.week:
        final days = _daysBack(7, today);
        return ([for (final d in days) val(d)],
            [for (final d in days) Dates.dayShort[Dates.weekdayIndex(d)]]);
      case TrendRange.month:
        final days = _daysBack(30, today);
        return ([for (final d in days) val(d)],
            [for (var i = 0; i < days.length; i++) i % 7 == 0 ? '${days[i].day}' : '']);
      case TrendRange.year:
        return _monthly(today, val);
    }
  }

  /// Aggrega per mese (ultimi 12): media dei valori presenti nel mese.
  (List<double?>, List<String>) _monthly(DateTime today, double? Function(DateTime) f) {
    final values = <double?>[];
    final labels = <String>[];
    for (var m = 11; m >= 0; m--) {
      final anchor = DateTime(today.year, today.month - m, 1);
      var sum = 0.0;
      var count = 0;
      for (var d = 1; d <= 31; d++) {
        final day = DateTime(anchor.year, anchor.month, d);
        if (day.month != anchor.month || day.isAfter(today)) continue;
        final v = f(day);
        if (v != null) { sum += v; count++; }
      }
      values.add(count == 0 ? null : sum / count);
      labels.add(Dates.months[anchor.month - 1].substring(0, 1).toUpperCase());
    }
    return (values, labels);
  }

  // ---------- widget di supporto ----------
  Widget _panel(BuildContext context, List<Widget> children) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.lineSoft),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    final c = context.c;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: WayFonts.label(color: c.inkFaint, size: 9)),
          const SizedBox(height: 3),
          Text(value, style: WayFonts.display(size: 18, color: c.ink)),
        ],
      ),
    );
  }

  Widget _sep(BuildContext context) => Container(
      width: 1, height: 30, margin: const EdgeInsets.symmetric(horizontal: 12),
      color: context.c.accentSoft);

  Widget _footRow(BuildContext context, String l1, String v1, String l2, String v2) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.only(top: 9),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: c.line))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l1, style: WayFonts.label(color: c.inkFaint, size: 9)),
            Text(v1, style: WayFonts.display(size: 16, color: c.ink)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(l2, style: WayFonts.label(color: c.inkFaint, size: 9)),
            Text(v2, style: WayFonts.display(size: 16, color: c.ink)),
          ]),
        ],
      ),
    );
  }

  Widget _rankCol(BuildContext context, String title, List<({Task task, int s})> items) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: WayFonts.label(color: c.inkFaint, size: 9)),
        const SizedBox(height: 6),
        for (final e in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(e.task.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WayFonts.ui(size: 12.5, color: c.ink)),
                ),
                Text('${e.s}', style: WayFonts.mono(size: 11, color: c.inkSoft)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _chip(BuildContext context, String label, bool on, VoidCallback onTap) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: on ? c.accentTint : c.surface2,
          border: Border.all(color: on ? c.accent : c.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: WayFonts.ui(size: 12.5, weight: FontWeight.w600, color: on ? c.accent : c.inkSoft)),
      ),
    );
  }

  String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
