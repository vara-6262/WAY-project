import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dates.dart';
import '../data/seed.dart';
import '../data/dates.dart';
import '../models/app_data.dart';
import '../models/sabus_scoring.dart';
import '../theme/way_colors.dart';
import '../services/notifications.dart';
import '../models/models.dart';

const proxyKey = 'way.prototype.v1';
const zeroKey = 'way.prototype.zero.v1';
const modeKey = 'way.prototype.mode.v1';

String storageKeyFor(PrototypeMode mode) =>
    mode == PrototypeMode.zero ? zeroKey : proxyKey;

/// Quello che main() legge dal disco prima del primo frame.
class Bootstrap {
  const Bootstrap({required this.mode, required this.data});

  final PrototypeMode mode;
  final AppData data;

  static Bootstrap load(SharedPreferences prefs) {
    final mode = prefs.getString(modeKey) == 'zero'
        ? PrototypeMode.zero
        : PrototypeMode.proxy;
    return Bootstrap(mode: mode, data: readData(prefs, mode));
  }

  static AppData readData(SharedPreferences prefs, PrototypeMode mode) {
    final raw = prefs.getString(storageKeyFor(mode));
    if (raw == null) return freshData(mode);
    try {
      return AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Archivio illeggibile (formato vecchio, dato corrotto): si riparte
      // pulito invece di aprire l'app su una schermata rotta.
      return freshData(mode);
    }
  }

  static AppData freshData(PrototypeMode mode) =>
      mode == PrototypeMode.zero ? buildEmptyData() : buildProxyData();
}

/// Riempiti da main() con override.
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('prefsProvider va sovrascritto in main()'),
);
final bootstrapProvider = Provider<Bootstrap>(
  (ref) => throw UnimplementedError('bootstrapProvider va sovrascritto in main()'),
);

final modeProvider =
    NotifierProvider<ModeController, PrototypeMode>(ModeController.new);

final appProvider = NotifierProvider<AppController, AppData>(AppController.new);

/// Selettori: i widget guardano solo la fetta che li riguarda.
final activePlaceProvider = Provider<Place?>(
  (ref) => ref.watch(appProvider).activePlace,
);
final onboardingProvider = Provider<OnboardingState>(
  (ref) => ref.watch(appProvider).onboarding,
);

/// Il tutorial esiste solo nella modalita' "configura da 0".
final tutorialActiveProvider = Provider<bool>((ref) {
  final mode = ref.watch(modeProvider);
  final ob = ref.watch(onboardingProvider);
  return mode == PrototypeMode.zero && ob.active;
});

String newId() {
  final r = Random();
  return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${r.nextInt(46656).toRadixString(36)}';
}

class ModeController extends Notifier<PrototypeMode> {
  @override
  PrototypeMode build() => ref.read(bootstrapProvider).mode;

  void set(PrototypeMode next) {
    if (next == state) return;
    final prefs = ref.read(prefsProvider);
    prefs.setString(modeKey, next.name);
    state = next;
    // Ogni modalita' ha il suo archivio: passare da una all'altra non
    // distrugge il lavoro fatto nell'altra.
    ref.read(appProvider.notifier).loadFor(next);
  }
}

class AppController extends Notifier<AppData> {
  @override
  AppData build() => _consolidate(ref.read(bootstrapProvider).data);

  PrototypeMode get _mode => ref.read(modeProvider);

  void _write(AppData next) {
    state = next;
    final prefs = ref.read(prefsProvider);
    // Salvataggio non atteso: la UI non deve mai fermarsi per una scrittura.
    prefs.setString(storageKeyFor(_mode), jsonEncode(next.toJson()));
  }

  void loadFor(PrototypeMode mode) {
    state = Bootstrap.readData(ref.read(prefsProvider), mode);
  }

  void resetCurrentMode() => _write(Bootstrap.freshData(_mode));

  // ---- Rollover / snapshot ----
  Map<String, Map<String, double>> _deepLog(AppData d) => {
        for (final e in d.log.entries) e.key: Map<String, double>.from(e.value),
      };

  double _basePoints(AppData d, String dateKey) =>
      d.dayPoints(Dates.parse(dateKey));

