import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../models/models.dart';
import 'fx_controller.dart';

/// Tre livelli di feedback, in scala con quello che l'utente ha ottenuto.
/// Chi chiama passa solo il fatto avvenuto: la regia decide quanto festeggiare.
class Reward {
  const Reward._();

  /// Livello 1 · soglia minima superata.
  static void threshold(FxController fx, Task task) {
    HapticFeedback.selectionClick();
    fx.notify(
      FxNotification(
        title: 'Obiettivo: ${task.name}',
        sub: 'Traguardo del giorno',
        iconKey: task.iconKey,
      ),
      hold: const Duration(milliseconds: 1700),
    );
  }

  /// Livello 2 · task completata. Il premio nasce dove hai toccato.
  static void taskDone(FxController fx, Task task, Offset? origin) {
    HapticFeedback.mediumImpact();
    if (origin != null) {
      fx.burst(FxBurst(origin: origin, count: 12, power: 300, spread: 2.0));
    }
    fx.notify(
      FxNotification(
        title: task.name,
        sub: 'Completata · LV${task.level}',
        iconKey: task.iconKey,
      ),
      hold: const Duration(milliseconds: 1800),
    );
  }

  /// Livello 3 · target del giorno. L'unico momento che prende il centro.
  static void dayDone(
    FxController fx, {
    required Offset? origin,
    required int percent,
    required int done,
    required int total,
    required int streak,
    required String placeName,
  }) {
    HapticFeedback.heavyImpact();
    fx.notify(
      const FxNotification(
        title: 'Giornata completata',
        sub: 'tutte le task chiuse',
        hype: true,
      ),
      hold: const Duration(milliseconds: 2600),
    );
    final from = origin ?? const Offset(200, 260);
    fx.burst(FxBurst(origin: from, count: 30, power: 430, spread: 2.4));
    Future.delayed(const Duration(milliseconds: 300), () {
      fx.burst(FxBurst(origin: from, count: 16, power: 360, spread: 2.6));
      fx.showCard(
        FxCard(
          kind: FxCardKind.day,
          eyebrow: 'Target di oggi',
          title: 'Giornata completata',
          bigValue: '$percent',
          bigSuffix: '%',
          stats: [
            '$done su $total task',
            if (streak >= 2) '$streak giorni di fila' else placeName,
          ],
        ),
        hold: const Duration(milliseconds: 2200),
      );
    });
  }

  /// Passaggio di livello: i coriandoli scendono dalla capsula, perche'
  /// e' da li' che arriva la notizia.
  static void levelUp(
    FxController fx,
    Task task,
    int fromLevel,
    Offset islandOrigin,
  ) {
    HapticFeedback.heavyImpact();
    fx.notify(
      FxNotification(
        title: '${task.name} sale a LV${task.level}',
        sub: 'Nuovo livello sbloccato',
        iconKey: task.iconKey,
        hype: true,
      ),
      hold: const Duration(milliseconds: 3000),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      fx.burst(FxBurst(
        origin: islandOrigin,
        count: 26,
        power: 210,
        spread: 2.9,
        angle: math.pi / 2,
        gravity: 0.5,
        life: 1.5,
      ));
    });
    Future.delayed(const Duration(milliseconds: 320), () {
      fx.showCard(
        FxCard(
          kind: FxCardKind.level,
          eyebrow: 'Passaggio di livello',
          title: task.name,
          fromLevel: 'LV$fromLevel',
          toLevel: 'LV${task.level}',
          stats: const ['Ora la task chiede di più'],
        ),
        hold: const Duration(milliseconds: 2500),
      );
    });
  }
}
