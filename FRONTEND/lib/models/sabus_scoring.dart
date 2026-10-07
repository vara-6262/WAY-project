import 'dart:math' as math;

import '../data/dates.dart';
import 'app_data.dart';
import 'models.dart';

/// Logica di punteggio di Sabus, iniettata sul modello di WAY (additiva):
/// punti con moltiplicatore di livello, number nerfato (al target = 0.5*target;
/// l'esponenziale premia le unità e accelera oltre il target), bonus da streak,
/// e streak DERIVATO dal log. Non tocca percentOf/dayScore esistenti.
// ---- Costanti number (tarabili) ----
const double _numBase = 2.0;       // un number a target vale 2x una checklist
const double _expPolar = 0.4;      // polarizzazione della curva number col livello
// ---- Costanti astinenza ----
const double _absFloor = 0.3;   // reward minimo di mantenimento
const double _absPeak = 3.0;    // reward massimo al picco della campana

/// Punti di un number: curva su p = v/target (normalizzata sul PROPRIO target).
/// - a target (p>=1) vale `mult` (comparabile a una checklist, qualunque target);
/// - sotto target: lineare (m*p) oppure polarizzata (m*p^k, k=1+alpha*level)
///   per l'esponenziale -> salendo di livello i valori bassi rendono sempre meno
///   e il grosso del reward si concentra vicino al target;
/// - sopra target: piccolo extra cappato (il superamento non e' il focus).
double _numberPoints(
    double v, double target, double mult, int level, RewardCurve curve) {
  if (target <= 0) return 0.0;
  final p = v / target;
  final double base;
  if (p >= 1) {
    base = mult;
  } else if (curve == RewardCurve.exponential) {
    base = mult * math.pow(p, 1 + _expPolar * level).toDouble();
  } else {
    base = mult * p;
  }
  // Oltre il target: lineare pieno, senza cap ne' accelerazione.
  // Sforare paga sempre, ma non da' nulla di speciale (streak/curva invariate).
  final over = p > 1 ? (p - 1) : 0.0;
  return _numBase * (base + mult * over);
}

/// Campana dell'astinenza: cresce nella fase critica (picco a n=tau), poi cala.
double _bell(int n, int tau, double mult) {
  final x = tau <= 0 ? 0.0 : n / tau;
  return mult * (_absFloor + _absPeak * x * math.exp(1 - x));
}

extension SabusScoring on AppData {
  static const double numK = 0.5;

  // Soglie del ciclo di vita
  static const int weeksToUpgrade = 2; // ~2 settimane del ritmo della task
  static const int upgradeFloor = 3; // minimo occorrenze per un upgrade
  static const int failThreshold = 3; // fallimenti per la riconfigurazione
  static const double overshootCapK = 0.3; // sconto max soglia da overshoot
  static const double consistencyCapK = 0.3; // sconto max soglia da consistenza
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

  /// Statistiche recenti (finestra) per modulare la soglia:
  /// - successRate: regolarita' (occorrenze riuscite / previste), in [0,1]
  /// - overshoot: superamento medio del target per i number, gia' cappato [0, overshootCapK]
  ({double successRate, double overshoot}) recentStats(Task t, {int window = 14}) {
    final ref = Dates.dayOf(DateTime.now());
    // La consistenza conta solo DALL'ultimo reset (upgrade/reconfig/Mantieni):
    // dopo un upgrade la task ha nuovi requisiti, la storia vecchia non vale.
    final floor = t.streakSince ?? t.createdOn;
    var day = Dates.addDays(ref, -1);
    var scheduled = 0, counted = 0;
    var overSum = 0.0;
    var overN = 0;
    for (var i = 0; i < 400 && scheduled < window; i++) {
      if (floor != null && day.isBefore(Dates.dayOf(floor))) break;
      if (t.activeOn(day)) {
        scheduled++;
        if (taskCounts(t, day)) {
          counted++;
          if (t.kind == TaskKind.measure && t.target > 0) {
            final v = valueOf(t, day);
            overSum += (v / t.target - 1).clamp(0.0, overshootCapK);
            overN++;
          }
        }
      }
      day = Dates.addDays(day, -1);
    }
    return (
      successRate: scheduled == 0 ? 0.0 : counted / scheduled,
      overshoot: overN == 0 ? 0.0 : overSum / overN,
    );
  }

  /// Soglia BASE (senza sconti), per famiglia.
  /// Soglia BASE derivata dalla FREQUENZA: occorrenze a settimana x weeksToUpgrade,
  /// con un pavimento. Cosi' una task a giorni alterni non richiede un mese.
  int upgradeBase(Task t) {
    final perWeek = isWeekly(t) ? 1 : (t.days.isEmpty ? 7 : t.days.length);
    final b = perWeek * weeksToUpgrade;
    return b < upgradeFloor ? upgradeFloor : b;
  }