  /// Consolida i giorni passati non ancora sigillati (ledger dai valori del log).
  AppData _consolidate(AppData d) {
    final todayKey = Dates.key(Dates.today());
    final yKey = Dates.key(Dates.addDays(Dates.today(), -1));
    final ledger = Map<String, double>.from(d.ledger);
    for (final k in d.log.keys) {
      if (k.compareTo(todayKey) >= 0) continue;
      if (d.reviewed.contains(k)) continue;
      ledger[k] = _basePoints(d, k);
    }
    // Ciclo di vita: conta successi/fallimenti sui giorni chiusi (< ieri).
    final succ = {for (final t in d.tasks) t.id: t.succ};
    final fail = {for (final t in d.tasks) t.id: t.fail};
    var last = d.lastLifecycleDay;
    final days = d.log.keys
        .where((k) => k.compareTo(yKey) < 0 && k.compareTo(last) > 0)
        .toList()
      ..sort();
    for (final k in days) {
      final day = Dates.parse(k);
      for (final t in d.tasks) {
        if (t.kind == TaskKind.abstinence || t.archived) continue;
        if (!d.existsOn(t, day)) continue; // non esisteva ancora
        if (t.period == DomainPeriod.weekly) {
          // Settimanale: valutata una volta, alla chiusura settimana (domenica).
          if (day.weekday != DateTime.sunday) continue;
          final monday = Dates.mondayOf(day);
          if (!d.weekHasScheduled(t, monday)) continue;
          if (d.weekCounted(t, monday)) {
            succ[t.id] = (succ[t.id] ?? 0) + 1;
            fail[t.id] = 0;
          } else {
            fail[t.id] = (fail[t.id] ?? 0) + 1;
            succ[t.id] = 0;
          }
        } else {
          if (!t.activeOn(day)) continue;
          if (d.taskCounts(t, day)) {
            succ[t.id] = (succ[t.id] ?? 0) + 1;
            fail[t.id] = 0;
          } else {
            fail[t.id] = (fail[t.id] ?? 0) + 1;
            succ[t.id] = 0;
          }
        }
      }
      last = k;
    }
    final tasks = d.tasks
        .map((t) => (t.kind == TaskKind.abstinence || t.archived)
            ? t
            : t.copyWith(succ: succ[t.id], fail: fail[t.id]))
        .toList();
    return d.copyWith(ledger: ledger, tasks: tasks, lastLifecycleDay: last);
  }

  // ---- Ciclo di vita: azioni ----
  List<Criterion> _mkCriteria(List<String> texts) => [
        for (var i = 0; i < texts.length; i++)
          Criterion(
              id: 'c${DateTime.now().microsecondsSinceEpoch}_$i',
              text: texts[i]),
      ];

  void applyUpgrade(
    Task t, {
    required List<String> requirements,
    required List<int> days,
    required int start,
    required int end,
    required DomainPeriod period,
    double? target,
    bool toNumber = false,
  }) {
    var up = t.copyWith(
      level: t.level + 1,
      succ: 0,
      fail: 0,
      criteria: _mkCriteria(requirements),
      days: days,
      start: start,
      end: end,
      period: period,
    );
    if (toNumber && t.kind == TaskKind.complete) {
      up = up.copyWith(kind: TaskKind.measure, target: target ?? 1);
    } else if (t.kind == TaskKind.measure && target != null) {
      up = up.copyWith(target: target);
    }
    updateTask(up);
  }

  /// "Mantieni": azzera i contatori e lo streak (ferma la crescita del bonus)
  /// senza toccare livello o configurazione.
  void keepTask(Task t) =>
      updateTask(t.copyWith(succ: 0, fail: 0, streakSince: Dates.today()));

  void applyReconfig(
    Task t, {
    required List<String> requirements,
    required List<int> days,
    required int start,
    required int end,
    required DomainPeriod period,
    double? target,
    bool downgrade = false,
  }) {
    var r = t.copyWith(
      succ: 0,
      fail: 0,
      criteria: _mkCriteria(requirements),
      days: days,
      start: start,
      end: end,
      period: period,
    );
    if (t.kind == TaskKind.measure && target != null) {
      r = r.copyWith(target: target);
    }
    if (downgrade) r = r.copyWith(level: t.level > 0 ? t.level - 1 : 0);
    updateTask(r);
  }

