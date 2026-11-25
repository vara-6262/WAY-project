import 'package:flutter/widgets.dart';

/// Lingue supportate.
enum AppLang {
  it('Italiano', 'it'),
  en('English', 'en'),
  es('Español', 'es'),
  fr('Français', 'fr');

  const AppLang(this.nativeName, this.code);

  /// Nome nella propria lingua (endonimo), mai tradotto.
  final String nativeName;

  /// Codice locale (per MaterialApp).
  final String code;
}

/// Stringhe localizzate. Sistema "a mano" (niente code-gen): ogni stringa e'
/// un getter che sceglie la lingua. Aggiungere una lingua = estendere `_p`.
/// Le lingue oltre it/en senza traduzione ricadono sull'inglese.
/// Si accede con `context.s.<stringa>` grazie a [L10nScope].
class S {
  const S(this.lang);

  final AppLang lang;

  String _p(String it, String en, [String? es, String? fr]) {
    switch (lang) {
      case AppLang.it:
        return it;
      case AppLang.en:
        return en;
      case AppLang.es:
        return es ?? en;
      case AppLang.fr:
        return fr ?? en;
    }
  }

  // --- generali ---
  String get ok => 'OK';
  String get cancel => _p('Annulla', 'Cancel', 'Cancelar', 'Annuler');
  String get save => _p('Salva', 'Save', 'Guardar', 'Enregistrer');

  // --- account ---
  String get account => 'Account';
  String get localProfile =>
      _p('Profilo locale', 'Local profile', 'Perfil local', 'Profil local');
  String get yourName => _p('Il tuo nome', 'Your name', 'Tu nombre', 'Ton nom');
  String get whatsYourName => _p(
      'Come ti chiami', "What's your name", '¿Cómo te llamas?', 'Comment t’appelles-tu');
  String get signInUp => _p('Accedi / Registrati', 'Sign in / Sign up',
      'Entrar / Registrarse', 'Se connecter / S’inscrire');
  String get syncSoon => _p(
      'Sincronizzazione account presto disponibile.',
      'Account sync coming soon.',
      'Sincronización de cuenta próximamente.',
      'Synchronisation du compte bientôt disponible.');
  String get soon => _p('presto', 'soon', 'pronto', 'bientôt');

  // --- sezioni ---
  String get appearance => _p('Aspetto', 'Appearance', 'Apariencia', 'Apparence');
  String get language => _p('Lingua', 'Language', 'Idioma', 'Langue');
  String get backupAndData => _p(
      'Backup e dati', 'Backup & data', 'Copia y datos', 'Sauvegarde et données');
  String get developer =>
      _p('Sviluppatore', 'Developer', 'Desarrollador', 'Développeur');

  // --- backup ---
  String get shareBackup => _p(
      'Condividi backup (Drive / File)',
      'Share backup (Drive / Files)',
      'Compartir copia (Drive / Archivos)',
      'Partager la sauvegarde (Drive / Fichiers)');
  String get importBackup => _p(
      'Importa backup dagli appunti',
      'Import backup from clipboard',
      'Importar copia del portapapeles',
      'Importer la sauvegarde du presse-papiers');
  String get exportBackupClipboard => _p(
      'Esporta backup negli appunti',
      'Copy backup to clipboard',
      'Copiar copia al portapapeles',
      'Copier la sauvegarde dans le presse-papiers');
  String get shareFailed => _p('Condivisione non riuscita', 'Share failed',
      'No se pudo compartir', 'Échec du partage');
  String get backupRestored => _p('Backup ripristinato', 'Backup restored',
      'Copia restaurada', 'Sauvegarde restaurée');
  String get backupInvalid => _p(
      'Backup non valido', 'Invalid backup', 'Copia no válida', 'Sauvegarde non valide');
  String get backupCopied => _p(
      'Backup copiato negli appunti',
      'Backup copied to clipboard',
      'Copia copiada al portapapeles',
      'Sauvegarde copiée dans le presse-papiers');

  // --- debug / strumenti ---
  String get devUnlocked => _p('Strumenti sviluppatore sbloccati',
      'Developer tools unlocked', 'Herramientas de desarrollador desbloqueadas',
      'Outils développeur débloqués');
  String get devHidden =>
      _p('Strumenti nascosti', 'Tools hidden', 'Herramientas ocultas', 'Outils masqués');
  String devMissing(int n) =>
      _p('Mancano $n…', '$n to go…', 'Faltan $n…', 'Encore $n…');
  String get prototypeMode => _p('MODALITÀ PROTOTIPO', 'PROTOTYPE MODE',
      'MODO PROTOTIPO', 'MODE PROTOTYPE');
  String get modeProxy => 'Proxy';
  String get modeFromZero => _p('Configura da 0', 'Set up from zero',
      'Configurar desde cero', 'Configurer de zéro');
  String get sendTestNotif => _p('Invia notifica di test',
      'Send test notification', 'Enviar notificación de prueba',
      'Envoyer une notification test');
  String get testNotifSent => _p('Notifica di test inviata',
      'Test notification sent', 'Notificación de prueba enviada',
      'Notification test envoyée');
  String get rescheduleReminders => _p('Riprogramma promemoria',
      'Reschedule reminders', 'Reprogramar recordatorios',
      'Replanifier les rappels');
  String remindersScheduled(int n) => _p('Promemoria programmati: $n',
      'Reminders scheduled: $n', 'Recordatorios programados: $n',
      'Rappels programmés : $n');
  String get notifIn1Min => _p('Notifica tra 1 minuto (test)',
      'Notification in 1 minute (test)', 'Notificación en 1 minuto (prueba)',
      'Notification dans 1 minute (test)');
  String get scheduledNotifTest => _p('Test notifica programmata',
      'Scheduled notification test', 'Prueba de notificación programada',
      'Test de notification programmée');
  String get bonusReport =>
      _p('Report bonus', 'Bonus report', 'Informe de bonus', 'Rapport bonus');
  String get bonusComposition => _p('Composizione bonus', 'Bonus breakdown',
      'Desglose del bonus', 'Détail du bonus');
  String get resetThisMode => _p('Reimposta questa modalità', 'Reset this mode',
      'Restablecer este modo', 'Réinitialiser ce mode');
  String get archiveReset => _p('Archivio reimpostato', 'Archive reset',
      'Archivo restablecido', 'Archive réinitialisée');
  String get hideDevTools => _p('Nascondi strumenti sviluppatore',
      'Hide developer tools', 'Ocultar herramientas de desarrollador',
      'Masquer les outils développeur');

