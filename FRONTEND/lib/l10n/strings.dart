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

  // --- first run (onboarding guidato) ---
  String get frTitleName => _p('Come si chiama?', "What's it called?");
  String frTitleDays(String name) =>
      _p('Quando vale $name?', 'When does $name count?');
  String get frTitleTrack => _p('Come la segni?', 'How do you log it?');
  String get frTitleCurve => _p(
      'Ogni unità in più vale uguale?', 'Does each extra unit count the same?');
  String get frTitleAmount =>
      _p('Quanto ne vuoi fare?', 'How much do you want to do?');
  String get frTitleCriteria =>
      _p('Cosa vuol dire farla bene?', 'What does doing it well mean?');
  String get frSubName => _p(
      'Il nome che te la fa riconoscere in un secondo.',
      'The name that lets you recognize it in a second.');
  String get frSubDays => _p(
      "Nei giorni che scegli WAY se l'aspetta. Negli altri no, e la tua "
          'percentuale non ne risente.',
      "On the days you choose, WAY expects it. Not on the others, and your "
          "percentage isn't affected.");
  String get frSubTrack => _p(
      'Decide cosa WAY ti chiede ogni giorno. Puoi cambiarlo quando vuoi.',
      'Decides what WAY asks of you each day. You can change it anytime.');
  String get frSubCurve => _p(
      'Serve a WAY per capire quanto premiare quello che fai oltre la soglia.',
      'Helps WAY understand how much to reward what you do beyond the '
          'threshold.');
  String get frSubAmount => _p(
      'La soglia è il minimo che conta come giornata valida. Il target è la '
          'giornata piena, il 100%.',
      'The threshold is the minimum that counts as a valid day. The target is '
          'a full day, 100%.');
  String get frSubCriteria => _p(
      'Facoltativo. Ogni condizione che aggiungi rende la task più '
          'impegnativa, e WAY lo tiene in conto.',
      'Optional. Each condition you add makes the task more demanding, and WAY '
          'accounts for it.');
  String get createWithoutCriteria =>
      _p('Crea senza criteri', 'Create without criteria');
  String get frNameHint =>
      _p('Studio, Allenamento, Lettura…', 'Study, Workout, Reading…');
  String get allDays => _p('Tutti i giorni', 'Every day');
  String get weekdaysOnly => _p('Solo feriali', 'Weekdays only');
  String get frKindCompleteTitle => _p('Fatta o non fatta', 'Done or not done');
  String get frKindCompleteBody =>
      _p('Ti basta una spunta a fine giornata.',
          'Just a check at the end of the day.');
  String get frKindMeasureTitle => _p('Conta quanto', 'Count how much');
  String get frKindMeasureBody => _p(
      'Registri una quantità: ore, pagine, chilometri.',
      'You log an amount: hours, pages, kilometers.');
  String get frCurveLinearTitle =>
      _p('Sì, vale sempre uguale', 'Yes, always the same');
  String get frCurveLinearBody => _p(
      'La decima uscita con gli amici costa quanto la prima.',
      'The tenth outing with friends costs as much as the first.');
  String get frCurveExpTitle =>
      _p('No, costa sempre di più', 'No, it costs more each time');
  String get frCurveExpBody => _p(
      'La quinta ora di studio pesa più della prima.',
      'The fifth study hour weighs more than the first.');
  String get dailyTargetCaps => _p('TARGET GIORNALIERO', 'DAILY TARGET');
  String get frAmountNote => _p(
      'La quantità che vale il 100% della giornata.',
      'The amount that counts as 100% of the day.');
  List<String> get frTagsComplete => _p3(
      ['Sveglia', 'Medicina', 'Stretching'],
      ['Alarm', 'Medicine', 'Stretching']);
  List<String> get frTagsMeasure =>
      _p3(['Studio', 'Lettura', 'Corsa'], ['Study', 'Reading', 'Running']);

  List<String> _p3(List<String> it, List<String> en) =>
      lang == AppLang.en ? en : it;

  // --- evolution & review ---
  String get close => _p('Chiudi', 'Close');
  String get confirm => _p('Conferma', 'Confirm');
  String get skip => _p('Salta', 'Skip');
  String get evolveUpgradeHelp => _p(
      'Sali di livello ridefinendo requisiti e dominio (più impegnativa); '
          'Mantieni per fermare la crescita del bonus restando al livello '
          'attuale; Consolida per bloccare gli upgrade e lasciar crescere '
          'solo lo streak.',
      'Level up by redefining requirements and domain (more demanding); Keep '
          'to stop bonus growth staying at the current level; Consolidate to '
          'lock upgrades and let only the streak grow.');
  String get evolveReconfigHelp => _p(
      'Tre fallimenti di fila: ridefinisci per renderla sostenibile. Il '
          'downgrade è opzionale.',
      'Three failures in a row: redefine it to make it sustainable. The '
          'downgrade is optional.');
  String get transformToMeasure =>
      _p('Trasforma in misura', 'Turn into measure');
  String requirementN(int n) => _p('Requisito $n', 'Requirement $n');
  String get conditionHint => _p('condizione...', 'condition...');
  String get levelDown => _p('Scendi di livello (-1)', 'Level down (-1)');
  String get levelUpAction => _p('Sali di livello', 'Level up');
  String get keepAction => _p('Mantieni', 'Keep');
  String get consolidate => _p('Consolida', 'Consolidate');
  String get reviewTitle => _p('Review a mente fredda', 'Cold-headed review');
  String get reviewExplain => _p(
      'Le correzioni valgono metà: recuperi metà dei punti che aggiungi, '
          'restituisci metà di quelli che togli. La costanza (streak) non si '
          'spezza.',
      'Corrections are worth half: you recover half the points you add, give '
          "back half of those you remove. Consistency (streak) doesn't break.");
  String reviewYesterday(String original) =>
      _p('Ieri $original → dopo review', 'Yesterday $original → after review');
  String get confirmReview => _p('Conferma review', 'Confirm review');
  String get statusIntact => _p('Intatta', 'Intact');
  String get statusCompromised => _p('Compromessa', 'Compromised');
  String get statusClean => _p('Pulito', 'Clean');
  String get statusDone => _p('Fatto', 'Done');
  String get statusNotDone => _p('Non fatto', 'Not done');

  // --- places & place wizard ---
  String get placesEyebrow => _p('Contesto', 'Context');
  String get placesTitle => 'Places';
  String get emptyHub => _p("Svuota l'hub", 'Clear the hub');
  String get noActiveEnv => _p(
      'Nessun ambiente attivo: resta solo la core session',
      'No active environment: only the core session remains');
  String get hubNote => _p(
      "Un solo ambiente per volta può stare nell'hub. Le statistiche si "
          "adattano al carico dell'ambiente attivo, non a un carico fisso.",
      "Only one environment at a time can be in the hub. Stats adapt to the "
          "active environment's load, not a fixed load.");
  String get active => _p('Attivo', 'Active');
  String placeLoad(int load, bool core) => _p(
      '$load task · core session ${core ? "attiva" : "disattivata"}',
      '$load tasks · core session ${core ? "on" : "off"}');
  String get createEnv => _p('Crea un ambiente', 'Create an environment');
  String get noEnvironments => _p('Nessun ambiente', 'No environments');
  String activeEnv(String name) =>
      _p('Ambiente attivo: $name', 'Active environment: $name');
  String envCreated(String name) =>
      _p('Ambiente creato: $name', 'Environment created: $name');
  String get setupComplete => _p('Configurazione completata', 'Setup complete');
  String get envUpdated => _p('Ambiente aggiornato', 'Environment updated');
  String get pwTitleRecog =>
      _p('Dove cambia la tua routine?', 'Where does your routine change?');
  String get pwTitleLoad => _p('Cosa ti porti dietro?', 'What do you bring along?');
  String get pwStepLoad => _p('Carico', 'Load');
  String get pwSubRecog => _p(
      "Un ambiente è un posto o un periodo con regole diverse: casa, "
          "università, una trasferta, la sessione d'esami.",
      'An environment is a place or period with different rules: home, '
          'university, a trip, exam season.');
  String get pwSubLoad => _p(
      'Puoi tenere la Core Session e aggiungere solo ciò che serve qui, '
          'oppure spegnerla e costruire una routine diversa.',
      'You can keep the Core Session and add only what you need here, or turn '
          'it off and build a different routine.');
  String get pwSub2Recog => _p(
      'Dove sei e che periodo è. Il nome basta a distinguerlo.',
      'Where you are and what period it is. The name is enough to tell it '
          'apart.');
  String get pwSub2Load =>
      _p('Quali task hanno senso qui dentro.', 'Which tasks make sense in here.');
  String get createEnvironment => _p("Crea l'ambiente", 'Create environment');
  String get envName => _p("Nome dell'ambiente", 'Environment name');
  String get envNameHint => _p(
      'Sede - Trento, Casa, In viaggio...', 'Office - Trento, Home, Traveling...');
  String get descriptionOptional =>
      _p('Descrizione (facoltativa)', 'Description (optional)');
  String get coreSession => 'Core session';
  String get tasksInEnv => _p("Task nell'ambiente", 'Tasks in the environment');
  String get noTasksCreated => _p(
      'Nessuna task creata. Torna in Tasks e creane almeno una.',
      'No tasks created. Go back to Tasks and create at least one.');

  // --- sheets (dettaglio task / elimina / criterio / place) ---
  String get inCore => _p('nel nucleo', 'in the core');
  String get outOfCore => _p('fuori dal nucleo', 'out of the core');
  String get openDetails => _p('Apri dettagli', 'Open details');
  String get removeFromCore =>
      _p('Togli dalla Core Session', 'Remove from Core Session');
  String get addToCore => _p('Aggiungi alla Core Session', 'Add to Core Session');
  String get deleteTask => _p('Elimina task', 'Delete task');
  String deleteConfirm(String name) =>
      _p('Eliminare "$name"?', 'Delete "$name"?');
  String get deleteBodyCore => _p(
      'Sparisce dal nucleo e dagli ambienti che la usano, insieme ai suoi '
          'criteri e al suo storico. Non si torna indietro.',
      'It disappears from the core and the environments using it, along with '
          "its criteria and history. There's no going back.");
  String get deleteBodyPlain => _p(
      'Spariscono anche i suoi criteri e il suo storico. Non si torna indietro.',
      "Its criteria and history disappear too. There's no going back.");
  String get delete => _p('Elimina', 'Delete');
  String get taskDeleted => _p('Task eliminata', 'Task deleted');
  String objective(String target) => _p('Obiettivo $target', 'Target $target');
  String get noCriterion => _p('Nessun criterio.', 'No criteria.');
  String get coreNote => _p(
      'Queste task valgono in ogni ambiente che tiene la core session attiva.',
      'These tasks apply in every environment that keeps the core session '
          'active.');
  String get allInCore =>
      _p('Tutte le task sono già nel nucleo.', 'All tasks are already in the core.');
  String get newCriterion => _p('Nuovo criterio', 'New criterion');
  String get editCriterion => _p('Modifica criterio', 'Edit criterion');
  String get criterionHelp => _p(
      'Una condizione verificabile: se non è vera, la giornata non conta.',
      "A verifiable condition: if it's not true, the day doesn't count.");
  String coreSessionState(bool core) => _p(
      'Core session ${core ? "attiva" : "disattivata"}',
      'Core session ${core ? "on" : "off"}');
  String get noTasks => _p('Nessuna task.', 'No tasks.');
  String get edit => _p('Modifica', 'Edit');
  String get activate => _p('Attiva', 'Activate');
  String get deleteEnvironment => _p('Elimina ambiente', 'Delete environment');
  String get environmentDeleted =>
      _p('Ambiente eliminato', 'Environment deleted');

  // --- onboarding flow & nav ---
  String get firstUse => _p('Primo utilizzo', 'First time');
  String get onbStartTitle =>
      _p('Partiamo da una cosa sola', "Let's start with just one thing");
  String get onbStartBody => _p(
      'Scegli un’attività che vuoi rendere parte delle tue giornate. '
          'Bastano tre domande: il resto lo costruiamo dopo, insieme.',
      'Choose an activity you want to make part of your days. Just three '
          'questions: we build the rest later, together.');
  String get onbTapCreateTask =>
      _p('Tocca “Crea una nuova task”', 'Tap “Create a new task”');
  String get skipTutorial => _p('Salta il tutorial', 'Skip the tutorial');
  String get onbCoreKicker =>
      _p('La base della tua routine', 'The base of your routine');
  String get onbCoreTitle =>
      _p('Questa è la tua Core Session', 'This is your Core Session');
  String get onbCoreBody => _p(
      'Le task che metti qui ti seguono ovunque. Quando cambi ambiente '
          'restano con te, salvo che tu decida il contrario.',
      'The tasks you put here follow you everywhere. When you change '
          'environment they stay with you, unless you decide otherwise.');
  String get onbPutTask => _p('Mettici la task', 'Put the task here');
  String get notNow => _p('Non ora', 'Not now');
  String get optional => _p('Facoltativo', 'Optional');
  String get onbPlacesTitle =>
      _p('La tua routine cambia con te', 'Your routine changes with you');
  String get onbPlacesBody => _p(
      'A casa, in trasferta o in vacanza una buona giornata non chiede le '
          'stesse cose. Gli ambienti servono a questo.',
      'At home, on a trip or on holiday, a good day asks for different '
          'things. Environments are for this.');
  String get onbSeePlaces => _p('Vediamo Places', "Let's see Places");
  String get onbDone => _p('Ho finito', "I'm done");
  String get onbCreateFirstEnv =>
      _p('Crea il tuo primo ambiente', 'Create your first environment');
  String get onbEnvBody => _p(
      'Un ambiente decide quali task valgono mentre sei lì. Puoi portarti '
          'dietro la Core Session e aggiungere solo ciò che serve.',
      "An environment decides which tasks apply while you're there. You can "
          'bring the Core Session along and add only what you need.');
  String get onbTapCreateEnv =>
      _p('Tocca “Crea un ambiente”', 'Tap “Create an environment”');
  String get navHome => 'Home';
  String get navTasks => 'Tasks';
  String get navPlaces => 'Places';
  String get navTrend => 'Trend';

  String get signLabel => _p('SEGNO', 'SIGN');
  String get dragHereEnv =>
      _p('TRASCINA QUI UN AMBIENTE', 'DRAG AN ENVIRONMENT HERE');
  String get activeEnvCaps => _p('AMBIENTE ATTIVO', 'ACTIVE ENVIRONMENT');

  String get editTask => _p('Modifica task', 'Edit task');
  String get editWindowNote => _p(
      "Hai 12h dalla creazione o dall'upgrade per correggere nome e requisiti.",
      'You have 12h from creation or upgrade to fix the name and requirements.');
  String get criteriaLabel => _p('CRITERI', 'CRITERIA');

  String get growthCurve => _p('CURVA DI CRESCITA', 'GROWTH CURVE');

  String get reactivateTask => _p('Riabilita task', 'Reactivate task');
  String get taskReactivated => _p('Task riabilitata', 'Task reactivated');

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
