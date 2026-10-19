
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:way/screens/wizard_scaffold.dart';

import '../data/dates.dart';
import '../l10n/strings.dart';
import '../models/sabus_scoring.dart';
import '../data/glyphs.dart';
import '../models/app_data.dart';
import '../models/models.dart';
import '../screens/place_wizard.dart';
import '../state/providers.dart';
import '../theme/way_colors.dart';
import '../theme/way_theme.dart';
import '../widgets/common.dart';

/// Guscio comune dei fogli: maniglia, angoli e padding sempre identici,
/// piu' lo spazio per la tastiera quando dentro c'e' un campo di testo.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final c = context.c;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(top: BorderSide(color: c.line)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  decoration: BoxDecoration(
                    color: c.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                    child: builder(ctx),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key, this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: WayFonts.display(size: 18, color: c.ink)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: WayFonts.ui(size: 12.5, color: c.inkSoft)),
        ],
      ],
    );
  }
}

class SheetAction extends StatelessWidget {
  const SheetAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = danger ? c.hard : c.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: c.surface2,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(icon, size: 19, color: danger ? c.hard : c.inkFaint),
                const SizedBox(width: 11),
                Text(
                  label,
                  style: WayFonts.ui(size: 13.5, weight: FontWeight.w600, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Riga selezionabile usata per scegliere task dentro nucleo e ambienti.
class PickRow extends StatelessWidget {
  const PickRow({
    super.key,
    required this.task,
    required this.selected,
    this.locked = false,
    this.lockedLabel = 'implicita',
    this.onTap,
  });

  final Task task;
  final bool selected;
  final bool locked;
  final String lockedLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final colors = difficultyColors(context, task.difficulty);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Opacity(
        opacity: locked ? 0.66 : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: selected ? c.accentTint : c.surface2,
              border: Border.all(color: selected ? c.accent : c.line),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(taskIcon(task.iconKey), size: 17, color: colors.fg),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    task.name,
                    style: WayFonts.ui(size: 13.5, weight: FontWeight.w600, color: c.ink),
                  ),
                ),
                if (locked)
                  Pill(lockedLabel, bg: c.surface, fg: c.inkFaint)
                else
                  Container(
                    width: 21,
                    height: 21,
                    decoration: BoxDecoration(
                      color: selected ? c.accent : Colors.transparent,
                      border: Border.all(color: selected ? c.accent : c.line, width: 1.5),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: selected
                        ? Icon(Icons.check, size: 14, color: c.accentInk)
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Fogli delle task -------------------------------------------------------

/// Menu contestuale della pressione prolungata.
Future<void> showTaskContextSheet(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final data = ref.read(appProvider);
  final inCore = data.isCore(task.id);
  final colors = difficultyColors(context, task.difficulty);
  final c = context.c;

  await showAppSheet<void>(
    context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(taskIcon(task.iconKey), size: 20, color: colors.fg),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.name, style: WayFonts.display(size: 18, color: c.ink)),
                  Text(
                    'LV${task.level} Â· ${inCore ? context.s.inCore : context.s.outOfCore}',
                    style: WayFonts.ui(size: 12.5, color: c.inkSoft),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SheetAction(
          icon: Icons.visibility_outlined,
          label: context.s.openDetails,
          onTap: () {
            Navigator.of(ctx).pop();
            showTaskDetailSheet(context, ref, task);
          },
        ),
        SheetAction(
          icon: inCore ? Icons.remove_circle_outline : Icons.auto_awesome,
          label: inCore
              ? context.s.removeFromCore
              : context.s.addToCore,
          onTap: () {
            ref.read(appProvider.notifier).toggleCore(task.id);
            Navigator.of(ctx).pop();
            showToast(
              context,
              inCore
                  ? '${task.name} fuori dal nucleo'
                  : '${task.name} e\' nel nucleo',
            );
          },
        ),
        if (task.editable)
          SheetAction(
            icon: Icons.edit_outlined,
            label: context.s.editTask,
            onTap: () {
              Navigator.of(ctx).pop();
              showEditTaskSheet(context, ref, task);
            },
          ),
        SheetAction(
          icon: Icons.delete_outline,
          label: context.s.deleteTask,
          danger: true,
          onTap: () {
            Navigator.of(ctx).pop();
            showDeleteTaskSheet(context, ref, task);
          },
        ),
      ],
    ),
  );
}

Future<void> showDeleteTaskSheet(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final data = ref.read(appProvider);
  final usedByPlaces = data.places.where((p) => p.taskIds.contains(task.id)).length;
  final alsoCore = data.isCore(task.id);

  await showAppSheet<void>(
    context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(
          context.s.deleteConfirm(task.name),
          subtitle: usedByPlaces > 0 || alsoCore
              ? context.s.deleteBodyCore
              : context.s.deleteBodyPlain,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GhostButton(
                label: context.s.cancel,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PrimaryButton(
                label: context.s.delete,
                color: context.c.hard,
                foreground: Colors.white,
                onPressed: () {
                  ref.read(appProvider.notifier).deleteTask(task.id);
                  Navigator.of(ctx).pop();
                  showToast(context, context.s.taskDeleted);
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<void> showTaskDetailSheet(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final c = context.c;
  final data = ref.read(appProvider);
  final colors = difficultyColors(context, task.difficulty);
  final places = data.places
      .where((p) => p.taskIds.contains(task.id) || (p.useCore && data.isCore(task.id)))
      .map((p) => p.name)
      .toList();

  await showAppSheet<void>(
    context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(taskIcon(task.iconKey), size: 23, color: colors.fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.name, style: WayFonts.display(size: 18, color: c.ink)),
                  Text(
                    'LV${task.level} Â· ${task.kind == TaskKind.measure ? '${context.s.kindMeasure} Â· ${task.reward == RewardCurve.exponential ? context.s.rewardExp : context.s.rewardLinear}' : task.kind == TaskKind.maintenance ? context.s.kindMaintain : task.kind == TaskKind.abstinence ? context.s.kindAbstinence : context.s.kindComplete}',
                    style: WayFonts.ui(size: 12.5, color: c.inkSoft),
                  ),
                ],
              ),
            ),
            DifficultyPill(task.difficulty),
          ],
        ),
        const SizedBox(height: 16),
        Text('GIORNI', style: WayFonts.label(color: c.inkFaint, size: 9.5)),
        const SizedBox(height: 7),
        Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: task.days.contains(i) ? c.accent : c.surface2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    Dates.dayShort[i],
                    style: WayFonts.mono(
                      size: 11,
                      weight: FontWeight.w600,
                      color: task.days.contains(i) ? c.accentInk : c.inkFaint,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Text('ORARIO', style: WayFonts.label(color: c.inkFaint, size: 9.5)),
        const SizedBox(height: 6),
        Text(
          '${task.start.toString().padLeft(2, '0')}:00 â ${task.end.toString().padLeft(2, '0')}:00 Â· ${task.period.label}',
          style: WayFonts.ui(size: 12.5, color: c.inkSoft),
        ),
        if (task.kind == TaskKind.measure) ...[
          const SizedBox(height: 16),
          Text('TARGET', style: WayFonts.label(color: c.inkFaint, size: 9.5)),
          const SizedBox(height: 6),
          Text(
            context.s.objective(_num(task.target)),
            style: WayFonts.ui(size: 12.5, color: c.inkSoft),
          ),
          if (task.reward == RewardCurve.exponential) ...[
            const SizedBox(height: 16),
            Text(context.s.growthCurve,
                style: WayFonts.label(color: c.inkFaint, size: 9.5)),
            const SizedBox(height: 10),
            _GrowthCurveChart(task: task),
          ],
        ],
        const SizedBox(height: 16),
        Text(
          'CRITERI DI VALIDAZIONE (${task.criteria.length})',
          style: WayFonts.label(color: c.inkFaint, size: 9.5),
        ),
        const SizedBox(height: 6),
        if (task.criteria.isEmpty)
          Text(context.s.noCriterion, style: WayFonts.ui(size: 12.5, color: c.inkFaint))
        else
          for (var i = 0; i < task.criteria.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${i + 1}',
                      style: WayFonts.mono(
                        size: 11,
                        weight: FontWeight.w600,
                        color: colors.fg,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      task.criteria[i].text,
                      style: WayFonts.ui(size: 13, color: c.ink),
                    ),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 16),
        Text('PRESENTE IN', style: WayFonts.label(color: c.inkFaint, size: 9.5)),
        const SizedBox(height: 6),
        Text(
          places.isEmpty ? context.s.noEnvironments : places.join(' Â· '),
          style: WayFonts.ui(size: 12.5, color: c.inkSoft),
        ),
        const SizedBox(height: 18),
        if (task.editable) ...[
          GhostButton(
            label: context.s.editTask,
            onPressed: () {
              Navigator.of(ctx).pop();
              showEditTaskSheet(context, ref, task);
            },
          ),
          const SizedBox(height: 8),
        ],
        if (task.archived) ...[
          GhostButton(
            label: context.s.reactivateTask,
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(appProvider.notifier).unarchiveTask(task);
              showToast(context, context.s.taskReactivated);
            },
          ),
          const SizedBox(height: 8),
        ],
        GhostButton(
          label: context.s.deleteTask,
          foreground: c.hard,
          onPressed: () {
            Navigator.of(ctx).pop();
            showDeleteTaskSheet(context, ref, task);
          },
        ),
      ],
    ),
  );
}

Future<void> showCorePickerSheet(BuildContext context, WidgetRef ref) async {
  await showAppSheet<void>(
    context,
    builder: (ctx) {
      return Consumer(
        builder: (ctx2, ref2, _) {
          final data = ref2.watch(appProvider);
          final available =
              data.tasks.where((t) => !data.isCore(t.id)).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetTitle(
                context.s.addToCore,
                subtitle:
                    context.s.coreNote,
              ),
              const SizedBox(height: 14),
              if (available.isEmpty)
                Text(
                  context.s.allInCore,
                  style: WayFonts.ui(size: 12.5, color: ctx2.c.inkFaint),
                )
              else
                for (final t in available)
                  PickRow(
                    task: t,
                    selected: false,
                    onTap: () {
                      ref2.read(appProvider.notifier).addToCore(t.id);
                      Navigator.of(ctx2).pop();
                      showToast(context, '${t.name} e\' nel nucleo');
                    },
                  ),
            ],
          );
        },
      );
    },
  );
}

