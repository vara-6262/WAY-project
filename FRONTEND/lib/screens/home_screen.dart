import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dates.dart';
import '../data/glyphs.dart';
import '../models/sabus_scoring.dart';
import 'review_screen.dart';
import 'task_evolution_screen.dart';
import '../fx/anchors.dart';
import '../fx/fx_controller.dart';
import '../fx/reward.dart';
import '../models/app_data.dart';
import '../models/models.dart';
import '../sheets/sheets.dart';
import '../state/providers.dart';
import '../theme/way_theme.dart';
import '../widgets/common.dart';
import '../widgets/progress_ring.dart';
import '../widgets/trend_chart.dart';

/// Home: dove si esegue. Le task non si creano qui, si registrano.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onOpenPlaces});

  final VoidCallback onOpenPlaces;

  /// Un solo punto di scrittura per l'esecuzione: calcola il prima e il
  /// dopo, aggiorna, e decide quanto festeggiare.
  void _commit(WidgetRef ref, Task task, double value) {
    final data = ref.read(appProvider);
    final fx = ref.read(fxProvider);
    final today = Dates.today();

    final beforeTask = data.percentOf(task, today);
    final beforeValue = data.valueOf(task, today);
    final beforeDay = data.dayScore(today) ?? 0;

    ref.read(appProvider.notifier).setValue(task, value, day: today);

    final after = ref.read(appProvider);
    final afterTask = after.percentOf(task, today);
    final afterDay = after.dayScore(today) ?? 0;

    final taskWon = beforeTask < 100 && afterTask >= 100;
    final dayWon = beforeDay < 100 && afterDay >= 100;
    if (taskWon && !dayWon) {
      Reward.taskDone(fx, task, anchorOf(taskAnchorKey(task.id)));
    }

    if (dayWon) {
      final list = after.tasksFor(today);
      final place = after.activePlace;
      Reward.dayDone(
        fx,
        origin: anchorOf(ringKey),
        percent: afterDay,
        done: list.where((t) => after.percentOf(t, today) >= 100).length,
        total: list.length,
        streak: after.dayStreak(),
        placeName: place?.name ?? 'Core Session',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final data = ref.watch(appProvider);
    final today = Dates.today();
    final filter = ref.watch(homeFilterProvider);
    final tasks = data.tasksForFilter(filter);
    final scheduled = data.tasksFor(today);
    final hiddenCount = data.hiddenDay == Dates.key(today)
        ? scheduled.where((t) => data.hidden.contains(t.id)).length
        : 0;
    final score = data.dayPercentSabus(today) ?? 0; // allineato al Sabus (come i grafici e il Trend)
    final done =
        scheduled.where((t) => data.percentOf(t, today) >= 100).length;
    final place = data.activePlace;
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Buongiorno' : (hour < 18 ? 'Buon pomeriggio' : 'Buonasera');

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: WayFonts.display(size: 24, color: c.ink),
                  ),
                  Text(
                    'Manuel',
                    style: WayFonts.display(size: 24, color: c.accent),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Da cosa iniziamo oggi?',
                    style: WayFonts.ui(size: 12.5, color: c.inkFaint),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => showProfileSheet(context, ref),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surface2,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.line),
                ),
                child: Text(
                  'M',
                  style: WayFonts.display(size: 15, color: c.ink),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _TodayCard(
          score: score,
          done: done,
          total: scheduled.length,
          place: place,
          onOpenPlaces: onOpenPlaces,
        ),
        const SizedBox(height: 12),
        const _ScoreBar(),
        const SizedBox(height: 22),
        if (data.reviewAvailable) ...[
          _ReviewBanner(
            onOpen: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReviewScreen()),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const SectionLabel('Esecuzione di oggi'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Segmented<HomeFilter>(
                values: HomeFilter.values,
                labels: const ['Disponibili', 'Mancanti', 'Tutte'],
                selected: filter,
                onChanged: (f) =>
                    ref.read(homeFilterProvider.notifier).state = f,
              ),
            ),
            if (hiddenCount > 0) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () =>
                    ref.read(appProvider.notifier).showHiddenToday(),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.visibility_outlined, size: 15, color: c.inkFaint),
                  const SizedBox(width: 4),
                  Text('$hiddenCount',
                      style: WayFonts.mono(size: 11, color: c.inkFaint)),
                ]),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (tasks.isEmpty)
          EmptyStateBox(
            icon: Icons.checklist_outlined,
            title: scheduled.isEmpty
                ? 'Giornata libera'
                : 'Niente in questa vista',
            body: scheduled.isEmpty
                ? 'Oggi non è previsto nulla in questo ambiente.'
                : 'Cambia filtro in alto per vedere le altre task di oggi.',
          )
        else
          for (final task in tasks)
            Dismissible(
              key: ValueKey('hide-${task.id}'),
              direction: DismissDirection.horizontal,
              onDismissed: (_) =>
                  ref.read(appProvider.notifier).hideTaskToday(task.id),
              background: _hideBackground(context, Alignment.centerLeft),
              secondaryBackground:
                  _hideBackground(context, Alignment.centerRight),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _lockedWrap(
                  !data.inWindowNow(task),
                  switch (task.kind) {
                    TaskKind.maintenance =>
                      _MaintenanceRow(task: task, day: today),
                    TaskKind.abstinence =>
                      _AbstinenceRow(task: task, day: today),
                    _ => _ExecutionRow(
                        key: ValueKey(task.id),
                        task: task,
                        day: today,
                        onCommit: (v) => _commit(ref, task, v),
                      ),
                  },
                ),
              ),
            ),
        const SizedBox(height: 22),
        const SectionLabel('Andamento'),
        _TrendSection(data: data),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.score,
    required this.done,
    required this.total,
    required this.place,
    required this.onOpenPlaces,
  });

  final int score;
  final int done;
  final int total;
  final Place? place;
  final VoidCallback onOpenPlaces;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final today = Dates.today();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.lineSoft),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          ProgressRing(key: ringKey, percent: score),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${Dates.dayLong[Dates.weekdayIndex(today)].capitalize()}, '
                  '${today.day} ${Dates.months[today.month - 1].capitalize()}',
                  style: WayFonts.ui(size: 11.5, color: c.inkFaint),
                ),
                const SizedBox(height: 3),
                Text(
                  '$done su $total completate',
                  style: WayFonts.display(size: 16, color: c.ink),
                ),
                const SizedBox(height: 9),
                GestureDetector(
                  onTap: onOpenPlaces,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 14, 9),
                    decoration: BoxDecoration(
                      color: c.surface3,
                      border: Border.all(color: c.line),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          place == null
                              ? Icons.hub_outlined
                              : placeGlyph(place!.glyphKey),
                          size: 14,
                          color: c.accent,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            place?.name ?? 'Core Session',
                            overflow: TextOverflow.ellipsis,
                            style: WayFonts.ui(
                              size: 12,
                              weight: FontWeight.w700,
                              color: c.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.accentTint,
          border: Border.all(color: c.accentSoft),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          Icon(Icons.history_toggle_off, color: c.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ieri — rivedi',
                  style: WayFonts.ui(size: 14, weight: FontWeight.w700, color: c.ink)),
              Text('Rivaluta a mente fredda · entro stasera',
                  style: WayFonts.mono(size: 10.5, color: c.inkSoft)),
            ]),
          ),
          Icon(Icons.chevron_right, color: c.inkFaint),
        ]),
      ),
    );
  }
}

