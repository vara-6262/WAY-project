import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fx/anchors.dart';
import '../models/app_data.dart';
import '../screens/shell.dart';
import '../state/providers.dart';
import '../theme/way_colors.dart';
import '../theme/way_theme.dart';

/// Il riflettore del primo utilizzo.
///
/// Ritaglia un buco sull'elemento vero invece di clonarlo: quattro
/// pannelli scuri intorno bloccano i tocchi, il buco resta libero e sotto
/// c'e' il pulsante autentico, con i suoi gestori. Niente copie, niente
/// doppioni della chiamata all'azione.
class OnboardingOverlay extends ConsumerStatefulWidget {
  const OnboardingOverlay({super.key});

  @override
  ConsumerState<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends ConsumerState<OnboardingOverlay> {
  Rect? _rect;
  OnboardingStage? _measured;

  void _scheduleMeasure(OnboardingStage stage, GlobalKey target) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final r = rectOf(target);
      if (r == null) {
        // Il bersaglio non e' ancora in albero: riprovo al frame dopo.
        _scheduleMeasure(stage, target);
        return;
      }
      if (_rect != r || _measured != stage) {
        setState(() {
          _rect = r;
          _measured = stage;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(tutorialActiveProvider);
    final stage = ref.watch(onboardingProvider).stage;
    final data = ref.watch(appProvider);
    final ctrl = ref.read(appProvider.notifier);
    final c = context.c;

    if (!active) return const SizedBox.shrink();

    final step = _stepFor(stage, data, ctrl);
    if (step == null) return const SizedBox.shrink();

    // Ogni tappa vive su una schermata precisa.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      shellKey.currentState?.goTo(step.tab, animate: false);
    });
    _scheduleMeasure(stage, step.target);

    final rect = _measured == stage ? _rect : null;
    if (rect == null) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;
    const pad = 7.0;
    final hole = Rect.fromLTRB(
      (rect.left - pad).clamp(0.0, size.width),
      (rect.top - pad).clamp(0.0, size.height),
      (rect.right + pad).clamp(0.0, size.width),
      (rect.bottom + pad).clamp(0.0, size.height),
    );
    // Il testo sta dalla parte opposta al buco, cosi' non lo copre mai.
    final copyAtTop = hole.center.dy > size.height * 0.52;

    return Stack(
      children: [
        _dim(Rect.fromLTRB(0, 0, size.width, hole.top)),
        _dim(Rect.fromLTRB(0, hole.bottom, size.width, size.height)),
        _dim(Rect.fromLTRB(0, hole.top, hole.left, hole.bottom)),
        _dim(Rect.fromLTRB(hole.right, hole.top, size.width, hole.bottom)),
        Positioned.fromRect(
          rect: hole,
          child: IgnorePointer(
            child: _PulseRing(live: step.targetIsAction),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          top: copyAtTop ? 90 : null,
          bottom: copyAtTop ? null : 104,
          child: _CopyPanel(
            kicker: step.kicker,
            title: step.title,
            body: step.body,
            pointLabel: step.targetIsAction ? step.pointLabel : null,
            pointUp: !copyAtTop,
            actions: step.actions,
          ),
        ),
      ],
    );
  }

  Widget _dim(Rect r) => Positioned.fromRect(
        rect: r,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: const ColoredBox(color: Color(0xDB050504)),
        ),
      );

  _Step? _stepFor(OnboardingStage stage, AppData data, AppController ctrl) {
    switch (stage) {
      case OnboardingStage.taskIntro:
        return _Step(
          tab: 1,
          target: taskCreateKey,
          kicker: 'Primo utilizzo',
          title: 'Partiamo da una cosa sola',
          body:
              'Scegli un’attività che vuoi rendere parte delle tue giornate. '
              'Bastano tre domande: il resto lo costruiamo dopo, insieme.',
          targetIsAction: true,
          pointLabel: 'Tocca “Crea una nuova task”',
          actions: [
            _Action('Salta il tutorial', ctrl.finishOnboarding, ghost: true),
          ],
        );
      case OnboardingStage.coreIntro:
        return _Step(
          tab: 1,
          target: coreHubKey,
          kicker: 'La base della tua routine',
          title: 'Questa è la tua Core Session',
          body:
              'Le task che metti qui ti seguono ovunque. Quando cambi ambiente '
              'restano con te, salvo che tu decida il contrario.',
          actions: [
            _Action('Mettici la task', () {
              final first = data.tasks.isNotEmpty ? data.tasks.first : null;
              if (first != null) ctrl.addToCore(first.id);
              ctrl.setStage(OnboardingStage.placesInvite);
            }),
            _Action(
              'Non ora',
              () => ctrl.setStage(OnboardingStage.placesInvite),
              ghost: true,
            ),
          ],
        );
      case OnboardingStage.placesInvite:
        return _Step(
          tab: 1,
          target: placesTabKey,
          kicker: 'Facoltativo',
          title: 'La tua routine cambia con te',
          body:
              'A casa, in trasferta o in vacanza una buona giornata non chiede '
              'le stesse cose. Gli ambienti servono a questo.',
          actions: [
            _Action(
              'Vediamo Places',
              () => ctrl.setStage(OnboardingStage.placeIntro),
            ),
            _Action('Ho finito', ctrl.finishOnboarding, ghost: true),
          ],
        );
      case OnboardingStage.placeIntro:
        return _Step(
          tab: 2,
          target: placeCreateKey,
          kicker: 'Primo utilizzo',
          title: 'Crea il tuo primo ambiente',
          body:
              'Un ambiente decide quali task valgono mentre sei lì. Puoi '
              'portarti dietro la Core Session e aggiungere solo ciò che serve.',
          targetIsAction: true,
          pointLabel: 'Tocca “Crea un ambiente”',
          actions: [_Action('Ho finito', ctrl.finishOnboarding, ghost: true)],
        );
      case OnboardingStage.taskWizard:
      case OnboardingStage.placeWizard:
      case OnboardingStage.done:
        return null;
    }
  }
}

class _Step {
  const _Step({
    required this.tab,
    required this.target,
    required this.kicker,
    required this.title,
    required this.body,
    this.targetIsAction = false,
    this.pointLabel = '',
    this.actions = const [],
  });

