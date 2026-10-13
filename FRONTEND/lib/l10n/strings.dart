import 'package:flutter/widgets.dart';

/// Lingue supportate.
enum AppLang {
  it('Italiano', 'it'),
  en('English', 'en');

  const AppLang(this.nativeName, this.code);

  /// Nome nella propria lingua (endonimo), mai tradotto.
  final String nativeName;

  /// Codice locale (per MaterialApp).
  final String code;
}

/// Stringhe localizzate. Sistema "a mano" (niente code-gen): ogni stringa e'
/// un getter che sceglie la lingua. Aggiungere una lingua = estendere `_p`.
/// Si accede con `context.s.<stringa>` grazie a [L10nScope].
class S {
  const S(this.lang);

  final AppLang lang;

  String _p(String it, String en) => lang == AppLang.en ? en : it;

  // --- generali ---
  String get ok => 'OK';
  String get cancel => _p('Annulla', 'Cancel');
  String get save => _p('Salva', 'Save');

  // --- account ---
  String get account => 'Account';
  String get localProfile => _p('Profilo locale', 'Local profile');
  String get yourName => _p('Il tuo nome', 'Your name');
  String get whatsYourName => _p('Come ti chiami', "What's your name");
  String get signInUp => _p('Accedi / Registrati', 'Sign in / Sign up');
  String get syncSoon =>
      _p('Sincronizzazione account presto disponibile.',
          'Account sync coming soon.');
  String get soon => _p('presto', 'soon');

  // --- sezioni ---
  String get appearance => _p('Aspetto', 'Appearance');
  String get language => _p('Lingua', 'Language');
  String get backupAndData => _p('Backup e dati', 'Backup & data');
  String get developer => _p('Sviluppatore', 'Developer');

  // --- backup ---
  String get shareBackup =>
      _p('Condividi backup (Drive / File)', 'Share backup (Drive / Files)');
  String get importBackup =>
      _p('Importa backup dagli appunti', 'Import backup from clipboard');
  String get exportBackupClipboard =>
      _p('Esporta backup negli appunti', 'Copy backup to clipboard');
  String get shareFailed => _p('Condivisione non riuscita', 'Share failed');
  String get backupRestored => _p('Backup ripristinato', 'Backup restored');
  String get backupInvalid => _p('Backup non valido', 'Invalid backup');
  String get backupCopied =>
      _p('Backup copiato negli appunti', 'Backup copied to clipboard');

  // --- debug / strumenti ---
  String get devUnlocked =>
      _p('Strumenti sviluppatore sbloccati', 'Developer tools unlocked');
  String get devHidden => _p('Strumenti nascosti', 'Tools hidden');
  String devMissing(int n) => _p('Mancano $n…', '$n to go…');
  String get prototypeMode => _p('MODALITÀ PROTOTIPO', 'PROTOTYPE MODE');
  String get modeProxy => 'Proxy';
  String get modeFromZero => _p('Configura da 0', 'Set up from zero');
  String get sendTestNotif =>
      _p('Invia notifica di test', 'Send test notification');
  String get testNotifSent =>
      _p('Notifica di test inviata', 'Test notification sent');
  String get rescheduleReminders =>
      _p('Riprogramma promemoria', 'Reschedule reminders');
  String remindersScheduled(int n) =>
      _p('Promemoria programmati: $n', 'Reminders scheduled: $n');
  String get notifIn1Min =>
      _p('Notifica tra 1 minuto (test)', 'Notification in 1 minute (test)');
  String get scheduledNotifTest =>
      _p('Test notifica programmata', 'Scheduled notification test');
  String get bonusReport => _p('Report bonus', 'Bonus report');
  String get bonusComposition =>
      _p('Composizione bonus', 'Bonus breakdown');
  String get resetThisMode =>
      _p('Reimposta questa modalità', 'Reset this mode');
  String get archiveReset => _p('Archivio reimpostato', 'Archive reset');
  String get hideDevTools =>
      _p('Nascondi strumenti sviluppatore', 'Hide developer tools');