class _MaintenanceRow extends ConsumerWidget {
  const _MaintenanceRow({required this.task, required this.day});
  final Task task;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final data = ref.watch(appProvider);
    final mask = data.valueOf(task, day).toInt();
    final compromised = mask != 0;
    final evolve = evolveControl(context, ref, task, data);
    bool broken(int i) => (mask & (1 << i)) != 0;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: compromised ? c.hardTint : c.surface2,
        border: Border.all(color: compromised ? c.hard : c.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          _cardIcon(context, task, fg: compromised ? c.hard : null),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _nameRow(context, task),
                  const SizedBox(height: 7),
                  _progressLine(context, data, task),
                ]),
          ),
          const SizedBox(width: 10),
          evolve ??
              Icon(compromised ? Icons.cancel : Icons.verified,
                  color: compromised ? c.hard : c.easy, size: 22),
        ]),
        if (task.criteria.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (var i = 0; i < task.criteria.length; i++)
              GestureDetector(
                onTap: () => ref
                    .read(appProvider.notifier)
                    .toggleMaintenanceCondition(task, i, day: day),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: broken(i) ? c.hardTint : c.surface,
                    border: Border.all(color: broken(i) ? c.hard : c.line),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(broken(i) ? Icons.close : Icons.check,
                        size: 14, color: broken(i) ? c.hard : c.easy),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(task.criteria[i].text,
                          style: WayFonts.ui(
                              size: 12,
                              color: broken(i) ? c.hard : c.inkSoft,
                              decoration: broken(i)
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none)),
                    ),
                  ]),
                ),
              ),
          ]),
        ],
      ]),
    );
  }
}

