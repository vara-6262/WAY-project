import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dates.dart';
import '../data/glyphs.dart';
import '../models/app_data.dart';
import '../models/models.dart';
import '../state/providers.dart';
import '../theme/way_theme.dart';
import '../widgets/common.dart';
import '../widgets/day_flower.dart';
import 'wizard_scaffold.dart';

/// Suggerisce l'icona dal nome: nella maggior parte dei casi indovina, e
/// toglie un passaggio a chi sta creando la prima task della sua vita.
const _iconHints = <(String, String)>[
  (r'stud|esam|univ|less|corso|libri', 'book'),
  (r'legg|lettur|pagin|libro', 'paper'),
  (r'allen|palestr|sport|corsa|corr|gym|fitness|pesi', 'dumbbell'),
  (r'svegl|matt|alzar|orari|dormi|sonno', 'alarm'),
  (r'amic|social|usci|famigl|chiam', 'people'),
  (r'medit|calm|respir|yoga|natur', 'leaf'),
  (r'acqu|bere|idrat', 'drop'),
  (r'scriv|diari|nota|appunt', 'pen'),
  (r'cod|program|svilupp|lavoro', 'code'),
  (r'music|chitarr|pian|strument', 'music'),
  (r'cura|salut|medic|terap', 'heart'),
  (r'foto|video|scatt', 'camera'),
  (r'sera|notte|riposo', 'moon'),
];

String guessIcon(String name) {
  final n = name.trim();
  if (n.isEmpty) return 'book';
  for (final (pattern, key) in _iconHints) {
    if (RegExp(pattern, caseSensitive: false).hasMatch(n)) return key;
  }
  return 'target';
}

enum _Page { name, days, track, curve, amount, criteria }

/// Il percorso guidato della prima task.
///
/// Quattro schermate per una task binaria, sei se scegli Misura. Le
/// spiegazioni non hanno pagine proprie: stanno addosso alla scelta, cosi'
/// l'utente impara facendo invece di leggere un manuale.
class FirstRunTaskWizard extends ConsumerStatefulWidget {
  const FirstRunTaskWizard({super.key});

  @override
  ConsumerState<FirstRunTaskWizard> createState() => _FirstRunTaskWizardState();
}