/// Editor del singolo criterio. Torna il testo, o null se si annulla.
Future<String?> showCriterionSheet(
  BuildContext context, {
  String? initial,
  VoidCallback? onDelete,
}) {
  final controller = TextEditingController(text: initial ?? '');
  return showAppSheet<String>(
    context,
    builder: (ctx) {
      final c = ctx.c;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(
            initial == null ? context.s.newCriterion : context.s.editCriterion,
            subtitle:
                context.s.criterionHelp,
          ),
          const SizedBox(height: 13),
          TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            style: WayFonts.ui(size: 13.5, color: c.ink),
            decoration: InputDecoration(
              hintText: 'Es. blocchi da almeno 45 minuti continuativi',
              hintStyle: WayFonts.ui(size: 13.5, color: c.inkFaint),
              filled: true,
              fillColor: c.surface2,
              contentPadding: const EdgeInsets.all(13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.accent),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (onDelete != null) ...[
                Expanded(
                  child: GhostButton(
                    label: context.s.delete,
                    foreground: c.hard,
                    onPressed: () {
                      onDelete();
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: context.s.save,
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    Navigator.of(ctx).pop(text);
                  },
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

// --- Fogli degli ambienti ---------------------------------------------------

Future<void> showPlaceDetailSheet(
  BuildContext context,
  WidgetRef ref,
  Place place,
) async {
  final c = context.c;
  final data = ref.read(appProvider);
  final tasks = data.tasksOf(place);
  final isActive = data.activePlaceId == place.id;

  await showAppSheet<void>(
    context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: c.accentTint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(placeGlyph(place.glyphKey), size: 23, color: c.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, style: WayFonts.display(size: 18, color: c.ink)),
                  Text(
                    context.s.coreSessionState(place.useCore),
                    style: WayFonts.ui(size: 12.5, color: c.inkSoft),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (place.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(place.description, style: WayFonts.ui(size: 12.5, color: c.inkSoft)),
        ],
        const SizedBox(height: 16),
        Text(
          'TASK IN CARICO (${tasks.length})',
          style: WayFonts.label(color: c.inkFaint, size: 9.5),
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          Text(context.s.noTasks, style: WayFonts.ui(size: 12.5, color: c.inkFaint))
        else
          for (final t in tasks)
            PickRow(
              task: t,
              selected: false,
              locked: place.useCore && data.isCore(t.id),
              lockedLabel: 'core',
            ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GhostButton(
                label: context.s.edit,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PlaceWizard(existing: place),
                    ),
                  );
                },
              ),
            ),
            if (!isActive) ...[
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  label: context.s.activate,
                  onPressed: () {
                    ref.read(appProvider.notifier).activatePlace(place.id);
                    Navigator.of(ctx).pop();
                    showToast(context, context.s.activeEnv(place.name));
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        GhostButton(
          label: context.s.deleteEnvironment,
          foreground: c.hard,
          onPressed: () {
            ref.read(appProvider.notifier).deletePlace(place.id);
            Navigator.of(ctx).pop();
            showToast(context, context.s.environmentDeleted);
          },
        ),
      ],
    ),
  );
}

String _num(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

String _fmtWhen(DateTime d) {
  final today = Dates.today();
  final day = DateTime(d.year, d.month, d.day);
  final hm =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  if (day == today) return 'oggi $hm';
  if (day == Dates.addDays(today, 1)) return 'domani $hm';
  return '${d.day}/${d.month} $hm';
}

/// Profilo e controlli del prototipo.
///
/// Le due modalita' non sono un interruttore da prodotto finito: servono
/// a mostrare l'app popolata oppure il primo utilizzo. Ognuna ha il suo
/// archivio, quindi passare dall'una all'altra non distrugge il lavoro.

Future<void> showEditTaskSheet(
        BuildContext context, WidgetRef ref, Task task) =>
    showAppSheet<void>(context, builder: (ctx) => _EditTaskSheet(task: task));

class _EditTaskSheet extends ConsumerStatefulWidget {
  const _EditTaskSheet({required this.task});
  final Task task;
  @override
  ConsumerState<_EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends ConsumerState<_EditTaskSheet> {
  late final TextEditingController _name;
  late final List<String> _criteria;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.task.name);
    _criteria = [for (final cr in widget.task.criteria) cr.text];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(s.editTask, subtitle: s.editWindowNote),
        const SizedBox(height: 16),
        LabeledField(label: s.name, controller: _name, hint: s.nameHint),
        const SizedBox(height: 16),
        Text(s.criteriaLabel,
            style: WayFonts.label(color: c.inkFaint, size: 9.5)),
        const SizedBox(height: 8),
        for (var i = 0; i < _criteria.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final r =
                        await showCriterionSheet(context, initial: _criteria[i]);
                    if (r != null && r.isNotEmpty) {
                      setState(() => _criteria[i] = r);
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      border: Border.all(color: c.line),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(_criteria[i],
                        style: WayFonts.ui(size: 13, color: c.ink)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _criteria.removeAt(i)),
                child: Icon(Icons.close, size: 18, color: c.inkFaint),
              ),
            ]),
          ),
        GhostButton(
          label: s.addCriterion,
          onPressed: () async {
            final r = await showCriterionSheet(context);
            if (r != null && r.isNotEmpty) setState(() => _criteria.add(r));
          },
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: s.save,
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            ref.read(appProvider.notifier).applyTaskEdit(
                  widget.task,
                  name: name,
                  requirements: _criteria,
                );
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

/// Curva di crescita del number esponenziale: punti in funzione del progresso
/// (0 -> target) al livello attuale (pieno) e al successivo (trasparente).
class _GrowthCurveChart extends StatelessWidget {
  const _GrowthCurveChart({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: 118,
        child: CustomPaint(
          painter: _GrowthCurvePainter(
            task: task,
            current: c.accent,
            next: c.accent.withValues(alpha: 0.28),
            grid: c.lineSoft,
          ),
          child: const SizedBox.expand(),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        _dot(c.accent),
        const SizedBox(width: 5),
        Text('LV${task.level}',
            style: WayFonts.mono(size: 9.5, color: c.inkSoft)),
        const SizedBox(width: 14),
        _dot(c.accent.withValues(alpha: 0.4)),
        const SizedBox(width: 5),
        Text('LV${task.level + 1}',
            style: WayFonts.mono(size: 9.5, color: c.inkFaint)),
        const Spacer(),
        Text('0 → target',
            style: WayFonts.mono(size: 9, color: c.inkFaint)),
      ]),
    ]);
  }

  Widget _dot(Color col) => Container(
      width: 8, height: 8,
      decoration: BoxDecoration(color: col, shape: BoxShape.circle));
}

class _GrowthCurvePainter extends CustomPainter {
  _GrowthCurvePainter(
      {required this.task,
      required this.current,
      required this.next,
      required this.grid});
  final Task task;
  final Color current, next, grid;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 3.0, n = 48;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    final cur = <double>[];
    final nxt = <double>[];
    for (var i = 0; i <= n; i++) {
      final p = i / n;
      cur.add(numberCurvePoint(task, p, task.level));
      nxt.add(numberCurvePoint(task, p, task.level + 1));
    }
    final maxY = [...cur, ...nxt].reduce((a, b) => a > b ? a : b);
    if (maxY <= 0) return;
    Offset at(int i, List<double> v) =>
        Offset(pad + (i / n) * w, pad + h - (v[i] / maxY) * h);

    canvas.drawLine(Offset(pad, pad + h), Offset(pad + w, pad + h),
        Paint()..color = grid..strokeWidth = 1);

    Path pathOf(List<double> v) {
      final path = Path()..moveTo(at(0, v).dx, at(0, v).dy);
      for (var i = 1; i <= n; i++) {
        path.lineTo(at(i, v).dx, at(i, v).dy);
      }
      return path;
    }

    canvas.drawPath(
        pathOf(nxt),
        Paint()
          ..color = next
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
    canvas.drawPath(
        pathOf(cur),
        Paint()
          ..color = current
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_GrowthCurvePainter old) =>
      old.task.level != task.level || old.task.reward != task.reward;
}
