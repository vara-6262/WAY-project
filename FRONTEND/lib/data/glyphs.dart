import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

const Map<String, IconData> taskIcons = {
  'book': Symbols.menu_book,
  'paper': Symbols.description,
  'dumbbell': Symbols.fitness_center,
  'alarm': Symbols.alarm,
  'people': Symbols.groups,
  'leaf': Symbols.eco,
  'drop': Symbols.water_drop,
  'pen': Symbols.edit,
  'code': Symbols.code,
  'music': Symbols.music_note,
  'target': Symbols.adjust,
  'heart': Symbols.favorite,
  'camera': Symbols.photo_camera,
  'moon': Symbols.dark_mode,

  // Studio
  'school': Symbols.school,
  'calculator': Symbols.calculate,
  'computer': Symbols.computer,
  'work': Symbols.work,
  'folder': Symbols.folder,
  'assignment': Symbols.assignment,

  // Sport
  'run': Symbols.directions_run,
  'walk': Symbols.directions_walk,
  'bike': Symbols.directions_bike,
  'pool': Symbols.pool,
  'stretch': Symbols.self_improvement,

  // Routine
  'clock': Symbols.schedule,
  'calendar': Symbols.calendar_month,
  'timer': Symbols.timer,
  'check': Symbols.check_circle,
  'repeat': Symbols.repeat,
  'sleep': Symbols.bedtime,
  'sun': Symbols.light_mode,

  // Vita quotidiana
  'home': Symbols.home,
  'person': Symbols.person,
  'phone': Symbols.smartphone,
  'message': Symbols.chat,
  'shopping': Symbols.shopping_cart,
  'food': Symbols.restaurant,
  'coffee': Symbols.local_cafe,
  'clean': Symbols.cleaning_services,

  // Hobby
  'guitar': Symbols.music_note,
  'camera_alt': Symbols.photo_camera,
  'art': Symbols.palette,
  'game': Symbols.sports_esports,
  'movie': Symbols.movie,
  'mic': Symbols.mic,

  // Obiettivi
  'star': Symbols.star,
  'flag': Symbols.flag,
  'trophy': Symbols.emoji_events,
  'rocket': Symbols.rocket_launch,
  'bolt': Symbols.bolt,
  'fire': Symbols.local_fire_department,
  'diamond': Symbols.diamond,

  // Tecnologia
  'wifi': Symbols.wifi,
  'cloud': Symbols.cloud,
  'lock': Symbols.lock,
  'settings': Symbols.settings,

  // Viaggi
  'plane': Symbols.flight,
  'train': Symbols.train,
  'car': Symbols.directions_car,
  'bus': Symbols.directions_bus,

  // User-defined
  'teeth': Symbols.dentistry,
  'order': Symbols.deployed_code,
  'shower': Symbols.shower,
  'morning_cleaning': Symbols.bathtub_rounded,
  'smoke': Symbols.smoke_free,
  'turbo':Symbols.eighteen_up_rating_rounded,
  

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