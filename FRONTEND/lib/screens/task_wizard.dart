import 'package:flutter/material.dart';
import '../theme/way_theme.dart';
import '../widgets/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dates.dart';
import '../data/glyphs.dart';
import '../models/models.dart';
import '../sheets/sheets.dart';
import '../state/providers.dart';
import '../widgets/domain_editor.dart';
import '../widgets/reward_curve.dart';
import '../l10n/strings.dart';
import 'wizard_scaffold.dart';

/// Creazione della task in quattro passi: riconoscimento, durata, criteri,
/// tipologia. Ogni passo ha una sola domanda.
enum _Stage { identity, kind, duration, criteria }

class TaskWizard extends ConsumerStatefulWidget {
  const TaskWizard({super.key});

  @override
  ConsumerState<TaskWizard> createState() => _TaskWizardState();
}

class _TaskWizardState extends ConsumerState<TaskWizard> {
  int _step = 0;

  final _name = TextEditingController();

  String _iconKey = 'book';
  final List<int> _days = [];
  final List<Criterion> _criteria = [];
  bool _newestFirst = true;
  TaskKind _kind = TaskKind.complete;
  RewardCurve _reward = RewardCurve.linear;
  final _targetCtrl = TextEditingController(text: '3');
  double get _target =>
      double.tryParse(_targetCtrl.text.replaceAll(',', '.')) ?? 1;
  int _start = 6;
  int _end = 23;
  DomainPeriod _period = DomainPeriod.daily;
  int _tau = 14;

  // Codipendenza (solo per Completa/Numero): timeframe dinamico legato a un
  // trigger invece di giorni+orario fissi.
  bool _codependent = false;
  String? _triggerId;
  int _windowMinutes = 120;

  bool get _canCodep =>
      _kind == TaskKind.complete || _kind == TaskKind.measure;
  bool get _isCodep => _codependent && _canCodep;

  void _useTriggerDays(List<int> trigDays) {
    _days
      ..clear()
      ..addAll(trigDays);
  }

  String _winLabel(int m) =>
      m < 60 ? context.s.winMinutes(m) : context.s.winHours(m ~/ 60);

