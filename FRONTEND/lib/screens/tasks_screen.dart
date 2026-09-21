import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/glyphs.dart';
import '../models/app_data.dart';
import '../models/models.dart';
import '../fx/anchors.dart';
import '../models/app_data.dart' show OnboardingStage;
import '../sheets/sheets.dart';
import 'first_run_wizard.dart';
import '../state/providers.dart';
import '../theme/way_theme.dart';
import '../widgets/common.dart';
import '../widgets/task_strip.dart';
import 'task_wizard.dart';

/// Carico trascinato: serve a distinguere una task che arriva dalla lista da
/// una che sta uscendo dal nucleo, cosi' i due bersagli non si confondono.
class TaskDrag {
  const TaskDrag({required this.task, required this.fromCore});

  final Task task;
  final bool fromCore;
}

/// Tasks: qui si configura, non si esegue.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  /// Null quando non si sta trascinando; altrimenti dice da dove parte il
  /// carico, per accendere il suggerimento giusto.
  bool? _draggingFromCore;

  void _setDragging(bool? fromCore) {
    if (_draggingFromCore == fromCore) return;
    setState(() => _draggingFromCore = fromCore);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appProvider);
    final hasTasks = data.tasks.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ScreenHeader(eyebrow: 'Configurazione', title: 'Tasks'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            children: [
              _CoreHub(
                data: data,
                showDropHint: _draggingFromCore == false,
                onDragStateChanged: _setDragging,
              ),
              const SizedBox(height: 20),
              const SectionLabel('Le tue task'),
              PrimaryButton(
                key: taskCreateKey,
                label: 'Crea una nuova task',
                icon: Icons.add_rounded,
                onPressed: () {
                  // Durante il primo utilizzo questo stesso pulsante apre
                  // il percorso guidato: il riflettore illumina lui, non
                  // una copia, quindi il gesto e' uno solo.
                  final ob = ref.read(onboardingProvider);
                  if (ref.read(tutorialActiveProvider) &&
                      ob.stage == OnboardingStage.taskIntro) {
                    ref
                        .read(appProvider.notifier)
                        .setStage(OnboardingStage.taskWizard);
                    Navigator.of(context)
                        .push(MaterialPageRoute<void>(
                      builder: (_) => const FirstRunTaskWizard(),
                    ))
                        .then((_) {
                      // Uscendo a meta' si torna all'invito, non al vuoto.
                      if (ref.read(onboardingProvider).stage ==
                          OnboardingStage.taskWizard) {
                        ref
                            .read(appProvider.notifier)
                            .setStage(OnboardingStage.taskIntro);
                      }
                    });
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const TaskWizard()),
                  );
                },
              ),
              const SizedBox(height: 10),
              if (hasTasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Trascina una task nell\'hub per metterla nel nucleo, trascinala fuori per toglierla. Tieni premuto per le opzioni.',
                    style: WayFonts.ui(size: 11.5, color: context.c.inkFaint),
                  ),
                ),
              if (!hasTasks)
                const EmptyStateBox(
                  icon: Icons.add,
                  title: 'Ancora niente',
                  body:
                      'Una task descrive cosa vuoi mantenere e a che livello di intensita\'. Gli ambienti si costruiscono sopra le task.',
                ),
              _TaskListDropZone(
                active: _draggingFromCore == true,
                onAccept: (drag) {
                  ref.read(appProvider.notifier).removeFromCore(drag.task.id);
                  showToast(context, '${drag.task.name} fuori dal nucleo');
                },
                child: Column(
                  children: [
                    for (final task in data.tasks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _DraggableTaskStrip(
                          task: task,
                          inCore: data.isCore(task.id),
                          onDragStateChanged: _setDragging,
                        ),
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

/// Hub della Core Session: disattivato finche' non esiste almeno una task,
/// perche' un nucleo vuoto non vuol dire niente.
class _CoreHub extends ConsumerWidget {
  const _CoreHub({
    required this.data,
    required this.showDropHint,
    required this.onDragStateChanged,
  });

  final AppData data;
  final bool showDropHint;
  final ValueChanged<bool?> onDragStateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final hasTasks = data.tasks.isNotEmpty;

    return DragTarget<TaskDrag>(
      onWillAcceptWithDetails: (details) => !details.data.fromCore,
      onAcceptWithDetails: (details) {
        final task = details.data.task;
        if (data.isCore(task.id)) {
          showToast(context, '${task.name} e\' gia\' nel nucleo');
          return;
        }
        ref.read(appProvider.notifier).addToCore(task.id);
        showToast(context, '${task.name} e\' nel nucleo');
      },
      builder: (context, candidate, rejected) {
        final hot = candidate.isNotEmpty;
        return AnimatedContainer(
          key: coreHubKey,
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hot
                  ? [c.accentTint, c.accentTint]
                  : [c.accentTint, c.surface2],
              stops: const [0, 0.62],
            ),
            border: Border.all(color: hot ? c.accent : c.line, width: hot ? 1.5 : 1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Opacity(
            opacity: hasTasks ? 1 : 0.62,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.accent,
                        boxShadow: [
                          BoxShadow(color: c.accentTint, blurRadius: 0, spreadRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        'My Core Session',
                        style: WayFonts.display(
                          size: 15.5,
                          weight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                    ),
                    if (hasTasks)
                      Pill('${data.coreIds.length} task', bg: c.surface, fg: c.inkFaint)
                    else
                      Icon(Icons.lock_outline, size: 15, color: c.inkFaint),
                  ],
                ),
                const SizedBox(height: 11),
                if (!hasTasks)
                  Text(
                    'Il nucleo che resta attivo in ogni ambiente. Si sblocca appena crei la prima task.',
                    style: WayFonts.ui(size: 12.5, color: c.inkSoft),
                  )
                else ...[
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final id in data.coreIds)
                        if (data.taskById(id) != null)
                          _CoreChip(
                            task: data.taskById(id)!,
                            onDragStateChanged: onDragStateChanged,
                          ),
                      _AddChip(onTap: () => showCorePickerSheet(context, ref)),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Text(
                    'Restano attive ovunque, qualunque ambiente sia inserito nell\'hub.',
                    style: WayFonts.ui(size: 12.5, color: c.inkSoft),
                  ),
                  if (showDropHint) ...[
                    const SizedBox(height: 11),
                    Text(
                      '↓ RILASCIA QUI PER AGGIUNGERE AL NUCLEO',
                      style: WayFonts.label(color: c.accent, size: 9.5),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CoreChip extends ConsumerWidget {
  const _CoreChip({required this.task, required this.onDragStateChanged});

  final Task task;
  final ValueChanged<bool?> onDragStateChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chip = _ChipBody(task: task);
    return LongPressDraggable<TaskDrag>(
      data: TaskDrag(task: task, fromCore: true),
      delay: const Duration(milliseconds: 320),
      hapticFeedbackOnStart: true,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () => onDragStateChanged(true),
      onDragEnd: (_) => onDragStateChanged(null),
      onDraggableCanceled: (_, __) => onDragStateChanged(null),
      feedback: Material(
        color: Colors.transparent,
        child: Transform.translate(
          offset: const Offset(-60, -20),
          child: _ChipBody(task: task, elevated: true),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: chip),
      child: GestureDetector(
        onTap: () => showTaskDetailSheet(context, ref, task),
        child: chip,
      ),
    );
  }
}

class _ChipBody extends StatelessWidget {
  const _ChipBody({required this.task, this.elevated = false});

  final Task task;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 6, 10, 6),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: elevated ? c.accent : c.line),
        borderRadius: BorderRadius.circular(999),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: c.ink.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(taskIcon(task.iconKey), size: 15, color: c.inkSoft),
          const SizedBox(width: 6),
          Text(
            task.name,
            style: WayFonts.ui(size: 12.5, weight: FontWeight.w500, color: c.ink),
          ),
        ],
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 6, 12, 6),
        decoration: BoxDecoration(
          border: Border.all(color: c.accentSoft),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 15, color: c.accent),
            const SizedBox(width: 5),
            Text(
              'Aggiungi',
              style: WayFonts.ui(size: 12.5, weight: FontWeight.w500, color: c.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// Zona di rilascio per togliere dal nucleo: e' tutta la lista delle task,
/// cosi' basta portare il chip "giu'" senza cercare un bersaglio piccolo.
class _TaskListDropZone extends StatelessWidget {
  const _TaskListDropZone({
    required this.active,
    required this.onAccept,
    required this.child,
  });

  final bool active;
  final ValueChanged<TaskDrag> onAccept;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DragTarget<TaskDrag>(
      onWillAcceptWithDetails: (details) => details.data.fromCore,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, rejected) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (active)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '↑ RILASCIA QUI PER TOGLIERE DAL NUCLEO',
                  style: WayFonts.label(color: c.accent, size: 9.5),
                ),
              ),
            Container(
              padding: active ? const EdgeInsets.all(6) : EdgeInsets.zero,
              decoration: active
                  ? BoxDecoration(
                      border: Border.all(
                        color: candidate.isNotEmpty ? c.accent : c.accentSoft,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    )
                  : null,
              child: child,
            ),
          ],
        );
      },
    );
  }
}

/// Striscia trascinabile. La pressione prolungata solleva la task: muovendola
/// si sposta, rilasciandola ferma apre il menu contestuale.
class _DraggableTaskStrip extends ConsumerStatefulWidget {
  const _DraggableTaskStrip({
    required this.task,
    required this.inCore,
    required this.onDragStateChanged,
  });

  final Task task;
  final bool inCore;
  final ValueChanged<bool?> onDragStateChanged;

  @override
  ConsumerState<_DraggableTaskStrip> createState() => _DraggableTaskStripState();
}

class _DraggableTaskStripState extends ConsumerState<_DraggableTaskStrip> {
  final _key = GlobalKey();
  Offset? _origin;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 36;
    final strip = TaskStrip(task: widget.task, inCore: widget.inCore);

    return LongPressDraggable<TaskDrag>(
      key: _key,
      data: TaskDrag(task: widget.task, fromCore: false),
      delay: const Duration(milliseconds: 350),
      hapticFeedbackOnStart: true,
      onDragStarted: () {
        widget.onDragStateChanged(false);
        final box = _key.currentContext?.findRenderObject() as RenderBox?;
        _origin = box?.localToGlobal(Offset.zero);
      },
      onDragEnd: (details) {
        widget.onDragStateChanged(null);
        // Premuto e rilasciato senza spostarsi: e' una richiesta di menu,
        // non un trascinamento andato a vuoto.
        final origin = _origin;
        if (!details.wasAccepted &&
            origin != null &&
            (details.offset - origin).distance < 14) {
          showTaskContextSheet(context, ref, widget.task);
        }
      },
      feedback: SizedBox(
        width: width,
        child: Material(
          color: Colors.transparent,
          child: TaskStrip(
            task: widget.task,
            inCore: widget.inCore,
            elevated: true,
          ),
        ),
      ),
      childWhenDragging: TaskStrip(
        task: widget.task,
        inCore: widget.inCore,
        faded: true,
      ),
      child: GestureDetector(
        onTap: () => showTaskDetailSheet(context, ref, widget.task),
        child: strip,
      ),
    );
  }
}