  // --- home ---
  String get todayExecution => _p(
      'Esecuzione di oggi', "Today's tasks", 'Tareas de hoy', 'Tâches du jour');
  String get filterAvailable =>
      _p('Disponibili', 'Available', 'Disponibles', 'Disponibles');
  String get filterAll => _p('Tutte', 'All', 'Todas', 'Toutes');
  String get freeDay =>
      _p('Giornata libera', 'Free day', 'Día libre', 'Journée libre');
  String doneOfTotal(int done, int total) => _p('$done su $total completate',
      '$done of $total done', '$done de $total hechas', '$done sur $total faites');
  String get trend => _p('ANDAMENTO', 'TREND', 'TENDENCIA', 'TENDANCE');
  String get yesterdayReview => _p('Ieri — rivedi', 'Yesterday — review',
      'Ayer — revisar', 'Hier — revoir');
  String get reviewSubtitle => _p(
      'Rivaluta a mente fredda · entro stasera',
      'Reassess with a clear head · by tonight',
      'Revalora con calma · antes de esta noche',
      'Réévalue à tête reposée · avant ce soir');
  String get relapseToday =>
      _p('Ricaduta oggi', 'Relapsed today', 'Recaída hoy', 'Rechute aujourd’hui');
  String cleanStreak(int days, String reward) => _p(
      'Pulito · ${days}g · +$reward',
      'Clean · ${days}d · +$reward',
      'Limpio · ${days}d · +$reward',
      'Propre · ${days}j · +$reward');
  String get relapse => _p('Ricaduta', 'Relapse', 'Recaída', 'Rechute');
  String get archive => _p('Archivia', 'Archive', 'Archivar', 'Archiver');
  String get reconfigure => _p('Rivedi', 'Review', 'Revisar', 'Revoir');
  String get levelUp => 'Level up';
  String get hide => _p('Nascondi', 'Hide', 'Ocultar', 'Masquer');
  String get scoreDone => _p('Fatto', 'Done', 'Hecho', 'Fait');
  String get maintenance =>
      _p('Mantenimento', 'Maintenance', 'Mantenimiento', 'Maintien');
  String get scoreComposition => _p('COMPOSIZIONE PUNTEGGIO', 'SCORE BREAKDOWN',
      'DESGLOSE DE PUNTOS', 'DÉTAIL DU SCORE');
  String get bonusConstancyTitle => _p('Bonus costanza', 'Consistency bonus',
      'Bonus de constancia', 'Bonus de régularité');
  String get bonusConstancyBody => _p(
      'Stai ricevendo un extra per la costanza delle tue abitudini '
          '(streak attive).',
      "You're getting an extra for the consistency of your habits "
          '(active streaks).',
      'Recibes un extra por la constancia de tus hábitos (rachas activas).',
      'Tu reçois un extra pour la régularité de tes habitudes (séries actives).');
  String get pts => _p('pt', 'pts', 'pt', 'pt');
  String pointsToday(String value) => _p('+$value punti oggi',
      '+$value points today', '+$value puntos hoy', '+$value points aujourd’hui');
  String greeting(int hour) => hour < 12
      ? _p('Buongiorno', 'Good morning', 'Buenos días', 'Bonjour')
      : (hour < 18
          ? _p('Buon pomeriggio', 'Good afternoon', 'Buenas tardes', 'Bon après-midi')
          : _p('Buonasera', 'Good evening', 'Buenas noches', 'Bonsoir'));
  String get whatToStart => _p('Da cosa iniziamo oggi?',
      'What shall we start with?', '¿Por dónde empezamos hoy?', 'Par quoi commence-t-on ?');
  String get nothingHere => _p('Niente in questa vista', 'Nothing in this view',
      'Nada en esta vista', 'Rien dans cette vue');
  String get emptyEnvBody => _p(
      'Oggi non è previsto nulla in questo ambiente.',
      'Nothing scheduled in this environment today.',
      'Hoy no hay nada previsto en este entorno.',
      'Rien de prévu dans cet environnement aujourd’hui.');
  String get emptyFilterBody => _p(
      'Cambia filtro in alto per vedere le altre task di oggi.',
      "Switch the filter above to see today's other tasks.",
      'Cambia el filtro de arriba para ver las demás tareas de hoy.',
      'Change le filtre en haut pour voir les autres tâches du jour.');

  // --- trend ---
  String get monitoring =>
      _p('Monitoraggio', 'Tracking', 'Seguimiento', 'Suivi');
  String get trendTitle => 'Trend';
  String get metricPointsToday =>
      _p('PUNTI OGGI', 'POINTS TODAY', 'PUNTOS HOY', 'POINTS DU JOUR');
  String get metricScore =>
      _p('PUNTEGGIO', 'SCORE', 'PUNTUACIÓN', 'SCORE');
  String get metricBonus => 'BONUS';
  String get streakInProgress => _p('Streak in corso', 'Active streaks',
      'Rachas activas', 'Séries en cours');
  String get noActiveStreak => _p('Nessuna streak attiva', 'No active streaks',
      'Sin rachas activas', 'Aucune série active');
  String get noStreakBody => _p(
      'Completa le task nei loro giorni: qui le costanze crescono.',
      'Complete tasks on their days: streaks grow here.',
      'Completa las tareas en sus días: aquí crecen las rachas.',
      'Fais tes tâches les bons jours : les séries grandissent ici.');
  String get habitsHealth => _p('Salute delle abitudini', 'Habits health',
      'Salud de los hábitos', 'Santé des habitudes');
  String get healthy => _p('IN SALUTE', 'HEALTHY', 'SANAS', 'EN FORME');
  String get needsCare =>
      _p('DA CURARE', 'NEEDS CARE', 'A CUIDAR', 'À SOIGNER');
  String get analysis => _p('Analisi', 'Analysis', 'Análisis', 'Analyse');
  String get modeNumber => _p('Number', 'Numbers', 'Números', 'Nombres');
  String get modeAbstinence =>
      _p('Astinenze', 'Abstinences', 'Abstinencias', 'Abstinences');
  String get modeBonus => 'Bonus';
  String get rangeWeek => _p('7 giorni', '7 days', '7 días', '7 jours');
  String get rangeMonth => _p('30 giorni', '30 days', '30 días', '30 jours');
  String get rangeYear => _p('12 mesi', '12 months', '12 meses', '12 mois');
  String get noMeasureTask => _p('Nessuna task a quantità', 'No measured tasks',
      'Sin tareas de cantidad', 'Aucune tâche mesurée');
  String get noMeasureBody => _p(
      'Le task di tipo misura appariranno qui.',
      'Measure-type tasks will appear here.',
      'Las tareas de tipo medida aparecerán aquí.',
      'Les tâches de type mesure apparaîtront ici.');
  String get noAbstinence => _p('Nessuna astinenza', 'No abstinences',
      'Sin abstinencias', 'Aucune abstinence');
  String get noAbstinenceBody => _p(
      'Le astinenze appariranno qui, con la loro curva.',
      'Abstinences will appear here, with their curve.',
      'Las abstinencias aparecerán aquí, con su curva.',
      'Les abstinences apparaîtront ici, avec leur courbe.');
  String get avg => _p('MEDIA', 'AVG', 'MEDIA', 'MOY');
  String get max => _p('MASSIMO', 'MAX', 'MÁXIMO', 'MAX');
  String get today => _p('OGGI', 'TODAY', 'HOY', 'AUJOURD’HUI');
  String get peak => _p('PICCO', 'PEAK', 'PICO', 'PIC');
  String bellNote(int tau) => _p(
      'Punti della campana: salgono verso il picco (τ=${tau}g) poi calano.',
      'Bell points: rise to the peak (τ=${tau}d) then fall.',
      'Puntos de campana: suben al pico (τ=${tau}d) y luego bajan.',
      'Points en cloche : montent vers le pic (τ=${tau}j) puis descendent.');
  String get bonusTimeNote => _p(
      'Punti dal bonus ogni giorno (cala dopo upgrade e fallimenti).',
      'Bonus points each day (drops after upgrades and failures).',
      'Puntos del bonus cada día (bajan tras subidas y fallos).',
      'Points de bonus chaque jour (baissent après montées et échecs).');

