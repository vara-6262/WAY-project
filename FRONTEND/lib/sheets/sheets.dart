import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dates.dart';
import '../data/glyphs.dart';
import '../models/app_data.dart';
import '../models/models.dart';
import '../screens/place_wizard.dart';
import '../services/notifications.dart';
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
    barrierColor: Colors.black.withOpacity(0.42),
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
                    'LV${task.level} · ${inCore ? 'nel nucleo' : 'fuori dal nucleo'}',
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
          label: 'Apri dettagli',
          onTap: () {
            Navigator.of(ctx).pop();
            showTaskDetailSheet(context, ref, task);
          },
        ),
        SheetAction(
          icon: inCore ? Icons.remove_circle_outline : Icons.auto_awesome,
          label: inCore
              ? 'Togli dalla Core Session'
              : 'Aggiungi alla Core Session',
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
        SheetAction(
          icon: Icons.delete_outline,
          label: 'Elimina task',
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
          'Eliminare "${task.name}"?',
          subtitle: usedByPlaces > 0 || alsoCore
              ? 'Sparisce dal nucleo e dagli ambienti che la usano, insieme ai suoi criteri e al suo storico. Non si torna indietro.'
              : 'Spariscono anche i suoi criteri e il suo storico. Non si torna indietro.',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GhostButton(
                label: 'Annulla',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PrimaryButton(
                label: 'Elimina',
                color: context.c.hard,
                foreground: Colors.white,
                onPressed: () {
                  ref.read(appProvider.notifier).deleteTask(task.id);
                  Navigator.of(ctx).pop();
                  showToast(context, 'Task eliminata');
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
                    'LV${task.level} · ${task.kind == TaskKind.measure ? 'Misura · ${task.reward == RewardCurve.exponential ? 'esponenziale' : 'lineare'}' : task.kind == TaskKind.maintenance ? 'Mantenimento' : task.kind == TaskKind.abstinence ? 'Astinenza' : 'Completa'}',
                    style: WayFonts.ui(size: 12.5, color: c.inkSoft),
                  ),
                ],
              ),
            ),
            DifficultyPill(task.difficulty),
          ],
        ),
        if (task.description.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(task.description, style: WayFonts.ui(size: 12.5, color: c.inkSoft)),
        ],
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
        if (task.kind == TaskKind.measure) ...[
          const SizedBox(height: 16),
          Text('SOGLIA E TARGET', style: WayFonts.label(color: c.inkFaint, size: 9.5)),
          const SizedBox(height: 6),
          Text(
            'Obiettivo ${_num(task.target)}',
            style: WayFonts.ui(size: 12.5, color: c.inkSoft),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'CRITERI DI VALIDAZIONE (${task.criteria.length})',
          style: WayFonts.label(color: c.inkFaint, size: 9.5),
        ),
        const SizedBox(height: 6),
        if (task.criteria.isEmpty)
          Text('Nessun criterio.', style: WayFonts.ui(size: 12.5, color: c.inkFaint))
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
          places.isEmpty ? 'Nessun ambiente' : places.join(' · '),
          style: WayFonts.ui(size: 12.5, color: c.inkSoft),
        ),
        const SizedBox(height: 18),
        GhostButton(
          label: 'Elimina task',
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
              const SheetTitle(
                'Aggiungi alla Core Session',
                subtitle:
                    'Queste task valgono in ogni ambiente che tiene la core session attiva.',
              ),
              const SizedBox(height: 14),
              if (available.isEmpty)
                Text(
                  'Tutte le task sono gia\' nel nucleo.',
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
            initial == null ? 'Nuovo criterio' : 'Modifica criterio',
            subtitle:
                'Una condizione verificabile: se non e\' vera, la giornata non conta.',
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
                    label: 'Elimina',
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
                  label: 'Salva',
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
                    'Core session ${place.useCore ? 'attiva' : 'disattivata'}',
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
          Text('Nessuna task.', style: WayFonts.ui(size: 12.5, color: c.inkFaint))
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
                label: 'Modifica',
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
                  label: 'Attiva',
                  onPressed: () {
                    ref.read(appProvider.notifier).activatePlace(place.id);
                    Navigator.of(ctx).pop();
                    showToast(context, 'Ambiente attivo: ${place.name}');
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        GhostButton(
          label: 'Elimina ambiente',
          foreground: c.hard,
          onPressed: () {
            ref.read(appProvider.notifier).deletePlace(place.id);
            Navigator.of(ctx).pop();
            showToast(context, 'Ambiente eliminato');
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
Future<void> showProfileSheet(BuildContext context, WidgetRef ref) async {
  await showAppSheet<void>(
    context,
    builder: (ctx) => Consumer(
      builder: (ctx2, ref2, _) {
        final c = ctx2.c;
        final mode = ref2.watch(modeProvider);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.surface2,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.line),
                  ),
                  child: Text('M', style: WayFonts.display(size: 16, color: c.ink)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Manuel',
                          style: WayFonts.display(size: 18, color: c.ink)),
                      Text('Profilo personale',
                          style: WayFonts.ui(size: 12.5, color: c.inkSoft)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('MODALITÀ PROTOTIPO',
                style: WayFonts.label(color: c.inkFaint, size: 9.5)),
            const SizedBox(height: 8),
            Segmented<PrototypeMode>(
              values: PrototypeMode.values,
              labels: const ['Proxy', 'Configura da 0'],
              selected: mode,
              onChanged: (m) => ref2.read(modeProvider.notifier).set(m),
            ),
            const SizedBox(height: 8),
            Text(
              mode == PrototypeMode.zero
                  ? 'Archivio vuoto con il tutorial del primo utilizzo.'
                  : 'Demo popolata: cinque task, tre ambienti, 90 giorni di storico.',
              style: WayFonts.ui(size: 11.5, color: c.inkFaint),
            ),
            const SizedBox(height: 18),
            Text('TEMA', style: WayFonts.label(color: c.inkFaint, size: 9.5)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final preset in WayColors.presets)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            ref2.read(themeProvider.notifier).setId(preset.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: preset.$3.surface2,
                            border: Border.all(
                              color: identical(preset.$3, ref2.watch(themeProvider))
                                  ? preset.$3.accent
                                  : c.line,
                              width: identical(preset.$3, ref2.watch(themeProvider))
                                  ? 2
                                  : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                    color: preset.$3.accent, shape: BoxShape.circle),
                              ),
                              const SizedBox(height: 6),
                              Text(preset.$2,
                                  style: WayFonts.mono(
                                      size: 9.5,
                                      weight: FontWeight.w700,
                                      color: c.inkSoft)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text('NOTIFICHE', style: WayFonts.label(color: c.inkFaint, size: 9.5)),
            const SizedBox(height: 8),
            Builder(builder: (_) {
              final nx = ref2
                  .read(notificationsProvider)
                  .next(ref2.read(appProvider));
              return Text(
                nx == null
                    ? 'Nessuna notifica programmata.'
                    : 'Prossima: ${_fmtWhen(nx.when)} · ${nx.text}',
                style: WayFonts.ui(size: 12, color: c.inkFaint),
              );
            }),
            const SizedBox(height: 8),
            GhostButton(
              label: 'Invia notifica di test',
              onPressed: () async {
                await ref2.read(notificationsProvider).sendTest();
                showToast(context, 'Notifica di test inviata');
              },
            ),
            const SizedBox(height: 8),
            GhostButton(
              label: 'Riprogramma promemoria',
              onPressed: () async {
                final n = ref2.read(notificationsProvider);
                await n.scheduleFor(ref2.read(appProvider));
                final count = await n.pendingCount();
                showToast(context, 'Promemoria programmati: $count');
              },
            ),
            const SizedBox(height: 18),
            GhostButton(
              label: 'Reimposta questa modalità',
              foreground: c.hard,
              onPressed: () {
                ref2.read(appProvider.notifier).resetCurrentMode();
                Navigator.of(ctx2).pop();
                showToast(context, 'Archivio reimpostato');
              },
            ),
          ],
        );
      },
    ),
  );
}