  // --- home ---
  String get todayExecution => _p('Esecuzione di oggi', "Today's tasks");
  String get filterAvailable => _p('Disponibili', 'Available');
  String get filterAll => _p('Tutte', 'All');
  String get freeDay => _p('Giornata libera', 'Free day');
  String doneOfTotal(int done, int total) =>
      _p('$done su $total completate', '$done of $total done');
  String get trend => _p('ANDAMENTO', 'TREND');
  String get yesterdayReview => _p('Ieri — rivedi', 'Yesterday — review');
  String get reviewSubtitle => _p(
      'Rivaluta a mente fredda · entro stasera',
      'Reassess with a clear head · by tonight');
  String get relapseToday => _p('Ricaduta oggi', 'Relapsed today');
  String cleanStreak(int days, String reward) =>
      _p('Pulito · ${days}g · +$reward', 'Clean · ${days}d · +$reward');
  String get relapse => _p('Ricaduta', 'Relapse');
  String get archive => _p('Archivia', 'Archive');
  String get reconfigure => _p('Rivedi', 'Review');
  String get levelUp => 'Level up';
  String get hide => _p('Nascondi', 'Hide');
  String get scoreDone => _p('Fatto', 'Done');
  String get maintenance => _p('Mantenimento', 'Maintenance');
  String get scoreComposition =>
      _p('COMPOSIZIONE PUNTEGGIO', 'SCORE BREAKDOWN');
  String get ecoTitle => _p('Eco', 'Echo');
  String get ecoBody => _p(
      'Stai ricevendo punti da abitudini completate in precedenza che oggi '
          'non sono in programma: il loro merito continua a contare per '
          'qualche giorno.',
      "You're getting points from habits completed earlier that aren't "
          'scheduled today: their merit keeps counting for a few days.');
  String get bonusConstancyTitle => _p('Bonus costanza', 'Consistency bonus');
  String get bonusConstancyBody => _p(
      'Stai ricevendo un extra per la costanza delle tue abitudini '
          '(streak attive).',
      "You're getting an extra for the consistency of your habits "
          '(active streaks).');
  String get pts => _p('pt', 'pts');
  String pointsToday(String value) =>
      _p('+$value punti oggi', '+$value points today');
  String greeting(int hour) => hour < 12
      ? _p('Buongiorno', 'Good morning')
      : (hour < 18
          ? _p('Buon pomeriggio', 'Good afternoon')
          : _p('Buonasera', 'Good evening'));
  String get whatToStart =>
      _p('Da cosa iniziamo oggi?', 'What shall we start with?');
  String get nothingHere => _p('Niente in questa vista', 'Nothing in this view');
  String get emptyEnvBody => _p(
      'Oggi non è previsto nulla in questo ambiente.',
      'Nothing scheduled in this environment today.');
  String get emptyFilterBody => _p(
      'Cambia filtro in alto per vedere le altre task di oggi.',
      "Switch the filter above to see today's other tasks.");

  // --- trend ---
  String get monitoring => _p('Monitoraggio', 'Tracking');
  String get trendTitle => 'Trend';
  String get metricPointsToday => _p('PUNTI OGGI', 'POINTS TODAY');
  String get metricScore => _p('PUNTEGGIO', 'SCORE');
  String get metricBonus => 'BONUS';
  String get streakInProgress => _p('Streak in corso', 'Active streaks');
  String get noActiveStreak => _p('Nessuna streak attiva', 'No active streaks');
  String get noStreakBody => _p(
      'Completa le task nei loro giorni: qui le costanze crescono.',
      'Complete tasks on their days: streaks grow here.');
  String get habitsHealth => _p('Salute delle abitudini', 'Habits health');
  String get healthy => _p('IN SALUTE', 'HEALTHY');
  String get needsCare => _p('DA CURARE', 'NEEDS CARE');
  String get analysis => _p('Analisi', 'Analysis');
  String get modeNumber => _p('Number', 'Numbers');
  String get modeAbstinence => _p('Astinenze', 'Abstinences');
  String get modeBonus => 'Bonus';
  String get rangeWeek => _p('7 giorni', '7 days');
  String get rangeMonth => _p('30 giorni', '30 days');
  String get rangeYear => _p('12 mesi', '12 months');
  String get noMeasureTask => _p('Nessuna task a quantità', 'No measured tasks');
  String get noMeasureBody => _p(
      'Le task di tipo misura appariranno qui.',
      'Measure-type tasks will appear here.');
  String get noAbstinence => _p('Nessuna astinenza', 'No abstinences');
  String get noAbstinenceBody => _p(
      'Le astinenze appariranno qui, con la loro curva.',
      'Abstinences will appear here, with their curve.');
  String get avg => _p('MEDIA', 'AVG');
  String get max => _p('MASSIMO', 'MAX');
  String get today => _p('OGGI', 'TODAY');
  String get peak => _p('PICCO', 'PEAK');
  String bellNote(int tau) => _p(
      'Punti della campana: salgono verso il picco (τ=${tau}g) poi calano.',
      'Bell points: rise to the peak (τ=${tau}d) then fall.');
  String get bonusTimeNote => _p(
      'Punti dal bonus ogni giorno (cala dopo upgrade e fallimenti).',
      'Bonus points each day (drops after upgrades and failures).');

