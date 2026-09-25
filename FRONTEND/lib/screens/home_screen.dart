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
    final tasks = data.visibleToday();
    final scheduled = data.tasksFor(today);
    final nowM = DateTime.now().hour * 60 + DateTime.now().minute;
    final outWindow = scheduled
        .where((t) => nowM < t.start * 60 || nowM >= t.end * 60)
        .length;
    final score = data.dayScore(today) ?? 0;
    final done =
        scheduled.where((t) => data.percentOf(t, today) >= 100).length;
    final place = data.activePlace;
    final candidate = data.levelUpCandidate();
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
        if (tasks.isEmpty)
          const EmptyStateBox(
            icon: Icons.checklist_outlined,
            title: 'Giornata libera',
            body:
                'Nessuna task dell\'ambiente attivo cade oggi. È una scelta della configurazione, non un buco.',
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
                child: switch (task.kind) {
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
        if (data.hiddenDay == Dates.key(today))
          Builder(builder: (context) {
            final n = data
                .tasksFor(today)
                .where((t) => data.hidden.contains(t.id))
                .length;
            if (n == 0) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => ref.read(appProvider.notifier).showHiddenToday(),
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility_outlined, size: 14, color: c.inkFaint),
                    const SizedBox(width: 6),
                    Text('Mostra $n nascoste',
                        style: WayFonts.mono(size: 10.5, color: c.inkFaint)),
                  ],
                ),
              ),
            );
          }),
        if (outWindow > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule, size: 13, color: c.inkFaint),
                const SizedBox(width: 6),
                Text('$outWindow fuori dalla fascia oraria',
                    style: WayFonts.mono(size: 10.5, color: c.inkFaint)),
              ],
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