  @override
  void dispose() {
    _name.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  // Ordine: identita' -> tipo -> timeframe -> criteri. Il timeframe e' saltato
  // per l'astinenza (non e' mai ammessa, orario e giorno non contano).
  List<_Stage> get _stages => [
        _Stage.identity,
        _Stage.kind,
        if (_kind != TaskKind.abstinence) _Stage.duration,
        _Stage.criteria,
      ];

  _Stage get _stage => _stages[_step.clamp(0, _stages.length - 1)];

  bool get _stepValid => switch (_stage) {
        _Stage.identity => _name.text.trim().isNotEmpty,
        _Stage.duration =>
          _isCodep ? (_triggerId != null && _days.isNotEmpty) : _days.isNotEmpty,
        _ => true,
      };

  void _next() {
    if (_step < _stages.length - 1) {
      setState(() => _step++);
      return;
    }
    final isAbst = _kind == TaskKind.abstinence;
    final codep = _isCodep && _triggerId != null;
    final task = Task(
      id: newId(),
      name: _name.text.trim(),
      iconKey: _iconKey,
      description: '',
      // Astinenza: ogni giorno. Codipendenza: vale ogni giorno, e' la finestra
      // del trigger a decidere quando (giorni+orario fissi irrilevanti).
      // Astinenza: ogni giorno. Codipendenza: i giorni scelti (sottoinsieme di
      // quelli del trigger); l'orario fisso e' irrilevante (decide la finestra).
      days: isAbst ? const [0, 1, 2, 3, 4, 5, 6] : (_days.toList()..sort()),
      criteria: List.of(_criteria),
      kind: _kind,
      reward: _reward,
      target: _target,
      start: (isAbst || codep) ? 0 : _start,
      end: (isAbst || codep) ? 23 : _end,
      period: (isAbst || codep) ? DomainPeriod.daily : _period,
      tau: _tau,
      triggerId: codep ? _triggerId : null,
      windowMinutes: _windowMinutes,
      level: 0,
      streak: 0,
    );
    ref.read(appProvider.notifier).addTask(task);
    Navigator.of(context).pop();
    showToast(context, context.s.taskCreated(task.name));
  }

  @override
  Widget build(BuildContext context) {
    final stages = _stages;
    final stage = stages[_step.clamp(0, stages.length - 1)];
    final titles = {
      _Stage.identity: context.s.wizStepRecognition,
      _Stage.kind: context.s.wizStepType,
      _Stage.duration: context.s.wizStepDuration,
      _Stage.criteria: context.s.wizStepCriteria,
    };
    final subtitles = {
      _Stage.identity: context.s.wizSubRecognition,
      _Stage.kind: context.s.wizSubType,
      _Stage.duration: context.s.wizSubDuration,
      _Stage.criteria: context.s.wizSubCriteria,
    };

    return WizardScaffold(
      stepIndex: _step,
      stepCount: stages.length,
      title: titles[stage]!,
      subtitle: subtitles[stage]!,
      nextLabel:
          _step == stages.length - 1 ? context.s.createTask : context.s.continueLabel,
      onNext: _stepValid ? _next : null,
      onBack: _step > 0 ? () => setState(() => _step--) : null,
      body: switch (stage) {
        _Stage.identity => _stepIdentity(),
        _Stage.kind => _stepKind(),
        _Stage.duration => _stepDuration(),
        _Stage.criteria => _stepCriteria(),
      },
    );
  }

  Widget _stepIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: context.s.name,
          controller: _name,
          hint: context.s.nameHint,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 15),
        Text(context.s.icon, style: WayFonts.label(color: context.c.inkFaint, size: 9.5)),
        const SizedBox(height: 7),
        IconPicker(
          icons: taskIcons,
          selected: _iconKey,
          onSelect: (key) => setState(() => _iconKey = key),
        ),
      ],
    );
  }

  Widget _fixedTimeframe() {
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

  Widget _stepDuration() {
    // Solo Completa/Numero possono essere codipendenti; le altre -> fisso.
    if (!_canCodep) return _fixedTimeframe();

    final triggers = ref
        .watch(appProvider)
        .tasks
        .where((t) =>
            t.kind == TaskKind.complete || t.kind == TaskKind.measure)
        .toList();
    final c = context.c;

    Widget modeOption(bool codep) => _KindOption(
          title: codep ? context.s.tfCodep : context.s.tfFixed,
          caption: codep ? context.s.tfCodepSub : context.s.tfFixedSub,
          selected: _codependent == codep,
          onTap: (codep && triggers.isEmpty)
              ? null
              : () => setState(() {
                    _codependent = codep;
                    if (codep) {
                      _triggerId ??= triggers.first.id;
                      final trig = triggers.firstWhere(
                          (t) => t.id == _triggerId,
                          orElse: () => triggers.first);
                      _useTriggerDays(trig.days);
                    }
                  }),
        );

    final trig = triggers.isEmpty
        ? null
        : triggers.firstWhere((t) => t.id == _triggerId,
            orElse: () => triggers.first);
    final trigName = trig?.name ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        modeOption(false),
        modeOption(true),
        const SizedBox(height: 14),
        if (!_codependent)
          _fixedTimeframe()
        else if (triggers.isEmpty)
          ExplainBox(context.s.codepNoTriggers)
        else ...[
          Text(context.s.codepTrigger,
              style: WayFonts.label(color: c.inkFaint, size: 9.5)),
          const SizedBox(height: 4),
          Text(context.s.codepTriggerHint,
              style: WayFonts.ui(color: c.inkFaint, size: 11)),
          const SizedBox(height: 8),
          for (final t in triggers)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _KindOption(
                title: t.name,
                caption: t.kind == TaskKind.measure
                    ? context.s.kindMeasure
                    : context.s.kindComplete,
                selected: _triggerId == t.id,
                onTap: () => setState(() {
                  _triggerId = t.id;
                  _useTriggerDays(t.days);
                }),
              ),
            ),
          const SizedBox(height: 6),
          Text(context.s.codepWindow,
              style: WayFonts.label(color: c.inkFaint, size: 9.5)),
          const SizedBox(height: 8),
          _KindOption(
            title: context.s.winNoLimit,
            caption: context.s.winNoLimitSub,
            selected: _windowMinutes <= 0,
            onTap: () => setState(() => _windowMinutes = 0),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final m in const [30, 60, 120, 240])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _windowMinutes = m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _windowMinutes == m
                              ? c.accentTint
                              : c.surface2,
                          border: Border.all(
                              color: _windowMinutes == m ? c.accent : c.line),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_winLabel(m),
                            style: WayFonts.mono(
                                size: 10.5, color: c.inkSoft)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(context.s.codepDaysLabel,
              style: WayFonts.label(color: c.inkFaint, size: 9.5)),
          const SizedBox(height: 4),
          Text(context.s.codepDaysHint,
              style: WayFonts.ui(color: c.inkFaint, size: 11)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Builder(builder: (_) {
                      final allowed = trig?.days.contains(i) ?? false;
                      final on = allowed && _days.contains(i);
                      return GestureDetector(
                        onTap: allowed
                            ? () => setState(() {
                                  _days.contains(i)
                                      ? _days.remove(i)
                                      : _days.add(i);
                                })
                            : null,
                        child: Opacity(
                          opacity: allowed ? 1 : 0.35,
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: on ? c.accent : c.surface2,
                              border: Border.all(
                                  color: on ? c.accent : c.line),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(Dates.dayShort[i],
                                style: WayFonts.mono(
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: on ? c.onSolid : c.inkSoft)),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ExplainBox(context.s.codepDesc(
              trigName,
              _windowMinutes <= 0
                  ? context.s.winUntilEod
                  : _winLabel(_windowMinutes))),
        ],
      ],
    );
  }

  Widget _stepCriteria() {
    final c = context.c;
    final count = _criteria.length;
    final ordered = _newestFirst ? _criteria.reversed.toList() : _criteria;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('$count criteri',
                style: WayFonts.mono(size: 11, color: c.inkFaint)),
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
                  _newestFirst ? '↓ RECENTI' : '↑ MENO RECENTI',
                  style: WayFonts.mono(
                      size: 10, weight: FontWeight.w600, color: c.inkSoft),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Container(
          decoration:
              BoxDecoration(border: Border(top: BorderSide(color: c.line))),
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
                        child: Text('${_criteria.indexOf(criterion) + 1}',
                            style: WayFonts.mono(
                                size: 11,
                                weight: FontWeight.w600,
                                color: c.accent)),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _editCriterion(criterion),
                          child: Text(criterion.text,
                              style: WayFonts.ui(size: 13, color: c.ink)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _criteria.remove(criterion)),
                        child: Icon(Icons.close, size: 17, color: c.inkFaint),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 13),
        DashedActionButton(label: context.s.addCriterion, onTap: _addCriterion),
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
        _KindOption(
          title: context.s.kindComplete,
          caption: context.s.kindCompleteSub,
          selected: _kind == TaskKind.complete,
          onTap: () => setState(() => _kind = TaskKind.complete),
        ),
        _KindOption(
          title: context.s.kindMeasure,
          caption: context.s.kindMeasureSub,
          selected: _kind == TaskKind.measure,
          onTap: () => setState(() => _kind = TaskKind.measure),
        ),
        _KindOption(
          title: context.s.kindMaintain,
          caption: context.s.kindMaintainSub,
          selected: _kind == TaskKind.maintenance,
          onTap: () => setState(() => _kind = TaskKind.maintenance),
        ),
        _KindOption(
          title: context.s.kindAbstinence,
          caption: context.s.kindAbstinenceSub,
          selected: _kind == TaskKind.abstinence,
          onTap: () => setState(() => _kind = TaskKind.abstinence),
        ),
        const SizedBox(height: 12),
        ExplainBox(
          switch (_kind) {
            TaskKind.complete => context.s.kindCompleteDesc,
            TaskKind.measure => context.s.kindMeasureDesc,
            TaskKind.maintenance => context.s.kindMaintainDesc,
            TaskKind.abstinence => context.s.kindAbstinenceDesc,
          },
        ),
        if (_kind == TaskKind.measure) ...[
          const SizedBox(height: 18),
          Text(
            context.s.rewardSystem,
            style: WayFonts.label(color: context.c.inkFaint, size: 9.5),
          ),
          const SizedBox(height: 7),
          BigSwitch<RewardCurve>(
            options: [
              BigSwitchOption(
                value: RewardCurve.linear,
                title: context.s.rewardLinear,
                caption: context.s.rewardLinearSub,
              ),
              BigSwitchOption(
                value: RewardCurve.exponential,
                title: context.s.rewardExp,
                caption: context.s.rewardExpSub,
              ),
            ],
            selected: _reward,
            onChanged: (r) => setState(() => _reward = r),
          ),
          const SizedBox(height: 12),
          ExplainBox(
            _reward == RewardCurve.linear
                ? context.s.rewardLinearDesc
                : context.s.rewardExpDesc,
          ),
          const SizedBox(height: 12),
          RewardCurvePreview(
            curve: _reward,
            target: _target,
          ),
          const SizedBox(height: 18),
          LabeledField(
            label: context.s.dailyTarget,
            controller: _targetCtrl,
            hint: context.s.targetHint,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
        ],
        if (_kind == TaskKind.abstinence) ...[
          const SizedBox(height: 18),
          Text(context.s.criticalPhase,
              style: WayFonts.label(color: context.c.inkFaint, size: 9.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final p in [(7, context.s.phaseShort), (14, context.s.phaseMedium), (30, context.s.phaseLong)])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _tau = p.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _tau == p.$1
                              ? context.c.accentTint
                              : context.c.surface2,
                          border: Border.all(
                              color: _tau == p.$1 ? context.c.accent : context.c.line),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${p.$2}\n${p.$1}gg',
                            textAlign: TextAlign.center,
                            style: WayFonts.mono(size: 10.5, color: context.c.inkSoft)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _KindOption extends StatelessWidget {
  const _KindOption({
    required this.title,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String caption;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? c.accentTint : c.surface2,
          border: Border.all(color: selected ? c.accent : c.line, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: WayFonts.ui(
                          size: 14, weight: FontWeight.w700,
                          color: selected ? c.accent : c.ink)),
                  Text(caption, style: WayFonts.mono(size: 10, color: c.inkFaint)),
                ],
              ),
            ),
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18, color: selected ? c.accent : c.inkFaint),
          ],
        ),
      ),
    );
  }
}
