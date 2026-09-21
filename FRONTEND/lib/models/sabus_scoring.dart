import '../data/dates.dart';
import 'app_data.dart';
import 'models.dart';

/// Logica di punteggio di Sabus, iniettata sul modello di WAY (additiva):
/// punti con moltiplicatore di livello, number nerfato (al target = 0.5*target;
/// l'esponenziale premia le unità e accelera oltre il target), bonus da streak,
/// e streak DERIVATO dal log. Non tocca percentOf/dayScore esistenti.
extension SabusScoring on AppData {
  static const double numK = 0.5;

  double sabusMult(Task t) => 1 + 0.5 * t.level; // livello 0 = base

  /// Il giorno "conta" (streak): complete = fatto; measure = raggiunta la soglia.
  bool taskCounts(Task t, DateTime day) {
    final v = valueOf(t, day);
    if (t.kind == TaskKind.complete) return v > 0;
    return v >= t.target;
  }

  /// Punti attesi completando al target (denominatore della percentuale).
  double expectedAtTarget(Task t) {
    final m = sabusMult(t);
    if (t.kind == TaskKind.complete) return m;
    return numK * t.target * m;
  }

  /// Punti effettivi del giorno. Sotto soglia = 0; al target = numK*target;
  /// oltre, l'esponenziale accelera. Premia ogni unità (base lineare).
  double taskPoints(Task t, DateTime day) {
    final m = sabusMult(t);
    final v = valueOf(t, day);
    if (t.kind == TaskKind.complete) return v > 0 ? m : 0.0;
    if (t.target <= 0) return 0.0;
    final atTarget = numK * t.target * m;
    final r = v / t.target;
    return t.reward == RewardCurve.exponential
        ? atTarget * (0.5 * r + 0.5 * r * r)
        : atTarget * r;
  }

  /// Streak reale: occorrenze consecutive "contate" dal log, da ieri all'indietro.
  int derivedStreak(Task t, {DateTime? asOf}) {
    final ref = Dates.dayOf(asOf ?? DateTime.now());
    var day = Dates.addDays(ref, -1);
    var streak = 0;
    for (var i = 0; i < 400; i++) {
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
    final total = dayPoints(day) * (1 + dayBonusFraction(day));
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