  void archiveTask(Task t) => updateTask(t.copyWith(archived: true));

  /// Nasconde una task dalla Home per il giorno corrente (swipe).
  void hideTaskToday(String taskId) {
    final today = Dates.key(Dates.today());
    final list = state.hiddenDay == today ? [...state.hidden] : <String>[];
    if (!list.contains(taskId)) list.add(taskId);
    _write(state.copyWith(hiddenDay: today, hidden: list));
  }

  void showHiddenToday() => _write(
      state.copyWith(hiddenDay: Dates.key(Dates.today()), hidden: const []));

  // ---- Review di ieri ----
  /// Applica la review: delta dei punti DIMEZZATO; lo streak si puo' salvare
  /// (gli "add" entrano nel log) ma non si spezza (le rimozioni non lo toccano).
  void applyReview(Map<String, double> proposed) {
    final y = Dates.addDays(Dates.today(), -1);
    final key = Dates.key(y);
    final tasks = state.tasksFor(y);

    // stato proposto (copia del log con i valori proposti per ieri)
    final propLog = _deepLog(state);
    final propDay = Map<String, double>.from(propLog[key] ?? const {});
    for (final t in tasks) {
      if (proposed.containsKey(t.id)) propDay[t.id] = proposed[t.id]!;
    }
    propLog[key] = propDay;
    final proposedData = state.copyWith(log: propLog);

    var originalBase = 0.0, proposedBase = 0.0;
    for (final t in tasks) {
      originalBase += state.taskPoints(t, y);
      proposedBase += proposedData.taskPoints(t, y);
    }
    final sealedPts = originalBase + (proposedBase - originalBase) * 0.5;

    // log finale: scrivo solo gli "add" che fanno contare la task (streak salvato);
    // le rimozioni non toccano il log (streak protetto).
    final finalLog = _deepLog(state);
    final finalDay = Map<String, double>.from(finalLog[key] ?? const {});
    for (final t in tasks) {
      final origCounts = state.taskCounts(t, y);
      final propCounts = proposedData.taskCounts(t, y);
      if (propCounts && !origCounts) {
        finalDay[t.id] = proposed[t.id] ?? finalDay[t.id] ?? 1;
      }
    }
    finalLog[key] = finalDay;

    final ledger = Map<String, double>.from(state.ledger)..[key] = sealedPts;
    final reviewed = {...state.reviewed, key};
    _write(state.copyWith(log: finalLog, ledger: ledger, reviewed: reviewed));
  }

  /// Salta la review: sigilla ieri com'era (nessuna correzione).
  void skipReview() {
    final key = Dates.key(Dates.addDays(Dates.today(), -1));
    final ledger = Map<String, double>.from(state.ledger)
      ..[key] = _basePoints(state, key);
    _write(state.copyWith(ledger: ledger, reviewed: {...state.reviewed, key}));
  }

  // --- Task -----------------------------------------------------------------

  void addTask(Task task) => _write(state.copyWith(tasks: [
        ...state.tasks,
        task.copyWith(
          streakSince: task.streakSince ?? Dates.today(),
          createdOn: task.createdOn ?? Dates.today(),
        ),
      ]));

  void updateTask(Task task) => _write(
        state.copyWith(
          tasks: [
            for (final t in state.tasks) if (t.id == task.id) task else t,
          ],
        ),
      );

  void deleteTask(String taskId) => _write(
        state.copyWith(
          tasks: state.tasks.where((t) => t.id != taskId).toList(),
          coreIds: state.coreIds.where((id) => id != taskId).toList(),
          places: [
            for (final p in state.places)
              p.copyWith(taskIds: p.taskIds.where((id) => id != taskId).toList()),
          ],
        ),
      );

  // --- Core Session ---------------------------------------------------------

  void addToCore(String taskId) {
    if (state.coreIds.contains(taskId)) return;
    _write(state.copyWith(coreIds: [...state.coreIds, taskId]));
  }

  void removeFromCore(String taskId) => _write(
        state.copyWith(
          coreIds: state.coreIds.where((id) => id != taskId).toList(),
        ),
      );

