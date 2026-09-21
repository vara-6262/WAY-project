import 'dart:math';

import '../models/app_data.dart';
import '../models/models.dart';
import 'dates.dart';

/// Archivio vuoto: la modalita' "configura da 0" parte da qui, con il
/// tutorial alla prima tappa.
AppData buildEmptyData() => const AppData(
      tasks: [],
      coreIds: [],
      places: [],
      activePlaceId: null,
      log: {},
      dismissedLevelUps: [],
      range: TrendRange.week,
      onboarding: OnboardingState.start,
    );

/// Demo popolata: il caso studio di partenza, sessione a Trento contro
/// rientro a casa. Il generatore usa un seme fisso, cosi' la demo e'
/// identica a ogni reset.
AppData buildProxyData() {
  final today = Dates.today();
  var seq = 0;
  Criterion c(String text) => Criterion(id: 'c${seq++}', text: text);

  final studio = Task(
    id: 'task-studio',
    name: 'Studio',
    iconKey: 'book',
    description: 'Sessione di studio effettiva, senza pause e spostamenti.',
    days: const [0, 1, 2, 3, 4],
    criteria: [
      c('Telefono in un\'altra stanza per tutta la sessione'),
      c('Blocchi da almeno 45 minuti continuativi'),
      c('Ogni sessione chiude con una sintesi scritta'),
      c('Nessun materiale nuovo dopo le 21:00'),
      c('Le pause non superano i 10 minuti'),
    ],
    kind: TaskKind.measure,
    reward: RewardCurve.exponential,
    target: 5,
    level: 3,
    streak: 11,
  );

  final allenamento = Task(
    id: 'task-allenamento',
    name: 'Allenamento',
    iconKey: 'dumbbell',
    description: 'Palestra o corsa, conta il tempo sotto sforzo.',
    days: const [0, 2, 4],
    criteria: [
      c('Riscaldamento completo prima di iniziare'),
      c('Carichi o tempi registrati a fine sessione'),
      c('Nessuna sessione saltata due volte di fila'),
    ],
    kind: TaskKind.measure,
    reward: RewardCurve.linear,
    target: 2,
    level: 2,
    streak: 21,
  );

  final svegliaTask = Task(
    id: 'task-sveglia',
    name: 'Sveglia 8:00',
    iconKey: 'alarm',
    description: 'Fuori dal letto entro le 8:00, snooze incluso.',
    days: const [0, 1, 2, 3, 4, 5, 6],
    criteria: [
      c('Piedi a terra entro le 8:00, snooze compreso'),
      c('Niente telefono nei primi 15 minuti'),
    ],
    kind: TaskKind.complete,
    reward: RewardCurve.linear,
    target: 1,
    level: 2,
    streak: 6,
  );

  final lettura = Task(
    id: 'task-lettura',
    name: 'Lettura',
    iconKey: 'paper',
    description: 'Lettura non universitaria.',
    days: const [0, 1, 2, 3, 4, 5, 6],
    criteria: [c('Carta o e-reader, non telefono')],
    kind: TaskKind.measure,
    reward: RewardCurve.linear,
    target: 30,
    level: 1,
    streak: 4,
  );

  final socialita = Task(
    id: 'task-socialita',
    name: 'Socialita',
    iconKey: 'people',
    description: 'Uscite o incontri di persona, non messaggi.',
    days: const [4, 5, 6],
    criteria: [c('Di persona, non in chiamata'), c('Almeno un\'ora')],
    kind: TaskKind.measure,
    reward: RewardCurve.linear,
    target: 3,
    level: 2,
    streak: 8,
  );

  final tasks = [studio, allenamento, svegliaTask, lettura, socialita];

  final places = [
    Place(
      id: 'place-trento',
      name: 'Sede - Trento',
      glyphKey: 'building',
      description: 'Periodo di sessione, fuori casa.',
      useCore: true,
      taskIds: [studio.id, socialita.id],
    ),
    const Place(
      id: 'place-casa',
      name: 'Casa',
      glyphKey: 'home',
      description: 'Rientro tra una sessione e l\'altra.',
      useCore: true,
      taskIds: ['task-socialita'],
    ),
    const Place(
      id: 'place-viaggio',
      name: 'In viaggio',
      glyphKey: 'plane',
      description: 'Spostamenti lunghi, poca continuita.',
      useCore: false,
      taskIds: ['task-lettura'],
    ),
  ];

  final random = Random(7);
  final log = <String, Map<String, double>>{};
  for (var i = 90; i >= 0; i--) {
    final day = Dates.addDays(today, -i);
    final entry = <String, double>{};
    for (final t in tasks) {
      if (!t.activeOn(day)) continue;
      final hitRate = i > 14 ? 0.90 : 0.78;
      final roll = random.nextDouble();
      if (t.kind == TaskKind.complete) {
        entry[t.id] = roll < hitRate ? 1 : 0;
      } else {
        if (roll < 0.08) {
          entry[t.id] = 0;
        } else {
          final spread = t.target * (0.55 + random.nextDouble() * 0.75);
          entry[t.id] = (spread * 2).round() / 2;
        }
      }
    }
    log[Dates.key(day)] = entry;
  }

  // La giornata di oggi resta a meta': l'app si apre su uno stato di
  // lavoro reale, non su una schermata vuota ne' su una gia' chiusa.
  log[Dates.key(today)] = {
    studio.id: 3,
    allenamento.id: 0,
    svegliaTask.id: 1,
    lettura.id: 12,
    socialita.id: 0,
  };

  return AppData(
    tasks: tasks,
    coreIds: [svegliaTask.id, allenamento.id, lettura.id],
    places: places,
    activePlaceId: places.first.id,
    log: log,
    dismissedLevelUps: const [],
    range: TrendRange.week,
    onboarding: OnboardingState.finished,
  );
}
