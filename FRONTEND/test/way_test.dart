import 'package:flutter_test/flutter_test.dart';
import 'package:way/data/dates.dart';
import 'package:way/data/seed.dart';
import 'package:way/models/app_data.dart';
import 'package:way/models/models.dart';
import 'package:way/screens/first_run_wizard.dart';

void main() {
  test('la difficolta segue il numero di criteri', () {
    expect(difficultyForCriteria(0), Difficulty.easy);
    expect(difficultyForCriteria(3), Difficulty.easy);
    expect(difficultyForCriteria(4), Difficulty.media);
    expect(difficultyForCriteria(7), Difficulty.media);
    expect(difficultyForCriteria(8), Difficulty.hard);
  });

  test('la demo si serializza e torna identica', () {
    final seed = buildProxyData();
    final back = AppData.fromJson(seed.toJson());
    expect(back.tasks.length, seed.tasks.length);
    expect(back.places.length, seed.places.length);
    expect(back.coreIds, seed.coreIds);
    expect(back.activePlaceId, seed.activePlaceId);
    expect(back.onboarding.stage, OnboardingStage.done);
  });

  test('l archivio vuoto parte con il tutorial alla prima tappa', () {
    final empty = buildEmptyData();
    expect(empty.tasks, isEmpty);
    expect(empty.onboarding.stage, OnboardingStage.taskIntro);
    expect(empty.onboarding.active, isTrue);
  });

  test('senza ambiente attivo resta solo la core session', () {
    final seed = buildProxyData().copyWith(clearActivePlace: true);
    final ids = seed.tasksInScope().map((t) => t.id).toSet();
    expect(ids, seed.coreIds.toSet());
  });

  test('la percentuale del giorno puo superare il 100', () {
    var seed = buildProxyData();
    final task = seed.tasks.firstWhere((t) => t.kind == TaskKind.measure);
    final today = Dates.today();
    final log = {for (final e in seed.log.entries) e.key: {...e.value}};
    log[Dates.key(today)] = {task.id: task.target * 2};
    seed = seed.copyWith(log: log);
    expect(seed.percentOf(task, today), greaterThan(100));
  });

  test('i giorni senza task non spezzano la serie', () {
    final empty = buildEmptyData();
    expect(empty.dayScore(Dates.today()), isNull);
    expect(empty.dayStreak(), 0);
  });

  test('l icona viene indovinata dal nome', () {
    expect(guessIcon('Allenamento'), 'dumbbell');
    expect(guessIcon('Studio di storia'), 'book');
    expect(guessIcon('Sveglia 8:00'), 'alarm');
    expect(guessIcon('qualcosa di strano'), 'target');
  });
}