  void toggleCore(String taskId) =>
      state.coreIds.contains(taskId) ? removeFromCore(taskId) : addToCore(taskId);

  // --- Ambienti -------------------------------------------------------------

  void addPlace(Place place) =>
      _write(state.copyWith(places: [...state.places, place]));

  void updatePlace(Place place) => _write(
        state.copyWith(
          places: [
            for (final p in state.places) if (p.id == place.id) place else p,
          ],
        ),
      );

  void deletePlace(String placeId) {
    final next = state.copyWith(
      places: state.places.where((p) => p.id != placeId).toList(),
    );
    _write(state.activePlaceId == placeId
        ? next.copyWith(clearActivePlace: true)
        : next);
  }

  void activatePlace(String placeId) =>
      _write(state.copyWith(activePlaceId: placeId));

  void clearActivePlace() => _write(state.copyWith(clearActivePlace: true));

  // --- Esecuzione giornaliera ----------------------------------------------

  void setValue(Task task, double value, {DateTime? day}) {
    final key = Dates.key(day ?? DateTime.now());
    final log = {for (final e in state.log.entries) e.key: {...e.value}};
    final entry = log.putIfAbsent(key, () => <String, double>{});
    entry[task.id] = value < 0 ? 0 : value;
    _write(state.copyWith(log: log));
  }

  /// Mantenimento: accende/spegne il bit della condizione i (0 = intatta).
  void toggleMaintenanceCondition(Task task, int index, {DateTime? day}) {
    final cur = state.valueOf(task, day ?? DateTime.now()).toInt();
    final bit = 1 << index;
    final next = (cur & bit) != 0 ? cur & ~bit : cur | bit;
    setValue(task, next.toDouble(), day: day);
  }

  /// Astinenza: alterna pulito (0) / ricaduta (1) per il giorno.
  void toggleAbstinence(Task task, {DateTime? day}) {
    final cur = state.valueOf(task, day ?? DateTime.now());
    setValue(task, cur == 0 ? 1 : 0, day: day);
  }

  void toggleDone(Task task, {DateTime? day}) {
    final current = state.valueOf(task, day ?? DateTime.now());
    setValue(task, current > 0 ? 0 : 1, day: day);
  }

  void bump(Task task, double delta, {DateTime? day}) {
    final current = state.valueOf(task, day ?? DateTime.now());
    final next = ((current + delta) * 2).round() / 2;
    setValue(task, next < 0 ? 0 : next, day: day);
  }

  // --- Livelli e vista ------------------------------------------------------

  void acceptLevelUp(Task task) =>
      updateTask(task.copyWith(level: task.level + 1, streak: 0));

  void dismissLevelUp(Task task) => _write(
        state.copyWith(dismissedLevelUps: [...state.dismissedLevelUps, task.id]),
      );

  void setRange(TrendRange range) => _write(state.copyWith(range: range));

  // --- Primo utilizzo -------------------------------------------------------

  void setStage(OnboardingStage stage) =>
      _write(state.copyWith(onboarding: state.onboarding.copyWith(stage: stage)));

  void finishOnboarding() =>
      _write(state.copyWith(onboarding: OnboardingState.finished));

  void markEducation({bool? criteria, bool? complete, bool? measure}) => _write(
        state.copyWith(
          onboarding: state.onboarding.copyWith(
            criteriaSeen: criteria,
            completeSeen: complete,
            measureSeen: measure,
          ),
        ),
      );
}


/// Tema selezionato (palette WayColors), persistito.
final themeProvider =
    NotifierProvider<ThemeController, WayColors>(ThemeController.new);

class ThemeController extends Notifier<WayColors> {
  static const _key = 'way_theme_id';

  @override
  WayColors build() {
    final id = ref.read(prefsProvider).getString(_key) ?? 'lime';
    return WayColors.byId(id);
  }

  void setId(String id) {
    ref.read(prefsProvider).setString(_key, id);
    state = WayColors.byId(id);
  }
}

/// Servizio notifiche (istanza inizializzata in main).
final notificationsProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError('notificationsProvider va sovrascritto in main()'),
);
