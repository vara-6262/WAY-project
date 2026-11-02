/// Helper di data condivisi. Settimana che inizia di lunedi': indice 0 = lunedi'.
class Dates {
  const Dates._();

  static const dayShort = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
  static const dayLong = [
    'lunedi',
    'martedi',
    'mercoledi',
    'giovedi',
    'venerdi',
    'sabato',
    'domenica',
  ];
  static const months = [
    'gennaio',
    'febbraio',
    'marzo',
    'aprile',
    'maggio',
    'giugno',
    'luglio',
    'agosto',
    'settembre',
    'ottobre',
    'novembre',
    'dicembre',
  ];

  /// 0 = lunedi', 6 = domenica.
  static int weekdayIndex(DateTime d) => d.weekday - 1;

  /// Il lunedi' della settimana di calendario che contiene [d].
  static DateTime mondayOf(DateTime d) => addDays(dayOf(d), -weekdayIndex(d));

  static DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime today() => dayOf(DateTime.now());

  static String key(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  static DateTime parse(String key) => DateTime.parse(key);

  static DateTime addDays(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day + n);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Vero se `d` cade nella finestra [start, end], estremi inclusi.
  static bool inWindow(DateTime d, DateTime start, DateTime end) {
    final x = dayOf(d);
    return !x.isBefore(dayOf(start)) && !x.isAfter(dayOf(end));
  }

  static String short(DateTime d) => '${d.day} ${months[d.month - 1].substring(0, 3)}';

  static String pretty(DateTime d) => '${d.day}/${d.month}/${d.year}';

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// Quanti giorni vuoti prima del primo del mese, con settimana da lunedi'.
  static int leadingBlanks(int year, int month) =>
      DateTime(year, month, 1).weekday - 1;
}
