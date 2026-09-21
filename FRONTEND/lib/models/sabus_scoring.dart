import 'dart:math' as math;

import '../data/dates.dart';
import 'app_data.dart';
import 'models.dart';

/// Logica di punteggio di Sabus, iniettata sul modello di WAY (additiva):
/// punti con moltiplicatore di livello, number nerfato (al target = 0.5*target;
/// l'esponenziale premia le unità e accelera oltre il target), bonus da streak,
/// e streak DERIVATO dal log. Non tocca percentOf/dayScore esistenti.
// ---- Costanti number (tarabili) ----
const double _linPerUnit = 0.5; // punti per unità del lineare
const double _expBase = 0.85;   // punti per unità BASE dell'esponenziale (~ una checklist)
const double _expAccel = 0.12;  // quanto cresce ogni unità successiva
// ---- Costanti astinenza ----
const double _absFloor = 0.3;   // reward minimo di mantenimento
const double _absPeak = 3.0;    // reward massimo al picco della campana

double _linPoints(double v, double mult) => _linPerUnit * mult * v;
double _expPoints(double v, double mult) =>
    mult * (_expBase * v + _expAccel * v * (v - 1) / 2);

/// Campana dell'astinenza: cresce nella fase critica (picco a n=tau), poi cala.
double _bell(int n, int tau, double mult) {
  final x = tau <= 0 ? 0.0 : n / tau;
  return mult * (_absFloor + _absPeak * x * math.exp(1 - x));
}

extension SabusScoring on AppData {
  static const double numK = 0.5;

  // Soglie del ciclo di vita
  static const int upThreshold = 14; // successi per l'upgrade
  static const int failThreshold = 3; // fallimenti per la riconfigurazione
  static const double absEndK = 3.0; // fine astinenza a ~absEndK * tau

  bool upgradeReady(Task t) =>
      t.kind != TaskKind.abstinence && !t.archived && t.succ >= upThreshold;
  bool reconfigReady(Task t) =>
      t.kind != TaskKind.abstinence && !t.archived && t.fail >= failThreshold;
  bool abstinenceConcluded(Task t) =>
      t.kind == TaskKind.abstinence &&
      !t.archived &&
      derivedStreak(t) >= (absEndK * t.tau).round();

  double sabusMult(Task t) => 1 + 0.5 * t.level; // livello 0 = base

  /// Il giorno "conta" (streak): complete = fatto; measure = raggiunta la soglia.
  bool taskCounts(Task t, DateTime day) {
    final v = valueOf(t, day);
    if (t.kind == TaskKind.complete) return v > 0;
    if (t.kind == TaskKind.maintenance) return v == 0; // intatta
    if (t.kind == TaskKind.abstinence) return v == 0; // pulita
    return v >= t.target; // measure
  }

  /// Punti attesi completando al target (denominatore della percentuale).
  double expectedAtTarget(Task t) {
    final m = sabusMult(t);
    if (t.kind == TaskKind.complete) return m;
    if (t.kind == TaskKind.maintenance) return m;
    if (t.kind == TaskKind.abstinence) return _bell(derivedStreak(t), t.tau, m);
    return t.reward == RewardCurve.exponential
        ? _expPoints(t.target, m)
        : _linPoints(t.target, m);
  }

  /// Punti effettivi del giorno. Sotto soglia = 0; al target = numK*target;
  /// oltre, l'esponenziale accelera. Premia ogni unità (base lineare).
  double taskPoints(Task t, DateTime day) {
    final m = sabusMult(t);
    final v = valueOf(t, day);
    if (t.kind == TaskKind.complete) return v > 0 ? m : 0.0;
    if (t.kind == TaskKind.maintenance) return v == 0 ? m : 0.0;
    if (t.kind == TaskKind.abstinence) {
      return v == 0 ? _bell(derivedStreak(t, asOf: day), t.tau, m) : 0.0;
    }
    if (t.target <= 0) return 0.0;
    return t.reward == RewardCurve.exponential ? _expPoints(v, m) : _linPoints(v, m);
  }

  /// Streak reale: occorrenze consecutive "contate" dal log, da ieri all'indietro.
  int derivedStreak(Task t, {DateTime? asOf}) {
    final ref = Dates.dayOf(asOf ?? DateTime.now());
    final floor = t.streakSince;
    var day = Dates.addDays(ref, -1);
    var streak = 0;
    for (var i = 0; i < 400; i++) {
      if (floor != null && day.isBefore(Dates.dayOf(floor))) break;
      if (t.activeOn(day)) {
        if (taskCounts(t, day)) {
          streak++;
        } else {
          break;
        }
      }
      day = Dates.addDays(day, -1);
    }
    return streak;
  }

  double dayPoints(DateTime day) {
    var sum = 0.0;
    for (final t in tasksFor(day)) {
      sum += taskPoints(t, day);
    }
    return sum;
  }

  double expectedPointsFor(DateTime day) {
    var sum = 0.0;
    for (final t in tasksFor(day)) {
      sum += expectedAtTarget(t);
    }
    return sum;
  }

  /// Bonus del giorno (frazione): somma di min(streak,30)*(level+1)*0.02 per streak>=3.
  double dayBonusFraction(DateTime day) {
    var b = 0.0;
    for (final t in tasksFor(day)) {
      final s = derivedStreak(t, asOf: day);
      if (s >= 3) {
        final capped = s > 30 ? 30 : s;
        b += capped * (t.level + 1) * 0.02;
      }
    }
    return b;
  }

  /// Percentuale Sabus del giorno = punti*(1+bonus)/attesi*100 (può superare 100).
  int? dayPercentSabus(DateTime day) {
    final exp = expectedPointsFor(day);
    if (exp <= 0) return null;
    final base = ledger[Dates.key(day)] ?? dayPoints(day);
    final total = base * (1 + dayBonusFraction(day));
    return (total / exp * 100).round();
  }

  /// Serie giornaliera del valore registrato per una task (per il plot dei number).
  /// null sui giorni in cui la task non è prevista.
  List<double?> valueSeries(Task t, List<DateTime> days) => [
        for (final d in days) t.activeOn(d) ? valueOf(t, d) : null,
      ];

  /// Forza 0–100 di una task (per "in salute / da curare").
  int taskStrength(Task t) {
    final streak = derivedStreak(t);
    var s = 0.0;
    s += (streak > 14 ? 14 : streak) / 14 * 45;
    s += (t.level > 6 ? 6 : t.level) / 6 * 25;
    s += streak > 0 ? 15 : 0;
    s += (streak >= 20 ? 15 : 0);
    return s.clamp(0, 100).round();
  }
}
