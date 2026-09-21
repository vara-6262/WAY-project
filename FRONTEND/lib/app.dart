import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/shell.dart';
import 'state/providers.dart';
import 'theme/way_theme.dart';

class WayApp extends ConsumerWidget {
  const WayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(themeProvider);
    return MaterialApp(
      title: 'WAY',
      debugShowCheckedModeBanner: false,
      theme: WayTheme.build(palette),
      home: Shell(key: shellKey),
    );
  }
}
