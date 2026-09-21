import 'package:flutter/material.dart';

/// Icone delle task. La chiave finisce nel JSON, l'icona no: cosi' si puo'
/// cambiare set grafico senza migrare i dati salvati.
const Map<String, IconData> taskIcons = {
  'book': Icons.menu_book_outlined,
  'paper': Icons.description_outlined,
  'dumbbell': Icons.fitness_center_outlined,
  'alarm': Icons.alarm_outlined,
  'people': Icons.people_alt_outlined,
  'leaf': Icons.eco_outlined,
  'drop': Icons.water_drop_outlined,
  'pen': Icons.edit_outlined,
  'code': Icons.code,
  'music': Icons.music_note_outlined,
  'target': Icons.adjust_outlined,
  'heart': Icons.favorite_border,
  'camera': Icons.photo_camera_outlined,
  'moon': Icons.dark_mode_outlined,
};

/// Segni degli ambienti: volutamente diversi da quelli delle task.
const Map<String, IconData> placeGlyphs = {
  'building': Icons.apartment_outlined,
  'home': Icons.home_outlined,
  'plane': Icons.flight_outlined,
  'tent': Icons.cabin_outlined,
  'coffee': Icons.local_cafe_outlined,
  'pin': Icons.place_outlined,
};

IconData taskIcon(String key) => taskIcons[key] ?? Icons.circle_outlined;

IconData placeGlyph(String key) => placeGlyphs[key] ?? Icons.place_outlined;
