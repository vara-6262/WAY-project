import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../fx/anchors.dart';
import '../fx/fx_controller.dart';
import '../fx/fx_overlays.dart';
import '../fx/reward_layer.dart';
import '../onboarding/onboarding_flow.dart';
import '../models/app_data.dart';
import '../state/providers.dart';
import '../theme/way_theme.dart';
import 'home_screen.dart';
import 'places_screen.dart';
import 'tasks_screen.dart';
import 'trend_screen.dart';

/// Permette al tutorial di cambiare schermata senza passare per il
/// contesto: le sue tappe vivono fuori dall'albero delle pagine.
final GlobalKey<ShellState> shellKey = GlobalKey<ShellState>();

/// Le quattro schermate in ordine di navigazione logica, scorribili con
/// swipe orizzontale o con la barra in basso.
class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});

  @override
  ConsumerState<Shell> createState() => ShellState();
}

class ShellState extends ConsumerState<Shell> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void goTo(int index, {bool animate = true}) {
    if (!_controller.hasClients) return;
    if (animate) {
      _controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _controller.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fx = ref.watch(fxProvider);

    // Riprogramma le notifiche a ogni cambio di stato (task/ambiente).
    ref.listen<AppData>(appProvider, (prev, next) {
      ref.read(notificationsProvider).scheduleFor(next);
    });

    return Scaffold(
      backgroundColor: c.canvas,
      body: Stack(
        key: fxAreaKey,
        children: [
          SafeArea(
            bottom: false,
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                HomeScreen(onOpenPlaces: () => goTo(2)),
                const TasksScreen(),
                const PlacesScreen(),
                const TrendScreen(),
              ],
            ),
          ),
          // Il tutorial sta sopra le schermate ma sotto il feedback: puo'
          // oscurare l'app, non la festa che l'app produce.
          const Positioned.fill(child: OnboardingOverlay()),
          Positioned.fill(child: RewardLayer(controller: fx)),
          AnimatedBuilder(
            animation: fx,
            builder: (_, __) => Stack(
              children: [
                RewardCardView(card: fx.card),
                IslandBanner(notification: fx.notification),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _TabBar(index: _index, onTap: goTo),
    );
  }
}

/// Barra flottante a pillola, come nel prototipo.
class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const items = <({IconData icon, String label})>[
    (icon: Icons.home_outlined, label: 'Home'),
    (icon: Icons.checklist_outlined, label: 'Tasks'),
    (icon: Icons.place_outlined, label: 'Places'),
    (icon: Icons.show_chart_outlined, label: 'Trend'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Container(
          height: 60,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: c.surface2,
            border: Border.all(color: c.line),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      key: i == 2 ? placesTabKey : null,
                      decoration: BoxDecoration(
                        color: i == index ? c.surface3 : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            items[i].icon,
                            size: 20,
                            color: i == index ? c.ink : c.inkFaint,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            items[i].label,
                            style: WayFonts.mono(
                              size: 8.5,
                              weight: FontWeight.w700,
                              color: i == index ? c.ink : c.inkFaint,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