  /// Soglia di successi per l'upgrade. Per le giornaliere complete/misura e'
  /// scontata da consistenza (regolarita' recente) e overshoot (cappato).
  /// I due sconti hanno un tetto naturale: niente pavimento esplicito.
  int upgradeThreshold(Task t) {
    final base = upgradeBase(t);
    if (t.kind == TaskKind.abstinence || t.period == DomainPeriod.weekly) {
      return base; // astinenza non usa succ; settimanale ha gia' soglia bassa
    }
    // Mantenimento: riceve lo sconto consistenza (overshoot = 0 per sua natura).
    final st = recentStats(t);
    final consDiscount = consistencyCapK * st.successRate; // [0, 0.3]
    final overDiscount = st.overshoot; // gia' [0, 0.3]
    final eff = base * (1 - consDiscount) * (1 - overDiscount);
    final r = eff.round();
    return r < 1 ? 1 : r;
  }

  /// Successi che mancano all'upgrade (0 se gia' pronta).
  int upgradeRemaining(Task t) {
    final r = upgradeThreshold(t) - derivedStreak(t);
    return r < 0 ? 0 : r;
  }

  /// Fallimenti che mancano alla riconfigurazione.
  int reconfigRemaining(Task t) {
    final r = failThreshold - t.fail;
    return r < 0 ? 0 : r;
  }

  bool upgradeReady(Task t) =>
      t.kind != TaskKind.abstinence &&
      !t.archived &&
      derivedStreak(t) >= upgradeThreshold(t);
  bool reconfigReady(Task t) =>
      t.kind != TaskKind.abstinence && !t.archived && t.fail >= failThreshold;
  /// Task da mostrare in Home oggi: previste oggi, ma le settimanali gia'
  /// completate questa settimana spariscono (restano attive per l'eco).
  /// La task e' dentro la sua finestra oraria in questo momento?
  bool inWindowNow(Task t) {
    final now = DateTime.now();
    final nowM = now.hour * 60 + now.minute;
    return nowM >= t.start * 60 && nowM < t.end * 60;
  }

