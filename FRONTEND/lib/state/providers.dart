import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dates.dart';
import '../data/seed.dart';
import '../models/app_data.dart';
import '../theme/way_colors.dart';
import '../services/notifications.dart';
import '../models/models.dart';

const proxyKey = 'way.prototype.v1';
const zeroKey = 'way.prototype.zero.v1';
const modeKey = 'way.prototype.mode.v1';

String storageKeyFor(PrototypeMode mode) =>
    mode == PrototypeMode.zero ? zeroKey : proxyKey;

/// Quello che main() legge dal disco prima del primo frame.
class Bootstrap {
  const Bootstrap({required this.mode, required this.data});

  final PrototypeMode mode;
  final AppData data;

  static Bootstrap load(SharedPreferences prefs) {
    final mode = prefs.getString(modeKey) == 'zero'
        ? PrototypeMode.zero
        : PrototypeMode.proxy;
    return Bootstrap(mode: mode, data: readData(prefs, mode));
  }

  static AppData readData(SharedPreferences prefs, PrototypeMode mode) {
    final raw = prefs.getString(storageKeyFor(mode));
    if (raw == null) return freshData(mode);
    try {
      return AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Archivio illeggibile (formato vecchio, dato corrotto): si riparte
      // pulito invece di aprire l'app su una schermata rotta.
      return freshData(mode);
    }
  }

  static AppData freshData(PrototypeMode mode) =>
      mode == PrototypeMode.zero ? buildEmptyData() : buildProxyData();
}

/// Riempiti da main() con override.
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('prefsProvider va sovrascritto in main()'),
);
final bootstrapProvider = Provider<Bootstrap>(
  (ref) => throw UnimplementedError('bootstrapProvider va sovrascritto in main()'),
);

final modeProvider =
    NotifierProvider<ModeController, PrototypeMode>(ModeController.new);

final appProvider = NotifierProvider<AppController, AppData>(AppController.new);

/// Selettori: i widget guardano solo la fetta che li riguarda.
final activePlaceProvider = Provider<Place?>(
  (ref) => ref.watch(appProvider).activePlace,
);
final onboardingProvider = Provider<OnboardingState>(
  (ref) => ref.watch(appProvider).onboarding,
);

/// Il tutorial esiste solo nella modalita' "configura da 0".
final tutorialActiveProvider = Provider<bool>((ref) {
  final mode = ref.watch(modeProvider);
  final ob = ref.watch(onboardingProvider);
  return mode == PrototypeMode.zero && ob.active;
});

String newId() {
  final r = Random();
  return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${r.nextInt(46656).toRadixString(36)}';
}

class ModeController extends Notifier<PrototypeMode> {
  @override
  PrototypeMode build() => ref.read(bootstrapProvider).mode;

  void set(PrototypeMode next) {
    if (next == state) return;
    final prefs = ref.read(prefsProvider);
    prefs.setString(modeKey, next.name);
    state = next;
    // Ogni modalita' ha il suo archivio: passare da una all'altra non
    // distrugge il lavoro fatto nell'altra.
    ref.read(appProvider.notifier).loadFor(next);
  }
}

class AppController extends Notifier<AppData> {
  @override
  AppData build() => ref.read(bootstrapProvider).data;

  PrototypeMode get _mode => ref.read(modeProvider);

  void _write(AppData next) {
    state = next;
    final prefs = ref.read(prefsProvider);
    // Salvataggio non atteso: la UI non deve mai fermarsi per una scrittura.
    prefs.setString(storageKeyFor(_mode), jsonEncode(next.toJson()));
  }

  void loadFor(PrototypeMode mode) {
    state = Bootstrap.readData(ref.read(prefsProvider), mode);
  }

  void resetCurrentMode() => _write(Bootstrap.freshData(_mode));

  // --- Task -----------------------------------------------------------------

  void addTask(Task task) => _write(state.copyWith(tasks: [...state.tasks, task]));

  void updateTask(Task task) => _write(
        state.copyWith(
          tasks: [
            for (final t in state.tasks) if (t.id == task.id) task else t,
          ],
        ),
      );

