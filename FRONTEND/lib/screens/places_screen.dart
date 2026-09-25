import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/glyphs.dart';
import '../models/app_data.dart';
import '../models/models.dart';
import '../fx/anchors.dart';
import '../models/app_data.dart' show OnboardingStage;
import '../sheets/sheets.dart';
import '../state/providers.dart';
import '../theme/way_theme.dart';
import '../widgets/common.dart';
import 'place_wizard.dart';

/// Places: un solo ambiente per volta puo' stare nell'hub, e quello decide
/// il carico rispetto a cui vengono misurate le giornate.
class PlacesScreen extends ConsumerWidget {
  const PlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appProvider);
    final active = data.activePlace;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ScreenHeader(eyebrow: 'Contesto', title: 'Places'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            children: [
              _PlaceHub(data: data, active: active),
              if (active != null) ...[
                const SizedBox(height: 10),
                GhostButton(
                  label: 'Svuota l\'hub',
                  onPressed: () {
                    ref.read(appProvider.notifier).clearActivePlace();
                    showToast(
                      context,
                      'Nessun ambiente attivo: resta solo la core session',
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),
              const SectionLabel('I tuoi ambienti'),
              PrimaryButton(
                key: placeCreateKey,
                label: 'Crea un ambiente',
                icon: Icons.add_rounded,
                onPressed: () {
                  final guided = ref.read(tutorialActiveProvider) &&
                      ref.read(onboardingProvider).stage ==
                          OnboardingStage.placeIntro;
                  if (guided) {
                    ref
                        .read(appProvider.notifier)
                        .setStage(OnboardingStage.placeWizard);
                  }
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(
                    builder: (_) => PlaceWizard(guided: guided),
                  ))
                      .then((_) {
                    if (ref.read(onboardingProvider).stage ==
                        OnboardingStage.placeWizard) {
                      ref
                          .read(appProvider.notifier)
                          .setStage(OnboardingStage.placeIntro);
                    }
                  });
                },
              ),
              const SizedBox(height: 10),
              if (data.places.isEmpty)
                const EmptyStateBox(
                  icon: Icons.place_outlined,
                  title: 'Nessun ambiente',
                  body:
                      'Un ambiente e\' un carico di lavoro che ha senso in un posto e in un periodo. Senza ambienti resta attiva solo la core session.',
                ),
              for (final place in data.places)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DraggablePlaceCard(
                    place: place,
                    isActive: place.id == data.activePlaceId,
                    load: data.loadOf(place),
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                'Un solo ambiente per volta puo\' stare nell\'hub. Le statistiche si adattano al carico dell\'ambiente attivo, non a un carico fisso.',
                style: WayFonts.ui(size: 12.5, color: context.c.inkSoft),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaceHub extends ConsumerWidget {
  const _PlaceHub({required this.data, required this.active});

  final AppData data;
  final Place? active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return DragTarget<Place>(
      onWillAcceptWithDetails: (details) => details.data.id != data.activePlaceId,
      onAcceptWithDetails: (details) {
        ref.read(appProvider.notifier).activatePlace(details.data.id);
        showToast(context, 'Ambiente attivo: ${details.data.name}');
      },
      builder: (context, candidate, rejected) {
        final hot = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 186,
          decoration: BoxDecoration(
            color: hot ? c.accentTint : c.surface2,
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: _ContourPainter(color: c.accentSoft.withOpacity(0.5)),
            foregroundPainter: _HubBorderPainter(
              color: hot ? c.accent : c.accentSoft,
              solid: hot,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: active == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hub vuoto',
                            style: WayFonts.display(size: 19, color: c.inkFaint),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'TRASCINA QUI UN AMBIENTE',
                            style: WayFonts.label(color: c.inkFaint, size: 9.5),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(placeGlyph(active!.glyphKey), size: 20, color: c.ink),
                              const SizedBox(width: 9),
                              Flexible(
                                child: Text(
                                  active!.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: WayFonts.display(size: 19, color: c.ink),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${data.loadOf(active!)} task in carico',
                            style: WayFonts.ui(size: 12, color: c.inkSoft),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'AMBIENTE ATTIVO',
                            style: WayFonts.label(color: c.inkFaint, size: 9.5),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ContourPainter extends CustomPainter {
  const _ContourPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 5; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: (52 + i * 40) * 2,
          height: (30 + i * 24) * 2,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ContourPainter old) => old.color != color;
}

class _HubBorderPainter extends CustomPainter {
  const _HubBorderPainter({required this.color, required this.solid});

  final Color color;
  final bool solid;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = solid ? 1.6 : 1.3;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );
    if (solid) {
      canvas.drawRRect(rrect, paint);
      return;
    }
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 6;
        canvas.drawPath(
          metric.extractPath(distance, math.min(next, metric.length)),
          paint,
        );
        distance = next + 5;
      }
    }
  }

  @override
  bool shouldRepaint(_HubBorderPainter old) =>
      old.color != color || old.solid != solid;
}

class _DraggablePlaceCard extends ConsumerWidget {
  const _DraggablePlaceCard({
    required this.place,
    required this.isActive,
    required this.load,
  });

  final Place place;
  final bool isActive;
  final int load;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width - 36;
    final card = _PlaceCard(place: place, isActive: isActive, load: load);

    return LongPressDraggable<Place>(
      data: place,
      delay: const Duration(milliseconds: 300),
      hapticFeedbackOnStart: true,
      feedback: SizedBox(
        width: width,
        child: Material(
          color: Colors.transparent,
          child: Transform.rotate(
            angle: -0.024,
            child: _PlaceCard(
              place: place,
              isActive: isActive,
              load: load,
              elevated: true,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: card),
      child: GestureDetector(
        onTap: () => showPlaceDetailSheet(context, ref, place),
        child: card,
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.isActive,
    required this.load,
    this.elevated = false,
  });

  final Place place;
  final bool isActive;
  final int load;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.accentTint, c.surface],
                stops: const [0, 0.7],
              )
            : null,
        color: isActive ? null : c.surface,
        border: Border.all(color: isActive || elevated ? c.accent : c.line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: c.ink.withOpacity(0.22),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(placeGlyph(place.glyphKey), size: 20, color: c.accent),
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
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WayFonts.ui(
                          size: 14,
                          weight: FontWeight.w600,
                          color: c.ink,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 7),
                      Pill('Attivo', fg: c.accent, bg: c.accentTint),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$load task · core session ${place.useCore ? 'attiva' : 'disattivata'}',
                  style: WayFonts.mono(size: 10.5, color: c.inkFaint),
                ),
              ],
            ),
          ),
          Icon(Icons.drag_indicator, size: 20, color: c.inkFaint),
        ],
      ),
    );
  }
}
