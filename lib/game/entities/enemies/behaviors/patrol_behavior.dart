import 'dart:math';
import 'dart:ui';
import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/entities/enemies/behaviors/hearing_behavior.dart';
import 'package:echo_world/game/level/manager/level_manager.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

/// Behavior de patrulla por waypoints para el estado ATORMENTADO.
/// Elige un punto aleatorio cercano y lo asigna como target al HearingBehavior.
class PatrolBehavior extends Behavior<PositionedEntity> {
  PatrolBehavior({this.waitTime = 2.0, this.patrolRadius = 5});

  final double waitTime; // Tiempo de espera al llegar al destino
  final int patrolRadius; // Radio en tiles para buscar nuevo punto
  double _timer = 0;
  final Random _random = Random();

  @override
  void update(double dt) {
    final hearing = parent.findBehavior<HearingBehavior>();

    // Solo patrullar si está en estado ATORMENTADO
    if (hearing.estadoActual != AIState.atormentado) {
      hearing.patrolTarget = null; // Limpiar target si cambia de estado
      return;
    }

    // Si ya tiene target, verificar si llegó
    if (hearing.patrolTarget != null) {
      if (parent.position.distanceTo(hearing.patrolTarget!) < 8) {
        // Llegó al destino (o muy cerca), esperar
        _timer += dt;
        if (_timer >= waitTime) {
          hearing.patrolTarget = null; // Limpiar para buscar nuevo
          _timer = 0;
        }
      }
      // Si no ha llegado, AIMovementBehavior se encarga de moverlo
      return;
    }

    // Buscar nuevo target inmediatamente
    _pickNewTarget(hearing);
  }

  void _pickNewTarget(HearingBehavior hearing) {
    final game = parent.findParent<BlackEchoGame>();
    if (game == null) return;

    final tileSize = LevelManagerComponent.tileSize;
    final currentTileX = (parent.position.x / tileSize).floor();
    final currentTileY = (parent.position.y / tileSize).floor();

    // Intentar encontrar un tile válido (hasta 10 intentos)
    for (int i = 0; i < 10; i++) {
      final dx = _random.nextInt(patrolRadius * 2 + 1) - patrolRadius;
      final dy = _random.nextInt(patrolRadius * 2 + 1) - patrolRadius;

      // Evitar el mismo tile
      if (dx == 0 && dy == 0) continue;

      final targetX = currentTileX + dx;
      final targetY = currentTileY + dy;

      // Verificar límites y si es transitable
      final rect = Rect.fromLTWH(
        targetX * tileSize,
        targetY * tileSize,
        tileSize,
        tileSize,
      );

      if (game.levelManager.isRectWalkable(rect)) {
        // Asignar centro del tile como target
        hearing.patrolTarget = Vector2(
          (targetX * tileSize) + (tileSize / 2),
          (targetY * tileSize) + (tileSize / 2),
        );
        return;
      }
    }
  }

  void reset() {
    _timer = 0;
    final hearing = parent.findBehavior<HearingBehavior>();
    hearing.patrolTarget = null;
  }
}
