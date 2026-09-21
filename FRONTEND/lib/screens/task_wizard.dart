import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/glyphs.dart';
import '../models/models.dart';
import '../sheets/sheets.dart';
import '../state/providers.dart';
import '../theme/way_theme.dart';
import '../widgets/common.dart';
import '../widgets/domain_editor.dart';
import '../widgets/reward_curve.dart';
import 'wizard_scaffold.dart';

enum _CriteriaView { quick, full }

/// Creazione della task in quattro passi: riconoscimento, durata, criteri,
/// tipologia. Ogni passo ha una sola domanda.
class TaskWizard extends ConsumerStatefulWidget {
  const TaskWizard({super.key});

  @override
  ConsumerState<TaskWizard> createState() => _TaskWizardState();
}

class _TaskWizardState extends ConsumerState<TaskWizard> {
  int _step = 0;

  final _name = TextEditingController();
  final _description = TextEditingController();

  String _iconKey = 'book';
  final List<int> _days = [];
  final List<Criterion> _criteria = [];
  _CriteriaView _view = _CriteriaView.quick;
  bool _newestFirst = true;
  TaskKind _kind = TaskKind.complete;
  RewardCurve _reward = RewardCurve.linear;
  final _targetCtrl = TextEditingController(text: '3');
  double get _target =>
      double.tryParse(_targetCtrl.text.replaceAll(',', '.')) ?? 1;
  int _start = 6;
  int _end = 23;
  DomainPeriod _period = DomainPeriod.daily;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  bool get _stepValid => switch (_step) {
        0 => _name.text.trim().isNotEmpty,
        1 => _days.isNotEmpty,
        _ => true,
      };

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    final task = Task(
      id: newId(),
      name: _name.text.trim(),
      iconKey: _iconKey,
      description: _description.text.trim(),
      days: (_days.toList()..sort()),
      criteria: List.of(_criteria),
      kind: _kind,
      reward: _reward,
      target: _target,
      start: _start,
      end: _end,
      period: _period,
      level: 0,
      streak: 0,
    );
    ref.read(appProvider.notifier).addTask(task);
    Navigator.of(context).pop();
    showToast(context, 'Task creata: ${task.name}');
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Riconoscimento', 'Durata', 'Criteri', 'Tipologia'];
    const subtitles = [
      'Come si chiama e come la riconosci in un colpo d\'occhio.',
      'Nei giorni che scegli WAY se l\'aspetta. Negli altri no.',
      'Ogni condizione che aggiungi rende la task piu\' impegnativa.',
      'Come si registra l\'esecuzione ogni giorno.',
    ];

