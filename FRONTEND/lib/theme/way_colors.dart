import 'package:flutter/material.dart';

/// Palette WAY: lime su nero caldo. Unica sorgente dei colori dell'app,
/// agganciata al ThemeData come extension.
@immutable
class WayColors extends ThemeExtension<WayColors> {
  const WayColors({
    required this.canvas,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.line,
    required this.lineSoft,
    required this.accent,
    required this.accentInk,
    required this.accentTint,
    required this.accentSoft,
    required this.easy,
    required this.easyTint,
    required this.media,
    required this.mediaTint,
    required this.hard,
    required this.hardTint,
    required this.advice,
  });

  final Color canvas;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color line;
  final Color lineSoft;
  final Color accent;
  final Color accentInk;
  final Color accentTint;
  final Color accentSoft;

  /// Difficolta': verde facile, viola media, rosso difficile.
  final Color easy;
  final Color easyTint;
  final Color media;
  final Color mediaTint;
  final Color hard;
  final Color hardTint;

  /// Colore dei suggerimenti e degli occhielli del tutorial.
  final Color advice;

  static const dark = WayColors(
    canvas: Color(0xFF0B0A08),
    surface: Color(0xFF121009),
    surface2: Color(0xFF17150F),
    surface3: Color(0xFF2C2820),
    ink: Color(0xFFF6F2E8),
    inkSoft: Color(0xFFD9D2C2),
    inkFaint: Color(0xFFA79C87),
    line: Color(0xFF332E22),
    lineSoft: Color(0xFF231F17),
    accent: Color(0xFFCFFF5C),
    accentInk: Color(0xFF17210A),
    accentTint: Color(0xFF263014),
    accentSoft: Color(0xFF8FAE3E),
    easy: Color(0xFF72D6A0),
    easyTint: Color(0xFF132B21),
    media: Color(0xFF8484FF),
    mediaTint: Color(0xFF1D1D3C),
    hard: Color(0xFFFF5A36),
    hardTint: Color(0xFF351811),
    advice: Color(0xFF9296FF),
  );

  @override
  WayColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? ink,
    Color? inkSoft,
    Color? inkFaint,
    Color? line,
    Color? lineSoft,
    Color? accent,
    Color? accentInk,
    Color? accentTint,
    Color? accentSoft,
    Color? easy,
    Color? easyTint,
    Color? media,
    Color? mediaTint,
    Color? hard,
    Color? hardTint,
    Color? advice,
  }) {
    return WayColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkFaint: inkFaint ?? this.inkFaint,
      line: line ?? this.line,
      lineSoft: lineSoft ?? this.lineSoft,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentTint: accentTint ?? this.accentTint,
      accentSoft: accentSoft ?? this.accentSoft,
      easy: easy ?? this.easy,
      easyTint: easyTint ?? this.easyTint,
      media: media ?? this.media,
      mediaTint: mediaTint ?? this.mediaTint,
      hard: hard ?? this.hard,
      hardTint: hardTint ?? this.hardTint,
      advice: advice ?? this.advice,
    );
  }

  @override
  WayColors lerp(ThemeExtension<WayColors>? other, double t) {
    if (other is! WayColors) return this;
    Color m(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return WayColors(
      canvas: m(canvas, other.canvas),
      surface: m(surface, other.surface),
      surface2: m(surface2, other.surface2),
      surface3: m(surface3, other.surface3),
      ink: m(ink, other.ink),
      inkSoft: m(inkSoft, other.inkSoft),
      inkFaint: m(inkFaint, other.inkFaint),
      line: m(line, other.line),
      lineSoft: m(lineSoft, other.lineSoft),
      accent: m(accent, other.accent),
      accentInk: m(accentInk, other.accentInk),
      accentTint: m(accentTint, other.accentTint),
      accentSoft: m(accentSoft, other.accentSoft),
      easy: m(easy, other.easy),
      easyTint: m(easyTint, other.easyTint),
      media: m(media, other.media),
      mediaTint: m(mediaTint, other.mediaTint),
      hard: m(hard, other.hard),
      hardTint: m(hardTint, other.hardTint),
      advice: m(advice, other.advice),
    );
  }

  // ---- Palette alternative (coerenti: cambia la famiglia dell'accento) ----
  static const indigo = WayColors(
    canvas: Color(0xFF0B0A08), surface: Color(0xFF121009), surface2: Color(0xFF17150F),
    surface3: Color(0xFF2C2820), ink: Color(0xFFF6F2E8), inkSoft: Color(0xFFD9D2C2),
    inkFaint: Color(0xFFA79C87), line: Color(0xFF332E22), lineSoft: Color(0xFF231F17),
    accent: Color(0xFF8FA0FF), accentInk: Color(0xFF0A0E28), accentTint: Color(0xFF1A2050),
    accentSoft: Color(0xFF6070C8),
    easy: Color(0xFF72D6A0), easyTint: Color(0xFF132B21), media: Color(0xFF8484FF),
    mediaTint: Color(0xFF1D1D3C), hard: Color(0xFFFF5A36), hardTint: Color(0xFF351811),
    advice: Color(0xFF9296FF),
  );

  static const ember = WayColors(
    canvas: Color(0xFF0B0A08), surface: Color(0xFF121009), surface2: Color(0xFF17150F),
    surface3: Color(0xFF2C2820), ink: Color(0xFFF6F2E8), inkSoft: Color(0xFFD9D2C2),
    inkFaint: Color(0xFFA79C87), line: Color(0xFF332E22), lineSoft: Color(0xFF231F17),
    accent: Color(0xFFFFB454), accentInk: Color(0xFF2A1705), accentTint: Color(0xFF3A2610),
    accentSoft: Color(0xFFB88540),
    easy: Color(0xFF72D6A0), easyTint: Color(0xFF132B21), media: Color(0xFF8484FF),
    mediaTint: Color(0xFF1D1D3C), hard: Color(0xFFFF5A36), hardTint: Color(0xFF351811),
    advice: Color(0xFFFFC98A),
  );

  /// Temi disponibili: (id, etichetta, palette).
  static const List<(String, String, WayColors)> presets = [
    ('lime', 'Lime', dark),
    ('indaco', 'Indaco', indigo),
    ('brace', 'Brace', ember),
  ];

  static WayColors byId(String id) {
    for (final p in presets) {
      if (p.$1 == id) return p.$3;
    }
    return dark;
  }
}
