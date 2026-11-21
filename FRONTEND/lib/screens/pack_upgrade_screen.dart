import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/packs.dart';
import '../fx/fx_controller.dart';
import '../fx/reward.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../models/sabus_scoring.dart';
import '../state/providers.dart';
import '../theme/way_theme.dart';
import '../widgets/common.dart';
import 'wizard_scaffold.dart';

/// Upgrade PRE-SCRIPTATO di una task di pack: non si edita nulla, si vede il
/// passo gia' deciso (con la spiegazione del perche') e lo si applica. Serve a
/// insegnare come si evolve una task: gradualita', quando toccare finestra,
/// frequenza, qualita' o target.
class PackUpgradeScreen extends ConsumerWidget {
  const PackUpgradeScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    final lang = ref.watch(localeProvider);
    final data = ref.watch(appProvider);
    Task? task;
    for (final t in data.tasks) {
      if (t.id == taskId) task = t;
    }
    final t = task;
    if (t == null) {
      return const Scaffold(body: SafeArea(child: SizedBox.shrink()));
    }
    final step = data.packNextUpgrade(t);
    if (step == null) {
      return const Scaffold(body: SafeArea(child: SizedBox.shrink()));
    }

    final changes = _changes(context, t, step, lang);

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.s.packUpgradeKicker,
                            style: WayFonts.label(color: c.inkFaint, size: 9.5)),
                        const SizedBox(height: 2),
                        Text('${t.name}  ·  LV${t.level} → LV${t.level + 1}',
                            style: WayFonts.display(size: 20, color: c.ink)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Text(context.s.close,
                        style: WayFonts.ui(
                            size: 12, weight: FontWeight.w700, color: c.inkFaint)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                children: [
                  ExplainBox(step.note(lang)),
                  const SizedBox(height: 18),
                  Text(context.s.packWhatChanges,
                      style: WayFonts.label(color: c.inkFaint, size: 9.5)),
                  const SizedBox(height: 10),
                  if (changes.isEmpty)
                    Text(context.s.packNoChange,
                        style: WayFonts.ui(size: 13, color: c.inkSoft))
                  else
                    for (final line in changes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.arrow_forward_rounded,
                                size: 15, color: c.accent),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(line,
                                  style:
                                      WayFonts.ui(size: 13.5, color: c.ink)),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.lineSoft)),
              ),
              child: PrimaryButton(
                label: context.s.packUpgradeApply,
                onPressed: () {
                  final from = t.level;
                  ref.read(appProvider.notifier).applyPackUpgrade(t);
                  final updated = ref.read(appProvider).tasks.firstWhere(
                        (x) => x.id == t.id,
                        orElse: () => t,
                      );
                  final size = MediaQuery.of(context).size;
                  Reward.levelUp(ref.read(fxProvider), updated, from,
                      Offset(size.width / 2, size.height / 2));
                  Navigator.of(context).maybePop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Riepilogo leggibile di cosa cambia in questo passo.
  List<String> _changes(
      BuildContext context, Task t, PackUpgrade step, AppLang lang) {
    final out = <String>[];
    final s = context.s;

    if (step.toNumber && t.kind == TaskKind.complete) {
      out.add(s.packToNumber(step.target ?? 1.0));
    } else if (step.target != null && step.target != t.target) {
      out.add(s.packTargetChange(_fmt(t.target), _fmt(step.target!)));
    }

    final newWin = step.windowMinutes;
    if (t.isCodependent && newWin != null && newWin != t.windowMinutes) {
      out.add(s.packWindowChange(_win(t.windowMinutes), _win(newWin)));
    }

    if (step.requirements != null) {
      final reqs = step.requirements!.map((r) => r(lang)).join(' · ');
      out.add(s.packNewRequirements(reqs));
    }

    if (step.days != null && !_sameDays(step.days!, t.days)) {
      out.add(s.packFrequencyChange(t.days.length, step.days!.length));
    }
    return out;
  }

  String _fmt(double v) => v % 1 == 0 ? v.toStringAsFixed(0) : '$v';
  String _win(int m) => m < 60 ? '${m}m' : '${m ~/ 60}h${m % 60 == 0 ? '' : m % 60}';
  bool _sameDays(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final sa = [...a]..sort();
    final sb = [...b]..sort();
    for (var i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) return false;
    }
    return true;
  }
}
