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

  // Settimanale + mantenimento
  static const double ecoK = 0.7; // punti passivi = 70% dell'ultima occorrenza
  static const int ecoWindow = 8; // giorni max di eco dopo l'ultima occorrenza

  bool isWeekly(Task t) => t.period == DomainPeriod.weekly;

  bool weekHasScheduled(Task t, DateTime monday) {
    for (var i = 0; i < 7; i++) {
      if (t.activeOn(Dates.addDays(monday, i))) return true;
    }
    return false;
  }

  /// La settimana [monday] e' riuscita: la task ha contato in almeno un giorno
  /// previsto (fino a [upTo] incluso, per non valutare il futuro).
  bool weekCounted(Task t, DateTime monday, {DateTime? upTo}) {
    final limit = upTo ?? Dates.addDays(monday, 6);
    for (var i = 0; i < 7; i++) {
      final d = Dates.addDays(monday, i);
      if (d.isAfter(limit)) break;
      if (t.activeOn(d) && taskCounts(t, d)) return true;
    }
    return false;
  }

  /// Eco di mantenimento (solo settimanali): 70% dell'ultima occorrenza
  /// riuscita entro [ecoWindow] giorni.
  double ecoPoints(Task t, DateTime day) {
    if (!isWeekly(t)) return 0;
    for (var back = 1; back <= ecoWindow; back++) {
      final d = Dates.addDays(day, -back);
      if (t.activeOn(d) && taskCounts(t, d)) return ecoK * taskPoints(t, d);
    }
    return 0;
  }

  /// Punti effettivi di una task in un giorno (occorrenza piena oppure eco).
  double taskDayEarned(Task t, DateTime day) {
    if (isWeekly(t)) {
      if (t.activeOn(day) && taskCounts(t, day)) return taskPoints(t, day);
      return ecoPoints(t, day);
    }
    return t.activeOn(day) ? taskPoints(t, day) : 0;
  }

  /// Punti attesi di una task in un giorno (denominatore della percentuale).
  double taskDayExpected(Task t, DateTime day) {
    if (isWeekly(t)) {
      if (t.activeOn(day) && taskCounts(t, day)) return expectedAtTarget(t);
      return ecoPoints(t, day);
    }
    return t.activeOn(day) ? expectedAtTarget(t) : 0;
  }

  bool upgradeReady(Task t) =>
      t.kind != TaskKind.abstinence && !t.archived && t.succ >= upThreshold;
  bool reconfigReady(Task t) =>
      t.kind != TaskKind.abstinence && !t.archived && t.fail >= failThreshold;
  /// Task da mostrare in Home oggi: previste oggi, ma le settimanali gia'
  /// completate questa settimana spariscono (restano attive per l'eco).
  List<Task> visibleToday() {
    final today = Dates.today();
    final now = DateTime.now();
    final nowM = now.hour * 60 + now.minute;
    final hiddenSet =
        hiddenDay == Dates.key(today) ? hidden.toSet() : const <String>{};
    return tasksFor(today).where((t) {
      if (hiddenSet.contains(t.id)) return false;
      if (isWeekly(t) && weekCounted(t, Dates.mondayOf(today), upTo: today)) {
        return false;
      }
      // Fascia oraria: mostra solo dentro [start, end).
      if (nowM < t.start * 60 || nowM >= t.end * 60) return false;
      return true;
    }).toList(growable: false);
  }

  bool abstinenceConcluded(Task t) =>
      t.kind == TaskKind.abstinence &&
      !t.archived &&
      derivedStreak(t) >= (absEndK * t.tau).round();

  double sabusMult(Task t) => 1 + 0.5 * t.level; // livello 0 = base

  /// La task esiste in [day]? Prima di createdOn non conta e non da' punti.
  bool existsOn(Task t, DateTime day) =>
      t.createdOn == null ||
      !Dates.dayOf(day).isBefore(Dates.dayOf(t.createdOn!));

  /// Il giorno "conta" (streak): complete = fatto; measure = raggiunta la soglia.
  bool taskCounts(Task t, DateTime day) {
    if (!existsOn(t, day)) return false;
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
    if (!existsOn(t, day)) return 0.0;
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
    if (isWeekly(t)) {
      var monday = Dates.addDays(Dates.mondayOf(ref), -7); // settimana scorsa
      var weeks = 0;
      for (var i = 0; i < 200; i++) {
        if (floor != null && monday.isBefore(Dates.mondayOf(Dates.dayOf(floor)))) {
          break;
        }
        if (weekHasScheduled(t, monday)) {
          if (weekCounted(t, monday)) {
            weeks++;
          } else {
            break;
          }
        }
        monday = Dates.addDays(monday, -7);
      }
      return weeks;
    }
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
    for (final t in tasksInScope()) {
      sum += taskDayEarned(t, day);
    }
    return sum;
  }

  double expectedPointsFor(DateTime day) {
    var sum = 0.0;
    for (final t in tasksInScope()) {
      sum += taskDayExpected(t, day);
    }
    return sum;
  }

  /// Bonus del giorno (frazione): somma di min(streak,30)*(level+1)*0.02 per streak>=3.
  /// Costante e tetto del bonus giornaliero (evita che superi il piatto).
  static const double bonusK = 0.01;
  static const double bonusCap = 0.5;

  double dayBonusFraction(DateTime day) {
    var b = 0.0;
    for (final t in tasksFor(day)) {
      final s = derivedStreak(t, asOf: day);
      if (s >= 3) {
        final capped = s > 30 ? 30 : s;
        b += capped * (t.level + 1) * bonusK;
      }
    }
    return b > bonusCap ? bonusCap : b;
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
