import 'package:flutter/material.dart';
import '../theme/way_theme.dart';
import '../widgets/common.dart';

/// Guscio comune ai due wizard: stessa intestazione, stessa barra di passo,
/// stesso piede. Cambia solo il corpo.
class WizardScaffold extends StatelessWidget {
  const WizardScaffold({
    super.key,
    required this.stepIndex,
    required this.stepCount,
    required this.title,
    required this.subtitle,
    required this.body,
    this.nextLabel,
    required this.onNext,
    this.onBack,
  })  : assert(stepCount > 0, 'stepCount deve essere maggiore di 0'),
        assert(
          stepIndex >= 0 && stepIndex < stepCount,
          'stepIndex deve essere compreso tra 0 e stepCount - 1',
        );

  final int stepIndex;
  final int stepCount;
  final String title;
  final String subtitle;
  final Widget body;

  /// Null quando l'azione sta nelle card di scelta: in quelle pagine un
  /// pulsante primario sarebbe un doppione.
  final String? nextLabel;

  /// Null disabilita il pulsante: il passo non e' ancora valido.
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // Prevenzione di divisione per zero o overflow visivi
    final safeStepCount = stepCount < 1 ? 1 : stepCount;
    final safeStepIndex = stepIndex.clamp(0, safeStepCount - 1);

    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra di avanzamento sempre visibile
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            for (var i = 0; i < safeStepCount; i++) ...[
                              if (i > 0) const SizedBox(width: 4),
                              Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 260),
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: i < safeStepIndex
                                        ? c.accent.withValues(alpha: 0.45)
                                        : (i == safeStepIndex
                                            ? c.accent
                                            : c.surface3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text.rich(
                        TextSpan(
                          text: '${safeStepIndex + 1}',
                          style: WayFonts.mono(
                            size: 10,
                            weight: FontWeight.w700,
                            color: c.ink,
                          ),
                          children: [
                            TextSpan(
                              text: '/$safeStepCount',
                              style: WayFonts.mono(
                                size: 10,
                                color: c.inkFaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Text(
                          'Annulla',
                          style: WayFonts.ui(
                            size: 12,
                            weight: FontWeight.w700,
                            color: c.inkFaint,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(title, style: WayFonts.display(size: 21, color: c.ink)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      style: WayFonts.ui(size: 12.5, color: c.inkSoft),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: body,
              ),
            ),
            if (nextLabel != null || onBack != null)
              Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border(top: BorderSide(color: c.lineSoft)),
                ),
                child: Row(
                  children: [
                    if (onBack != null) ...[
                      _BackButton(onTap: onBack!),
                      const SizedBox(width: 9),
                    ],
                    if (nextLabel != null)
                      Expanded(
                        child: PrimaryButton(
                          label: nextLabel!,
                          onPressed: onNext,
                        ),
                      )
                    else
                      const Spacer(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.surface2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.chevron_left, color: c.inkSoft),
        ),
      ),
    );
  }
}

/// Campo di testo con l'etichetta mono sopra, usato in tutti i wizard.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.multiline = false,
    this.keyboardType,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final bool multiline;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: WayFonts.label(color: c.inkFaint, size: 9.5),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          maxLines: multiline ? 4 : 1,
          minLines: multiline ? 3 : 1,
          textCapitalization: TextCapitalization.sentences,
          style: WayFonts.ui(size: multiline ? 13.5 : 14.5, color: c.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: WayFonts.ui(
              size: multiline ? 13.5 : 14.5,
              color: c.inkFaint,
            ),
            filled: true,
            fillColor: c.surface2,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.accent),
            ),
          ),
        ),
      ],
    );
  }
}

/// Griglia di icone a sei colonne.
class IconPicker extends StatelessWidget {
  const IconPicker({
    super.key,
    required this.icons,
    required this.selected,
    required this.onSelect,
  });

  final Map<String, IconData> icons;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final entries = icons.entries.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 7,
        crossAxisSpacing: 7,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) {
        final entry = entries[i];
        final on = entry.key == selected;
        return GestureDetector(
          onTap: () => onSelect(entry.key),
          child: Container(
            decoration: BoxDecoration(
              color: on ? c.accent : c.surface2,
              border: Border.all(color: on ? c.accent : c.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              entry.value,
              size: 20,
              color: on ? c.accentInk : c.inkSoft,
            ),
          ),
        );
      },
    );
  }
}

/// Modello per ciascuna opzione di [BigSwitch].
class BigSwitchOption<T> {
  const BigSwitchOption({
    required this.value,
    required this.title,
    required this.caption,
  });

  final T value;
  final String title;
  final String caption;
}

/// Interruttore a scelte multiple con titolo e riga di spiegazione.
class BigSwitch<T> extends StatelessWidget {
  const BigSwitch({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  }) : assert(options.length > 0, 'BigSwitch richiede almeno un\'opzione');

  final List<BigSwitchOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(options[i].value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: options[i].value == selected
                        ? c.accent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Column(
                    children: [
                      Text(
                        options[i].title,
                        textAlign: TextAlign.center,
                        style: WayFonts.ui(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: options[i].value == selected
                              ? c.accentInk
                              : c.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        options[i].caption,
                        textAlign: TextAlign.center,
                        style: WayFonts.ui(
                          size: 10.5,
                          height: 1.3,
                          color: options[i].value == selected
                              ? c.accentInk.withValues(alpha: 0.74)
                              : c.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
/// Nota esplicativa con il filetto laterale.
class ExplainBox extends StatelessWidget {
  const ExplainBox(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.surface2,
        border: Border(left: BorderSide(color: c.accentSoft, width: 2)),
        borderRadius:
            const BorderRadius.horizontal(right: Radius.circular(10)),
      ),
      child: Text(text, style: WayFonts.ui(size: 12, color: c.inkSoft)),
    );
  }
}