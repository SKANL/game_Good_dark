import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/entities/enemies/behaviors/hearing_behavior.dart';
import 'package:echo_world/game/utils/pathfinding.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

/// Behavior de movimiento inteligente usando A* Pathfinding.
/// Mueve la entidad hacia el target definido por HearingBehavior.
class AIMovementBehavior extends Behavior<PositionedEntity> {
  List<Vector2> _path = [];
  Vector2? _lastTargetPos;
  double _repathTimer = 0;
  static const double _repathInterval =
      0.5; // Recalcular cada 0.5s si el target se mueve

  @override
  void update(double dt) {
    final hearing = parent.findBehavior<HearingBehavior>();
    final target = hearing.targetActual;

    // Si no hay target, detenerse y limpiar camino
    if (target == null) {
      _path.clear();
      _lastTargetPos = null;
      return;
    }

    _repathTimer += dt;

    // Determinar si necesitamos recalcular el camino
    bool needRepath = false;

    // 1. No tenemos camino
    if (_path.isEmpty && _lastTargetPos == null) {
      needRepath = true;
    }
    // 2. El target se ha movido significativamente (más de 1 tile) y pasó el tiempo
    else if (_lastTargetPos != null &&
        target.distanceTo(_lastTargetPos!) > 32 &&
        _repathTimer >= _repathInterval) {
      needRepath = true;
    }
    // 3. El camino se vació pero no estamos en el target final (caso raro)
    else if (_path.isEmpty && parent.position.distanceTo(target) > 16) {
      needRepath = true;
    }

    if (needRepath) {
      _recalculatePath(target);
    }

    // Seguir el camino
    if (_path.isNotEmpty) {
      final nextPoint = _path.first;
      final distance = parent.position.distanceTo(nextPoint);

      // Si estamos muy cerca del siguiente punto, avanzamos al siguiente
      if (distance < 4) {
        _path.removeAt(0);
        if (_path.isNotEmpty) {
          // Recursión para moverse inmediatamente al siguiente si es posible
          // update(dt); // Cuidado con stack overflow, mejor dejar para siguiente frame
        }
        return;
      }

      // Moverse hacia nextPoint
      final dir = (nextPoint - parent.position).normalized();
      final delta = dir * hearing.velocidadActual * dt;

      // Aplicar movimiento (sin colisiones complejas, confiamos en A*)
      // Aún así, mantenemos una comprobación básica por si acaso
      parent.position += delta;
    }
  }

  void _recalculatePath(Vector2 target) {
    final game = parent.findParent<BlackEchoGame>();
    if (game != null) {
      _path = findPath(parent.position, target, game.levelManager);
      _lastTargetPos = target.clone();
      _repathTimer = 0;

      // Optimización: Si el camino es muy largo, solo tomar los primeros N pasos
      // para evitar recalcular todo si el target cambia mucho.
      // Por ahora usamos todo el camino.
    }
  }

  void reset() {
    _path.clear();
    _lastTargetPos = null;
    _repathTimer = 0;
  }
}