  // --- wizard creazione (condiviso task_wizard / first_run) ---
  String taskCreated(String name) => _p('Task creata: $name',
      'Task created: $name', 'Tarea creada: $name', 'Tâche créée : $name');
  String get wizStepRecognition =>
      _p('Riconoscimento', 'Recognition', 'Reconocimiento', 'Reconnaissance');
  String get wizStepDuration =>
      _p('Durata', 'Duration', 'Duración', 'Durée');
  String get wizStepCriteria =>
      _p('Criteri', 'Criteria', 'Criterios', 'Critères');
  String get wizStepType => _p('Tipologia', 'Type', 'Tipo', 'Type');
  String get wizSubRecognition => _p(
      "Come si chiama e come la riconosci in un colpo d'occhio.",
      "What it's called and how you recognize it at a glance.",
      'Cómo se llama y cómo la reconoces de un vistazo.',
      'Comment elle s’appelle et comment tu la reconnais d’un coup d’œil.');
  String get wizSubDuration => _p(
      "Nei giorni che scegli WAY se l'aspetta. Negli altri no.",
      'On the days you choose, WAY expects it. Not on the others.',
      'En los días que elijas, WAY la espera. En los demás no.',
      'Les jours que tu choisis, WAY l’attend. Pas les autres.');
  String get wizSubCriteria => _p(
      'Ogni condizione che aggiungi rende la task più impegnativa.',
      'Each condition you add makes the task more demanding.',
      'Cada condición que añades hace la tarea más exigente.',
      'Chaque condition ajoutée rend la tâche plus exigeante.');
  String get wizSubType => _p("Come si registra l'esecuzione ogni giorno.",
      'How you log it each day.', 'Cómo registras su ejecución cada día.',
      'Comment tu la consignes chaque jour.');
  String get createTask =>
      _p('Crea la task', 'Create task', 'Crear tarea', 'Créer la tâche');
  String get continueLabel =>
      _p('Continua', 'Continue', 'Continuar', 'Continuer');
  String get name => _p('Nome', 'Name', 'Nombre', 'Nom');
  String get nameHint => _p('Studio, Allenamento, Sveglia...',
      'Study, Workout, Alarm...', 'Estudio, Entreno, Despertar...',
      'Étude, Entraînement, Réveil...');
  String get icon => _p('ICONA', 'ICON', 'ICONO', 'ICÔNE');
  String get addCriterion => _p('Aggiungi criterio', 'Add criterion',
      'Añadir criterio', 'Ajouter un critère');
  String get kindComplete =>
      _p('Completa', 'Complete', 'Completa', 'Complète');
  String get kindCompleteSub => _p('Fatto / non fatto', 'Done / not done',
      'Hecho / no hecho', 'Fait / pas fait');
  String get kindMeasure => _p('Misura', 'Measure', 'Medida', 'Mesure');
  String get kindMeasureSub => _p('Quantità al giorno', 'Amount per day',
      'Cantidad al día', 'Quantité par jour');
  String get kindMaintain => _p('Mantieni', 'Maintain', 'Mantén', 'Maintenir');
  String get kindMaintainSub => _p('Intatta finché non la infrangi',
      'Intact until you break it', 'Intacta hasta que la rompas',
      'Intacte jusqu’à ce que tu la brises');
  String get kindAbstinence =>
      _p('Astinenza', 'Abstinence', 'Abstinencia', 'Abstinence');
  String get kindAbstinenceSub => _p('Il valore è nel non ricadere',
      'The value is in not relapsing', 'El valor está en no recaer',
      'La valeur est de ne pas rechuter');
  String get kindCompleteDesc => _p(
      'Task senza gradazione: o è rispettata o no.',
      'Task with no gradation: either met or not.',
      'Tarea sin gradación: o se cumple o no.',
      'Tâche sans gradation : elle est remplie ou non.');
  String get kindMeasureDesc => _p(
      'La quantità dice la qualità: ore di studio, pagine, uscite.',
      'The amount tells the quality: study hours, pages, outings.',
      'La cantidad dice la calidad: horas de estudio, páginas, salidas.',
      'La quantité dit la qualité : heures d’étude, pages, sorties.');
  String get kindMaintainDesc => _p(
      'Parte completata e resta valida finché non infrangi una delle '
          'condizioni (i criteri del passo precedente). Alla prima infrazione '
          'la giornata è persa.',
      'Starts complete and stays valid until you break one of the conditions '
          '(the criteria from the previous step). At the first breach the day '
          'is lost.',
      'Empieza completada y sigue válida hasta que rompes una de las '
          'condiciones (los criterios del paso anterior). A la primera '
          'infracción el día se pierde.',
      'Commence remplie et reste valide jusqu’à ce que tu brises une des '
          'conditions (les critères de l’étape précédente). À la première '
          'entorse, la journée est perdue.');
  String get kindAbstinenceDesc => _p(
      'Ogni giorno pulito conta. Il punteggio cresce nella fase critica '
          'iniziale e poi si stabilizza: scegli quanto dura.',
      'Every clean day counts. The score grows in the initial critical phase '
          'then stabilizes: choose how long it lasts.',
      'Cada día limpio cuenta. La puntuación crece en la fase crítica inicial '
          'y luego se estabiliza: elige cuánto dura.',
      'Chaque jour propre compte. Le score croît dans la phase critique '
          'initiale puis se stabilise : choisis sa durée.');
  String get rewardSystem => _p('SISTEMA DI RICOMPENSA', 'REWARD SYSTEM',
      'SISTEMA DE RECOMPENSA', 'SYSTÈME DE RÉCOMPENSE');
  String get rewardLinear => _p('Lineare', 'Linear', 'Lineal', 'Linéaire');
  String get rewardLinearSub => _p('Attrito costante', 'Constant friction',
      'Fricción constante', 'Friction constante');
  String get rewardExp =>
      _p('Esponenziale', 'Exponential', 'Exponencial', 'Exponentielle');
  String get rewardExpSub => _p('Attrito crescente', 'Growing friction',
      'Fricción creciente', 'Friction croissante');
  String get rewardLinearDesc => _p(
      'Ogni unità in più vale quanto la precedente. Adatto quando continuare '
          "non costa fatica aggiuntiva: uscire con gli amici una volta in più.",
      'Each extra unit is worth the same as the previous. Good when continuing '
          'costs no extra effort: going out with friends one more time.',
      'Cada unidad extra vale igual que la anterior. Útil cuando continuar no '
          'cuesta esfuerzo extra: salir con amigos una vez más.',
      'Chaque unité en plus vaut autant que la précédente. Utile quand '
          'continuer ne coûte pas d’effort en plus : sortir une fois de plus.');
  String get rewardExpDesc => _p(
      'Ogni unità in più vale più della precedente. Adatto quando la fatica '
          "cresce: la quinta ora di studio non è la prima.",
      'Each extra unit is worth more than the previous. Good when effort '
          "grows: the fifth study hour isn't the first.",
      'Cada unidad extra vale más que la anterior. Útil cuando el esfuerzo '
          'crece: la quinta hora de estudio no es la primera.',
      'Chaque unité en plus vaut plus que la précédente. Utile quand l’effort '
          'croît : la cinquième heure d’étude n’est pas la première.');
  String get dailyTarget => _p('Target giornaliero', 'Daily target',
      'Objetivo diario', 'Objectif quotidien');
  String get targetHint =>
      _p('es. 40, 5, 3...', 'e.g. 40, 5, 3...', 'ej. 40, 5, 3...', 'ex. 40, 5, 3...');
  String get criticalPhase =>
      _p('FASE CRITICA', 'CRITICAL PHASE', 'FASE CRÍTICA', 'PHASE CRITIQUE');
  String get phaseShort => _p('Breve', 'Short', 'Corta', 'Courte');
  String get phaseMedium => _p('Media', 'Medium', 'Media', 'Moyenne');
  String get phaseLong => _p('Lunga', 'Long', 'Larga', 'Longue');

  // --- codipendenza ---
  String get tfFixed => _p('Timeframe fisso', 'Fixed timeframe',
      'Horario fijo', 'Créneau fixe');
  String get tfFixedSub => _p('Giorni e orario stabiliti', 'Set days and hours',
      'Días y horas definidos', 'Jours et heures définis');
  String get tfCodep =>
      _p('Codipendenza', 'Codependency', 'Codependencia', 'Codépendance');
  String get tfCodepSub => _p(
      'Si sblocca al completamento di un\'altra task',
      'Unlocks when another task is done',
      'Se desbloquea al completar otra tarea',
      'Se débloque quand une autre tâche est faite');
  String get codepTrigger => _p('TASK TRIGGER', 'TRIGGER TASK',
      'TAREA DISPARADORA', 'TÂCHE DÉCLENCHEUSE');
  String get codepTriggerHint => _p(
      'Quale completamento apre la finestra?',
      'Which completion opens the window?',
      '¿Qué finalización abre la ventana?',
      'Quelle réalisation ouvre la fenêtre ?');
  String get codepWindow => _p('FINESTRA', 'WINDOW', 'VENTANA', 'FENÊTRE');
  String get codepDaysLabel => _p('GIORNI', 'DAYS', 'DÍAS', 'JOURS');
  String get codepDaysHint => _p(
      'Solo nei giorni in cui e\' attivo il trigger.',
      'Only on days when the trigger is active.',
      'Solo los días en que el disparador está activo.',
      'Seulement les jours où le déclencheur est actif.');
  String get triggerNeededByDependent => _p(
      'Serve a una task codipendente in questo ambiente.',
      'Needed by a codependent task in this environment.',
      'La necesita una tarea codependiente en este entorno.',
      'Nécessaire à une tâche codépendante dans cet environnement.');
  String triggerAutoAdded(String name) => _p(
      'Aggiunto anche il trigger «$name»',
      'Trigger "$name" added too',
      'También se añadió el disparador «$name»',
      'Déclencheur « $name » ajouté aussi');
  String get codepNoTriggers => _p(
      'Serve almeno una task Completa o Numero gia\' esistente da usare come trigger.',
      'You need at least one existing Complete or Number task to use as a trigger.',
      'Necesitas al menos una tarea Completa o Número ya existente como disparador.',
      'Il faut au moins une tâche Complète ou Nombre déjà existante comme déclencheur.');
  String codepDesc(String trigger, String window) => _p(
      'Dopo aver completato "$trigger" hai $window per completare questa task. Fuori dalla finestra non vale, e nei giorni senza "$trigger" la task e\' neutra.',
      'After you complete "$trigger" you have $window to complete this task. Outside the window it doesn\'t count, and on days without "$trigger" the task is neutral.',
      'Tras completar "$trigger" tienes $window para completar esta tarea. Fuera de la ventana no cuenta, y los días sin "$trigger" la tarea es neutra.',
      'Après avoir fait "$trigger", tu as $window pour faire cette tâche. Hors de la fenêtre ça ne compte pas, et les jours sans "$trigger" la tâche est neutre.');
  String winMinutes(int m) => _p('$m min', '$m min', '$m min', '$m min');
  String winHours(int h) => _p('${h}h', '${h}h', '${h}h', '${h}h');
  String codepWaiting(String trigger) => _p('In attesa di $trigger',
      'Waiting for $trigger', 'Esperando $trigger', 'En attente de $trigger');
  String codepOpenUntil(String time) => _p(
      'Finestra aperta · chiude $time',
      'Window open · closes $time',
      'Ventana abierta · cierra $time',
      'Fenêtre ouverte · ferme $time');
  String get codepUnlocked => _p('Sbloccata oggi', 'Unlocked today',
      'Desbloqueada hoy', 'Débloquée aujourd’hui');
  String get winNoLimit =>
      _p('Nessun limite', 'No limit', 'Sin límite', 'Sans limite');
  String get winNoLimitSub => _p('Fino a fine giornata', 'Until end of day',
      'Hasta el final del día', 'Jusqu’à la fin de la journée');
  String get winUntilEod => _p('fino a fine giornata', 'until end of day',
      'hasta el final del día', 'jusqu’à la fin de la journée');

