import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/strings.dart';
import 'screens/shell.dart';
import 'state/providers.dart';
import 'theme/way_theme.dart';

class WayApp extends ConsumerWidget {
  const WayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(themeProvider);
    final lang = ref.watch(localeProvider);
    return L10nScope(
      strings: S(lang),
      child: MaterialApp(
        title: 'WAY',
        debugShowCheckedModeBanner: false,
        theme: WayTheme.build(palette),
        locale: Locale(lang.name),
        supportedLocales: const [Locale('it'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Shell(key: shellKey),
      ),
    );
  }
}
