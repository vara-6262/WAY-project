import '../l10n/strings.dart';
import '../models/models.dart';

/// Testo bilingue per i contenuti statici dei pack (non possono usare context).
class LT {
  const LT(this.it, this.en);
  final String it;
  final String en;
  // Per ora i contenuti dei pack sono it/en; le altre lingue ricadono
  // sull'inglese (come il resto delle stringhe).
  String call(AppLang lang) => lang == AppLang.it ? it : en;
}

/// Un passo di upgrade PRE-DECISO per una task di pack. Insegna *come* si fa
/// evolvere una task: cosa cambia (frequenza, finestra, qualita', target) e
/// perche'. I campi null lasciano invariato il valore attuale.
class PackUpgrade {
  const PackUpgrade({
    required this.note,
    this.requirements,
    this.days,
    this.start,
    this.end,
    this.period,
    this.target,
    this.toNumber = false,
    this.windowMinutes,
  });

  /// Spiegazione del passo, mostrata sulla card di upgrade.
  final LT note;
  final List<LT>? requirements;
  final List<int>? days;
  final int? start;
  final int? end;
  final DomainPeriod? period;
  final double? target;
  final bool toNumber;
  final int? windowMinutes;
}

/// Blueprint di una task dentro un pack. Non e' una Task: le Task vere nascono
/// con id freschi quando il pack viene applicato.
class TaskSeed {
  const TaskSeed({
    required this.localKey,
    required this.name,
    required this.iconKey,
    required this.kind,
    required this.role,
    this.reward = RewardCurve.linear,
    this.target = 1,
    this.days = const [0, 1, 2, 3, 4, 5, 6],
    this.start = 6,
    this.end = 23,
    this.period = DomainPeriod.daily,
    this.criteria = const [],
    this.anchorKey,
    this.triggerAnchorKey,
    this.windowMinutes = 120,
    this.upgrades = const [],
  });

  /// Chiave locale al pack: genera l'id della task e viene salvata su
  /// Task.packSeedKey per ritrovare gli upgrade pre-scriptati.
  final String localKey;
  final LT name;
  final String iconKey;
  final TaskKind kind;

  /// Ruolo della task dentro il pack, mostrato solo in anteprima.
  final LT role;
  final RewardCurve reward;
  final double target;
  final List<int> days;
  final int start;
  final int end;
  final DomainPeriod period;
  final List<LT> criteria;

  /// Identita' di ancora condivisa (es. 'wake'): rende questa task
  /// referenziabile come trigger anche da altri pack e soggetta a priorita'.
  final String? anchorKey;

  /// Ancora da cui questa task dipende (codipendenza, anche cross-pack):
  /// si sblocca quando la task PRIMARIA con questo anchorKey viene completata.
  final String? triggerAnchorKey;
  final int windowMinutes;
  final List<PackUpgrade> upgrades;
}

/// Un pacchetto di abitudini pre-confezionato: un sistema di task che si
/// sinergizzano. Contenuto statico (ships con l'app), non modificabile.
class HabitPack {
  const HabitPack({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.description,
    required this.seeds,
  });

  final String id;
  final LT name;
  final String iconKey;

  /// Spiega, nel modo piu' semplice possibile, come le task lavorano insieme.
  final LT description;
  final List<TaskSeed> seeds;
}