class _AbstinenceRow extends ConsumerWidget {
  const _AbstinenceRow({required this.task, required this.day});
  final Task task;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final data = ref.watch(appProvider);
    final relapsed = data.valueOf(task, day) != 0;
    final streak = data.derivedStreak(task);
    final evolve = evolveControl(context, ref, task, data);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: relapsed ? c.hardTint : c.surface2,
        border: Border.all(color: relapsed ? c.hard : c.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        _cardIcon(context, task, fg: relapsed ? c.hard : null),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _nameRow(context, task),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.local_fire_department,
                      size: 12, color: relapsed ? c.inkFaint : c.easy),
                  const SizedBox(width: 3),
                  Text(
                      relapsed ? 'Ricaduta oggi' : 'Pulito · ${streak}g di fila',
                      style: WayFonts.mono(
                          size: 10.5, color: relapsed ? c.hard : c.easy)),
                ]),
              ]),
        ),
        const SizedBox(width: 10),
        evolve ??
            GestureDetector(
              onTap: () =>
                  ref.read(appProvider.notifier).toggleAbstinence(task, day: day),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: relapsed ? c.surface : c.hardTint,
                  border: Border.all(color: relapsed ? c.line : c.hard),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(relapsed ? 'Annulla' : 'Ricaduta',
                    style: WayFonts.mono(
                        size: 11,
                        weight: FontWeight.w700,
                        color: relapsed ? c.inkSoft : c.hard)),
              ),
            ),
      ]),
    );
  }
}

class _ExecutionRow extends ConsumerWidget {
  const _ExecutionRow({
    super.key,
    required this.task,
    required this.day,
    required this.onCommit,
  });

  final Task task;
  final DateTime day;
  final ValueChanged<double> onCommit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final data = ref.watch(appProvider);
    final value = data.valueOf(task, day);
    final percent = data.percentOf(task, day);
    final complete = percent >= 100;
    final step = task.target >= 20 ? 5.0 : (task.target >= 8 ? 1.0 : 0.5);
    final evolve = evolveControl(context, ref, task, data);
    final measure = task.kind == TaskKind.measure;
    final gain = measure
        ? data.pointsAtValue(task, value + step) -
            data.pointsAtValue(task, value)
        : 0.0;

    return Container(
      key: taskAnchorKey(task.id),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: complete ? c.accentSoft : c.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        _cardIcon(context, task),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _nameRow(context, task,
                    trailing: measure
                        ? '${fmtNum(value)}/${fmtNum(task.target)}'
                        : null,
                    dim: complete),
                const SizedBox(height: 7),
                _progressLine(context, data, task),
              ]),
        ),
        const SizedBox(width: 10),
        if (evolve != null)
          evolve
        else if (!measure)
          CheckButton(on: value > 0, onTap: () => onCommit(value > 0 ? 0 : 1))
        else
          Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                StepperControl(
                  value: value,
                  onMinus: () =>
                      onCommit((value - step).clamp(0, double.infinity)),
                  onPlus: () => onCommit(value + step),
                ),
                if (gain > 0) ...[
                  const SizedBox(height: 3),
                  Text('+${gain.toStringAsFixed(1)}',
                      style: WayFonts.mono(size: 9, color: c.accent)),
                ],
              ]),
      ]),
    );
  }
}


class _TrendSection extends ConsumerWidget {
  const _TrendSection({required this.data});

  final AppData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final today = Dates.today();
    final values = <int?>[];
    final labels = <String>[];

    switch (data.range) {
      case TrendRange.week:
        for (var i = 6; i >= 0; i--) {
          final day = Dates.addDays(today, -i);
          values.add(data.dayPercentSabus(day));
          labels.add(Dates.dayShort[Dates.weekdayIndex(day)]);
        }
        break;
      case TrendRange.month:
        for (var i = 29; i >= 0; i--) {
          final day = Dates.addDays(today, -i);
          values.add(data.dayPercentSabus(day));
          labels.add(i % 7 == 0 ? '${day.day}' : '');
        }
        break;
      case TrendRange.year:
        for (var m = 11; m >= 0; m--) {
          final ref0 = DateTime(today.year, today.month - m, 1);
          var sum = 0;
          var count = 0;
          for (var d = 1; d <= 28; d++) {
            final day = DateTime(ref0.year, ref0.month, d);
            if (day.isAfter(today)) break;
            final s = data.dayPercentSabus(day);
            if (s != null) {
              sum += s;
              count++;
            }
          }
          values.add(count == 0 ? null : (sum / count).round());
          labels.add(Dates.months[ref0.month - 1][0].toUpperCase());
        }
        break;
    }

