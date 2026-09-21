import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'way_colors.dart';

/// Due sole famiglie, come nel prototipo: Manrope per tutto il testo,
/// Space Mono per numeri ed etichette. `getFont` prende il nome come
/// stringa, cosi' il progetto compila con qualsiasi versione di
/// google_fonts e i font si possono sostituire con asset locali
/// cambiando solo queste due funzioni.
class WayFonts {
  const WayFonts._();

  static TextStyle ui({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.45,
    double letterSpacing = 0, TextDecoration? decoration,
  }) {
    return GoogleFonts.getFont(
      'Manrope',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Titoli: stesso carattere del testo, pesi alti e tracking negativo.
  static TextStyle display({
    double size = 22,
    FontWeight weight = FontWeight.w800,
    Color? color,
    double height = 1.1,
    double letterSpacing = -0.7,
  }) =>
      ui(
        size: size,
        weight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono({
    double size = 11,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.4,
    double letterSpacing = 0.5,
  }) {
    return GoogleFonts.getFont(
      'Space Mono',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Occhiello maiuscolo delle sezioni.
  static TextStyle label({double size = 10, Color? color}) =>
      mono(size: size, weight: FontWeight.w700, color: color, letterSpacing: 1.2);
}

class WayTheme {
  const WayTheme._();

  static ThemeData build([WayColors c = WayColors.dark]) {
    final scheme = ColorScheme.fromSeed(
      seedColor: c.accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: c.surface,
      primary: c.accent,
      onPrimary: c.accentInk,
      error: c.hard,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.canvas,
      splashFactory: InkRipple.splashFactory,
      extensions: <ThemeExtension<dynamic>>[c],
      textTheme: TextTheme(
        bodyMedium: WayFonts.ui(color: c.ink),
        bodySmall: WayFonts.ui(size: 12.5, color: c.inkSoft),
        titleMedium: WayFonts.display(size: 16, color: c.ink),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 6,
        activeTrackColor: c.accent,
        inactiveTrackColor: c.surface3,
        thumbColor: c.accent,
        overlayColor: c.accent.withOpacity(0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
    );
  }
}

/// Scorciatoia: `context.c.accent`.
extension WayThemeX on BuildContext {
  WayColors get c => Theme.of(this).extension<WayColors>()!;
}

/// Colore del testo su superficie piena (accento).
extension WayColorsX on WayColors {
  Color get onSolid => accentInk;
}
