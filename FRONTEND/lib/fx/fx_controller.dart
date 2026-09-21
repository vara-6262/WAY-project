import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifica che compare nella capsula in cima allo schermo.
class FxNotification {
  const FxNotification({
    required this.title,
    this.sub = '',
    this.iconKey,
    this.hype = false,
  });

  final String title;
  final String sub;

  /// Chiave dell'icona task; null usa la spunta.
  final String? iconKey;

  /// Eventi importanti: la capsula respira e un lampo la attraversa.
  final bool hype;
}

enum FxCardKind { day, level }

/// Il cartellino di riconoscimento. Compare una volta al giorno per il
/// target, e a ogni passaggio di livello.
class FxCard {
  const FxCard({
    required this.kind,
    required this.eyebrow,
    required this.title,
    this.bigValue,
    this.bigSuffix,
    this.fromLevel,
    this.toLevel,
    this.stats = const [],
  });

  final FxCardKind kind;
  final String eyebrow;
  final String title;
  final String? bigValue;
  final String? bigSuffix;
  final String? fromLevel;
  final String? toLevel;

  /// Riga di dati sotto il titolo, gia' formattati.
  final List<String> stats;
}

class FxBurst {
  const FxBurst({
    required this.origin,
    required this.count,
    required this.power,
    required this.spread,
    this.angle = -1.5707963,
    this.gravity = 1,
    this.life = 1,
  });

  final Offset origin;
  final int count;
  final double power;
  final double spread;
  final double angle;
  final double gravity;
  final double life;
}

/// Regia del feedback. Non disegna niente: raccoglie le richieste e le
/// espone a chi le sa dipingere, cosi' le schermate non sanno nulla di
/// particelle e di capsule.
class FxController extends ChangeNotifier {
  FxNotification? _notification;
  FxCard? _card;
  final List<FxBurst> _pending = [];

  Timer? _notifyTimer;
  Timer? _cardTimer;

  FxNotification? get notification => _notification;
  FxCard? get card => _card;

  /// Chi dipinge le particelle svuota questa coda e la consuma.
  List<FxBurst> drainBursts() {
    if (_pending.isEmpty) return const [];
    final out = List<FxBurst>.of(_pending);
    _pending.clear();
    return out;
  }

  bool get hasPendingBursts => _pending.isNotEmpty;

  void notify(FxNotification n, {Duration hold = const Duration(milliseconds: 2200)}) {
    _notification = n;
    notifyListeners();
    _notifyTimer?.cancel();
    _notifyTimer = Timer(hold, () {
      _notification = null;
      notifyListeners();
    });
  }

  void showCard(FxCard c, {Duration hold = const Duration(milliseconds: 2200)}) {
    _card = c;
    notifyListeners();
    _cardTimer?.cancel();
    _cardTimer = Timer(hold, () {
      _card = null;
      notifyListeners();
    });
  }

  void burst(FxBurst b) {
    _pending.add(b);
    notifyListeners();
  }

  void dismissCard() {
    _cardTimer?.cancel();
    _card = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _notifyTimer?.cancel();
    _cardTimer?.cancel();
    super.dispose();
  }
}

final fxProvider = Provider<FxController>((ref) {
  final c = FxController();
  ref.onDispose(c.dispose);
  return c;
});
