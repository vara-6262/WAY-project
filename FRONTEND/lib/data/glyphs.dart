import 'package02:flutter/material.dart';

/// Icone delle task. La chiave finisce nel JSON, l'icona no: così si può
/// cambiare set grafico senza migrare i dati salvati.
const Map<String, IconData> taskIcons = {
  // STUDIO & LAVORO
  'book': Icons.menu_book_outlined,
  'paper': Icons.description_outlined,
  'pen': Icons.edit_outlined,
  'code': Icons.code,
  'target': Icons.adjust_outlined,
  'laptop': Icons.laptop_outlined,
  'briefcase': Icons.work_outline,
  'school': Icons.school_outlined,
  'calculator': Icons.calculate_outlined,
  'brain': Icons.psychology_outlined,
  'lightbulb': Icons.lightbulb_outline,
  'archive': Icons.inventory_2_outlined,

  // SALUTE & FITNESS
  'dumbbell': Icons.fitness_center_outlined,
  'heart': Icons.favorite_border,
  'drop': Icons.water_drop_outlined,
  'runner': Icons.directions_run_outlined,
  'bike': Icons.directions_bike_outlined,
  'apple': Icons.nutrition_outlined, // In alternativa: Icons.restaurant_outlined
  'bed': Icons.bed_outlined,
  'meditation': Icons.self_improvement,
  'pool': Icons.pool_outlined,

  // TEMPO LIBERO & CREATIVITÀ
  'music': Icons.music_note_outlined,
  'camera': Icons.photo_camera_outlined,
  'palette': Icons.palette_outlined,
  'gamepad': Icons.sports_esports_outlined,
  'movie': Icons.movie_creation_outlined,
  'mic': Icons.mic_none_outlined,
  'headset': Icons.headset_mic_outlined,

  // ROUTINE & CASA
  'alarm': Icons.alarm_outlined,
  'people': Icons.people_alt_outlined,
  'leaf': Icons.eco_outlined,
  'moon': Icons.dark_mode_outlined,
  'sun': Icons.wb_sunny_outlined,
  'cart': Icons.shopping_cart_outlined,
  'broom': Icons.cleaning_services_outlined,
  'utensils': Icons.restaurant_outlined,
  'pill': Icons.medication_outlined,
  'wallet': Icons.account_balance_wallet_outlined,
  'check': Icons.check_circle_outline,
  'star': Icons.star_border,
};

/// Segni degli ambienti: usati per distinguere i vari contesti di utilizzo.
const Map<String, IconData> placeGlyphs = {
  'building': Icons.apartment_outlined,
  'home': Icons.home_outlined,
  'plane': Icons.flight_outlined,
  'tent': Icons.cabin_outlined,
  'coffee': Icons.local_cafe_outlined,
  'pin': Icons.place_outlined,
  'school': Icons.school_outlined,
  'park': Icons.park_outlined,
  'store': Icons.storefront_outlined,
  'car': Icons.directions_car_outlined,
  'train': Icons.train_outlined,
  'library': Icons.local_library_outlined,
};

IconData taskIcon(String key) => taskIcons[key] ?? Icons.circle_outlined;

IconData placeGlyph(String key) => placeGlyphs[key] ?? Icons.place_outlined;