import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/notifications.dart';
import 'state/providers.dart';
//hhhhhhhhhh
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  // I dati vengono letti prima del primo frame e iniettati con un override:
  // il controller resta sincrono e l'app non parte mai da uno stato vuoto
  // che poi cambia sotto gli occhi.
  final prefs = await SharedPreferences.getInstance();
  final boot = Bootstrap.load(prefs);

  final notif = NotificationService();
  try {
    await notif.init();
  } catch (e, s) {
    debugPrint('Init notifiche: $e\n$s');
  }
  try {
    await notif.scheduleFor(boot.data);
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        bootstrapProvider.overrideWithValue(boot),
        notificationsProvider.overrideWithValue(notif),
      ],
      child: const WayApp(),
    ),
  );
}
