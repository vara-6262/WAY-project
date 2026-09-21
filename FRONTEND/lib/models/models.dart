import '../data/dates.dart';

enum Difficulty { easy, media, hard }

extension DifficultyLabel on Difficulty {
  String get label => switch (this) {
        Difficulty.easy => 'Facile',
        Difficulty.media => 'Media',
        Difficulty.hard => 'Difficile',
      };
}

/// Regola del prodotto: 1-3 criteri facile, 4-7 media, 8+ difficile.
/// La difficolta' non si sceglie, si ottiene.
Difficulty difficultyForCriteria(int count) {
  if (count < 4) return Difficulty.easy;
  if (count <= 7) return Difficulty.media;
  return Difficulty.hard;
}

/// Come si registra l'esecuzione: una spunta oppure una quantita'.
enum TaskKind { complete, measure, maintenance, abstinence }

/// Come cresce il valore di quello che fai oltre la soglia.
enum RewardCurve { linear, exponential }

/// Periodo del dominio: ogni giorno scelto, oppure una volta a settimana.
enum DomainPeriod { daily, weekly }

extension DomainPeriodLabel on DomainPeriod {
  String get label =>
      this == DomainPeriod.daily ? 'Giornaliera' : 'Settimanale';
}

class Criterion {
  const Criterion({required this.id, required this.text});

  final String id;
  final String text;

  Criterion copyWith({String? text}) =>
      Criterion(id: id, text: text ?? this.text);

  Map<String, dynamic> toJson() => {'id': id, 'text': text};

  factory Criterion.fromJson(Map<String, dynamic> j) =>
      Criterion(id: j['id'] as String, text: j['text'] as String);
}

class Task {
  const Task({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.description,
    required this.days,
    required this.criteria,
    required this.kind,
    required this.reward,
    required this.target,
    this.start = 6,
    this.end = 23,
    this.period = DomainPeriod.daily,
    this.tau = 14,
    required this.level,
    required this.streak,
  });

  final String id;
  final String name;
  final String iconKey;
  final String description;

  /// Giorni della settimana in cui la task vale, 0 = lunedi'.
  final List<int> days;
  final List<Criterion> criteria;
  final TaskKind kind;
  final RewardCurve reward;

  /// Quantita' che vale il 100% della giornata.
  final double target;

  /// Finestra oraria (ore) e periodo del dominio.
  final int start;
  final int end;
  final DomainPeriod period;

  /// Astinenza: durata della fase critica (giorni) per la curva a campana.
  final int tau;

  /// Le task nascono a livello 0 e salgono con la costanza.
  final int level;

  /// Esecuzioni consecutive riuscite.
  final int streak;

  Difficulty get difficulty => difficultyForCriteria(criteria.length);

  /// Avanzamento verso il livello successivo: 28 esecuzioni costanti.
  double get levelProgress => (streak / 28).clamp(0.0, 1.0);

  bool activeOn(DateTime day) => days.contains(Dates.weekdayIndex(day));

  Task copyWith({
    String? name,
    String? iconKey,
    String? description,
    List<int>? days,
    List<Criterion>? criteria,
    TaskKind? kind,
    RewardCurve? reward,
    double? target,
    int? start,
    int? end,
    DomainPeriod? period,
    int? tau,
    int? level,
    int? streak,
  }) {
    return Task(
      id: id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      description: description ?? this.description,
      days: days ?? this.days,
      criteria: criteria ?? this.criteria,
      kind: kind ?? this.kind,
      reward: reward ?? this.reward,
      target: target ?? this.target,
      start: start ?? this.start,
      end: end ?? this.end,
      period: period ?? this.period,
      tau: tau ?? this.tau,
      level: level ?? this.level,
      streak: streak ?? this.streak,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'description': description,
        'days': days,
        'criteria': criteria.map((c) => c.toJson()).toList(),
        'kind': kind.name,
        'reward': reward.name,
        'target': target,
        'start': start,
        'end': end,
        'period': period.name,
        'tau': tau,
        'level': level,
        'streak': streak,
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String,
        name: j['name'] as String,
        iconKey: j['iconKey'] as String? ?? 'book',
        description: j['description'] as String? ?? '',
        days: (j['days'] as List<dynamic>? ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        criteria: (j['criteria'] as List<dynamic>? ?? const [])
            .map((e) => Criterion.fromJson(e as Map<String, dynamic>))
            .toList(),
        kind: TaskKind.values.firstWhere(
          (k) => k.name == j['kind'],
          orElse: () => TaskKind.complete,
        ),
        reward: RewardCurve.values.firstWhere(
          (r) => r.name == j['reward'],
          orElse: () => RewardCurve.linear,
        ),
        target: (j['target'] as num?)?.toDouble() ?? 1,
        start: (j['start'] as num?)?.toInt() ?? 6,
        end: (j['end'] as num?)?.toInt() ?? 23,
        period: DomainPeriod.values.firstWhere(
          (p) => p.name == j['period'],
          orElse: () => DomainPeriod.daily,
        ),
        tau: (j['tau'] as num?)?.toInt() ?? 14,
        level: (j['level'] as num?)?.toInt() ?? 0,
        streak: (j['streak'] as num?)?.toInt() ?? 0,
      );
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.glyphKey,
    required this.description,
    required this.useCore,
    required this.taskIds,
  });

  final String id;
  final String name;
  final String glyphKey;
  final String description;

  /// Se vero le task del nucleo sono gia' dentro, implicitamente.
  final bool useCore;
  final List<String> taskIds;

  Place copyWith({
    String? name,
    String? glyphKey,
    String? description,
    bool? useCore,
    List<String>? taskIds,
  }) {
    return Place(
      id: id,
      name: name ?? this.name,
      glyphKey: glyphKey ?? this.glyphKey,
      description: description ?? this.description,
      useCore: useCore ?? this.useCore,
      taskIds: taskIds ?? this.taskIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'glyphKey': glyphKey,
        'description': description,
        'useCore': useCore,
        'taskIds': taskIds,
      };

  factory Place.fromJson(Map<String, dynamic> j) => Place(
        id: j['id'] as String,
        name: j['name'] as String,
        glyphKey: j['glyphKey'] as String? ?? 'pin',
        description: j['description'] as String? ?? '',
        useCore: j['useCore'] as bool? ?? true,
        taskIds: (j['taskIds'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
      );
}
