import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:way/fx/fx_controller.dart';

import '../fx/reward.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../theme/way_theme.dart';
import '../widgets/common.dart';
import '../widgets/domain_editor.dart';
import 'wizard_scaffold.dart';

/// Evoluzione di una task: upgrade (sali di livello / mantieni / trasforma) o
/// riconfigurazione dopo fallimenti (con downgrade opzionale). In entrambi si
/// possono ridefinire requisiti e dominio.
class TaskEvolutionScreen extends ConsumerStatefulWidget {
  const TaskEvolutionScreen({super.key, required this.taskId, required this.mode});

  final String taskId;
  final String mode; // 'upgrade' | 'reconfig'

  @override
  ConsumerState<TaskEvolutionScreen> createState() => _TaskEvolutionScreenState();
}

class _TaskEvolutionScreenState extends ConsumerState<TaskEvolutionScreen> {
  late final List<TextEditingController> _reqs;
  late final Set<int> _days;
  late DomainPeriod _period;
  late int _start;
  late int _end;
  late final TextEditingController _target;
  bool _toNumber = false;
  bool _downgrade = false;
  bool _init = false;

  Task? get _task {
    for (final t in ref.read(appProvider).tasks) {
      if (t.id == widget.taskId) return t;
    }
    return null;
  }

  void _initFrom(Task t) {
    _reqs = [
      for (final c in t.criteria) TextEditingController(text: c.text),
    ];
    if (_reqs.isEmpty) _reqs.add(TextEditingController());
    _days = {...t.days};
    _period = t.period;
    _start = t.start;
    _end = t.end;
    _target = TextEditingController(
        text: t.target % 1 == 0 ? t.target.toStringAsFixed(0) : '${t.target}');
    _init = true;
  }

  @override
  void dispose() {
    if (_init) {
      for (final c in _reqs) {
        c.dispose();
      }
      _target.dispose();
    }
    super.dispose();
  }

  List<String> get _reqTexts =>
      _reqs.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

  double? get _targetVal =>
      double.tryParse(_target.text.replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = _task;
    if (t == null) {
      return const Scaffold(body: SafeArea(child: SizedBox.shrink()));
    }
    if (!_init) _initFrom(t);

    final upgrade = widget.mode == 'upgrade';
    final showTarget = t.kind == TaskKind.measure || _toNumber;

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
                        Text(upgrade ? 'LEVEL UP' : 'RICONFIGURA',
                            style: WayFonts.label(color: c.inkFaint, size: 9.5)),
                        const SizedBox(height: 2),
                        Text(t.name, style: WayFonts.display(size: 21, color: c.ink)),
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
                  ExplainBox(upgrade
                      ? 'Sali di livello ridefinendo requisiti e dominio (piu impegnativa), oppure Mantieni per fermare la crescita del bonus senza cambiare livello.'
                      : 'Tre fallimenti di fila: ridefinisci per renderla sostenibile. Il downgrade e opzionale.'),
                  const SizedBox(height: 16),
                  if (t.kind == TaskKind.complete && upgrade) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Trasforma in misura',
                          style: WayFonts.ui(size: 13.5, color: c.ink)),
                      subtitle: Text('Da fatto/non fatto a quantita; eredita i requisiti.',
                          style: WayFonts.mono(size: 9.5, color: c.inkFaint)),
                      value: _toNumber,
                      onChanged: (v) => setState(() => _toNumber = v),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text('REQUISITI', style: WayFonts.label(color: c.inkFaint, size: 9.5)),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _reqs.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Expanded(
                          child: LabeledField(
                            label: 'Requisito ${i + 1}',
                            controller: _reqs[i],
                            hint: 'condizione...',
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() {
                            if (_reqs.length > 1) _reqs.removeAt(i);
                          }),
                          child: Icon(Icons.close, size: 18, color: c.inkFaint),
                        ),
                      ]),
                    ),
                  GestureDetector(
                    onTap: () => setState(() => _reqs.add(TextEditingController())),
                    child: Text('+ aggiungi requisito',
                        style: WayFonts.ui(size: 12.5, weight: FontWeight.w700, color: c.accent)),
                  ),
                  if (showTarget) ...[
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Target giornaliero',
                      controller: _target,
                      hint: 'es. 3',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                  const SizedBox(height: 18),
                  DomainEditor(
                    days: _days.toList()..sort(),
                    period: _period,
                    start: _start,
                    end: _end,
                    onToggleDay: (i) => setState(() {
                      _days.contains(i) ? _days.remove(i) : _days.add(i);
                    }),
                    onPeriod: (p) => setState(() => _period = p),
                    onStart: (h) => setState(() => _start = h),
                    onEnd: (h) => setState(() => _end = h),
                  ),
                  if (!upgrade && t.level > 0) ...[
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Scendi di livello (-1)',
                          style: WayFonts.ui(size: 13.5, color: c.ink)),
                      value: _downgrade,
                      onChanged: (v) => setState(() => _downgrade = v),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.lineSoft)),
              ),
              child: upgrade
                  ? Row(children: [
                      Expanded(
                        child: GhostButton(
                          label: 'Mantieni',
                          onPressed: () {
                            ref.read(appProvider.notifier).keepTask(t);
                            Navigator.of(context).maybePop();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Sali di livello',
                          onPressed: () {
                            final from = t.level;
                            ref.read(appProvider.notifier).applyUpgrade(
                                  t,
                                  requirements: _reqTexts,
                                  days: _days.toList()..sort(),
                                  start: _start,
                                  end: _end,
                                  period: _period,
                                  target: showTarget ? _targetVal : null,
                                  toNumber: _toNumber,
                                );
                            final updated = ref.read(appProvider).tasks.firstWhere(
                                  (x) => x.id == t.id,
                                  orElse: () => t,
                                );
                            final size = MediaQuery.of(context).size;
                            Reward.levelUp(ref.read(fxProvider), updated, from,
                                Offset(size.width / 2, size.height / 2));
                            Navigator.of(context).maybePop();
                          },
                        ),
                      ),
                    ])
                  : PrimaryButton(
                      label: 'Conferma',
                      onPressed: () {
                        ref.read(appProvider.notifier).applyReconfig(
                              t,
                              requirements: _reqTexts,
                              days: _days.toList()..sort(),
                              start: _start,
                              end: _end,
                              period: _period,
                              target: t.kind == TaskKind.measure ? _targetVal : null,
                              downgrade: _downgrade,
                            );
                        Navigator.of(context).maybePop();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