/// Catalogo dei pack: sistemi di abitudini pre-confezionati e sinergici.
const List<HabitPack> habitPacks = [
  // --------------------------------------------------------- 1. RITMO
  HabitPack(
    id: 'circadian',
    name: LT('Ritmo circadiano', 'Circadian rhythm'),
    iconKey: 'sun',
    description: LT(
      'Le quattro leve che spostano il tuo orologio biologico: svegliarti, '
          'prendere luce al mattino, un segnale di melatonina la sera e un '
          'confine chiaro prima del sonno. Gli upgrade anticipano tutto a '
          'piccoli passi, insieme.',
      'The four levers that shift your body clock: waking, morning light, an '
          'evening melatonin signal and a clear boundary before sleep. The '
          'upgrades move everything earlier in small steps, together.',
    ),
    seeds: [
      TaskSeed(
        localKey: 'wake',
        anchorKey: 'wake',
        name: LT('Sveglia', 'Wake up'),
        iconKey: 'alarm',
        kind: TaskKind.complete,
        role: LT('Apre la mattina e fa da innesco a tutto il resto.',
            'Opens the morning and triggers everything else.'),
        days: [0, 1, 2, 3, 4, 5],
        criteria: [LT('Check entro 1h dal risveglio', 'Check within 1h of waking')],
        upgrades: [
          PackUpgrade(
            note: LT('Stringi la promessa: entro 45 minuti dal risveglio.',
                'Tighten the promise: within 45 minutes of waking.'),
            requirements: [
              LT('Check entro 45 min dal risveglio',
                  'Check within 45 min of waking')
            ],
          ),
          PackUpgrade(
            note: LT('Ancora più stretto: entro 30 minuti dal risveglio.',
                'Even tighter: within 30 minutes of waking.'),
            requirements: [
              LT('Check entro 30 min dal risveglio',
                  'Check within 30 min of waking')
            ],
          ),
        ],
      ),
      TaskSeed(
        localKey: 'light',
        name: LT('Luce mattutina', 'Morning light'),
        iconKey: 'sun',
        kind: TaskKind.complete,
        role: LT('Si sblocca con la sveglia: luce intensa appena sveglio.',
            'Unlocks with wake up: bright light right after waking.'),
        triggerAnchorKey: 'wake',
        windowMinutes: 60,
        days: [0, 1, 2, 3, 4, 5],
        criteria: [
          LT('Luce intensa o sole', 'Bright light or sun'),
          LT('Serrande / tende aperte', 'Blinds / curtains open'),
        ],
        upgrades: [
          PackUpgrade(
            note: LT('Avvicina la luce al risveglio: finestra da 60 a 40 min.',
                'Bring light closer to waking: window from 60 to 40 min.'),
            windowMinutes: 40,
          ),
          PackUpgrade(
            note: LT('Ancora più vicina: finestra da 40 a 25 min.',
                'Even closer: window from 40 to 25 min.'),
            windowMinutes: 25,
          ),
        ],
      ),
      TaskSeed(
        localKey: 'melatonin',
        name: LT('Melatonina cronobiotica', 'Chronobiotic melatonin'),
        iconKey: 'moon',
        kind: TaskKind.complete,
        role: LT('Segnale di fase, ~3h prima di dormire. Non è un sonnifero.',
            'A phase signal, ~3h before sleep. Not a sleeping pill.'),
        days: [0, 1, 2, 3, 4, 6],
        start: 19,
        end: 21,
        criteria: [
          LT('Melatonina cronobiotica, ~3h prima di dormire',
              'Chronobiotic melatonin, ~3h before sleep')
        ],
        upgrades: [
          PackUpgrade(
            note: LT('Il sonno si è anticipato: sposta il segnale a 18-20.',
                'Sleep has moved earlier: shift the signal to 18-20.'),
            start: 18,
            end: 20,
          ),
          PackUpgrade(
            note: LT('Ancora prima: 17-19.', 'Earlier still: 17-19.'),
            start: 17,
            end: 19,
          ),
        ],
      ),
      TaskSeed(
        localKey: 'bed',
        name: LT('A letto', 'In bed'),
        iconKey: 'sleep',
        kind: TaskKind.maintenance,
        role: LT('Chiudi la giornata per far spazio al sonno.',
            'Close the day to make room for sleep.'),
        days: [0, 1, 2, 3, 4, 6],
        criteria: [
          LT('Chiudi tutto entro un’ora dal sonno',
              'Wrap up within an hour of sleep')
        ],
        upgrades: [
          PackUpgrade(
            note: LT('Aggiungi i filtri luce blu la sera.',
                'Add blue-light filters in the evening.'),
            requirements: [
              LT('Chiudi tutto entro un’ora dal sonno',
                  'Wrap up within an hour of sleep'),
              LT('Filtri luce blu attivi', 'Blue-light filters on'),
            ],
          ),
          PackUpgrade(
            note: LT('Togli gli schermi: niente schermi nell’ultima ora.',
                'Drop the screens: none in the last hour.'),
            requirements: [
              LT('Niente schermi nell’ultima ora prima di dormire',
                  'No screens in the last hour before sleep'),
              LT('Filtri luce blu attivi', 'Blue-light filters on'),
            ],
          ),
        ],
      ),
    ],
  ),

  // ------------------------------------------------- 2. ROUTINE MATTUTINA
  HabitPack(
    id: 'morning',
    name: LT('Routine mattutina', 'Morning routine'),
    iconKey: 'coffee',
    description: LT(
      'La catena concreta della mattina, agganciata alla sveglia: una doccia '
          'per metterti in piedi e una colazione sempre alla stessa ora, che '
          'col tempo diventa una sveglia biologica. Va a braccetto con Ritmo '
          'circadiano.',
      'The concrete morning chain, hooked to waking: a shower to get you up '
          'and a breakfast at the same time every day, which becomes a '
          'biological alarm. It pairs with Circadian rhythm.',
    ),
    seeds: [
      TaskSeed(
        localKey: 'shower',
        name: LT('Doccia', 'Shower'),
        iconKey: 'shower',
        kind: TaskKind.complete,
        role: LT('La prima cosa concreta: falla e sei in piedi.',
            'The first concrete thing: do it and you are up.'),
        triggerAnchorKey: 'wake',
        windowMinutes: 90,
        days: [0, 1, 2, 3, 4, 5],
        criteria: [LT('Doccia fatta', 'Shower done')],
        upgrades: [
          PackUpgrade(
            note: LT('Rendila più asciutta: doccia entro 10 minuti.',
                'Make it leaner: shower within 10 minutes.'),
            requirements: [
              LT('Doccia entro 10 minuti', 'Shower within 10 minutes')
            ],
          ),
          PackUpgrade(
            note: LT('Essenziale: doccia entro 5 minuti.',
                'Essential: shower within 5 minutes.'),
            requirements: [LT('Doccia entro 5 minuti', 'Shower within 5 minutes')],
          ),
        ],
      ),
      TaskSeed(
        localKey: 'breakfast',
        anchorKey: 'breakfast',
        name: LT('Colazione', 'Breakfast'),
        iconKey: 'coffee',
        kind: TaskKind.complete,
        role: LT(
            'Mangia presto e sempre alla stessa ora: diventa un segnale biologico.',
            'Eat early and always at the same time: it becomes a biological signal.'),
        triggerAnchorKey: 'wake',
        windowMinutes: 120,
        days: [0, 1, 2, 3, 4, 5],
        criteria: [LT('Colazione fatta', 'Breakfast done')],
        upgrades: [
          PackUpgrade(
            note: LT('Stabilizza il segnale: colazione sempre alla stessa ora.',
                'Stabilize the signal: breakfast always at the same time.'),
            requirements: [
              LT('Colazione fatta', 'Breakfast done'),
              LT('Sempre alla stessa ora', 'Always at the same time'),
            ],
          ),
          PackUpgrade(
            note: LT('Stringi la finestra dal risveglio.',
                'Tighten the window from waking.'),
            windowMinutes: 90,
          ),
        ],
      ),
      TaskSeed(
        localKey: 'lunch',
        anchorKey: 'lunch',
        name: LT('Pranzo', 'Lunch'),
        iconKey: 'food',
        kind: TaskKind.complete,
        role: LT(
            'Punto fisso di metà giornata; fa da ancora alle sessioni pomeridiane.',
            'A midday fixed point; it anchors the afternoon sessions.'),
        days: [0, 1, 2, 3, 4, 5],
        start: 12,
        end: 15,
        criteria: [LT('Pranzo fatto', 'Lunch done')],
        upgrades: [
          PackUpgrade(
            note: LT('Rendi l’ora costante.', 'Keep the time constant.'),
            requirements: [
              LT('Pranzo fatto', 'Lunch done'),
              LT('Sempre alla stessa ora', 'Always at the same time'),
            ],
          ),
        ],
      ),
    ],
  ),

  // ----------------------------------------------------- 3. ALLENAMENTO
  HabitPack(
    id: 'training',
    name: LT('Allenamento', 'Training'),
    iconKey: 'dumbbell',
    description: LT(
      'Un programma di base per tenersi in forma: l’app traccia la disciplina '
          'del rituale (ci sei andato, con che costanza), non ti dà la scheda. '
          'Chi fa sul serio mette la propria.',
      'A basic program to stay in shape: the app tracks the discipline of the '
          'ritual (you showed up, how consistently), it does not give you the '
          'plan. If you are serious, bring your own.',
    ),
    seeds: [
      TaskSeed(
        localKey: 'train',
        anchorKey: 'train',
        name: LT('Allenamento', 'Workout'),
        iconKey: 'dumbbell',
        kind: TaskKind.complete,
        role: LT('Il check dell’allenamento; la scheda la decidi tu.',
            'The workout check; you decide the plan.'),
        days: [0, 2, 4],
        start: 6,
        end: 22,
        criteria: [LT('Allenamento fatto', 'Workout done')],
        upgrades: [
          PackUpgrade(
            note: LT('Più puntuale: allenati nella fascia che ti sei dato.',
                'More punctual: train in the slot you set.'),
            requirements: [
              LT('Allenamento fatto', 'Workout done'),
              LT('Nella fascia oraria scelta', 'In the chosen time slot'),
            ],
          ),
          PackUpgrade(
            note: LT('Proteggi le articolazioni: riscaldamento prima di iniziare.',
                'Protect your joints: warm up before you start.'),
            requirements: [
              LT('Allenamento fatto', 'Workout done'),
              LT('Riscaldamento fatto', 'Warm-up done'),
            ],
          ),
          PackUpgrade(
            note: LT('Aggiungi una seduta: porta la frequenza a 4 volte.',
                'Add a session: bring frequency to 4 times.'),
            days: [0, 2, 4, 5],
          ),
        ],
      ),
      TaskSeed(
        localKey: 'recovery',
        name: LT('Reintegro', 'Recovery'),
        iconKey: 'drop',
        kind: TaskKind.complete,
        role: LT('Chiudi la sessione: idratazione e reintegro.',
            'Close the session: hydration and recovery.'),
        triggerAnchorKey: 'train',
        windowMinutes: 90,
        days: [0, 2, 4],
        criteria: [LT('Idratazione post-sessione', 'Post-session hydration')],
        upgrades: [
          PackUpgrade(
            note: LT('Aggiungi il reintegro post, senza stare a dire cosa.',
                'Add post recovery, no need to say what.'),
            requirements: [
              LT('Idratazione + reintegro post', 'Hydration + post recovery')
            ],
          ),
          PackUpgrade(
            note: LT('Struttura pre e post attorno alla sessione.',
                'Structure pre and post around the session.'),
            requirements: [
              LT('Reintegro pre e post sessione',
                  'Pre- and post-session recovery')
            ],
          ),
        ],
      ),
    ],
  ),

  // ---------------------------------------------------- 4. PRODUTTIVITA
  HabitPack(
    id: 'focus',
    name: LT('Produttività', 'Productivity'),
    iconKey: 'bolt',
    description: LT(
      'Separa i colli di bottiglia: una task per vincere la partenza (entrare '
          'nel posto giusto, togliere le distrazioni) e due sessioni a pomodoro '
          'per la concentrazione, ancorate ai pasti. Domenica è scarico.',
      'Separates the bottlenecks: one task to win the start (get in the right '
          'place, remove distractions) and two pomodoro sessions for focus, '
          'anchored to meals. Sunday is a rest day.',
    ),
    seeds: [
      TaskSeed(
        localKey: 'env',
        name: LT('Ambiente di lavoro', 'Work setup'),
        iconKey: 'work',
        kind: TaskKind.complete,
        role: LT('Vinci la partenza: posto giusto, niente distrazioni.',
            'Win the start: right place, no distractions.'),
        days: [0, 1, 2, 3, 4, 5],
        criteria: [
          LT('Entrato nell’ambiente di lavoro', 'Entered the work environment'),
          LT('Telefono fuori dal luogo di lavoro', 'Phone outside the workspace'),
        ],
        upgrades: [
          PackUpgrade(
            note: LT('Resta seduto: non alzarti durante la sessione.',
                'Stay put: no getting up during the session.'),
            requirements: [
              LT('Entrato nell’ambiente di lavoro', 'Entered the work environment'),
              LT('Telefono fuori dal luogo di lavoro', 'Phone outside the workspace'),
              LT('Non alzarti durante la sessione',
                  'No getting up during the session'),
            ],
          ),
        ],
      ),
      TaskSeed(
        localKey: 'am',
        name: LT('Sessione mattina', 'Morning session'),
        iconKey: 'timer',
        kind: TaskKind.measure,
        target: 2,
        reward: RewardCurve.exponential,
        role: LT('Conta le sessioni di focus della mattina.',
            'Count the morning focus sessions.'),
        triggerAnchorKey: 'breakfast',
        windowMinutes: 300,
        days: [0, 1, 2, 3, 4, 5],
        criteria: [
          LT('Sessione da 25 min + 5 di pausa', '25-min session + 5 break')
        ],
        upgrades: [
          PackUpgrade(
            note: LT('Passa al pomodoro pieno: 50 minuti + 10 di pausa.',
                'Move to a full pomodoro: 50 minutes + 10 break.'),
            requirements: [
              LT('Sessione da 50 min + 10 di pausa', '50-min session + 10 break')
            ],
          ),
          PackUpgrade(
            note: LT('Alza l’asticella: da 2 a 3 sessioni.',
                'Raise the bar: from 2 to 3 sessions.'),
            target: 3,
          ),
        ],
      ),
      TaskSeed(
        localKey: 'pm',
        name: LT('Sessione pomeriggio', 'Afternoon session'),
        iconKey: 'timer',
        kind: TaskKind.measure,
        target: 2,
        reward: RewardCurve.exponential,
        role: LT('Conta le sessioni di focus del pomeriggio.',
            'Count the afternoon focus sessions.'),
        triggerAnchorKey: 'lunch',
        windowMinutes: 300,
        days: [0, 1, 2, 3, 4, 5],
        criteria: [
          LT('Sessione da 25 min + 5 di pausa', '25-min session + 5 break')
        ],
        upgrades: [
          PackUpgrade(
            note: LT('Passa al pomodoro pieno: 50 minuti + 10 di pausa.',
                'Move to a full pomodoro: 50 minutes + 10 break.'),
            requirements: [
              LT('Sessione da 50 min + 10 di pausa', '50-min session + 10 break')
            ],
          ),
          PackUpgrade(
            note: LT('Alza l’asticella: da 2 a 3 sessioni.',
                'Raise the bar: from 2 to 3 sessions.'),
            target: 3,
          ),
        ],
      ),
    ],
  ),
];

HabitPack? habitPackById(String id) {
  for (final p in habitPacks) {
    if (p.id == id) return p;
  }
  return null;
}

/// Ritrova il seed di un pack dalla sua chiave locale.
TaskSeed? packSeed(String packId, String? seedKey) {
  if (seedKey == null) return null;
  final pack = habitPackById(packId);
  if (pack == null) return null;
  for (final s in pack.seeds) {
    if (s.localKey == seedKey) return s;
  }
  return null;
}
