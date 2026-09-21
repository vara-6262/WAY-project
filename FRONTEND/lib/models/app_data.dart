import '../data/dates.dart';
import 'models.dart';

enum TrendRange { week, month, year }

extension TrendRangeLabel on TrendRange {
  String get label => switch (this) {
        TrendRange.week => '7 giorni',
        TrendRange.month => '30 giorni',
        TrendRange.year => '12 mesi',
      };
}

/// Le due modalita' del prototipo: la demo gia' popolata e la
/// configurazione da zero, ciascuna con il proprio archivio.
enum PrototypeMode { proxy, zero }

/// Tappe del primo utilizzo. Sono uno stato salvato, non un contatore in
/// memoria: se l'utente chiude l'app a meta' tutorial, riprende da li'.
enum OnboardingStage {
  taskIntro,
  taskWizard,
  coreIntro,
  placesInvite,
  placeIntro,
  placeWizard,
  done,
}

class OnboardingState {
  const OnboardingState({
    required this.stage,
    required this.criteriaSeen,
    required this.completeSeen,
    required this.measureSeen,
  });

  final OnboardingStage stage;

  /// Concetti gia' spiegati: non si ripetono alla seconda task.
  final bool criteriaSeen;
  final bool completeSeen;
  final bool measureSeen;

  static const start = OnboardingState(
    stage: OnboardingStage.taskIntro,
    criteriaSeen: false,
    completeSeen: false,
    measureSeen: false,
  );

  static const finished = OnboardingState(
    stage: OnboardingStage.done,
    criteriaSeen: true,
    completeSeen: true,
    measureSeen: true,
  );

  bool get active => stage != OnboardingStage.done;

  OnboardingState copyWith({
    OnboardingStage? stage,
    bool? criteriaSeen,
    bool? completeSeen,
    bool? measureSeen,
  }) {
    return OnboardingState(
      stage: stage ?? this.stage,
      criteriaSeen: criteriaSeen ?? this.criteriaSeen,
      completeSeen: completeSeen ?? this.completeSeen,
      measureSeen: measureSeen ?? this.measureSeen,
    );
  }

  Map<String, dynamic> toJson() => {
        'stage': stage.name,
        'criteriaSeen': criteriaSeen,
        'completeSeen': completeSeen,
        'measureSeen': measureSeen,
      };

  factory OnboardingState.fromJson(Map<String, dynamic> j) => OnboardingState(
        stage: OnboardingStage.values.firstWhere(
          (s) => s.name == j['stage'],
          orElse: () => OnboardingStage.done,
        ),
        criteriaSeen: j['criteriaSeen'] as bool? ?? false,
        completeSeen: j['completeSeen'] as bool? ?? false,
        measureSeen: j['measureSeen'] as bool? ?? false,
      );
}

/// Stato completo dell'app. Immutabile: ogni modifica passa da copyWith,
/// cosi' Riverpod sa sempre quando ridisegnare.
class AppData {
  const AppData({
    required this.tasks,
    required this.coreIds,
    required this.places,
    required this.activePlaceId,
    required this.log,
    required this.dismissedLevelUps,
    required this.range,
    required this.onboarding,
    this.ledger = const {},
    this.reviewed = const {},
    this.lastLifecycleDay = '',
  });

  final List<Task> tasks;

  /// Le task della Core Session, attive in ogni ambiente che la tiene accesa.
  final List<String> coreIds;
  final List<Place> places;

  /// Un solo ambiente per volta puo' stare nell'hub.
  final String? activePlaceId;

  /// dataKey -> (taskId -> quantita' registrata quel giorno).
  final Map<String, Map<String, double>> log;
  final List<String> dismissedLevelUps;
  final TrendRange range;
  final OnboardingState onboarding;

  /// dataKey -> punti sigillati del giorno (consolidati / rivisti).
  final Map<String, double> ledger;

  /// dataKey dei giorni gia' rivisti (una review per giorno).
  final Set<String> reviewed;

  /// Ultimo giorno processato per i contatori del ciclo di vita.
  final String lastLifecycleDay;

  AppData copyWith({
    List<Task>? tasks,
    List<String>? coreIds,
    List<Place>? places,
    String? activePlaceId,
    bool clearActivePlace = false,
    Map<String, Map<String, double>>? log,
    List<String>? dismissedLevelUps,
    TrendRange? range,
    OnboardingState? onboarding,
    Map<String, double>? ledger,
    Set<String>? reviewed,
    String? lastLifecycleDay,
  }) {
    return AppData(
      tasks: tasks ?? this.tasks,
      coreIds: coreIds ?? this.coreIds,
      places: places ?? this.places,
      activePlaceId:
          clearActivePlace ? null : (activePlaceId ?? this.activePlaceId),
      log: log ?? this.log,
      dismissedLevelUps: dismissedLevelUps ?? this.dismissedLevelUps,
      range: range ?? this.range,
      onboarding: onboarding ?? this.onboarding,
      ledger: ledger ?? this.ledger,
      reviewed: reviewed ?? this.reviewed,
      lastLifecycleDay: lastLifecycleDay ?? this.lastLifecycleDay,
    );
  }