    final valid = values.whereType<int>().toList();
    final average = valid.isEmpty
        ? 0
        : (valid.reduce((a, b) => a + b) / valid.length).round();
    final overHundred = valid.where((v) => v >= 100).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Segmented<TrendRange>(
          values: TrendRange.values,
          labels: TrendRange.values.map((r) => r.label).toList(),
          selected: data.range,
          onChanged: (r) => ref.read(appProvider.notifier).setRange(r),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
          decoration: BoxDecoration(
            color: c.surface2,
            border: Border.all(color: c.lineSoft),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TrendChart(values: values, labels: labels),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(top: 11),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.line)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MEDIA PERIODO',
                            style: WayFonts.label(color: c.inkFaint, size: 9)),
                        Text('$average%',
                            style: WayFonts.display(size: 17, color: c.accent)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('GIORNI ≥ 100%',
                            style: WayFonts.label(color: c.inkFaint, size: 9)),
                        Text('$overHundred/${valid.length}',
                            style: WayFonts.display(size: 17, color: c.accent)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


/// Pulsante d'azione (Level up / Rivedi / Archivia) da mostrare nella card al
/// posto dei controlli, quando la task e' in stato di evoluzione. null altrimenti.
Widget? evolveControl(
    BuildContext context, WidgetRef ref, Task task, AppData data) {
  final c = context.c;
  if (data.abstinenceConcluded(task)) {
    return _EvolvePill(
      label: 'Archivia',
      icon: Icons.emoji_events_outlined,
      color: c.easy,
      onTap: () => ref.read(appProvider.notifier).archiveTask(task),
    );
  }
  if (data.reconfigReady(task)) {
    return _EvolvePill(
      label: 'Rivedi',
      icon: Icons.build_outlined,
      color: c.hard,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              TaskEvolutionScreen(taskId: task.id, mode: 'reconfig'))),
    );
  }
  if (data.upgradeReady(task)) {
    return _EvolvePill(
      label: 'Level up',
      icon: Icons.trending_up,
      color: c.accent,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              TaskEvolutionScreen(taskId: task.id, mode: 'upgrade'))),
    );
  }
  return null;
}

class _EvolvePill extends StatelessWidget {
  const _EvolvePill({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          border: Border.all(color: color.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: WayFonts.mono(size: 11, weight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}

/// Sfondo mostrato durante lo swipe di una card per nasconderla.
Widget _hideBackground(BuildContext context, Alignment align) {
  final c = context.c;
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 22),
    alignment: align,
    decoration: BoxDecoration(
      color: c.surface3,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.visibility_off_outlined, size: 18, color: c.inkFaint),
        const SizedBox(width: 6),
        Text('Nascondi',
            style: WayFonts.mono(
                size: 11, weight: FontWeight.w700, color: c.inkFaint)),
      ],
    ),
  );
}


/// Task fuori dalla finestra oraria: mostrata ma "bloccata" (attenuata e non toccabile).
Widget _lockedWrap(bool locked, Widget child) => locked
    ? Opacity(opacity: 0.45, child: IgnorePointer(child: child))
    : child;


/// Barra di composizione del punteggio di oggi: fatto / mantenimento / bonus.
/// Tap per espandere le tre liste dettagliate.
class _ScoreBar extends ConsumerWidget {
  const _ScoreBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final data = ref.watch(appProvider);
    final today = Dates.today();
    final b = data.dayBreakdown(today);
    final core = b.active + b.eco; // punti reali (fatto + mantenimento)
    final total = core + b.bonus;
    if (total <= 0) return const SizedBox.shrink();

    final segs = <(String, double, Color)>[
      ('Fatto', b.active, c.accent),
      ('Mantenimento', b.eco, c.media),
    ].where((s) => s.$2 > 0).toList();
    final bonusPct = (data.dayBonusFraction(today) * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.lineSoft),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text('COMPOSIZIONE PUNTEGGIO',
              style: WayFonts.label(color: c.inkFaint, size: 9)),
          const Spacer(),
          if (bonusPct > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: c.easyTint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.bolt, size: 11, color: c.easy),
                const SizedBox(width: 1),
                Text('+$bonusPct%',
                    style: WayFonts.mono(
                        size: 9.5, weight: FontWeight.w700, color: c.easy)),
              ]),
            ),
            const SizedBox(width: 8),
          ],
          Text('${total.toStringAsFixed(1)} pt',
              style: WayFonts.mono(size: 11, color: c.inkSoft)),
        ]),
        if (segs.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 8,
            child: LayoutBuilder(builder: (ctx, cons) {
              final w = cons.maxWidth;
              final activeW = core > 0 ? w * (b.active / core) : 0.0;
              final ecoW = core > 0 ? w * (b.eco / core) : 0.0;
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(children: [
                  Positioned.fill(child: ColoredBox(color: c.surface3)),
                  if (activeW > 0)
                    Positioned(
                      left: 0, top: 0, bottom: 0,
                      width: activeW,
                      child: ColoredBox(color: c.accent),
                    ),
                  if (ecoW > 0)
                    Positioned(
                      left: activeW, top: 0, bottom: 0,
                      width: ecoW,
                      child: ColoredBox(color: c.media),
                    ),
                ]),
              );
            }),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 4, children: [
            for (final s in segs)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: s.$3, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('${s.$1} ${s.$2.toStringAsFixed(1)}',
                    style: WayFonts.mono(size: 9.5, color: c.inkFaint)),
              ]),
          ]),
        ],
      ]),
    );
  }
}




