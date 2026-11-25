import 'dates.dart';

/// Serie pronta per il grafico: valori (null = nessun dato) ed etichette.
class ChartSeries {
  const ChartSeries(this.values, this.labels);
  final List<double?> values;
  final List<String> labels;
}

/// Numero massimo di candele renderizzate prima di aggregare (densità target
/// per la larghezza di un telefono).
const int kMaxCandles = 64;

/// Aggregazione adattiva per la vista "Storico": copre da [firstDay] a [today]
/// (niente spazi vuoti), e sceglie la dimensione del bucket (1,2,3,7,14,30,…)
/// più piccola che tiene il numero di candele ≤ [maxCandles]. Finché i dati
/// sono pochi le candele sono giornaliere; man mano che lo storico cresce si
/// aggregano da sole. [value] torna null per i giorni senza dato/fuori dominio.
ChartSeries adaptiveHistory({
  required DateTime firstDay,
  required DateTime today,
  required double? Function(DateTime) value,
  required List<String> months,
  int maxCandles = kMaxCandles,
}) {
  final first = Dates.dayOf(firstDay);
  final last = Dates.dayOf(today);
  var spanDays = last.difference(first).inDays + 1;
  if (spanDays < 1) spanDays = 1;

  const steps = [1, 2, 3, 7, 14, 30, 60, 90, 180, 365];
  var bucket = steps.last;
  for (final b in steps) {
    if ((spanDays / b).ceil() <= maxCandles) {
      bucket = b;
      break;
    }
  }

  final nBuckets = (spanDays / bucket).ceil();
  final labelEvery = (nBuckets / 6).ceil().clamp(1, nBuckets);
  final values = <double?>[];
  final labels = <String>[];

  for (var bk = nBuckets - 1; bk >= 0; bk--) {
    var sum = 0.0;
    var n = 0;
    DateTime? rep; // giorno più recente del bucket, per l'etichetta
    for (var k = 0; k < bucket; k++) {
      final d = Dates.addDays(today, -(bk * bucket + k));
      if (d.isBefore(first)) continue;
      rep ??= d;
      final v = value(d);
      if (v != null) {
        sum += v;
        n++;
      }
    }
    values.add(n == 0 ? null : sum / n);
    labels.add(
        (bk % labelEvery == 0 && rep != null) ? _label(rep, bucket, months) : '');
  }
  return ChartSeries(values, labels);
}

String _label(DateTime d, int bucket, List<String> months) {
  if (bucket >= 28) return months[d.month - 1].substring(0, 3);
  if (bucket >= 7) return '${d.day}/${d.month}';
  return '${d.day}';
}
