import 'package:flutter/material.dart';

/// Punti di aggancio condivisi fra schermate, feedback e tutorial.
/// Stanno in un file loro per non incatenare fra loro i moduli che li usano.

/// L'area che ospita schermate e feedback: serve a convertire la posizione
/// di un widget in coordinate dello strato dei coriandoli.
final GlobalKey fxAreaKey = GlobalKey();

/// Bersagli del riflettore del primo utilizzo.
final GlobalKey taskCreateKey = GlobalKey();
final GlobalKey coreHubKey = GlobalKey();
final GlobalKey placesTabKey = GlobalKey();
final GlobalKey placeCreateKey = GlobalKey();

/// L'anello della Home: origine dei coriandoli del target giornaliero.
final GlobalKey ringKey = GlobalKey();

/// Centro di un widget in coordinate dello strato del feedback.
Offset? anchorOf(GlobalKey key) {
  final box = key.currentContext?.findRenderObject() as RenderBox?;
  final area = fxAreaKey.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || area == null || !box.hasSize || !area.hasSize) return null;
  final global = box.localToGlobal(box.size.center(Offset.zero));
  return area.globalToLocal(global);
}

/// Rettangolo di un widget in coordinate dello strato del feedback.
Rect? rectOf(GlobalKey key) {
  final box = key.currentContext?.findRenderObject() as RenderBox?;
  final area = fxAreaKey.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || area == null || !box.hasSize || !area.hasSize) return null;
  final topLeft = area.globalToLocal(box.localToGlobal(Offset.zero));
  return topLeft & box.size;
}

/// Una chiave per ogni riga di esecuzione: serve a far partire i
/// coriandoli dal punto esatto in cui l'utente ha toccato.
final Map<String, GlobalKey> _taskAnchors = {};

GlobalKey taskAnchorKey(String taskId) =>
    _taskAnchors.putIfAbsent(taskId, () => GlobalKey());