  void deleteTask(String taskId) => _write(
        state.copyWith(
          tasks: state.tasks.where((t) => t.id != taskId).toList(),
          coreIds: state.coreIds.where((id) => id != taskId).toList(),
          places: [
            for (final p in state.places)
              p.copyWith(taskIds: p.taskIds.where((id) => id != taskId).toList()),
          ],
        ),
      );

  // --- Core Session ---------------------------------------------------------

  void addToCore(String taskId) {
    if (state.coreIds.contains(taskId)) return;
    _write(state.copyWith(coreIds: [...state.coreIds, taskId]));
  }

  void removeFromCore(String taskId) => _write(
        state.copyWith(
          coreIds: state.coreIds.where((id) => id != taskId).toList(),
        ),
      );

  void toggleCore(String taskId) =>
      state.coreIds.contains(taskId) ? removeFromCore(taskId) : addToCore(taskId);

  // --- Ambienti -------------------------------------------------------------

  void addPlace(Place place) =>
      _write(state.copyWith(places: [...state.places, place]));

  void updatePlace(Place place) => _write(
        state.copyWith(
          places: [
            for (final p in state.places) if (p.id == place.id) place else p,
          ],
        ),
      );

  void deletePlace(String placeId) {
    final next = state.copyWith(
      places: state.places.where((p) => p.id != placeId).toList(),
    );
    _write(state.activePlaceId == placeId
        ? next.copyWith(clearActivePlace: true)
        : next);
  }

  void activatePlace(String placeId) =>
      _write(state.copyWith(activePlaceId: placeId));

  void clearActivePlace() => _write(state.copyWith(clearActivePlace: true));

  // --- Esecuzione giornaliera ----------------------------------------------

  void setValue(Task task, double value, {DateTime? day}) {
    final key = Dates.key(day ?? DateTime.now());
    final log = {for (final e in state.log.entries) e.key: {...e.value}};
    final entry = log.putIfAbsent(key, () => <String, double>{});
    entry[task.id] = value < 0 ? 0 : value;
    _write(state.copyWith(log: log));
  }

  void toggleDone(Task task, {DateTime? day}) {
    final current = state.valueOf(task, day ?? DateTime.now());
    setValue(task, current > 0 ? 0 : 1, day: day);
  }

  void bump(Task task, double delta, {DateTime? day}) {
    final current = state.valueOf(task, day ?? DateTime.now());
    final next = ((current + delta) * 2).round() / 2;
    setValue(task, next < 0 ? 0 : next, day: day);
  }

  // --- Livelli e vista ------------------------------------------------------

  void acceptLevelUp(Task task) =>
      updateTask(task.copyWith(level: task.level + 1, streak: 0));

  void dismissLevelUp(Task task) => _write(
        state.copyWith(dismissedLevelUps: [...state.dismissedLevelUps, task.id]),
      );

  void setRange(TrendRange range) => _write(state.copyWith(range: range));

  // --- Primo utilizzo -------------------------------------------------------

  void setStage(OnboardingStage stage) =>
      _write(state.copyWith(onboarding: state.onboarding.copyWith(stage: stage)));

  void finishOnboarding() =>
      _write(state.copyWith(onboarding: OnboardingState.finished));

  void markEducation({bool? criteria, bool? complete, bool? measure}) => _write(
        state.copyWith(
          onboarding: state.onboarding.copyWith(
            criteriaSeen: criteria,
            completeSeen: complete,
            measureSeen: measure,
          ),
        ),
      );
}


/// Tema selezionato (palette WayColors), persistito.
final themeProvider =
    NotifierProvider<ThemeController, WayColors>(ThemeController.new);

class ThemeController extends Notifier<WayColors> {
  static const _key = 'way_theme_id';

  @override
  WayColors build() {
    final id = ref.read(prefsProvider).getString(_key) ?? 'lime';
    return WayColors.byId(id);
  }

  void setId(String id) {
    ref.read(prefsProvider).setString(_key, id);
    state = WayColors.byId(id);
  }
}

/// Servizio notifiche (istanza inizializzata in main).
final notificationsProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError('notificationsProvider va sovrascritto in main()'),
);
