import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/components/world/wall_component.dart';
import 'package:echo_world/game/entities/enemies/behaviors/hearing_behavior.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

/// Behavior que permite a ciertos enemigos (como Bruto) destruir paredes débiles
/// cuando están en estado de CAZA.
class DestructionBehavior extends Behavior<PositionedEntity>
    with HasGameRef<BlackEchoGame> {
  DestructionBehavior();

  /// Tiempo mínimo entre destrucciones de pared (cooldown)
  static const double _destructionCooldown = 1;
  double _timeSinceLastDestruction = 0;

  @override
  void update(double dt) {
    super.update(dt);

    _timeSinceLastDestruction += dt;

    // Solo intentar destruir paredes si:
    // 1. El enemigo tiene HearingBehavior en estado CAZA
    // 2. Ha pasado el cooldown
    if (_timeSinceLastDestruction < _destructionCooldown) return;

    final hearingBehavior = parent.findBehavior<HearingBehavior>();
    if (hearingBehavior.estadoActual != AIState.caza) return;

    // Buscar paredes destructibles en colisión
    final walls = gameRef.world.children.query<WallComponent>();
    for (final wall in walls) {
      if (!wall.destructible) continue;

      // Verificar proximidad (overlap de hitboxes)
      final distance = parent.position.distanceTo(wall.position);
      if (distance < 32) {
        // Tamaño de tile + pequeño margen
        wall.removeFromParent();
        _timeSinceLastDestruction = 0.0;
        break; // Solo destruir una pared por frame
      }
    }
  }
}
