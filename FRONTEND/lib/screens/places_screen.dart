import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/packs.dart';

import '../data/glyphs.dart';
import '../l10n/strings.dart';
import '../models/app_data.dart';
import '../models/models.dart';
import '../fx/anchors.dart';
import '../sheets/sheets.dart';
import '../state/providers.dart';
import '../theme/way_theme.dart';
import '../widgets/common.dart';
import 'place_wizard.dart';
import 'wizard_scaffold.dart';

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
        ScreenHeader(eyebrow: context.s.placesEyebrow, title: context.s.placesTitle),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            children: [
              _PlaceHub(data: data, active: active),
              if (active != null) ...[
                const SizedBox(height: 10),
                GhostButton(
                  label: context.s.emptyHub,
                  onPressed: () {
                    ref.read(appProvider.notifier).clearActivePlace();
                    showToast(
                      context,
                      context.s.noActiveEnv,
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),
              const SectionLabel('I tuoi ambienti'),
              PrimaryButton(
                key: placeCreateKey,
                label: context.s.createEnv,
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
                EmptyStateBox(
                  icon: Icons.place_outlined,
                  title: context.s.noEnvironments,
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
              const SizedBox(height: 24),
              const _PacksSection(),
              const SizedBox(height: 14),
              Text(
                context.s.hubNote,
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
        showToast(context, context.s.activeEnv(details.data.name));
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
            painter: _ContourPainter(color: c.accentSoft.withValues(alpha: 0.5)),
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
                            context.s.dragHereEnv,
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
                            context.s.activeEnvCaps,
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
                  color: c.ink.withValues(alpha: 0.22),
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
                      Pill(context.s.active, fg: c.accent, bg: c.accentTint),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  context.s.placeLoad(load, place.useCore),
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


/// Sezione "Pacchetti" nella schermata Places: i pack applicati (con toggle di
/// sospensione e rimozione) e quelli disponibili (anteprima + aggiungi). I pack
/// sono sistemi di task che girano SOPRA l'ambiente attivo, e piu' pack possono
/// convivere.
class _PacksSection extends ConsumerWidget {
  const _PacksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appProvider);
    final lang = ref.watch(localeProvider);
    final applied = data.appliedPackIds;
    final available = habitPacks.where((p) => !applied.contains(p.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(context.s.packsSection),
        const SizedBox(height: 8),
        if (applied.isEmpty && available.isEmpty)
          const SizedBox.shrink(),
        for (final id in applied)
          if (habitPackById(id) != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AppliedPackCard(
                pack: habitPackById(id)!,
                count: data.tasksOfPack(id).length,
                paused: data.pausedPackIds.contains(id),
              ),
            ),
        for (final pack in available)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AvailablePackCard(pack: pack, lang: lang),
          ),
      ],
    );
  }
}

class _AppliedPackCard extends ConsumerWidget {
  const _AppliedPackCard(
      {required this.pack, required this.count, required this.paused});

  final HabitPack pack;
  final int count;
  final bool paused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final lang = ref.watch(localeProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: paused ? c.surface : c.surface2,
        border: Border.all(color: paused ? c.line : c.accentSoft),
        borderRadius: BorderRadius.circular(16),
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
            child: Icon(placeGlyph(pack.iconKey), size: 20, color: c.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(pack.name(lang),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WayFonts.ui(
                        size: 14, weight: FontWeight.w600, color: c.ink)),
                const SizedBox(height: 3),
                Text(
                  paused
                      ? context.s.packPaused
                      : context.s.packTaskCount(count),
                  style: WayFonts.mono(size: 10.5, color: c.inkFaint),
                ),
              ],
            ),
          ),
          Switch(
            value: !paused,
            onChanged: (_) =>
                ref.read(appProvider.notifier).togglePackPaused(pack.id),
          ),
          GestureDetector(
            onTap: () => _confirmRemove(context, ref, pack),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.delete_outline, size: 19, color: c.inkFaint),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref, HabitPack pack) {
    final lang = ref.read(localeProvider);
    showAppSheet<void>(
      context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.s.packRemoveTitle,
              style: WayFonts.display(size: 18, color: ctx.c.ink)),
          const SizedBox(height: 8),
          Text(context.s.packRemoveBody(pack.name(lang)),
              style: WayFonts.ui(size: 13, color: ctx.c.inkSoft)),
          const SizedBox(height: 16),
          PrimaryButton(
            label: context.s.packRemoveConfirm,
            color: ctx.c.hard,
            onPressed: () {
              ref.read(appProvider.notifier).removePack(pack.id);
              Navigator.of(ctx).pop();
              showToast(context, context.s.packRemoved(pack.name(lang)));
            },
          ),
          const SizedBox(height: 8),
          GhostButton(
            label: context.s.cancel,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}

class _AvailablePackCard extends ConsumerWidget {
  const _AvailablePackCard({required this.pack, required this.lang});

  final HabitPack pack;
  final AppLang lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return GestureDetector(
      onTap: () => showPackPreview(context, ref, pack),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(16),
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
              child: Icon(placeGlyph(pack.iconKey), size: 20, color: c.inkSoft),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pack.name(lang),
                      style: WayFonts.ui(
                          size: 14, weight: FontWeight.w600, color: c.ink)),
                  const SizedBox(height: 3),
                  Text(context.s.packTaskCount(pack.seeds.length),
                      style: WayFonts.mono(size: 10.5, color: c.inkFaint)),
                ],
              ),
            ),
            Pill(context.s.packPreview, fg: c.accent, bg: c.accentTint),
          ],
        ),
      ),
    );
  }
}