class _LevelUpCard extends ConsumerWidget {
  const _LevelUpCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: c.accentTint,
        border: Border.all(color: c.accentSoft),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 20, color: c.accent),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: WayFonts.ui(size: 12.5, color: c.ink),
                children: [
                  TextSpan(
                    text: task.name,
                    style: WayFonts.ui(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  TextSpan(text: ' è costante da ${task.streak} esecuzioni.\n'),
                  const TextSpan(text: 'Passare a '),
                  TextSpan(
                    text: 'LV${task.level + 1}',
                    style: WayFonts.ui(
                      size: 12.5,
                      weight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  final from = task.level;
                  ref.read(appProvider.notifier).acceptLevelUp(task);
                  final updated = ref
                      .read(appProvider)
                      .taskById(task.id);
                  if (updated == null) return;
                  final island = Offset(
                    MediaQuery.of(context).size.width / 2,
                    MediaQuery.of(context).padding.top + 40,
                  );
                  Reward.levelUp(ref.read(fxProvider), updated, from, island);
                },
                child: Text(
                  'Accetta',
                  style: WayFonts.ui(
                    size: 12.5,
                    weight: FontWeight.w800,
                    color: c.accent,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              GestureDetector(
                onTap: () => ref.read(appProvider.notifier).dismissLevelUp(task),
                child: Text(
                  'Non ora',
                  style: WayFonts.ui(size: 12.5, color: c.inkFaint),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Riga di esecuzione: spunta per le task complete, contatore per quelle
/// a misura, con la tacca della soglia sulla barra.
class _EvolveBadge extends ConsumerWidget {
  const _EvolveBadge({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final data = ref.watch(appProvider);
    late final String label;
    late final IconData icon;
    late final Color col;
    late final VoidCallback onTap;
    if (data.abstinenceConcluded(task)) {
      label = 'Conclusa · archivia';
      icon = Icons.emoji_events_outlined;
      col = c.easy;
      onTap = () => ref.read(appProvider.notifier).archiveTask(task);
    } else if (data.reconfigReady(task)) {
      label = 'Rivedi';
      icon = Icons.build_outlined;
      col = c.hard;
      onTap = () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TaskEvolutionScreen(taskId: task.id, mode: 'reconfig')));
    } else {
      label = 'Level up';
      icon = Icons.trending_up;
      col = c.accent;
      onTap = () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TaskEvolutionScreen(taskId: task.id, mode: 'upgrade')));
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: col.withValues(alpha: 0.12),
          border: Border.all(color: col.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: col),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: WayFonts.ui(size: 12.5, weight: FontWeight.w700, color: col)),
          ),
          Icon(Icons.chevron_right, size: 18, color: col),
        ]),
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
    final colors = difficultyColors(context, task.difficulty);
    final evolve = evolveControl(context, ref, task, data);
    bool broken(int i) => (mask & (1 << i)) != 0;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: compromised ? c.hardTint : c.surface2,
        border: Border.all(color: compromised ? c.hard : c.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(11)),
            child: Icon(taskIcon(task.iconKey), size: 19,
                color: compromised ? c.hard : colors.fg),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(task.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: WayFonts.ui(size: 13.5, weight: FontWeight.w600, color: c.ink)),
              const SizedBox(height: 4),
              Text(
                  compromised
                      ? 'Compromessa oggi'
                      : 'Intatta · LV${task.level} · streak ${data.derivedStreak(task)}',
                  style: WayFonts.mono(size: 10.5, color: compromised ? c.hard : c.easy)),
            ]),
          ),
          evolve ??
              Icon(compromised ? Icons.cancel : Icons.verified,
                  color: compromised ? c.hard : c.easy, size: 22),
        ]),
        if (task.criteria.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (var i = 0; i < task.criteria.length; i++)
              GestureDetector(
                onTap: () => ref.read(appProvider.notifier)
                    .toggleMaintenanceCondition(task, i, day: day),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: broken(i) ? c.hardTint : c.surface,
                    border: Border.all(color: broken(i) ? c.hard : c.line),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(broken(i) ? Icons.close : Icons.check, size: 14,
                        color: broken(i) ? c.hard : c.easy),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(task.criteria[i].text,
                          style: WayFonts.ui(size: 12,
                              color: broken(i) ? c.hard : c.inkSoft,
                              decoration: broken(i) ? TextDecoration.lineThrough : null)),
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
    final colors = difficultyColors(context, task.difficulty);
    final evolve = evolveControl(context, ref, task, data);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: relapsed ? c.hardTint : c.surface2,
        border: Border.all(color: relapsed ? c.hard : c.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(11)),
          child: Icon(taskIcon(task.iconKey), size: 19,
              color: relapsed ? c.hard : colors.fg),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(task.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: WayFonts.ui(size: 13.5, weight: FontWeight.w600, color: c.ink)),
            const SizedBox(height: 4),
            Text(relapsed ? 'Ricaduta oggi' : 'Pulito · ${streak}g di fila',
                style: WayFonts.mono(size: 10.5, color: relapsed ? c.hard : c.easy)),
          ]),
        ),
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
                    style: WayFonts.mono(size: 11, weight: FontWeight.w700,
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
    final colors = difficultyColors(context, task.difficulty);
    final value = data.valueOf(task, day);
    final percent = data.percentOf(task, day);
    final complete = percent >= 100;
    final step = task.target >= 20 ? 5.0 : (task.target >= 8 ? 1.0 : 0.5);
    final evolve = evolveControl(context, ref, task, data);

    return Container(
      key: taskAnchorKey(task.id),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: complete ? c.accentSoft : c.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: c.surface3, shape: BoxShape.circle),
            child: Icon(taskIcon(task.iconKey), size: 19, color: colors.fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        task.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WayFonts.ui(
                          size: 13.5,
                          weight: FontWeight.w800,
                          color: complete ? c.inkSoft : c.ink,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '| LV${task.level}',
                      style: WayFonts.mono(size: 10, color: c.inkFaint),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  task.kind == TaskKind.measure
                      ? '${fmtNum(value)} / ${fmtNum(task.target)} · $percent%'
                      : (complete ? 'Fatto' : 'Da fare'),
                  style: WayFonts.mono(size: 10.5, color: c.inkFaint),
                ),
                const SizedBox(height: 2),
                Text('${typeLabel(task)} · streak ${data.derivedStreak(task)}',
                    style: WayFonts.mono(size: 9, color: c.inkFaint)),
                if (task.kind == TaskKind.measure) ...[
                  const SizedBox(height: 7),
                  MeasureBar(
                    percent: percent,
                    color: colors.fg,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (evolve != null)
            evolve
          else if (task.kind == TaskKind.complete)
            CheckButton(
              on: value > 0,
              onTap: () => onCommit(value > 0 ? 0 : 1),
            )
          else
            StepperControl(
              value: value,
              onMinus: () => onCommit((value - step).clamp(0, double.infinity)),
              onPlus: () => onCommit(value + step),
            ),
        ],
      ),
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
          values.add(data.dayScore(day));
          labels.add(Dates.dayShort[Dates.weekdayIndex(day)]);
        }
        break;
      case TrendRange.month:
        for (var i = 29; i >= 0; i--) {
          final day = Dates.addDays(today, -i);
          values.add(data.dayScore(day));
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
            final s = data.dayScore(day);
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


String typeLabel(Task t) => switch (t.kind) {
      TaskKind.complete => 'Completa',
      TaskKind.measure => 'Misura',
      TaskKind.maintenance => 'Mantenimento',
      TaskKind.abstinence => 'Astinenza',
    };

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
