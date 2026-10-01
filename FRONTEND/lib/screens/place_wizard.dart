import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/glyphs.dart';
import '../models/app_data.dart';
import '../models/models.dart';
import '../sheets/sheets.dart';
import '../state/providers.dart';
import '../theme/way_theme.dart';
import '../widgets/common.dart';
import 'wizard_scaffold.dart';

/// Creazione o modifica di un ambiente: riconoscimento e carico.
class PlaceWizard extends ConsumerStatefulWidget {
  const PlaceWizard({super.key, this.existing, this.guided = false});

  final Place? existing;

  /// In modalita' guidata le due schermate parlano la lingua del tutorial:
  /// la spiegazione sta addosso alla domanda, non in pagine separate.
  final bool guided;

  @override
  ConsumerState<PlaceWizard> createState() => _PlaceWizardState();
}

class _PlaceWizardState extends ConsumerState<PlaceWizard> {
  int _step = 0;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late String _glyphKey;
  late bool _useCore;
  late List<String> _taskIds;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _glyphKey = p?.glyphKey ?? 'pin';
    _useCore = p?.useCore ?? true;
    _taskIds = List.of(p?.taskIds ?? const <String>[]);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    final controller = ref.read(appProvider.notifier);
    final existing = widget.existing;
    if (existing == null) {
      final place = Place(
        id: newId(),
        name: _name.text.trim(),
        glyphKey: _glyphKey,
        description: _description.text.trim(),
        useCore: _useCore,
        taskIds: _taskIds,
      );
      controller.addPlace(place);
      if (widget.guided) controller.finishOnboarding();
      Navigator.of(context).pop();
      showToast(
        context,
        'Ambiente creato: ${place.name}',
        widget.guided ? 'Configurazione completata' : '',
      );
    } else {
      controller.updatePlace(
        existing.copyWith(
          name: _name.text.trim(),
          glyphKey: _glyphKey,
          description: _description.text.trim(),
          useCore: _useCore,
          taskIds: _taskIds,
        ),
      );
      Navigator.of(context).pop();
      showToast(context, 'Ambiente aggiornato');
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return WizardScaffold(
      stepIndex: _step,
      stepCount: 2,
      title: widget.guided
          ? (_step == 0 ? 'Dove cambia la tua routine?' : 'Cosa ti porti dietro?')
          : (_step == 0 ? 'Riconoscimento' : 'Carico'),
      subtitle: widget.guided
          ? (_step == 0
              ? 'Un ambiente è un posto o un periodo con regole diverse: casa, università, una trasferta, la sessione d\'esami.'
              : 'Puoi tenere la Core Session e aggiungere solo ciò che serve qui, oppure spegnerla e costruire una routine diversa.')
          : (_step == 0
              ? 'Dove sei e che periodo è. Il nome basta a distinguerlo.'
              : 'Quali task hanno senso qui dentro.'),
      nextLabel: _step == 0 ? 'Continua' : (editing ? 'Salva' : 'Crea l\'ambiente'),
      onNext: _step == 0 && _name.text.trim().isEmpty ? null : _next,
      onBack: _step > 0 ? () => setState(() => _step = 0) : null,
      body: _step == 0 ? _stepIdentity() : _stepLoad(),
    );
  }

  Widget _stepIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: 'Nome dell\'ambiente',
          controller: _name,
          hint: 'Sede - Trento, Casa, In viaggio...',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 15),
        Text('SEGNO', style: WayFonts.label(color: context.c.inkFaint, size: 9.5)),
        const SizedBox(height: 7),
        IconPicker(
          icons: placeGlyphs,
          selected: _glyphKey,
          onSelect: (key) => setState(() => _glyphKey = key),
        ),
        const SizedBox(height: 15),
        LabeledField(
          label: 'Descrizione (facoltativa)',
          controller: _description,
          hint: 'Che periodo e\', e cosa cambia rispetto agli altri.',
          multiline: true,
        ),
      ],
    );
  }

  Widget _stepLoad() {
    final c = context.c;
    final data = ref.watch(appProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => setState(() => _useCore = !_useCore),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: c.surface2,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Core session',
                        style: WayFonts.ui(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _useCore
                            ? 'Le task del nucleo sono gia\' dentro: non serve aggiungerle.'
                            : 'Il nucleo non vale qui. Tutte le task sono disponibili da inserire.',
                        style: WayFonts.ui(size: 11.5, color: c.inkSoft),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _Knob(on: _useCore),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionLabel('Task nell\'ambiente'),
        if (data.tasks.isEmpty)
          Text(
            'Nessuna task creata. Torna in Tasks e creane almeno una.',
            style: WayFonts.ui(size: 12.5, color: c.inkFaint),
          )
        else
          for (final task in data.tasks)
            PickRow(
              task: task,
              selected: (_useCore && data.isCore(task.id)) ||
                  _taskIds.contains(task.id),
              locked: _useCore && data.isCore(task.id),
              onTap: () {
                if (_useCore && data.isCore(task.id)) {
                  showToast(context, 'E\' nella core session: gia\' inclusa');
                  return;
                }
                setState(() {
                  if (_taskIds.contains(task.id)) {
                    _taskIds.remove(task.id);
                  } else {
                    _taskIds.add(task.id);
                  }
                });
              },
            ),
      ],
    );
  }
}

class _Knob extends StatelessWidget {
  const _Knob({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 44,
      height: 26,
      decoration: BoxDecoration(
        color: on ? c.accent : c.surface3,
        border: Border.all(color: on ? c.accent : c.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 160),
            left: on ? 20 : 2,
            top: 1,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.surface,
                boxShadow: [
                  BoxShadow(
                    color: c.ink.withOpacity(0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