/// Anteprima di un pack: cosa contiene e come le task si sinergizzano, prima di
/// aggiungerlo.
void showPackPreview(BuildContext context, WidgetRef ref, HabitPack pack) {
  final lang = ref.read(localeProvider);
  showAppSheet<void>(
    context,
    builder: (ctx) {
      final c = ctx.c;
      String kindLabel(TaskKind k) => switch (k) {
            TaskKind.complete => ctx.s.kindComplete,
            TaskKind.measure => ctx.s.kindMeasure,
            TaskKind.maintenance => ctx.s.kindMaintain,
            TaskKind.abstinence => ctx.s.kindAbstinence,
          };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(placeGlyph(pack.iconKey), size: 20, color: c.accent),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(pack.name(lang),
                  style: WayFonts.display(size: 18, color: c.ink)),
            ),
          ]),
          const SizedBox(height: 12),
          ExplainBox(pack.description(lang)),
          const SizedBox(height: 16),
          Text(ctx.s.packContains,
              style: WayFonts.label(color: c.inkFaint, size: 9.5)),
          const SizedBox(height: 8),
          for (final seed in pack.seeds)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(taskIcon(seed.iconKey), size: 18, color: c.inkSoft),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(
                            child: Text(seed.name(lang),
                                style: WayFonts.ui(
                                    size: 13.5,
                                    weight: FontWeight.w700,
                                    color: c.ink)),
                          ),
                          const SizedBox(width: 7),
                          Pill(kindLabel(seed.kind),
                              fg: c.inkSoft, bg: c.surface2),
                        ]),
                        const SizedBox(height: 2),
                        Text(seed.role(lang),
                            style: WayFonts.mono(size: 10, color: c.inkFaint)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: ctx.s.packAdd,
            icon: Icons.add_rounded,
            onPressed: () {
              ref.read(appProvider.notifier).applyPack(pack);
              Navigator.of(ctx).pop();
              final conflicts =
                  ref.read(appProvider).anchorConflicts(pack.id);
              if (conflicts.isNotEmpty) {
                showPackConflicts(context, ref, pack.id);
              } else {
                showToast(context, context.s.packAdded(pack.name(lang)));
              }
            },
          ),
        ],
      );
    },
  );
}


/// Dialog di conflitto d'ancora: due o piu' task condividono lo stesso
/// anchorKey. L'utente sceglie quale tenere PRIMARIA; le altre si sopprimono
/// finche' il loro pack e' attivo.
void showPackConflicts(BuildContext context, WidgetRef ref, String packId) {
  final data = ref.read(appProvider);
  final conflicts = data.anchorConflicts(packId);
  if (conflicts.isEmpty) return;
  final lang = ref.read(localeProvider);
  final sel = <String, String>{
    for (final e in conflicts.entries)
      e.key: data.effectiveAnchorTaskId(e.key) ?? e.value.first.id,
  };

  showAppSheet<void>(
    context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) {
        final c = ctx.c;
        Widget candidate(String anchorKey, Task t) {
          final chosen = sel[anchorKey] == t.id;
          final packName =
              t.packId != null ? (habitPackById(t.packId!)?.name(lang) ?? '') : '';
          return GestureDetector(
            onTap: () => setLocal(() => sel[anchorKey] = t.id),
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: chosen ? c.accentTint : c.surface2,
                border: Border.all(color: chosen ? c.accent : c.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                      chosen
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 18,
                      color: chosen ? c.accent : c.inkFaint),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.name,
                            style: WayFonts.ui(
                                size: 13.5,
                                weight: FontWeight.w700,
                                color: c.ink)),
                        if (packName.isNotEmpty)
                          Text(packName,
                              style:
                                  WayFonts.mono(size: 10, color: c.inkFaint)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ctx.s.anchorConflictTitle,
                style: WayFonts.display(size: 18, color: c.ink)),
            const SizedBox(height: 6),
            Text(ctx.s.anchorConflictBody,
                style: WayFonts.ui(size: 12.5, color: c.inkSoft)),
            const SizedBox(height: 16),
            for (final e in conflicts.entries) ...[
              Text(e.value.first.name.toUpperCase(),
                  style: WayFonts.label(color: c.inkFaint, size: 9.5)),
              const SizedBox(height: 8),
              for (final t in e.value) candidate(e.key, t),
              const SizedBox(height: 8),
            ],
            PrimaryButton(
              label: ctx.s.confirm,
              onPressed: () {
                final notifier = ref.read(appProvider.notifier);
                sel.forEach(notifier.setAnchorPrimary);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    ),
  );
}
