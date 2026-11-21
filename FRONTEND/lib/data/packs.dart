import '../l10n/strings.dart';
import '../models/models.dart';

/// Testo bilingue per i contenuti statici dei pack (non possono usare context).
class LT {
  const LT(this.it, this.en);
  final String it;
  final String en;
  String call(AppLang lang) => lang == AppLang.en ? en : it;
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
    this.triggerKey,
    this.windowMinutes = 120,
    this.upgrades = const [],
  });

  /// Chiave locale al pack: referenziata da [triggerKey] di altri seed e salvata
  /// su Task.packSeedKey per ritrovare gli upgrade.
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

  /// localKey del seed-trigger nello stesso pack (codipendenza interna).
  final String? triggerKey;
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

/// Catalogo dei pack. Per ora un solo pack simbolico per collaudare la pipeline.
const List<HabitPack> habitPacks = [
  HabitPack(
    id: 'morning',
    name: LT('Avvio mattina', 'Morning kickstart'),
    iconKey: 'sun',
    description: LT(
      'Una catena che parte dalla sveglia: appena la spunti si aprono due '
          'finestre brevi per idratarti e muoverti. Il risveglio fa da innesco, '
          'le altre due dipendono da lui — cosi\' la mattina ha un ordine.',
      'A chain that starts from waking up: once you check it, two short windows '
          'open to hydrate and move. Waking is the trigger, the other two depend '
          'on it — so your morning has an order.',
    ),
    seeds: [
      TaskSeed(
        localKey: 'wake',
        name: LT('Sveglia', 'Wake up'),
        iconKey: 'alarm',
        kind: TaskKind.complete,
        role: LT(
          'Il trigger della catena: spuntala appena sei in piedi.',
          'The chain trigger: check it as soon as you are up.',
        ),
        criteria: [
          LT('Piedi fuori dal letto', 'Feet out of bed'),
        ],
        upgrades: [
          PackUpgrade(
            note: LT(
              'Ora che la sveglia e\' stabile, aggiungi una qualita\': niente '
                  'telefono nei primi minuti. Stesso impegno, un gradino in piu\'.',
              'Now that waking is stable, add a quality bar: no phone in the '
                  'first minutes. Same effort, one step up.',
            ),
            requirements: [
              LT('Piedi fuori dal letto', 'Feet out of bed'),
              LT('Niente telefono per 5 minuti', 'No phone for 5 minutes'),
            ],
          ),
        ],
      ),
      TaskSeed(
        localKey: 'water',
        name: LT('Idratazione', 'Hydration'),
        iconKey: 'drop',
        kind: TaskKind.measure,
        target: 2,
        triggerKey: 'wake',
        windowMinutes: 60,
        role: LT(
          'Si sblocca con la sveglia: due bicchieri entro un\'ora.',
          'Unlocks with wake up: two glasses within an hour.',
        ),
        upgrades: [
          PackUpgrade(
            note: LT(
              'Alzi l\'asticella sul target: da 2 a 3 bicchieri. La finestra '
                  'resta larga finche\' l\'abitudine non e\' solida.',
              'Raise the target: from 2 to 3 glasses. The window stays wide '
                  'until the habit is solid.',
            ),
            target: 3,
          ),
          PackUpgrade(
            note: LT(
              'Ora stringi la finestra: da 60 a 45 minuti. Meno margine, piu\' '
                  'automatismo legato al risveglio.',
              'Now tighten the window: from 60 to 45 minutes. Less slack, more '
                  'automation tied to waking.',
            ),
            windowMinutes: 45,
          ),
        ],
      ),
      TaskSeed(
        localKey: 'move',
        name: LT('Movimento', 'Movement'),
        iconKey: 'run',
        kind: TaskKind.complete,
        triggerKey: 'wake',
        windowMinutes: 120,
        role: LT(
          'Si sblocca con la sveglia: due ore per muovere il corpo.',
          'Unlocks with wake up: two hours to move your body.',
        ),
        criteria: [
          LT('Almeno 5 minuti di movimento', 'At least 5 minutes moving'),
        ],
        upgrades: [
          PackUpgrade(
            note: LT(
              'Da "fatto/non fatto" a quantita\': conta i minuti. E\' il momento '
                  'di misurare, non solo spuntare.',
              'From done/not-done to a quantity: count the minutes. Time to '
                  'measure, not just check.',
            ),
            toNumber: true,
            target: 10,
          ),
          PackUpgrade(
            note: LT(
              'Stringi la finestra da 2 ore a 1 ora e mezza: il movimento si '
                  'lega sempre piu\' al risveglio.',
              'Tighten the window from 2h to 1h30: movement binds ever closer '
                  'to waking.',
            ),
            windowMinutes: 90,
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