    return WizardScaffold(
      stepIndex: _step,
      stepCount: 4,
      title: titles[_step],
      subtitle: subtitles[_step],
      nextLabel: _step == 3 ? 'Crea la task' : 'Continua',
      onNext: _stepValid ? _next : null,
      onBack: _step > 0 ? () => setState(() => _step--) : null,
      body: switch (_step) {
        0 => _stepIdentity(),
        1 => _stepDuration(),
        2 => _stepCriteria(),
        _ => _stepKind(),
      },
    );
  }

  Widget _stepIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: 'Nome',
          controller: _name,
          hint: 'Studio, Allenamento, Sveglia...',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 15),
        Text('ICONA', style: WayFonts.label(color: context.c.inkFaint, size: 9.5)),
        const SizedBox(height: 7),
        IconPicker(
          icons: taskIcons,
          selected: _iconKey,
          onSelect: (key) => setState(() => _iconKey = key),
        ),
        const SizedBox(height: 15),
        LabeledField(
          label: 'Descrizione (facoltativa)',
          controller: _description,
          hint: 'Cosa conta come esecuzione, in una riga.',
          multiline: true,
        ),
      ],
    );
  }

  Widget _stepDuration() {
    return DomainEditor(
      days: _days,
      period: _period,
      start: _start,
      end: _end,
      onToggleDay: (i) => setState(() {
        _days.contains(i) ? _days.remove(i) : _days.add(i);
      }),
      onPeriod: (p) => setState(() => _period = p),
      onStart: (h) => setState(() => _start = h),
      onEnd: (h) => setState(() => _end = h),
    );
  }

  Widget _stepCriteria() {
    final c = context.c;
    final count = _criteria.length;
    final difficulty = difficultyForCriteria(count);
    final colors = difficultyColors(context, difficulty);
    final ordered = _newestFirst ? _criteria.reversed.toList() : _criteria;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: colors.bg,
            border: Border.all(color: colors.fg.withValues(alpha: 0.28)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Text(
                '$count',
                style: WayFonts.display(size: 20, color: colors.fg, height: 1),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: WayFonts.ui(size: 12, color: c.inkSoft),
                    children: [
                      TextSpan(
                        text: difficulty.label,
                        style: WayFonts.ui(
                          size: 12,
                          weight: FontWeight.w700,
                          color: colors.fg,
                        ),
                      ),
                      const TextSpan(
                        text:
                            ' — sotto 4 criteri facile, da 4 a 7 media, oltre 7 difficile.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            SizedBox(
              width: 172,
              child: Segmented<_CriteriaView>(
                values: _CriteriaView.values,
                labels: const ['Rapida', 'Integrale'],
                selected: _view,
                onChanged: (v) => setState(() => _view = v),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _newestFirst = !_newestFirst),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: c.surface2,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _newestFirst ? '↓ PIÙ RECENTI' : '↑ MENO RECENTI',
                  style: WayFonts.mono(
                    size: 10,
                    weight: FontWeight.w600,
                    color: c.inkSoft,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        if (_view == _CriteriaView.quick)
          _quickView(ordered, colors, count)
        else
          _fullView(ordered, colors, difficulty, count),
      ],
    );
  }

  Widget _quickView(
    List<Criterion> ordered,
    ({Color fg, Color bg}) colors,
    int count,
  ) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final criterion in ordered)
              _Sphere(
                label: '${_criteria.indexOf(criterion) + 1}',
                color: colors.fg,
                onTap: () => _editCriterion(criterion),
              ),
            _Sphere.add(onTap: _addCriterion),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          count == 0
              ? 'Nessun criterio: la task risulterebbe facile per definizione.'
              : 'Tocca una sfera per modificarla.',
          style: WayFonts.ui(size: 12.5, color: c.inkSoft),
        ),
      ],
    );
  }

  Widget _fullView(
    List<Criterion> ordered,
    ({Color fg, Color bg}) colors,
    Difficulty difficulty,
    int count,
  ) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            children: [
              DifficultyPill(difficulty),
              const SizedBox(width: 9),
              Text(
                '$count criteri · ${_newestFirst ? 'dal piu\' recente' : 'dal meno recente'}',
                style: WayFonts.mono(size: 10, color: c.inkFaint),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: Column(
            children: [
              for (final criterion in ordered)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.lineSoft)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          '${_criteria.indexOf(criterion) + 1}',
                          style: WayFonts.mono(
                            size: 11,
                            weight: FontWeight.w600,
                            color: colors.fg,
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _editCriterion(criterion),
                          child: Text(
                            criterion.text,
                            style: WayFonts.ui(size: 13, color: c.ink),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _criteria.remove(criterion)),
                        child: Icon(Icons.close, size: 17, color: c.inkFaint),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        DashedActionButton(label: 'Aggiungi criterio', onTap: _addCriterion),
      ],
    );
  }

  Future<void> _addCriterion() async {
    final text = await showCriterionSheet(context);
    if (text == null) return;
    setState(() => _criteria.add(Criterion(id: newId(), text: text)));
  }

  Future<void> _editCriterion(Criterion criterion) async {
    final text = await showCriterionSheet(
      context,
      initial: criterion.text,
      onDelete: () => setState(() => _criteria.remove(criterion)),
    );
    if (text == null) return;
    setState(() {
      final index = _criteria.indexOf(criterion);
      if (index >= 0) _criteria[index] = criterion.copyWith(text: text);
    });
  }

  Widget _stepKind() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BigSwitch<TaskKind>(
          values: TaskKind.values,
          titles: const ['Completa', 'Misura'],
          captions: const ['Fatto / non fatto', 'Quantita\' al giorno'],
          selected: _kind,
          onChanged: (k) => setState(() => _kind = k),
        ),
        const SizedBox(height: 12),
        ExplainBox(
          _kind == TaskKind.complete
              ? 'Per task che in una giornata non hanno gradazione: la sveglia alle 8 o e\' rispettata o non lo e\'.'
              : 'Per task dove la quantita\' dice la qualita\' dell\'esecuzione: ore di studio, pagine lette, uscite.',
        ),
        if (_kind == TaskKind.measure) ...[
          const SizedBox(height: 18),
          Text(
            'SISTEMA DI RICOMPENSA',
            style: WayFonts.label(color: context.c.inkFaint, size: 9.5),
          ),
          const SizedBox(height: 7),
          BigSwitch<RewardCurve>(
            values: RewardCurve.values,
            titles: const ['Lineare', 'Esponenziale'],
            captions: const ['Attrito costante', 'Attrito crescente'],
            selected: _reward,
            onChanged: (r) => setState(() => _reward = r),
          ),
          const SizedBox(height: 12),
          ExplainBox(
            _reward == RewardCurve.linear
                ? 'Ogni unita\' in piu\' vale quanto la precedente. Adatto quando continuare non costa fatica aggiuntiva: uscire con gli amici una volta in piu\'.'
                : 'Ogni unita\' in piu\' vale piu\' della precedente. Adatto quando la fatica cresce: la quinta ora di studio non e\' la prima.',
          ),
          const SizedBox(height: 12),
          RewardCurvePreview(
            curve: _reward,
            target: _target,
          ),
          const SizedBox(height: 18),
          LabeledField(
            label: 'Target giornaliero',
            controller: _targetCtrl,
            hint: 'es. 40, 5, 3...',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ],
    );
  }
}

class _Sphere extends StatelessWidget {
  const _Sphere({required this.label, required this.color, required this.onTap})
      : isAdd = false;

  const _Sphere.add({required this.onTap})
      : label = '',
        color = null,
        isAdd = true;

  final String label;
  final Color? color;
  final bool isAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isAdd ? Colors.transparent : color,
          border: isAdd ? Border.all(color: c.accentSoft, width: 1.5) : null,
        ),
        child: isAdd
            ? Icon(Icons.add, size: 22, color: c.accent)
            : Text(
                label,
                style: WayFonts.display(
                  size: 15,
                  weight: FontWeight.w600,
                  color: c.onSolid,
                  letterSpacing: 0,
                ),
              ),
      ),
    );
  }
}

// ignore: unused_element
class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final String unit;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final shown = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: WayFonts.ui(size: 12.5, weight: FontWeight.w600, color: c.ink),
              ),
              Text(
                '$shown ${unit.trim()}',
                style: WayFonts.mono(size: 13, weight: FontWeight.w600, color: c.accent),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