class _FirstRunTaskWizardState extends ConsumerState<FirstRunTaskWizard> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  final _criterion = TextEditingController();

  _Page _page = _Page.name;
  final List<_Page> _history = [];

  String _iconKey = 'book';
  bool _iconTouched = false;
  bool _noteOpen = false;
  final List<int> _days = [];
  final List<Criterion> _criteria = [];
  TaskKind? _kind;
  RewardCurve _reward = RewardCurve.linear;
  final _targetCtrl = TextEditingController(text: '3');
  double get _target =>
      double.tryParse(_targetCtrl.text.replaceAll(',', '.')) ?? 1;

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _targetCtrl.dispose();
    _criterion.dispose();
    super.dispose();
  }

  /// Il percorso e' corto per le task binarie e si allunga solo se servono
  /// i numeri. La barra di avanzamento dice sempre la verita'.
  List<_Page> get _path => _kind == TaskKind.measure
      ? [_Page.name, _Page.days, _Page.track, _Page.curve, _Page.amount, _Page.criteria]
      : [_Page.name, _Page.days, _Page.track, _Page.criteria];

  void _goTo(_Page next) {
    setState(() {
      _history.add(_page);
      _page = next;
    });
  }

  void _back() {
    if (_history.isEmpty) return;
    setState(() => _page = _history.removeLast());
  }

  void _finish() {
    final task = Task(
      id: newId(),
      name: _name.text.trim(),
      iconKey: _iconKey,
      description: _note.text.trim(),
      days: (_days.toList()..sort()),
      criteria: List.of(_criteria),
      kind: _kind ?? TaskKind.complete,
      reward: _reward,
      target: _target,
      level: 0,
      streak: 0,
    );
    final ctrl = ref.read(appProvider.notifier);
    ctrl.addTask(task);
    ctrl.markEducation(criteria: true);
    ctrl.setStage(OnboardingStage.coreIntro);
    Navigator.of(context).pop();
    showToast(context, 'Task creata: ${task.name}');
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;
    final index = math.max(0, path.indexOf(_page));
    // L'uscita a meta' la gestisce chi ha aperto il wizard: qui non si
    // usa PopScope perche' il nome del suo callback cambia fra le
    // versioni di Flutter, e non vale un vincolo di versione.
    return WizardScaffold(
      stepIndex: index,
      stepCount: path.length,
      title: _title,
      subtitle: _subtitle,
      nextLabel: _nextLabel,
      onNext: _onNext,
      onBack: _history.isEmpty ? null : _back,
      body: _body(),
    );
  }

  String get _title => switch (_page) {
        _Page.name => 'Come si chiama?',
        _Page.days => 'Quando vale ${_name.text.trim()}?',
        _Page.track => 'Come la segni?',
        _Page.curve => 'Ogni unità in più vale uguale?',
        _Page.amount => 'Quanto ne vuoi fare?',
        _Page.criteria => 'Cosa vuol dire farla bene?',
      };

  String get _subtitle => switch (_page) {
        _Page.name => 'Il nome che te la fa riconoscere in un secondo.',
        _Page.days =>
          'Nei giorni che scegli WAY se l\'aspetta. Negli altri no, e la tua percentuale non ne risente.',
        _Page.track =>
          'Decide cosa WAY ti chiede ogni giorno. Puoi cambiarlo quando vuoi.',
        _Page.curve =>
          'Serve a WAY per capire quanto premiare quello che fai oltre la soglia.',
        _Page.amount =>
          'La soglia è il minimo che conta come giornata valida. Il target è la giornata piena, il 100%.',
        _Page.criteria =>
          'Facoltativo. Ogni condizione che aggiungi rende la task più impegnativa, e WAY lo tiene in conto.',
      };

  /// Nelle pagine di scelta l'azione sta nelle card: un pulsante primario
  /// in fondo sarebbe un doppione.
  String? get _nextLabel => switch (_page) {
        _Page.name => 'Continua',
        _Page.days => 'Continua',
        _Page.track => null,
        _Page.curve => null,
        _Page.amount => 'Continua',
        _Page.criteria =>
          _criteria.isEmpty ? 'Crea senza criteri' : 'Crea la task',
      };

  VoidCallback? get _onNext => switch (_page) {
        _Page.name =>
          _name.text.trim().isEmpty ? null : () => _goTo(_Page.days),
        _Page.days => _days.isEmpty ? null : () => _goTo(_Page.track),
        _Page.amount => () => _goTo(_Page.criteria),
        _Page.criteria => _finish,
        _ => null,
      };

  Widget _body() => switch (_page) {
        _Page.name => _nameBody(),
        _Page.days => _daysBody(),
        _Page.track => _trackBody(),
        _Page.curve => _curveBody(),
        _Page.amount => _amountBody(),
        _Page.criteria => _criteriaBody(),
      };

  // --- 1 · identita' --------------------------------------------------------

  Widget _nameBody() {
    final c = context.c;
    if (!_iconTouched) _iconKey = guessIcon(_name.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (_name.text.trim().isNotEmpty) _goTo(_Page.days);
          },
          style: WayFonts.ui(size: 17, weight: FontWeight.w700, color: c.ink),
          decoration: fieldDecoration(context, 'Studio, Allenamento, Lettura…'),
        ),
        const SizedBox(height: 18),
        Text('ICONA', style: WayFonts.label(color: c.inkFaint, size: 9.5)),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final key in taskIcons.keys)
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _iconKey = key;
                      _iconTouched = true;
                    }),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _iconKey == key ? c.accent : c.surface2,
                        border: Border.all(
                            color: _iconKey == key ? c.accent : c.line),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        taskIcon(key),
                        size: 19,
                        color: _iconKey == key ? c.accentInk : c.inkSoft,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () => setState(() => _noteOpen = !_noteOpen),
          child: Row(
            children: [
              Icon(_noteOpen ? Icons.remove : Icons.add,
                  size: 16, color: c.inkFaint),
              const SizedBox(width: 7),
              Text(
                _noteOpen ? 'Rimuovi la nota' : 'Aggiungi una nota',
                style: WayFonts.ui(
                  size: 12,
                  weight: FontWeight.w700,
                  color: c.inkFaint,
                ),
              ),
            ],
          ),
        ),
        if (_noteOpen) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            maxLines: 3,
            minLines: 2,
            style: WayFonts.ui(size: 13.5, color: c.ink),
            decoration: fieldDecoration(
              context,
              'Cosa intendi davvero con questa attività',
            ),
          ),
        ],
      ],
    );
  }

  // --- 2 · giorni -----------------------------------------------------------

  Widget _daysBody() {
    final all = _days.length == 7;
    final week = _days.length == 5 && [0, 1, 2, 3, 4].every(_days.contains);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ShortcutChip(
              label: 'Tutti i giorni',
              selected: all,
              onTap: () => setState(() {
                _days
                  ..clear()
                  ..addAll(all ? const <int>[] : [0, 1, 2, 3, 4, 5, 6]);
              }),
            ),
            const SizedBox(width: 8),
            ShortcutChip(
              label: 'Solo feriali',
              selected: week,
              onTap: () => setState(() {
                _days
                  ..clear()
                  ..addAll(week ? const <int>[] : [0, 1, 2, 3, 4]);
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: DayFlower(
            selected: _days,
            onToggle: (i) => setState(() {
              _days.contains(i) ? _days.remove(i) : _days.add(i);
            }),
            onToggleAll: () => setState(() {
              if (_days.length == 7) {
                _days.clear();
              } else {
                _days
                  ..clear()
                  ..addAll([0, 1, 2, 3, 4, 5, 6]);
              }
            }),
          ),
        ),
      ],
    );
  }

  // --- 3 · come si registra -------------------------------------------------

  Widget _trackBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoiceCard(
          icon: Icons.check_rounded,
          title: 'Fatta o non fatta',
          body: 'Ti basta una spunta a fine giornata.',
          tags: const ['Sveglia', 'Medicina', 'Stretching'],
          onTap: () {
            ref.read(appProvider.notifier).markEducation(complete: true);
            setState(() => _kind = TaskKind.complete);
            _goTo(_Page.criteria);
          },
        ),
        ChoiceCard(
          icon: Icons.show_chart_rounded,
          title: 'Conta quanto',
          body: 'Registri una quantità: ore, pagine, chilometri.',
          tags: const ['Studio', 'Lettura', 'Corsa'],
          onTap: () {
            ref.read(appProvider.notifier).markEducation(measure: true);
            setState(() => _kind = TaskKind.measure);
            _goTo(_Page.curve);
          },
        ),
      ],
    );
  }

  // --- 4 · curva (solo misura) ---------------------------------------------

  Widget _curveBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChoiceCard(
          leading: _CurveThumb(exponential: false),
          title: 'Sì, vale sempre uguale',
          body: 'La decima uscita con gli amici costa quanto la prima.',
          selected: _reward == RewardCurve.linear,
          onTap: () {
            setState(() => _reward = RewardCurve.linear);
            _goTo(_Page.amount);
          },
        ),
        ChoiceCard(
          leading: _CurveThumb(exponential: true),
          title: 'No, costa sempre di più',
          body: 'La quinta ora di studio pesa più della prima.',
          selected: _reward == RewardCurve.exponential,
          onTap: () {
            setState(() => _reward = RewardCurve.exponential);
            _goTo(_Page.amount);
          },
        ),
      ],
    );
  }

  // --- 5 · soglia e target --------------------------------------------------

  Widget _amountBody() {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('TARGET GIORNALIERO',
            style: WayFonts.label(color: c.inkFaint, size: 9.5)),
        const SizedBox(height: 8),
        TextField(
          controller: _targetCtrl,
          onChanged: (_) => setState(() {}),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: WayFonts.ui(size: 14.5, color: c.ink),
          decoration: fieldDecoration(context, 'es. 40, 5, 3...'),
        ),
        const SizedBox(height: 10),
        Text('La quantita\' che vale il 100% della giornata.',
            style: WayFonts.mono(size: 10.5, color: c.inkFaint)),
      ],
    );
  }

  Widget _scaleKey(
    BuildContext context,
    IconData icon,
    bool enabled,
    VoidCallback onTap,
  ) {
    final c = context.c;
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: c.surface3,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: c.ink),
          ),
        ),
      ),
    );
  }

  // --- 6 · criteri ----------------------------------------------------------

  Widget _criteriaBody() {
    final c = context.c;
    final n = _criteria.length;
    final difficulty = difficultyForCriteria(n);
    final colors = difficultyColors(context, difficulty);

    void add() {
      final v = _criterion.text.trim();
      if (v.isEmpty) return;
      setState(() {
        _criteria.add(Criterion(id: newId(), text: v));
        _criterion.clear();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: colors.bg,
            border: Border.all(color: colors.fg.withValues(alpha: 0.26)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 8; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i < math.min(n, 8) ? colors.fg : c.surface3,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(difficulty.label,
                      style: WayFonts.ui(
                          size: 12.5,
                          weight: FontWeight.w800,
                          color: colors.fg)),
                  Text(
                    n == 0 ? 'nessun criterio' : (n == 1 ? '1 criterio' : '$n criteri'),
                    style: WayFonts.mono(size: 10.5, color: c.inkFaint),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < _criteria.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 9, 6, 9),
              decoration: BoxDecoration(
                color: c.surface2,
                border: Border.all(color: c.lineSoft),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.surface3,
                      shape: BoxShape.circle,
                    ),
                    child: Text('${i + 1}',
                        style: WayFonts.mono(size: 9, color: c.inkFaint)),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _criteria[i].text,
                      style: WayFonts.ui(
                          size: 11.5, weight: FontWeight.w600, color: c.ink),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 17, color: c.inkFaint),
                    onPressed: () => setState(() => _criteria.removeAt(i)),
                    tooltip: 'Elimina criterio ${i + 1}',
                  ),
                ],
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _criterion,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => add(),
                style: WayFonts.ui(size: 13.5, color: c.ink),
                decoration:
                    fieldDecoration(context, 'Es. 45 minuti continuativi'),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: c.accent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: add,
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(Icons.add_rounded, color: c.accentInk),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Scala: 1–3 facile · 4–7 media · 8+ difficile',
          style: WayFonts.mono(size: 9.5, color: c.inkFaint),
        ),
      ],
    );
  }
}

/// Anteprima della curva dentro la card: si sceglie guardando la forma,
/// non leggendo la definizione.
class _CurveThumb extends StatelessWidget {
  const _CurveThumb({required this.exponential});

  final bool exponential;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 74,
      height: 40,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: c.surface3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: _CurvePainter(exponential: exponential, color: c.accent),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  const _CurvePainter({required this.exponential, required this.color});

  final bool exponential;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i <= 24; i++) {
      final x = i / 24;
      final y = exponential ? math.pow(x, 2.2).toDouble() : x;
      final p = Offset(x * size.width, size.height - y * size.height);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CurvePainter old) => old.exponential != exponential;
}

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: WayFonts.ui(
                      size: 12.5, weight: FontWeight.w700, color: c.ink)),
              Text(
                '${fmtNum(value)}${unit.isEmpty ? '' : ' $unit'}',
                style: WayFonts.mono(
                    size: 13, weight: FontWeight.w700, color: c.accent),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions > 0 ? divisions : null,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