  Map<String, dynamic> toJson() => {
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'coreIds': coreIds,
        'places': places.map((p) => p.toJson()).toList(),
        'activePlaceId': activePlaceId,
        'log': log.map(
          (day, values) => MapEntry(day, values.map((k, v) => MapEntry(k, v))),
        ),
        'dismissedLevelUps': dismissedLevelUps,
        'range': range.name,
        'onboarding': onboarding.toJson(),
        'ledger': ledger,
        'reviewed': reviewed.toList(),
        'lastLifecycleDay': lastLifecycleDay,
      };

  factory AppData.fromJson(Map<String, dynamic> j) {
    final rawLog = (j['log'] as Map<String, dynamic>? ?? const {});
    return AppData(
      tasks: (j['tasks'] as List<dynamic>? ?? const [])
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList(),
      coreIds: (j['coreIds'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      places: (j['places'] as List<dynamic>? ?? const [])
          .map((e) => Place.fromJson(e as Map<String, dynamic>))
          .toList(),
      activePlaceId: j['activePlaceId'] as String?,
      log: rawLog.map(
        (day, values) => MapEntry(
          day,
          (values as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, (v as num).toDouble())),
        ),
      ),
      dismissedLevelUps: (j['dismissedLevelUps'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
      range: TrendRange.values.firstWhere(
        (r) => r.name == j['range'],
        orElse: () => TrendRange.week,
      ),
      onboarding: j['onboarding'] == null
          ? OnboardingState.finished
          : OnboardingState.fromJson(j['onboarding'] as Map<String, dynamic>),
      ledger: (j['ledger'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
      reviewed: ((j['reviewed'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toSet()),
      lastLifecycleDay: j['lastLifecycleDay'] as String? ?? '',
    );
  }
}

/// Tutte le letture derivate stanno qui: nessuna schermata ricalcola a
/// modo suo, e la regola del prodotto vive in un posto solo.
extension AppStats on AppData {
  /// C'e' la giornata di ieri da rivedere (non ancora rivista)?
  bool get reviewAvailable {
    final y = Dates.addDays(Dates.today(), -1);
    if (reviewed.contains(Dates.key(y))) return false;
    return tasksFor(y).isNotEmpty;
  }

  Task? taskById(String id) {
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Place? get activePlace {
    if (activePlaceId == null) return null;
    for (final p in places) {
      if (p.id == activePlaceId) return p;
    }
    return null;
  }

  bool isCore(String taskId) => coreIds.contains(taskId);

  /// Le task in carico nell'ambiente attivo, nucleo incluso quando previsto.
  /// Senza ambiente attivo resta solo la Core Session.
  List<Task> tasksInScope() {
    final place = activePlace;
    final ids = <String>[];
    if (place == null) {
      ids.addAll(coreIds);
    } else {
      if (place.useCore) ids.addAll(coreIds);
      for (final id in place.taskIds) {
        if (!ids.contains(id)) ids.add(id);
      }
    }
    return ids.map(taskById).whereType<Task>().toList(growable: false);
  }

  List<Task> tasksFor(DateTime day) => tasksInScope()
      .where((t) => !t.archived && t.activeOn(day))
      .toList(growable: false);

  double valueOf(Task task, DateTime day) => log[Dates.key(day)]?[task.id] ?? 0;

  /// Percentuale della singola task in un giorno. Puo' superare 100.
  int percentOf(Task task, DateTime day) {
    final v = valueOf(task, day);
    if (task.kind == TaskKind.maintenance) return v == 0 ? 100 : 0;
    if (task.kind == TaskKind.abstinence) return v == 0 ? 100 : 0;
    if (task.kind == TaskKind.complete) return v > 0 ? 100 : 0;
    if (task.target <= 0) return 0;
    return (v / task.target * 100).round();
  }

  /// Percentuale della giornata: media delle task attive quel giorno.
  /// Null quando la giornata non prevede nessuna task: e' una giornata
  /// libera, non una giornata a zero.
  int? dayScore(DateTime day) {
    final list = tasksFor(day);
    if (list.isEmpty) return null;
    var sum = 0;
    for (final t in list) {
      sum += percentOf(t, day);
    }
    return (sum / list.length).round();
  }

  /// Giorni consecutivi chiusi al 100%. I giorni senza task previste non
  /// spezzano la serie: non erano giornate da vincere.
  int dayStreak() {
    final today = Dates.today();
    var n = 0;
    for (var i = 0; i < 400; i++) {
      final s = dayScore(Dates.addDays(today, -i));
      if (s == null) continue;
      if (s >= 100) {
        n++;
      } else {
        break;
      }
    }
    return n;
  }

  /// Prima task costante abbastanza da meritare una proposta di livello.
  Task? levelUpCandidate() {
    for (final t in tasks) {
      if (t.streak >= 20 && t.level < 5 && !dismissedLevelUps.contains(t.id)) {
        return t;
      }
    }
    return null;
  }

  List<Task> tasksOf(Place place) {
    final ids = <String>[];
    if (place.useCore) ids.addAll(coreIds);
    for (final id in place.taskIds) {
      if (!ids.contains(id)) ids.add(id);
    }
    return ids.map(taskById).whereType<Task>().toList(growable: false);
  }

  int loadOf(Place place) => tasksOf(place).length;
}
