import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/dates.dart';
import '../l10n/strings.dart';
import '../models/app_data.dart';
import '../models/sabus_scoring.dart';
import '../state/providers.dart';
import '../theme/way_colors.dart';
import '../theme/way_theme.dart';
import '../widgets/common.dart';

const _appVersion = '0.2.0';
const _kNameKey = 'way.profile.name';
const _kDebugKey = 'way.debug.unlocked';

/// Schermata Account: profilo locale (offline), spazio per l'account remoto
/// (in arrivo col server), aspetto, lingua, backup, e strumenti sviluppatore
/// nascosti dietro 7 tap sulla versione.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  int _taps = 0;
  bool _debug = false;
  late String _name;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(prefsProvider);
    _debug = prefs.getBool(_kDebugKey) ?? false;
    _name = prefs.getString(_kNameKey) ?? 'Manuel';
  }

  void _onVersionTap() {
    if (_debug) return;
    setState(() => _taps++);
    if (_taps >= 7) {
      ref.read(prefsProvider).setBool(_kDebugKey, true);
      setState(() {
        _debug = true;
        _taps = 0;
      });
      showToast(context, context.s.devUnlocked);
    } else if (_taps >= 4) {
      showToast(context, context.s.devMissing(7 - _taps));
    }
  }

  void _hideDebug() {
    ref.read(prefsProvider).setBool(_kDebugKey, false);
    setState(() => _debug = false);
    showToast(context, context.s.devHidden);
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _name);
    final c = context.c;
    final s = context.s;
    final newName = await showDialog<String>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: c.surface2,
        title: Text(s.yourName, style: WayFonts.display(size: 16, color: c.ink)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: WayFonts.ui(size: 14.5, color: c.ink),
          decoration: fieldDecoration(dctx, s.whatsYourName),
          onSubmitted: (v) => Navigator.of(dctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(),
            child: Text(s.cancel, style: WayFonts.ui(size: 13, color: c.inkFaint)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(ctrl.text.trim()),
            child: Text(s.save, style: WayFonts.ui(size: 13, color: c.accent)),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      ref.read(prefsProvider).setString(_kNameKey, newName);
      setState(() => _name = newName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final s = context.s;
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 18, 6),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Icon(Icons.chevron_left, color: c.inkSoft),
                ),
                const SizedBox(width: 6),
                Text(s.account, style: WayFonts.display(size: 20, color: c.ink)),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  _header(c, s),
                  const SizedBox(height: 20),
                  _accountCard(c, s),
                  const SizedBox(height: 22),
                  SectionLabel(s.appearance),
                  const SizedBox(height: 10),
                  _themeRow(c),
                  const SizedBox(height: 22),
                  SectionLabel(s.language),
                  const SizedBox(height: 10),
                  Segmented<AppLang>(
                    values: AppLang.values,
                    labels: const ['Italiano', 'English'],
                    selected: ref.watch(localeProvider),
                    onChanged: (l) => ref.read(localeProvider.notifier).set(l),
                  ),
                  const SizedBox(height: 22),
                  SectionLabel(s.backupAndData),
                  const SizedBox(height: 10),
                  _backupButtons(c, s),
                  if (_debug) ...[
                    const SizedBox(height: 24),
                    SectionLabel(s.developer),
                    const SizedBox(height: 10),
                    _debugTools(c, s),
                  ],
                  const SizedBox(height: 26),
                  Center(
                    child: GestureDetector(
                      onTap: _onVersionTap,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('WAY $_appVersion',
                            style: WayFonts.mono(size: 10, color: c.inkFaint)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(WayColors c, S s) {
    final initial = _name.isEmpty ? '?' : _name.substring(0, 1).toUpperCase();
    return Row(children: [
      Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surface2,
          shape: BoxShape.circle,
          border: Border.all(color: c.line),
        ),
        child: Text(initial, style: WayFonts.display(size: 18, color: c.ink)),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_name, style: WayFonts.display(size: 19, color: c.ink)),
            Text(s.localProfile,
                style: WayFonts.ui(size: 12.5, color: c.inkSoft)),
          ],
        ),
      ),
      GestureDetector(
        onTap: _editName,
        child: Icon(Icons.edit_outlined, size: 18, color: c.inkFaint),
      ),
    ]);
  }

  Widget _accountCard(WayColors c, S s) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.lineSoft),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(Icons.cloud_outlined, size: 22, color: c.inkFaint),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.signInUp,
                  style: WayFonts.ui(
                      size: 14, weight: FontWeight.w700, color: c.inkSoft)),
              const SizedBox(height: 2),
              Text(s.syncSoon, style: WayFonts.ui(size: 11.5, color: c.inkFaint)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: c.surface3,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(s.soon, style: WayFonts.mono(size: 9, color: c.inkFaint)),
        ),
      ]),
    );
  }

  Widget _themeRow(WayColors c) {
    return Row(children: [
      for (final preset in WayColors.presets)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ref.read(themeProvider.notifier).setId(preset.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: preset.$3.surface2,
                  border: Border.all(
                    color: identical(preset.$3, ref.watch(themeProvider))
                        ? preset.$3.accent
                        : c.line,
                    width: identical(preset.$3, ref.watch(themeProvider)) ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                        color: preset.$3.accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(height: 6),
                  Text(preset.$2,
                      style: WayFonts.mono(
                          size: 9.5,
                          weight: FontWeight.w700,
                          color: c.inkSoft)),
                ]),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _backupButtons(WayColors c, S s) {
    return Column(children: [
      GhostButton(
        label: s.shareBackup,
        onPressed: () async {
          try {
            final json = ref.read(appProvider.notifier).exportState();
            final dir = await getTemporaryDirectory();
            final f = File('${dir.path}/way_backup.json');
            await f.writeAsString(json);
            await Share.shareXFiles([XFile(f.path)], subject: 'Backup WAY');
          } catch (_) {
            if (mounted) showToast(context, context.s.shareFailed);
          }
        },
      ),
      const SizedBox(height: 8),
      GhostButton(
        label: s.importBackup,
        onPressed: () async {
          final d = await Clipboard.getData('text/plain');
          final ok = d?.text != null &&
              ref.read(appProvider.notifier).importState(d!.text!);
          if (!mounted) return;
          showToast(
              context, ok ? context.s.backupRestored : context.s.backupInvalid);
        },
      ),
    ]);
  }

  Widget _debugTools(WayColors c, S s) {
    final mode = ref.watch(modeProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(s.prototypeMode, style: WayFonts.label(color: c.inkFaint, size: 9.5)),
      const SizedBox(height: 8),
      Segmented<PrototypeMode>(
        values: PrototypeMode.values,
        labels: [s.modeProxy, s.modeFromZero],
        selected: mode,
        onChanged: (m) => ref.read(modeProvider.notifier).set(m),
      ),
      const SizedBox(height: 14),
      GhostButton(
        label: s.sendTestNotif,
        onPressed: () async {
          await ref.read(notificationsProvider).sendTest();
          if (mounted) showToast(context, context.s.testNotifSent);
        },
      ),
      const SizedBox(height: 8),
      GhostButton(
        label: s.rescheduleReminders,
        onPressed: () async {
          final n = ref.read(notificationsProvider);
          await n.scheduleFor(ref.read(appProvider));
          final count = await n.pendingCount();
          if (mounted) showToast(context, context.s.remindersScheduled(count));
        },
      ),
      const SizedBox(height: 8),
      GhostButton(
        label: s.notifIn1Min,
        onPressed: () async {
          final n = ref.read(notificationsProvider);
          if (!await n.canExact()) await n.requestExact();
          final diag = await n.sendDelayedTest();
          if (!mounted) return;
          showDialog<void>(
            context: context,
            builder: (dctx) => AlertDialog(
              title: Text(context.s.scheduledNotifTest),
              content: Text(diag),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dctx).pop(),
                    child: Text(context.s.ok)),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 8),
      GhostButton(
        label: s.exportBackupClipboard,
        onPressed: () async {
          await Clipboard.setData(
              ClipboardData(text: ref.read(appProvider.notifier).exportState()));
          if (mounted) showToast(context, context.s.backupCopied);
        },
      ),
      const SizedBox(height: 8),
      GhostButton(
        label: s.bonusReport,
        onPressed: () {
          final report = ref.read(appProvider).bonusReport(Dates.today());
          showDialog<void>(
            context: context,
            builder: (dctx) => AlertDialog(
              title: Text(context.s.bonusComposition),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: SelectableText(report,
                      style: WayFonts.mono(size: 11, color: c.ink)),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dctx).pop(),
                    child: Text(context.s.ok)),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 14),
      GhostButton(
        label: s.resetThisMode,
        foreground: c.hard,
        onPressed: () {
          ref.read(appProvider.notifier).resetCurrentMode();
          if (mounted) showToast(context, context.s.archiveReset);
        },
      ),
      const SizedBox(height: 8),
      GhostButton(label: s.hideDevTools, onPressed: _hideDebug),
    ]);
  }
}
