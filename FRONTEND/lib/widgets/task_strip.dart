import 'package:flutter/material.dart';

import '../data/glyphs.dart';
import '../models/models.dart';
import '../theme/way_theme.dart';
import 'common.dart';

/// Mini-card a striscia: icona, nome, livello, costanza verso il livello
/// successivo e badge di difficolta'. E' la stessa in lista e sotto il dito
/// mentre la si trascina.
class TaskStrip extends StatelessWidget {
  const TaskStrip({
    super.key,
    required this.task,
    this.inCore = false,
    this.onTap,
    this.elevated = false,
    this.faded = false,
  });

  final Task task;
  final bool inCore;
  final VoidCallback? onTap;

  /// Vero mentre la striscia e' sollevata dal drag.
  final bool elevated;

  /// Vero per il posto lasciato vuoto in lista durante il drag.
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final colors = difficultyColors(context, task.difficulty);
    final progress = task.levelProgress;

    final content = Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: elevated ? c.accentSoft : c.line),
        borderRadius: BorderRadius.circular(16),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: c.ink.withOpacity(0.22),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 3, color: colors.fg),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 11, 13, 11),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(taskIcon(task.iconKey), size: 20, color: colors.fg),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    task.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: WayFonts.ui(
                                      size: 14,
                                      weight: FontWeight.w600,
                                      color: c.ink,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                if (inCore) ...[
                                  const SizedBox(width: 6),
                                  Icon(Icons.auto_awesome, size: 13, color: c.accent),
                                ],
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.bg,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    'LV${task.level}',
                                    style: WayFonts.mono(
                                      size: 9.5,
                                      weight: FontWeight.w600,
                                      color: colors.fg,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 4,
                                      backgroundColor: c.surface3,
                                      valueColor: AlwaysStoppedAnimation(colors.fg),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  '${(progress * 100).round()}%',
                                  style: WayFonts.mono(size: 11, color: c.inkFaint),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      DifficultyPill(task.difficulty),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final wrapped = faded ? Opacity(opacity: 0.25, child: content) : content;

    if (onTap == null) return wrapped;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: wrapped,
    );
  }
}
