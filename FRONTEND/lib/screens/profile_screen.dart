import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_data.dart';
import '../state/providers.dart';
import '../theme/way_colors.dart';
import '../theme/way_theme.dart';
import '../widgets/common.dart';

/// Profilo: aspetto (tema), modalità dei dati e strumenti di debug.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final current = ref.watch(themeProvider);
    final mode = ref.watch(modeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ScreenHeader(eyebrow: 'Sistema', title: 'Profilo'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            children: [
              const SectionLabel('Tema'),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final preset in WayColors.presets)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _ThemeSwatch(
                          label: preset.$2,
                          palette: preset.$3,
                          selected: identical(preset.$3, current),
                          onTap: () => ref.read(themeProvider.notifier).setId(preset.$1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionLabel('Dati'),
              const SizedBox(height: 8),
              Text('Demo già popolata oppure configurazione da zero.',
                  style: WayFonts.ui(size: 12.5, color: c.inkFaint)),
              const SizedBox(height: 8),
              Segmented<PrototypeMode>(
                values: PrototypeMode.values,
                labels: const ['Demo', 'Da zero'],
                selected: mode,
                onChanged: (m) => ref.read(modeProvider.notifier).set(m),
              ),
              const SizedBox(height: 24),
              const SectionLabel('Debug'),
              const SizedBox(height: 8),
              _DebugButton(
                icon: Icons.refresh,
                label: 'Ricarica dati di questa modalità',
                onTap: () => ref.read(appProvider.notifier).resetCurrentMode(),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.surface2,
                  border: Border.all(color: c.lineSoft),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Debug notifiche (invio manuale e "prossima notifica programmata") in arrivo: richiede il modulo notifiche, non ancora integrato in questa build.',
                  style: WayFonts.ui(size: 12, color: c.inkFaint),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.label,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final WayColors palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: palette.surface2,
          border: Border.all(color: selected ? palette.accent : c.line, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _dot(palette.accent),
                const SizedBox(width: 4),
                _dot(palette.ink),
                const SizedBox(width: 4),
                _dot(palette.media),
              ],
            ),
            const SizedBox(height: 8),
            Text(label,
                style: WayFonts.mono(
                    size: 10,
                    weight: FontWeight.w700,
                    color: selected ? palette.accent : palette.inkSoft)),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _DebugButton extends StatelessWidget {
  const _DebugButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface2,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c.inkSoft),
            const SizedBox(width: 10),
            Text(label, style: WayFonts.ui(size: 13.5, color: c.ink)),
          ],
        ),
      ),
    );
  }
}