/// Icona quadrata arrotondata, stile unico per tutte le card.
Widget _cardIcon(BuildContext context, Task task, {Color? fg}) {
  final colors = difficultyColors(context, task.difficulty);
  return Container(
    width: 38,
    height: 38,
    alignment: Alignment.center,
    decoration:
        BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(12)),
    child: Icon(taskIcon(task.iconKey), size: 19, color: fg ?? colors.fg),
  );
}

/// Riga identita': nome prominente + livello (+ eventuale valore/target).
Widget _nameRow(BuildContext context, Task task, {String? trailing, bool dim = false}) {
  final c = context.c;
  return Row(children: [
    Flexible(
      child: Text(task.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: WayFonts.ui(
              size: 14,
              weight: FontWeight.w800,
              color: dim ? c.inkSoft : c.ink,
              height: 1.2)),
    ),
    const SizedBox(width: 7),
    Text('LV${task.level}', style: WayFonts.mono(size: 10, color: c.inkFaint)),
    if (trailing != null) ...[
      const SizedBox(width: 7),
      Text(trailing, style: WayFonts.mono(size: 10, color: c.inkFaint)),
    ],
  ]);
}

/// Riga progressione: streak + barra-regalo verso l'upgrade + quanto manca + regalo.
Widget _progressLine(BuildContext context, AppData data, Task task) {
  final c = context.c;
  final streak = data.derivedStreak(task);
  final upgradeable = task.kind != TaskKind.abstinence && !task.archived;
  final base = data.upgradeBase(task);
  final eff = data.upgradeThreshold(task);
  final rem = data.upgradeRemaining(task);
  final gift = base - eff;
  return Row(children: [
    Icon(Icons.local_fire_department,
        size: 12, color: streak > 0 ? c.accent : c.inkFaint),
    const SizedBox(width: 3),
    Text('$streak', style: WayFonts.mono(size: 10.5, color: c.inkSoft)),
    const SizedBox(width: 9),
    if (upgradeable && !data.upgradeReady(task)) ...[
      Expanded(
        child: _GiftBar(
            succ: task.succ,
            effective: eff,
            base: base,
            color: c.accent,
            gift: c.easy),
      ),
      const SizedBox(width: 8),
      Text('↑$rem',
          style:
              WayFonts.mono(size: 10, weight: FontWeight.w700, color: c.accent)),
      if (gift > 0) ...[
        const SizedBox(width: 5),
        Text('+$gift', style: WayFonts.mono(size: 10, color: c.easy)),
      ],
    ] else
      const Spacer(),
  ]);
}

/// Barra a lunghezza fissa (0 -> soglia base): track sempre visibile,
/// progresso reale da sinistra, giorni regalati da destra.
class _GiftBar extends StatelessWidget {
  const _GiftBar({
    required this.succ,
    required this.effective,
    required this.base,
    required this.color,
    required this.gift,
  });
  final int succ, effective, base;
  final Color color, gift;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final b = base <= 0 ? 1 : base;
    final realF = (succ / b).clamp(0.0, 1.0);
    final giftF = ((base - effective) / b).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        child: LayoutBuilder(builder: (ctx, cons) {
          final w = cons.maxWidth;
          return Stack(children: [
            Positioned.fill(
                child: ColoredBox(color: c.inkFaint.withValues(alpha: 0.18))),
            if (giftF > 0)
              Positioned(
                right: 0, top: 0, bottom: 0,
                width: w * giftF,
                child: ColoredBox(color: gift.withValues(alpha: 0.6)),
              ),
            if (realF > 0)
              Positioned(
                left: 0, top: 0, bottom: 0,
                width: w * realF,
                child: ColoredBox(color: color),
              ),
          ]);
        }),
      ),
    );
  }
}
