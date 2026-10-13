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