  // --- pacchetti (habit pack) ---
  String get packsSection => _p('Pacchetti', 'Packs', 'Paquetes', 'Packs');
  String get packPreview =>
      _p('Anteprima', 'Preview', 'Vista previa', 'Aperçu');
  String get packContains => _p('COSA CONTIENE', 'WHAT IT CONTAINS',
      'QUÉ CONTIENE', 'CE QU’IL CONTIENT');
  String get anchorConflictTitle => _p('Task in comune', 'Shared task',
      'Tarea en común', 'Tâche partagée');
  String get anchorConflictBody => _p(
      'Piu\' pacchetti usano la stessa task. Scegli quale tenere attiva: le altre restano in pausa finche\' tieni entrambi i pacchetti.',
      'More than one pack uses the same task. Pick which one stays active: the others stay paused while you keep both packs.',
      'Varios paquetes usan la misma tarea. Elige cuál mantener activa: las demás quedan en pausa mientras conserves ambos paquetes.',
      'Plusieurs packs utilisent la même tâche. Choisis laquelle garder active : les autres restent en pause tant que tu gardes les deux packs.');
  String get packAdd => _p('Aggiungi il pacchetto', 'Add this pack',
      'Añadir el paquete', 'Ajouter le pack');
  String packAdded(String name) => _p('"$name" aggiunto', '"$name" added',
      '"$name" añadido', '"$name" ajouté');
  String get packPaused => _p('Sospeso', 'Paused', 'En pausa', 'En pause');
  String packTaskCount(int n) => _p(
      '$n task nel pacchetto',
      '$n task${n == 1 ? '' : 's'} in the pack',
      '$n tarea${n == 1 ? '' : 's'} en el paquete',
      '$n tâche${n == 1 ? '' : 's'} dans le pack');
  String get packRemoveTitle => _p('Rimuovere il pacchetto?', 'Remove pack?',
      '¿Quitar el paquete?', 'Retirer le pack ?');
  String packRemoveBody(String name) => _p(
      'Elimini "$name" e tutte le sue task. L\'operazione non si puo\' annullare.',
      'This removes "$name" and all its tasks. This cannot be undone.',
      'Elimina "$name" y todas sus tareas. No se puede deshacer.',
      'Cela supprime "$name" et toutes ses tâches. Action irréversible.');
  String get packRemoveConfirm => _p('Rimuovi pacchetto', 'Remove pack',
      'Quitar paquete', 'Retirer le pack');
  String packRemoved(String name) => _p('"$name" rimosso', '"$name" removed',
      '"$name" eliminado', '"$name" retiré');
  String get packTaskLocked => _p(
      'Task di un pacchetto: si gestisce da Places.',
      'Pack task: managed from Places.',
      'Tarea de un paquete: se gestiona en Places.',
      'Tâche d’un pack : gérée depuis Places.');

