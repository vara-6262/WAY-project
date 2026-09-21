import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dates.dart';
import '../data/glyphs.dart';
import '../models/app_data.dart';
import '../models/models.dart';
import '../models/sabus_scoring.dart';
import '../state/providers.dart';
import '../theme/way_theme.dart';
import '../widgets/common.dart';

/// Review di ieri: rivaluti a mente fredda. Il delta dei punti è dimezzato
/// (in positivo e in negativo); lo streak si può salvare ma non si spezza.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final Map<String, double> _proposed = {};

  DateTime get _yesterday => Dates.addDays(Dates.today(), -1);

  double _val(AppData data, Task t) =>
      _proposed[t.id] ?? data.valueOf(t, _yesterday);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final data = ref.watch(appProvider);
    final y = _yesterday;
    final tasks = data.tasksFor(y);

    // stato proposto per il calcolo punti
    final propLog = {
      for (final e in data.log.entries) e.key: Map<String, double>.from(e.value),
    };
    final key = Dates.key(y);
    final propDay = Map<String, double>.from(propLog[key] ?? const {});
    for (final e in _proposed.entries) {
      propDay[e.key] = e.value;
    }
    propLog[key] = propDay;
    final proposedData = data.copyWith(log: propLog);

    var original = 0.0, proposed = 0.0;
    for (final t in tasks) {
      original += data.taskPoints(t, y);
      proposed += proposedData.taskPoints(t, y);
    }
    final sealed = original + (proposed - original) * 0.5;

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('IERI · ${Dates.dayShort[Dates.weekdayIndex(y)]} ${y.day}/${y.month}',
                            style: WayFonts.label(color: c.inkFaint, size: 9.5)),
                        const SizedBox(height: 2),
                        Text('Review a mente fredda',
                            style: WayFonts.display(size: 21, color: c.ink)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Text('Chiudi',
                        style: WayFonts.ui(size: 12, weight: FontWeight.w700, color: c.inkFaint)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                children: [
                  for (final t in tasks) _row(context, data, t),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      border: Border(left: BorderSide(color: c.accentSoft, width: 2)),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                    ),
                    child: Text(
                      'Le correzioni valgono metà: recuperi metà dei punti che aggiungi, '
                      'restituisci metà di quelli che togli. La costanza (streak) non si spezza.',
                      style: WayFonts.ui(size: 11.5, color: c.inkSoft),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.lineSoft)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ieri ${original.toStringAsFixed(1)} → dopo review',
                          style: WayFonts.ui(size: 12.5, color: c.inkSoft)),
                      Text('${sealed.toStringAsFixed(1)} pt',
                          style: WayFonts.display(size: 18, color: c.ink)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GhostButton(
                          label: 'Salta',
                          onPressed: () {
                            ref.read(appProvider.notifier).skipReview();
                            Navigator.of(context).maybePop();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Conferma review',
                          onPressed: () {
                            ref.read(appProvider.notifier).applyReview(_proposed);
                            Navigator.of(context).maybePop();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, AppData data, Task t) {
    final c = context.c;
    final v = _val(data, t);
    Widget control;
    switch (t.kind) {
      case TaskKind.measure:
        final step = t.target >= 20 ? 5.0 : (t.target >= 8 ? 1.0 : 0.5);
        control = Row(mainAxisSize: MainAxisSize.min, children: [
          _key(context, Icons.remove, () => setState(() => _proposed[t.id] = (v - step).clamp(0, 100000))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('${v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1)}/${t.target % 1 == 0 ? t.target.toStringAsFixed(0) : t.target}',
                style: WayFonts.mono(size: 12, color: c.ink)),
          ),
          _key(context, Icons.add, () => setState(() => _proposed[t.id] = v + step)),
        ]);
        break;
      case TaskKind.maintenance:
        final intact = v == 0;
        control = _toggle(context, intact ? 'Intatta' : 'Compromessa', intact,
            () => setState(() => _proposed[t.id] = intact ? 1 : 0));
        break;
      case TaskKind.abstinence:
        final clean = v == 0;
        control = _toggle(context, clean ? 'Pulito' : 'Ricaduta', clean,
            () => setState(() => _proposed[t.id] = clean ? 1 : 0));
        break;
      case TaskKind.complete:
        final done = v > 0;
        control = _toggle(context, done ? 'Fatto' : 'Non fatto', done,
            () => setState(() => _proposed[t.id] = done ? 0 : 1));
        break;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Icon(taskIcon(t.iconKey), size: 18, color: c.inkSoft),
        const SizedBox(width: 10),
        Expanded(
          child: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: WayFonts.ui(size: 13.5, weight: FontWeight.w600, color: c.ink)),
        ),
        control,
      ]),
    );
  }

  Widget _toggle(BuildContext context, String label, bool good, VoidCallback onTap) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: good ? c.easyTint : c.hardTint,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: WayFonts.mono(size: 10.5, weight: FontWeight.w700,
                color: good ? c.easy : c.hard)),
      ),
    );
  }

  Widget _key(BuildContext context, IconData icon, VoidCallback onTap) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30, alignment: Alignment.center,
        decoration: BoxDecoration(color: c.surface3, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 16, color: c.inkSoft),
      ),
    );
  }
}
