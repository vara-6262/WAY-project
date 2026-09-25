import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/dates.dart';
import '../models/app_data.dart';
import '../models/models.dart';

class Reminder {
  const Reminder(this.when, this.text);
  final DateTime when;
  final String text;
}

/// Notifiche locali per-task ricavate dai domini (giorni + finestra oraria):
/// "è il momento" all'ora di inizio, "scade tra 30 minuti" prima della fine.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'way_reminders',
      'Promemoria WAY',
      channelDescription: 'Disponibilità e scadenze delle task',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    final a = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await a?.requestNotificationsPermission();
    await a?.requestExactAlarmsPermission();
    await a?.createNotificationChannel(const AndroidNotificationChannel(
      'way_reminders',
      'Promemoria WAY',
      description: 'Disponibilità e scadenze delle task',
      importance: Importance.high,
    ));
  }

  /// Promemoria futuri per i prossimi [horizon] giorni, ordinati.
  List<Reminder> reminders(AppData data, {int horizon = 7}) {
    final out = <Reminder>[];
    final now = DateTime.now();
    final tasks = data.tasksInScope();
    final weeklyDone = <String>{};
    for (var d = 0; d < horizon; d++) {
      final day = Dates.addDays(Dates.today(), d);
      final wd = Dates.weekdayIndex(day);
      for (final t in tasks) {
        if (!t.days.contains(wd)) continue;
        if (t.period == DomainPeriod.weekly) {
          final wk = '${t.id}|${Dates.key(Dates.mondayOf(day))}';
          if (weeklyDone.contains(wk)) continue;
          weeklyDone.add(wk);
        }
        final avail = DateTime(day.year, day.month, day.day, t.start, 0);
        if (avail.isAfter(now)) out.add(Reminder(avail, '${t.name}: è il momento'));
        final warnH = (t.end - 1).clamp(0, 23);
        final warn = DateTime(day.year, day.month, day.day, warnH, 30);
        if (warn.isAfter(now)) out.add(Reminder(warn, '${t.name}: scade tra 30 minuti'));
      }
    }
    out.sort((a, b) => a.when.compareTo(b.when));
    return out;
  }

  Reminder? next(AppData data) {
    final r = reminders(data);
    return r.isEmpty ? null : r.first;
  }

  Future<void> scheduleFor(AppData data) async {
    await _plugin.cancelAll();
    var id = 1;
    for (final r in reminders(data)) {
      if (id > 400) break;
      await _one(id++, r);
    }
  }

  Future<void> _one(int id, Reminder r) async {
    final when = tz.TZDateTime.from(r.when, tz.local);
    try {
      await _plugin.zonedSchedule(id, 'WAY', r.text, when, _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime);
    } catch (_) {
      await _plugin.zonedSchedule(id, 'WAY', r.text, when, _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime);
    }
  }

  Future<void> sendTest() =>
      _plugin.show(999000, 'WAY — test', 'Se la vedi, le notifiche funzionano.', _details);

  /// Notifica PIANIFICATA (coda vera, non show immediato) tra 1 minuto:
  /// testa il percorso in background e l'affidabilità dello scheduling.
  Future<void> sendDelayedTest() async {
    final when = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
    try {
      await _plugin.zonedSchedule(
        999001,
        'WAY — test tra 1 minuto',
        'Se la vedi, le notifiche programmate in background funzionano.',
        when,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        999001,
        'WAY — test tra 1 minuto',
        'Pianificata in modalità inesatta (manca il permesso sveglie esatte).',
        when,
        _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Le "sveglie esatte" sono concesse? (causa n.1 delle notifiche che non partono)
  Future<bool> canExact() async {
    final a = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return (await a?.canScheduleExactNotifications()) ?? false;
  }

  Future<int> pendingCount() async =>
      (await _plugin.pendingNotificationRequests()).length;
}