  // --- upgrade scriptato dei pack ---
  String get packUpgradeKicker => _p('UPGRADE GUIDATO', 'GUIDED UPGRADE',
      'MEJORA GUIADA', 'AMÉLIORATION GUIDÉE');
  String get packWhatChanges => _p('COSA CAMBIA', 'WHAT CHANGES',
      'QUÉ CAMBIA', 'CE QUI CHANGE');
  String get packNoChange => _p('Stesso impianto, un livello in piu\'.',
      'Same setup, one level up.', 'Mismo esquema, un nivel más.',
      'Même structure, un niveau de plus.');
  String get packUpgradeApply => _p('Applica upgrade', 'Apply upgrade',
      'Aplicar mejora', 'Appliquer l’amélioration');
  String packToNumber(double target) => _p(
      'Da "fatto/non fatto" a numero: target ${_n(target)}',
      'From done/not-done to a number: target ${_n(target)}',
      'De "hecho/no hecho" a número: objetivo ${_n(target)}',
      'De "fait/pas fait" à un nombre : objectif ${_n(target)}');
  String packTargetChange(String from, String to) => _p('Target: $from → $to',
      'Target: $from → $to', 'Objetivo: $from → $to', 'Objectif : $from → $to');
  String packWindowChange(String from, String to) => _p('Finestra: $from → $to',
      'Window: $from → $to', 'Ventana: $from → $to', 'Fenêtre : $from → $to');
  String packNewRequirements(String reqs) => _p('Nuovi requisiti: $reqs',
      'New requirements: $reqs', 'Nuevos requisitos: $reqs',
      'Nouvelles exigences : $reqs');
  String packFrequencyChange(int from, int to) => _p(
      'Frequenza: $from → $to giorni a settimana',
      'Frequency: $from → $to days per week',
      'Frecuencia: $from → $to días por semana',
      'Fréquence : $from → $to jours par semaine');
  String _n(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : '$v';

  // --- first run (onboarding guidato) ---
  String get frTitleName => _p('Come si chiama?', "What's it called?",
      '¿Cómo se llama?', 'Comment ça s’appelle ?');
  String frTitleDays(String name) => _p('Quando vale $name?',
      'When does $name count?', '¿Cuándo cuenta $name?', 'Quand $name compte-t-elle ?');
  String get frTitleTrack => _p('Come la segni?', 'How do you log it?',
      '¿Cómo la registras?', 'Comment la consignes-tu ?');
  String get frTitleCurve => _p('Ogni unità in più vale uguale?',
      'Does each extra unit count the same?',
      '¿Cada unidad extra vale igual?',
      'Chaque unité en plus compte-t-elle pareil ?');
  String get frTitleAmount => _p('Quanto ne vuoi fare?',
      'How much do you want to do?', '¿Cuánto quieres hacer?', 'Combien veux-tu en faire ?');
  String get frTitleCriteria => _p('Cosa vuol dire farla bene?',
      'What does doing it well mean?', '¿Qué significa hacerla bien?',
      'Qu’est-ce que bien la faire ?');
  String get frSubName => _p(
      'Il nome che te la fa riconoscere in un secondo.',
      'The name that lets you recognize it in a second.',
      'El nombre que la hace reconocible en un segundo.',
      'Le nom qui te la fait reconnaître en une seconde.');
  String get frSubDays => _p(
      "Nei giorni che scegli WAY se l'aspetta. Negli altri no, e la tua "
          'percentuale non ne risente.',
      "On the days you choose, WAY expects it. Not on the others, and your "
          "percentage isn't affected.",
      'En los días que elijas, WAY la espera. En los demás no, y tu porcentaje '
          'no se ve afectado.',
      'Les jours que tu choisis, WAY l’attend. Pas les autres, et ton '
          'pourcentage n’en pâtit pas.');
  String get frSubTrack => _p(
      'Decide cosa WAY ti chiede ogni giorno. Puoi cambiarlo quando vuoi.',
      'Decides what WAY asks of you each day. You can change it anytime.',
      'Decide qué te pide WAY cada día. Puedes cambiarlo cuando quieras.',
      'Décide ce que WAY te demande chaque jour. Modifiable à tout moment.');
  String get frSubCurve => _p(
      'Serve a WAY per capire quanto premiare quello che fai oltre la soglia.',
      'Helps WAY understand how much to reward what you do beyond the '
          'threshold.',
      'Ayuda a WAY a saber cuánto premiar lo que haces por encima del umbral.',
      'Aide WAY à savoir combien récompenser ce que tu fais au-delà du seuil.');
  String get frSubAmount => _p(
      'La soglia è il minimo che conta come giornata valida. Il target è la '
          'giornata piena, il 100%.',
      'The threshold is the minimum that counts as a valid day. The target is '
          'a full day, 100%.',
      'El umbral es el mínimo que cuenta como día válido. El objetivo es el '
          'día completo, el 100%.',
      'Le seuil est le minimum qui compte comme journée valide. L’objectif est '
          'une journée pleine, 100%.');
  String get frSubCriteria => _p(
      'Facoltativo. Ogni condizione che aggiungi rende la task più '
          'impegnativa, e WAY lo tiene in conto.',
      'Optional. Each condition you add makes the task more demanding, and WAY '
          'accounts for it.',
      'Opcional. Cada condición que añades hace la tarea más exigente, y WAY '
          'lo tiene en cuenta.',
      'Facultatif. Chaque condition ajoutée rend la tâche plus exigeante, et '
          'WAY en tient compte.');
  String get createWithoutCriteria => _p('Crea senza criteri',
      'Create without criteria', 'Crear sin criterios', 'Créer sans critères');
  String get frNameHint => _p('Studio, Allenamento, Lettura…',
      'Study, Workout, Reading…', 'Estudio, Entreno, Lectura…',
      'Étude, Entraînement, Lecture…');
  String get allDays =>
      _p('Tutti i giorni', 'Every day', 'Todos los días', 'Tous les jours');
  String get weekdaysOnly => _p('Solo feriali', 'Weekdays only',
      'Solo laborables', 'En semaine seulement');
  String get frKindCompleteTitle => _p('Fatta o non fatta', 'Done or not done',
      'Hecha o no hecha', 'Faite ou non faite');
  String get frKindCompleteBody => _p('Ti basta una spunta a fine giornata.',
      'Just a check at the end of the day.',
      'Basta una marca al final del día.', 'Juste une coche en fin de journée.');
  String get frKindMeasureTitle => _p('Conta quanto', 'Count how much',
      'Cuenta cuánto', 'Compte combien');
  String get frKindMeasureBody => _p(
      'Registri una quantità: ore, pagine, chilometri.',
      'You log an amount: hours, pages, kilometers.',
      'Registras una cantidad: horas, páginas, kilómetros.',
      'Tu consignes une quantité : heures, pages, kilomètres.');
  String get frCurveLinearTitle => _p('Sì, vale sempre uguale',
      'Yes, always the same', 'Sí, vale siempre igual', 'Oui, toujours pareil');
  String get frCurveLinearBody => _p(
      'La decima uscita con gli amici costa quanto la prima.',
      'The tenth outing with friends costs as much as the first.',
      'La décima salida con amigos cuesta como la primera.',
      'La dixième sortie entre amis coûte autant que la première.');
  String get frCurveExpTitle => _p('No, costa sempre di più',
      'No, it costs more each time', 'No, cuesta cada vez más',
      'Non, ça coûte plus à chaque fois');
  String get frCurveExpBody => _p(
      'La quinta ora di studio pesa più della prima.',
      'The fifth study hour weighs more than the first.',
      'La quinta hora de estudio pesa más que la primera.',
      'La cinquième heure d’étude pèse plus que la première.');
  String get dailyTargetCaps => _p('TARGET GIORNALIERO', 'DAILY TARGET',
      'OBJETIVO DIARIO', 'OBJECTIF QUOTIDIEN');
  String get frAmountNote => _p(
      'La quantità che vale il 100% della giornata.',
      'The amount that counts as 100% of the day.',
      'La cantidad que vale el 100% del día.',
      'La quantité qui vaut 100% de la journée.');
  List<String> get frTagsComplete => _p3(
      ['Sveglia', 'Medicina', 'Stretching'],
      ['Alarm', 'Medicine', 'Stretching'],
      ['Despertar', 'Medicina', 'Estiramiento'],
      ['Réveil', 'Médicament', 'Étirements']);
  List<String> get frTagsMeasure => _p3(
      ['Studio', 'Lettura', 'Corsa'],
      ['Study', 'Reading', 'Running'],
      ['Estudio', 'Lectura', 'Correr'],
      ['Étude', 'Lecture', 'Course']);

  List<String> _p3(List<String> it, List<String> en,
      [List<String>? es, List<String>? fr]) {
    switch (lang) {
      case AppLang.it:
        return it;
      case AppLang.en:
        return en;
      case AppLang.es:
        return es ?? en;
      case AppLang.fr:
        return fr ?? en;
    }
  }

  // --- evolution & review ---
  String get close => _p('Chiudi', 'Close', 'Cerrar', 'Fermer');
  String get confirm => _p('Conferma', 'Confirm', 'Confirmar', 'Confirmer');
  String get skip => _p('Salta', 'Skip', 'Saltar', 'Passer');
  String get evolveUpgradeHelp => _p(
      'Sali di livello ridefinendo requisiti e dominio (più impegnativa); '
          'Mantieni per fermare la crescita del bonus restando al livello '
          'attuale; Consolida per bloccare gli upgrade e lasciar crescere '
          'solo lo streak.',
      'Level up by redefining requirements and domain (more demanding); Keep '
          'to stop bonus growth staying at the current level; Consolidate to '
          'lock upgrades and let only the streak grow.',
      'Sube de nivel redefiniendo requisitos y dominio (más exigente); Mantener '
          'para frenar el crecimiento del bonus en el nivel actual; Consolidar '
          'para bloquear las mejoras y dejar crecer solo la racha.',
      'Monte de niveau en redéfinissant exigences et domaine (plus exigeant) ; '
          'Maintenir pour stopper la hausse du bonus au niveau actuel ; '
          'Consolider pour bloquer les montées et ne laisser croître que la série.');
  String get evolveReconfigHelp => _p(
      'Tre fallimenti di fila: ridefinisci per renderla sostenibile. Il '
          'downgrade è opzionale.',
      'Three failures in a row: redefine it to make it sustainable. The '
          'downgrade is optional.',
      'Tres fallos seguidos: redefínela para hacerla sostenible. Bajar de '
          'nivel es opcional.',
      'Trois échecs d’affilée : redéfinis-la pour la rendre tenable. La '
          'rétrogradation est facultative.');
  String get transformToMeasure => _p('Trasforma in misura', 'Turn into measure',
      'Convertir en medida', 'Transformer en mesure');
  String requirementN(int n) => _p('Requisito $n', 'Requirement $n',
      'Requisito $n', 'Exigence $n');
  String get conditionHint =>
      _p('condizione...', 'condition...', 'condición...', 'condition...');
  String get levelDown => _p('Scendi di livello (-1)', 'Level down (-1)',
      'Bajar de nivel (-1)', 'Descendre d’un niveau (-1)');
  String get levelDownAction => _p('Scendi di livello', 'Level down',
      'Bajar de nivel', 'Descendre d’un niveau');
  String get levelDownRestoreNote => _p(
      'Verranno ripristinati criteri, tipo e timeframe del livello precedente.',
      'Criteria, type and timeframe of the previous level will be restored.',
      'Se restaurarán criterios, tipo y horario del nivel anterior.',
      'Les critères, le type et le créneau du niveau précédent seront restaurés.');
  String get levelDownNoHistory => _p(
      'Nessuno stato precedente salvato: verra\' solo abbassato il livello.',
      'No previous state saved: only the level will be lowered.',
      'No hay estado anterior guardado: solo se bajará el nivel.',
      'Aucun état précédent enregistré : seul le niveau sera abaissé.');
  String get levelUpAction =>
      _p('Sali di livello', 'Level up', 'Subir de nivel', 'Monter de niveau');
  String get consolidate =>
      _p('Consolida', 'Consolidate', 'Consolidar', 'Consolider');
  String get reviewTitle => _p('Review a mente fredda', 'Cold-headed review',
      'Revisión en frío', 'Revue à tête reposée');
  String get reviewExplain => _p(
      'Le correzioni valgono metà: recuperi metà dei punti che aggiungi, '
          'restituisci metà di quelli che togli. La costanza (streak) non si '
          'spezza.',
      'Corrections are worth half: you recover half the points you add, give '
          "back half of those you remove. Consistency (streak) doesn't break.",
      'Las correcciones valen la mitad: recuperas la mitad de los puntos que '
          'añades y devuelves la mitad de los que quitas. La racha no se rompe.',
      'Les corrections valent moitié : tu récupères la moitié des points '
          'ajoutés, rends la moitié de ceux retirés. La série ne se brise pas.');
  String reviewYesterday(String original) => _p(
      'Ieri $original → dopo review',
      'Yesterday $original → after review',
      'Ayer $original → tras revisión',
      'Hier $original → après revue');
  String get confirmReview => _p('Conferma review', 'Confirm review',
      'Confirmar revisión', 'Confirmer la revue');
  String get statusIntact => _p('Intatta', 'Intact', 'Intacta', 'Intacte');
  String get statusCompromised => _p('Compromessa', 'Compromised',
      'Comprometida', 'Compromise');
  String get statusClean => _p('Pulito', 'Clean', 'Limpio', 'Propre');
  String get statusDone => _p('Fatto', 'Done', 'Hecho', 'Fait');
  String get statusNotDone =>
      _p('Non fatto', 'Not done', 'No hecho', 'Pas fait');

  // --- places & place wizard ---
  String get placesEyebrow => _p('Contesto', 'Context', 'Contexto', 'Contexte');
  String get placesTitle => 'Places';
  String get emptyHub =>
      _p("Svuota l'hub", 'Clear the hub', 'Vaciar el hub', 'Vider le hub');
  String get noActiveEnv => _p(
      'Nessun ambiente attivo: resta solo la core session',
      'No active environment: only the core session remains',
      'Sin entorno activo: solo queda la core session',
      'Aucun environnement actif : seule la core session reste');
  String get hubNote => _p(
      "Un solo ambiente per volta può stare nell'hub. Le statistiche si "
          "adattano al carico dell'ambiente attivo, non a un carico fisso.",
      "Only one environment at a time can be in the hub. Stats adapt to the "
          "active environment's load, not a fixed load.",
      'Solo un entorno a la vez puede estar en el hub. Las estadísticas se '
          'adaptan a la carga del entorno activo, no a una carga fija.',
      'Un seul environnement à la fois peut être dans le hub. Les stats '
          's’adaptent à la charge de l’environnement actif, pas à une charge fixe.');
  String get active => _p('Attivo', 'Active', 'Activo', 'Actif');
  String placeLoad(int load, bool core) => _p(
      '$load task · core session ${core ? "attiva" : "disattivata"}',
      '$load tasks · core session ${core ? "on" : "off"}',
      '$load tareas · core session ${core ? "activa" : "desactivada"}',
      '$load tâches · core session ${core ? "activée" : "désactivée"}');
  String get createEnv => _p('Crea un ambiente', 'Create an environment',
      'Crear un entorno', 'Créer un environnement');
  String get noEnvironments => _p('Nessun ambiente', 'No environments',
      'Sin entornos', 'Aucun environnement');
  String activeEnv(String name) => _p('Ambiente attivo: $name',
      'Active environment: $name', 'Entorno activo: $name',
      'Environnement actif : $name');
  String envCreated(String name) => _p('Ambiente creato: $name',
      'Environment created: $name', 'Entorno creado: $name',
      'Environnement créé : $name');
  String get setupComplete => _p('Configurazione completata', 'Setup complete',
      'Configuración completada', 'Configuration terminée');
  String get envUpdated => _p('Ambiente aggiornato', 'Environment updated',
      'Entorno actualizado', 'Environnement mis à jour');
  String get pwTitleRecog => _p('Dove cambia la tua routine?',
      'Where does your routine change?', '¿Dónde cambia tu rutina?',
      'Où ta routine change-t-elle ?');
  String get pwTitleLoad => _p('Cosa ti porti dietro?',
      'What do you bring along?', '¿Qué te llevas contigo?', 'Qu’emportes-tu ?');
  String get pwStepLoad => _p('Carico', 'Load', 'Carga', 'Charge');
  String get pwSubRecog => _p(
      "Un ambiente è un posto o un periodo con regole diverse: casa, "
          "università, una trasferta, la sessione d'esami.",
      'An environment is a place or period with different rules: home, '
          'university, a trip, exam season.',
      'Un entorno es un lugar o periodo con reglas distintas: casa, '
          'universidad, un viaje, la época de exámenes.',
      'Un environnement est un lieu ou une période avec d’autres règles : '
          'maison, université, un déplacement, la période d’examens.');
  String get pwSubLoad => _p(
      'Puoi tenere la Core Session e aggiungere solo ciò che serve qui, '
          'oppure spegnerla e costruire una routine diversa.',
      'You can keep the Core Session and add only what you need here, or turn '
          'it off and build a different routine.',
      'Puedes mantener la Core Session y añadir solo lo necesario aquí, o '
          'apagarla y construir una rutina distinta.',
      'Tu peux garder la Core Session et n’ajouter que l’utile ici, ou '
          'l’éteindre et bâtir une autre routine.');
  String get pwSub2Recog => _p(
      'Dove sei e che periodo è. Il nome basta a distinguerlo.',
      'Where you are and what period it is. The name is enough to tell it '
          'apart.',
      'Dónde estás y qué periodo es. El nombre basta para distinguirlo.',
      'Où tu es et quelle période. Le nom suffit à le distinguer.');
  String get pwSub2Load => _p('Quali task hanno senso qui dentro.',
      'Which tasks make sense in here.', 'Qué tareas tienen sentido aquí.',
      'Quelles tâches ont du sens ici.');
  String get createEnvironment => _p("Crea l'ambiente", 'Create environment',
      'Crear el entorno', 'Créer l’environnement');
  String get envName => _p("Nome dell'ambiente", 'Environment name',
      'Nombre del entorno', 'Nom de l’environnement');
  String get envNameHint => _p('Sede - Trento, Casa, In viaggio...',
      'Office - Trento, Home, Traveling...', 'Oficina - Trento, Casa, De viaje...',
      'Bureau - Trento, Maison, En voyage...');
  String get descriptionOptional => _p('Descrizione (facoltativa)',
      'Description (optional)', 'Descripción (opcional)', 'Description (facultative)');
  String get coreSession => 'Core session';
  String get tasksInEnv => _p("Task nell'ambiente", 'Tasks in the environment',
      'Tareas del entorno', 'Tâches de l’environnement');
  String get noTasksCreated => _p(
      'Nessuna task creata. Torna in Tasks e creane almeno una.',
      'No tasks created. Go back to Tasks and create at least one.',
      'No hay tareas creadas. Vuelve a Tasks y crea al menos una.',
      'Aucune tâche créée. Retourne dans Tasks et crées-en au moins une.');

  // --- tasks screen ---
  String get tasksEyebrow => _p('Configurazione', 'Setup', 'Configuración',
      'Configuration');
  String get yourTasks =>
      _p('Le tue task', 'Your tasks', 'Tus tareas', 'Tes tâches');
  String get createNewTask => _p('Crea una nuova task', 'Create a new task',
      'Crear una nueva tarea', 'Créer une nouvelle tâche');
  String get taskDragHint => _p(
      'Trascina una task nell\'hub per metterla nel nucleo, trascinala fuori per toglierla. Tieni premuto per le opzioni.',
      'Drag a task into the hub to add it to the core, drag it out to remove it. Hold for options.',
      'Arrastra una tarea al hub para ponerla en el núcleo, arrástrala fuera para quitarla. Mantén pulsado para las opciones.',
      'Fais glisser une tâche dans le hub pour l’ajouter au noyau, hors du hub pour la retirer. Appuie longuement pour les options.');
  String get nothingYet =>
      _p('Ancora niente', 'Nothing yet', 'Todavía nada', 'Rien pour l’instant');
  String get noTasksBody => _p(
      'Una task descrive cosa vuoi mantenere e a che livello di intensita\'. Gli ambienti si costruiscono sopra le task.',
      'A task describes what you want to keep up and at what intensity. Environments are built on top of tasks.',
      'Una tarea describe qué quieres mantener y con qué intensidad. Los entornos se construyen sobre las tareas.',
      'Une tâche décrit ce que tu veux maintenir et à quelle intensité. Les environnements se bâtissent sur les tâches.');
  String get myCoreSession => 'My Core Session';
  String nTasks(int n) =>
      _p('$n task', '$n task${n == 1 ? '' : 's'}', '$n tarea${n == 1 ? '' : 's'}',
          '$n tâche${n == 1 ? '' : 's'}');
  String get coreLockedDesc => _p(
      'Il nucleo che resta attivo in ogni ambiente. Si sblocca appena crei la prima task.',
      'The core that stays active in every environment. It unlocks as soon as you create your first task.',
      'El núcleo que permanece activo en cada entorno. Se desbloquea al crear tu primera tarea.',
      'Le noyau qui reste actif dans chaque environnement. Il se débloque dès ta première tâche.');
  String get coreEverywhereDesc => _p(
      'Restano attive ovunque, qualunque ambiente sia inserito nell\'hub.',
      'They stay active everywhere, whatever environment is in the hub.',
      'Permanecen activas en todas partes, sea cual sea el entorno del hub.',
      'Elles restent actives partout, quel que soit l’environnement du hub.');
  String get dropToAddCore => _p(
      '↓ RILASCIA QUI PER AGGIUNGERE AL NUCLEO',
      '↓ DROP HERE TO ADD TO THE CORE',
      '↓ SUELTA AQUÍ PARA AÑADIR AL NÚCLEO',
      '↓ DÉPOSE ICI POUR AJOUTER AU NOYAU');
  String get dropToRemoveCore => _p(
      '↑ RILASCIA QUI PER TOGLIERE DAL NUCLEO',
      '↑ DROP HERE TO REMOVE FROM THE CORE',
      '↑ SUELTA AQUÍ PARA QUITAR DEL NÚCLEO',
      '↑ DÉPOSE ICI POUR RETIRER DU NOYAU');
  String get addShort => _p('Aggiungi', 'Add', 'Añadir', 'Ajouter');
  String taskOutOfCore(String name) => _p('$name fuori dal nucleo',
      '$name out of the core', '$name fuera del núcleo', '$name retirée du noyau');
  String taskAlreadyCore(String name) => _p('$name è già nel nucleo',
      '$name is already in the core', '$name ya está en el núcleo',
      '$name est déjà dans le noyau');
  String taskNowCore(String name) => _p('$name è nel nucleo',
      '$name is in the core', '$name está en el núcleo', '$name est dans le noyau');

  // --- sheets (dettaglio task / elimina / criterio / place) ---
  String get inCore =>
      _p('nel nucleo', 'in the core', 'en el núcleo', 'dans le noyau');
  String get outOfCore => _p('fuori dal nucleo', 'out of the core',
      'fuera del núcleo', 'hors du noyau');
  String get openDetails => _p('Apri dettagli', 'Open details',
      'Abrir detalles', 'Ouvrir les détails');
  String get removeFromCore => _p('Togli dalla Core Session',
      'Remove from Core Session', 'Quitar de la Core Session',
      'Retirer de la Core Session');
  String get addToCore => _p('Aggiungi alla Core Session', 'Add to Core Session',
      'Añadir a la Core Session', 'Ajouter à la Core Session');
  String get deleteTask =>
      _p('Elimina task', 'Delete task', 'Eliminar tarea', 'Supprimer la tâche');
  String deleteConfirm(String name) => _p('Eliminare "$name"?', 'Delete "$name"?',
      '¿Eliminar "$name"?', 'Supprimer "$name" ?');
  String get deleteBodyCore => _p(
      'Sparisce dal nucleo e dagli ambienti che la usano, insieme ai suoi '
          'criteri e al suo storico. Non si torna indietro.',
      'It disappears from the core and the environments using it, along with '
          "its criteria and history. There's no going back.",
      'Desaparece del núcleo y de los entornos que la usan, junto con sus '
          'criterios y su historial. No hay vuelta atrás.',
      'Elle disparaît du noyau et des environnements qui l’utilisent, avec ses '
          'critères et son historique. Pas de retour en arrière.');
  String get deleteBodyPlain => _p(
      'Spariscono anche i suoi criteri e il suo storico. Non si torna indietro.',
      "Its criteria and history disappear too. There's no going back.",
      'También desaparecen sus criterios y su historial. No hay vuelta atrás.',
      'Ses critères et son historique disparaissent aussi. Pas de retour en arrière.');
  String get delete => _p('Elimina', 'Delete', 'Eliminar', 'Supprimer');
  String get taskDeleted => _p('Task eliminata', 'Task deleted',
      'Tarea eliminada', 'Tâche supprimée');
  String objective(String target) => _p('Obiettivo $target', 'Target $target',
      'Objetivo $target', 'Objectif $target');
  String get noCriterion =>
      _p('Nessun criterio.', 'No criteria.', 'Sin criterios.', 'Aucun critère.');
  String get coreNote => _p(
      'Queste task valgono in ogni ambiente che tiene la core session attiva.',
      'These tasks apply in every environment that keeps the core session '
          'active.',
      'Estas tareas valen en todo entorno que mantenga la core session activa.',
      'Ces tâches valent dans tout environnement gardant la core session active.');
  String get allInCore => _p('Tutte le task sono già nel nucleo.',
      'All tasks are already in the core.', 'Todas las tareas ya están en el núcleo.',
      'Toutes les tâches sont déjà dans le noyau.');
  String get newCriterion => _p('Nuovo criterio', 'New criterion',
      'Nuevo criterio', 'Nouveau critère');
  String get editCriterion => _p('Modifica criterio', 'Edit criterion',
      'Editar criterio', 'Modifier le critère');
  String get criterionHelp => _p(
      'Una condizione verificabile: se non è vera, la giornata non conta.',
      "A verifiable condition: if it's not true, the day doesn't count.",
      'Una condición verificable: si no es cierta, el día no cuenta.',
      'Une condition vérifiable : si elle est fausse, la journée ne compte pas.');
  String coreSessionState(bool core) => _p(
      'Core session ${core ? "attiva" : "disattivata"}',
      'Core session ${core ? "on" : "off"}',
      'Core session ${core ? "activa" : "desactivada"}',
      'Core session ${core ? "activée" : "désactivée"}');
  String get noTasks => _p('Nessuna task.', 'No tasks.', 'Sin tareas.', 'Aucune tâche.');
  String get edit => _p('Modifica', 'Edit', 'Editar', 'Modifier');
  String get activate => _p('Attiva', 'Activate', 'Activar', 'Activer');
  String get deleteEnvironment => _p('Elimina ambiente', 'Delete environment',
      'Eliminar entorno', 'Supprimer l’environnement');
  String get environmentDeleted => _p('Ambiente eliminato', 'Environment deleted',
      'Entorno eliminado', 'Environnement supprimé');

  // --- onboarding flow & nav ---
  String get firstUse =>
      _p('Primo utilizzo', 'First time', 'Primer uso', 'Première fois');
  String get onbStartTitle => _p('Partiamo da una cosa sola',
      "Let's start with just one thing", 'Empecemos por una sola cosa',
      'Commençons par une seule chose');
  String get onbStartBody => _p(
      'Scegli un’attività che vuoi rendere parte delle tue giornate. '
          'Bastano tre domande: il resto lo costruiamo dopo, insieme.',
      'Choose an activity you want to make part of your days. Just three '
          'questions: we build the rest later, together.',
      'Elige una actividad que quieras hacer parte de tus días. Bastan tres '
          'preguntas: el resto lo construimos luego, juntos.',
      'Choisis une activité que tu veux intégrer à tes journées. Trois '
          'questions suffisent : on bâtit le reste ensuite, ensemble.');
  String get onbTapCreateTask => _p('Tocca “Crea una nuova task”',
      'Tap “Create a new task”', 'Toca “Crear una nueva tarea”',
      'Touche « Créer une nouvelle tâche »');
  String get skipTutorial => _p('Salta il tutorial', 'Skip the tutorial',
      'Saltar el tutorial', 'Passer le tutoriel');
  String get onbCoreKicker => _p('La base della tua routine',
      'The base of your routine', 'La base de tu rutina', 'La base de ta routine');
  String get onbCoreTitle => _p('Questa è la tua Core Session',
      'This is your Core Session', 'Esta es tu Core Session',
      'Voici ta Core Session');
  String get onbCoreBody => _p(
      'Le task che metti qui ti seguono ovunque. Quando cambi ambiente '
          'restano con te, salvo che tu decida il contrario.',
      'The tasks you put here follow you everywhere. When you change '
          'environment they stay with you, unless you decide otherwise.',
      'Las tareas que pongas aquí te siguen a todas partes. Al cambiar de '
          'entorno siguen contigo, salvo que decidas lo contrario.',
      'Les tâches mises ici te suivent partout. En changeant d’environnement '
          'elles restent avec toi, sauf décision contraire.');
  String get onbPutTask => _p('Mettici la task', 'Put the task here',
      'Pon la tarea aquí', 'Mets la tâche ici');
  String get notNow => _p('Non ora', 'Not now', 'Ahora no', 'Pas maintenant');
  String get optional => _p('Facoltativo', 'Optional', 'Opcional', 'Facultatif');
  String get onbPlacesTitle => _p('La tua routine cambia con te',
      'Your routine changes with you', 'Tu rutina cambia contigo',
      'Ta routine change avec toi');
  String get onbPlacesBody => _p(
      'A casa, in trasferta o in vacanza una buona giornata non chiede le '
          'stesse cose. Gli ambienti servono a questo.',
      'At home, on a trip or on holiday, a good day asks for different '
          'things. Environments are for this.',
      'En casa, de viaje o de vacaciones, un buen día no pide lo mismo. Para '
          'eso sirven los entornos.',
      'À la maison, en déplacement ou en vacances, une bonne journée ne '
          'demande pas la même chose. Les environnements servent à ça.');
  String get onbSeePlaces => _p('Vediamo Places', "Let's see Places",
      'Veamos Places', 'Voyons Places');
  String get onbDone => _p('Ho finito', "I'm done", 'He terminado', 'J’ai fini');
  String get onbCreateFirstEnv => _p('Crea il tuo primo ambiente',
      'Create your first environment', 'Crea tu primer entorno',
      'Crée ton premier environnement');
  String get onbEnvBody => _p(
      'Un ambiente decide quali task valgono mentre sei lì. Puoi portarti '
          'dietro la Core Session e aggiungere solo ciò che serve.',
      "An environment decides which tasks apply while you're there. You can "
          'bring the Core Session along and add only what you need.',
      'Un entorno decide qué tareas valen mientras estás ahí. Puedes llevarte '
          'la Core Session y añadir solo lo necesario.',
      'Un environnement décide quelles tâches valent quand tu y es. Tu peux '
          'emporter la Core Session et n’ajouter que l’utile.');
  String get onbTapCreateEnv => _p('Tocca “Crea un ambiente”',
      'Tap “Create an environment”', 'Toca “Crear un entorno”',
      'Touche « Créer un environnement »');
  String get navHome => 'Home';
  String get navTasks => 'Tasks';
  String get navPlaces => 'Places';
  String get navTrend => 'Trend';

  String get signLabel => _p('SEGNO', 'SIGN', 'SIGNO', 'SIGNE');
  String get dragHereEnv => _p('TRASCINA QUI UN AMBIENTE',
      'DRAG AN ENVIRONMENT HERE', 'ARRASTRA UN ENTORNO AQUÍ',
      'FAIS GLISSER UN ENVIRONNEMENT ICI');
  String get activeEnvCaps => _p('AMBIENTE ATTIVO', 'ACTIVE ENVIRONMENT',
      'ENTORNO ACTIVO', 'ENVIRONNEMENT ACTIF');

  String get editTask =>
      _p('Modifica task', 'Edit task', 'Editar tarea', 'Modifier la tâche');
  String get editWindowNote => _p(
      "Hai 12h dalla creazione o dall'upgrade per correggere nome e requisiti.",
      'You have 12h from creation or upgrade to fix the name and requirements.',
      'Tienes 12h desde la creación o la mejora para corregir nombre y requisitos.',
      'Tu as 12h après la création ou la montée pour corriger nom et exigences.');
  String get criteriaLabel => _p('CRITERI', 'CRITERIA', 'CRITERIOS', 'CRITÈRES');

  String get growthCurve => _p('CURVA DI CRESCITA', 'GROWTH CURVE',
      'CURVA DE CRECIMIENTO', 'COURBE DE CROISSANCE');

  String get reactivateTask => _p('Riabilita task', 'Reactivate task',
      'Reactivar tarea', 'Réactiver la tâche');
  String get taskReactivated => _p('Task riabilitata', 'Task reactivated',
      'Tarea reactivada', 'Tâche réactivée');

  String get whenLabel => _p('QUANDO', 'WHEN', 'CUÁNDO', 'QUAND');

  String get points => _p('Punti', 'Points', 'Puntos', 'Points');
  String get restartTutorial => _p('Riavvia tutorial', 'Restart tutorial',
      'Reiniciar tutorial', 'Relancer le tutoriel');
  String get convertToDaily => _p('Converti in giornaliera', 'Convert to daily',
      'Convertir en diaria', 'Convertir en quotidienne');
  String get convertToMaintenance => _p('Converti in mantenimento',
      'Convert to maintenance', 'Convertir en mantenimiento',
      'Convertir en maintien');
  String get convertMaintTitle => _p('Convertire in mantenimento?',
      'Convert to maintenance?', '¿Convertir en mantenimiento?',
      'Convertir en maintien ?');
  String get convertMaintBody => _p(
      'Diventerà "valida finché non la infrangi" e lo streak ripartirà da '
          'zero. I criteri diventano le condizioni da mantenere.',
      'It will become "valid until you break it" and the streak restarts from '
          'zero. The criteria become the conditions to keep.',
      'Pasará a ser "válida hasta que la rompas" y la racha volverá a cero. '
          'Los criterios se vuelven las condiciones a mantener.',
      'Elle deviendra « valide jusqu’à ce que tu la brises » et la série '
          'repart de zéro. Les critères deviennent les conditions à tenir.');
  String get convert => _p('Converti', 'Convert', 'Convertir', 'Convertir');
  String get needsCriteria => _p(
      'Aggiungi almeno un criterio prima di convertire.',
      'Add at least one criterion before converting.',
      'Añade al menos un criterio antes de convertir.',
      'Ajoute au moins un critère avant de convertir.');

  // --- date (nomi localizzati, gia' capitalizzati) ---
  List<String> get months {
    switch (lang) {
      case AppLang.en:
        return const [
          'January', 'February', 'March', 'April', 'May', 'June', 'July',
          'August', 'September', 'October', 'November', 'December'
        ];
      case AppLang.es:
        return const [
          'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio',
          'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
        ];
      case AppLang.fr:
        return const [
          'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet',
          'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
        ];
      case AppLang.it:
        return const [
          'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
          'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
        ];
    }
  }

  List<String> get daysLong {
    switch (lang) {
      case AppLang.en:
        return const [
          'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
          'Sunday'
        ];
      case AppLang.es:
        return const [
          'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado',
          'Domingo'
        ];
      case AppLang.fr:
        return const [
          'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi',
          'Dimanche'
        ];
      case AppLang.it:
        return const [
          'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato',
          'Domenica'
        ];
    }
  }

  List<String> get daysShort {
    switch (lang) {
      case AppLang.en:
        return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case AppLang.es:
        return const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      case AppLang.fr:
        return const ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      case AppLang.it:
        return const ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    }
  }
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