  // --- wizard creazione (condiviso task_wizard / first_run) ---
  String taskCreated(String name) =>
      _p('Task creata: $name', 'Task created: $name');
  String get wizStepRecognition => _p('Riconoscimento', 'Recognition');
  String get wizStepDuration => _p('Durata', 'Duration');
  String get wizStepCriteria => _p('Criteri', 'Criteria');
  String get wizStepType => _p('Tipologia', 'Type');
  String get wizSubRecognition => _p(
      "Come si chiama e come la riconosci in un colpo d'occhio.",
      "What it's called and how you recognize it at a glance.");
  String get wizSubDuration => _p(
      "Nei giorni che scegli WAY se l'aspetta. Negli altri no.",
      'On the days you choose, WAY expects it. Not on the others.');
  String get wizSubCriteria => _p(
      'Ogni condizione che aggiungi rende la task più impegnativa.',
      'Each condition you add makes the task more demanding.');
  String get wizSubType =>
      _p("Come si registra l'esecuzione ogni giorno.", 'How you log it each day.');
  String get createTask => _p('Crea la task', 'Create task');
  String get continueLabel => _p('Continua', 'Continue');
  String get name => _p('Nome', 'Name');
  String get nameHint =>
      _p('Studio, Allenamento, Sveglia...', 'Study, Workout, Alarm...');
  String get icon => _p('ICONA', 'ICON');
  String get addCriterion => _p('Aggiungi criterio', 'Add criterion');
  String get kindComplete => _p('Completa', 'Complete');
  String get kindCompleteSub => _p('Fatto / non fatto', 'Done / not done');
  String get kindMeasure => _p('Misura', 'Measure');
  String get kindMeasureSub => _p('Quantità al giorno', 'Amount per day');
  String get kindMaintain => _p('Mantieni', 'Maintain');
  String get kindMaintainSub =>
      _p('Intatta finché non la infrangi', 'Intact until you break it');
  String get kindAbstinence => _p('Astinenza', 'Abstinence');
  String get kindAbstinenceSub =>
      _p('Il valore è nel non ricadere', 'The value is in not relapsing');
  String get kindCompleteDesc => _p(
      'Task senza gradazione: o è rispettata o no.',
      'Task with no gradation: either met or not.');
  String get kindMeasureDesc => _p(
      'La quantità dice la qualità: ore di studio, pagine, uscite.',
      'The amount tells the quality: study hours, pages, outings.');
  String get kindMaintainDesc => _p(
      'Parte completata e resta valida finché non infrangi una delle '
          'condizioni (i criteri del passo precedente). Alla prima infrazione '
          'la giornata è persa.',
      'Starts complete and stays valid until you break one of the conditions '
          '(the criteria from the previous step). At the first breach the day '
          'is lost.');
  String get kindAbstinenceDesc => _p(
      'Ogni giorno pulito conta. Il punteggio cresce nella fase critica '
          'iniziale e poi si stabilizza: scegli quanto dura.',
      'Every clean day counts. The score grows in the initial critical phase '
          'then stabilizes: choose how long it lasts.');
  String get rewardSystem => _p('SISTEMA DI RICOMPENSA', 'REWARD SYSTEM');
  String get rewardLinear => _p('Lineare', 'Linear');
  String get rewardLinearSub => _p('Attrito costante', 'Constant friction');
  String get rewardExp => _p('Esponenziale', 'Exponential');
  String get rewardExpSub => _p('Attrito crescente', 'Growing friction');
  String get rewardLinearDesc => _p(
      'Ogni unità in più vale quanto la precedente. Adatto quando continuare '
          "non costa fatica aggiuntiva: uscire con gli amici una volta in più.",
      'Each extra unit is worth the same as the previous. Good when continuing '
          'costs no extra effort: going out with friends one more time.');
  String get rewardExpDesc => _p(
      'Ogni unità in più vale più della precedente. Adatto quando la fatica '
          "cresce: la quinta ora di studio non è la prima.",
      'Each extra unit is worth more than the previous. Good when effort '
          "grows: the fifth study hour isn't the first.");
  String get dailyTarget => _p('Target giornaliero', 'Daily target');
  String get targetHint => _p('es. 40, 5, 3...', 'e.g. 40, 5, 3...');
  String get criticalPhase => _p('FASE CRITICA', 'CRITICAL PHASE');
  String get phaseShort => _p('Breve', 'Short');
  String get phaseMedium => _p('Media', 'Medium');
  String get phaseLong => _p('Lunga', 'Long');

  // --- date (nomi localizzati, gia' capitalizzati) ---
  List<String> get months => lang == AppLang.en
      ? const [
          'January', 'February', 'March', 'April', 'May', 'June', 'July',
          'August', 'September', 'October', 'November', 'December'
        ]
      : const [
          'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
          'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
        ];
  List<String> get daysLong => lang == AppLang.en
      ? const [
          'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
          'Sunday'
        ]
      : const [
          'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato',
          'Domenica'
        ];
  List<String> get daysShort => lang == AppLang.en
      ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
      : const ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
}

/// Rende disponibile [S] in tutto l'albero. Posizionato sopra MaterialApp,
/// cosi' lo vedono anche le route e i dialog.
class L10nScope extends InheritedWidget {
  const L10nScope({super.key, required this.strings, required super.child});

  final S strings;

  static S of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<L10nScope>();
    return w?.strings ?? const S(AppLang.it);
  }

  @override
  bool updateShouldNotify(L10nScope old) => old.strings.lang != strings.lang;
}

extension L10nX on BuildContext {
  /// Stringhe localizzate correnti.
  S get s => L10nScope.of(this);
}