  /// Task di oggi secondo il filtro della Home.
  List<Task> tasksForFilter(HomeFilter f) {
    final today = Dates.today();
    final hiddenSet =
        hiddenDay == Dates.key(today) ? hidden.toSet() : const <String>{};
    bool weeklySatisfied(Task t) =>
        isWeekly(t) && weekCounted(t, Dates.mondayOf(today), upTo: today);
    bool isDone(Task t) => percentOf(t, today) >= 100;
    return tasksFor(today).where((t) {
      switch (f) {
        case HomeFilter.disponibili:
          return !hiddenSet.contains(t.id) &&
              !weeklySatisfied(t) &&
              !isDone(t) &&
              inWindowNow(t);
        case HomeFilter.tutte:
          return true;
      }
    }).toList(growable: false);
  }

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
    return _numBase * m; // number a target: buffato rispetto alla checklist
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
    return _numberPoints(v, t.target, m, t.level, t.reward);
  }

  /// Streak reale: occorrenze consecutive "contate" dal log, da ieri all'indietro.
  int derivedStreak(Task t, {DateTime? asOf}) {
    final ref = Dates.dayOf(asOf ?? DateTime.now());
    final floor = t.streakSince;
    if (isWeekly(t)) {
      var monday = Dates.mondayOf(ref); // settimana corrente
      var weeks = 0;
      for (var i = 0; i < 200; i++) {
        if (floor != null && monday.isBefore(Dates.mondayOf(Dates.dayOf(floor)))) {
          break;
        }
        if (weekHasScheduled(t, monday)) {
          final up = i == 0 ? ref : Dates.addDays(monday, 6);
          if (weekCounted(t, monday, upTo: up)) {
            weeks++;
          } else if (i != 0) {
            break; // settimana passata non riuscita: spezza
          }
          // settimana corrente ancora aperta: in sospeso, non spezza
        }
        monday = Dates.addDays(monday, -7);
      }
      return weeks;
    }
    var day = ref; // parte da OGGI (aggiornamento in tempo reale col check)
    var streak = 0;
    for (var i = 0; i < 400; i++) {
      if (floor != null && day.isBefore(Dates.dayOf(floor))) break;
      if (t.activeOn(day)) {
        if (taskCounts(t, day)) {
          streak++;
        } else if (i != 0) {
          break; // un giorno passato mancato spezza
        }
        // oggi non ancora fatto: in sospeso, non spezza lo streak
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
  static const double bonusK = 0.0025; // era 0.01; ridotto a 1/4
  static const double bonusCap = 0.35; // tetto ASINTOTICO (saturazione dolce)
  static const double bonusHalf = 0.4; // grezzo a cui si raggiunge meta' del tetto

  /// Report testuale (debug) di come nasce il bonus del giorno:
  /// contributo per task + grezzo vs tetto vs applicato.
  String bonusReport(DateTime day) {
    final rows =
        <({String name, int streak, int level, double freq, double contrib})>[];
    var raw = 0.0;
    for (final t in tasksFor(day)) {
      final s = derivedStreak(t, asOf: day);
      if (s < 3) continue;
      final capped = s > 30 ? 30 : s;
      final contrib = capped * (t.level + 1) * bonusK * bonusFreq(t);
      raw += contrib;
      rows.add((name: t.name, streak: s, level: t.level, freq: bonusFreq(t), contrib: contrib));
    }
    rows.sort((a, b) => b.contrib.compareTo(a.contrib));
    final applied = bonusCap * raw / (raw + bonusHalf);
    final buf = StringBuffer()
      ..writeln('Formula per task:')
      ..writeln('  per task: min(streak,30) x (LV+1) x $bonusK x (occorrenze/7)')
      ..writeln('  totale: cap x grezzo / (grezzo + mezza-sat)')
      ..writeln('')
      ..writeln('Grezzo:            ${(raw * 100).toStringAsFixed(0)}%')
      ..writeln('Tetto (asintoto):  ${(bonusCap * 100).toStringAsFixed(0)}%')
      ..writeln('Mezza-saturazione: a grezzo ${(bonusHalf * 100).toStringAsFixed(0)}%')
      ..writeln('Applicato:         ${(applied * 100).toStringAsFixed(0)}%  (saturazione dolce)')
      ..writeln('Task con bonus (streak>=3): ${rows.length}')
      ..writeln('');
    for (final r in rows) {
      buf.writeln('${r.name.padRight(16)}'
          'streak ${r.streak} · LV${r.level} · f${r.freq.toStringAsFixed(2)}  =  +${(r.contrib * 100).toStringAsFixed(1)}%');
    }
    if (rows.isEmpty) buf.writeln('(nessuna task con streak >= 3 oggi)');
    return buf.toString();
  }

  /// Peso del bonus per frequenza: occorrenze previste a settimana / 7.
  /// Settimanale = 1/7; giornaliera su N giorni = N/7.
  double bonusFreq(Task t) => (isWeekly(t) ? 1 : t.days.length) / 7.0;

  double dayBonusFraction(DateTime day) {
    var raw = 0.0;
    for (final t in tasksFor(day)) {
      final s = derivedStreak(t, asOf: day);
      if (s >= 3) {
        final capped = s > 30 ? 30 : s;
        raw += capped * (t.level + 1) * bonusK * bonusFreq(t);
      }
    }
    // Rendimenti decrescenti: saturazione dolce verso bonusCap, mai piatta.
    return bonusCap * raw / (raw + bonusHalf);
  }

  /// Scomposizione del punteggio del giorno: occorrenze, mantenimento (eco), bonus.
  ({double active, double maint, double eco, double bonus}) dayBreakdown(
      DateTime day) {
    var active = 0.0, maint = 0.0, eco = 0.0;
    for (final t in tasksInScope()) {
      final e = taskDayEarned(t, day);
      if (e <= 0) continue;
      if (t.kind == TaskKind.maintenance || t.kind == TaskKind.abstinence) {
        maint += e; // passivi DA TASK: mantenimento/astinenza intatti oggi
      } else if (isWeekly(t) && !(t.activeOn(day) && taskCounts(t, day))) {
        eco += e; // ECO: meccanica dell'app (settimanali fuori occorrenza)
      } else {
        active += e; // fatto oggi
      }
    }
    final bonus = (active + maint + eco) * dayBonusFraction(day);
    return (active: active, maint: maint, eco: eco, bonus: bonus);
  }

  /// Percentuale Sabus del giorno = punti*(1+bonus)/attesi*100 (può superare 100).
  int? dayPercentSabus(DateTime day) {
    final exp = expectedPointsFor(day);
    if (exp <= 0) return null;
    final base = ledger[Dates.key(day)] ?? dayPoints(day);
    final total = base * (1 + dayBonusFraction(day));
    return (total / exp * 100).round();
  }

  /// Punti che varrebbe una task measure a un dato valore (anteprima guadagno).
  double pointsAtValue(Task t, double v) {
    if (t.kind != TaskKind.measure || t.target <= 0 || v < 0) return 0;
    final m = sabusMult(t);
    return _numberPoints(v, t.target, m, t.level, t.reward);
  }

  /// Valore della campana dell'astinenza in un dato giorno (quanto paga stare puliti).
  double abstinenceRewardOn(Task t, DateTime day) =>
      t.kind == TaskKind.abstinence
          ? _bell(derivedStreak(t, asOf: day), t.tau, sabusMult(t))
          : 0.0;

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