  final int tab;
  final GlobalKey target;
  final String kicker;
  final String title;
  final String body;
  final bool targetIsAction;
  final String pointLabel;
  final List<_Action> actions;
}

class _Action {
  const _Action(this.label, this.onTap, {this.ghost = false});

  final String label;
  final VoidCallback onTap;
  final bool ghost;
}

/// L'invito pulsa tre volte e poi si ferma: un richiamo infinito diventa
/// rumore e rende piu' difficile centrare il tocco.
class _PulseRing extends StatefulWidget {
  const _PulseRing({required this.live});

  final bool live;

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.live) {
      _c.repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 4500), () {
        if (mounted) _c.animateTo(0);
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.c.accent;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent, width: 2),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.10 + 0.10 * _c.value),
              blurRadius: 0,
              spreadRadius: 3 + 6 * _c.value,
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyPanel extends StatelessWidget {
  const _CopyPanel({
    required this.kicker,
    required this.title,
    required this.body,
    required this.pointLabel,
    required this.pointUp,
    required this.actions,
  });

  final String kicker;
  final String title;
  final String body;
  final String? pointLabel;
  final bool pointUp;
  final List<_Action> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xF7100F0A),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.48),
              blurRadius: 48,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              kicker.toUpperCase(),
              style: WayFonts.mono(
                size: 9,
                weight: FontWeight.w700,
                color: c.advice,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(title, style: WayFonts.display(size: 18, color: c.ink)),
            const SizedBox(height: 6),
            Text(body, style: WayFonts.ui(size: 12, color: c.inkSoft)),
            if (pointLabel != null) ...[
              const SizedBox(height: 11),
              Row(
                children: [
                  Icon(
                    pointUp
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: c.accent,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      pointLabel!,
                      style: WayFonts.ui(
                        size: 11,
                        weight: FontWeight.w700,
                        color: c.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Flexible(
                      flex: actions[i].ghost ? 0 : 1,
                      child: _panelButton(c, actions[i]),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _panelButton(WayColors c, _Action a) {
    return Material(
      color: a.ghost ? Colors.transparent : c.accent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: a.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            border: Border.all(color: a.ghost ? c.line : c.accent),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            a.label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
            style: WayFonts.ui(
              size: 13,
              weight: FontWeight.w800,
              color: a.ghost ? c.ink : c.accentInk,
            ),
          ),
        ),
      ),
    );
  }
}
