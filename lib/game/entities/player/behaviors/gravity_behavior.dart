import 'dart:ui';
import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/components/vfx/landing_dust_component.dart';
import 'package:echo_world/game/entities/player/player.dart';
import 'package:echo_world/game/level/manager/level_manager.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

class GravityBehavior extends Behavior<PlayerComponent> {
  double _velocityY = 0;
  static const double gravity = 900; // px/s^2

  void impulse(double vy) {
    _velocityY = vy;
  }

  @override
  void update(double dt) {
    _velocityY += gravity * dt;
    final deltaY = _velocityY * dt;

    // Predicción de movimiento vertical
    final proposedY = parent.position.y + deltaY;

    // Usar collisionRect para la comprobación
    final currentRect = parent.collisionRect;
    // Desplazar el rect verticalmente
    final rectY = currentRect.shift(Offset(0, deltaY));

    final game = parent.gameRef;

    if (!game.levelManager.isRectWalkable(
      rectY,
      checkAbyss: false, // Permitir caer por abismos
      isCrouching: parent.gameBloc.state.estaAgachado,
    )) {
      // Colisión vertical (suelo o techo)
      if (_velocityY > 0) {
        // Cayendo -> Suelo
        _velocityY = 0;
        // Ajustar posición al suelo (parte superior del tile)
        final tileY = (rectY.bottom / LevelManagerComponent.tileSize).floor();
        final groundY = tileY * LevelManagerComponent.tileSize;
        final offset =
            parent.position.y -
            currentRect.bottom; // Distancia del centro al fondo del rect
        parent.position.y = groundY + offset;

        // Spawn landing dust
        parent.parent?.add(
          LandingDustComponent(
            position: Vector2(parent.position.x, currentRect.bottom),
          ),
        );
      } else {
        // Subiendo -> Techo
        _velocityY = 0;
        // Ajustar posición al techo (parte inferior del tile)
        final tileY = (rectY.top / LevelManagerComponent.tileSize).floor();
        final ceilingY = (tileY + 1) * LevelManagerComponent.tileSize;
        final offset =
            parent.position.y -
            currentRect.top; // Distancia del centro al top del rect
        parent.position.y = ceilingY + offset;
      }
    } else {
      // Sin colisión, aplicar movimiento
      parent.position.y = proposedY;

      // Verificar si cayó al vacío (fuera del mapa)
      final mapBottom =
          game.levelManager.currentChunk!.alto * LevelManagerComponent.tileSize;
      if (parent.position.y > mapBottom + 100) {
        _respawn(game);
      }
    }
  }

  void _respawn(BlackEchoGame game) {
    // Daño por caída
    // TODO: Implementar sistema de daño real
    // Por ahora, solo respawn en el inicio del chunk o checkpoint
    final chunk = game.levelManager.currentChunk!;
    if (chunk.spawnPoint != null) {
      parent.position = chunk.spawnPoint! * LevelManagerComponent.tileSize;
    } else {
      parent.position = Vector2(80, 80); // Fallback seguro
    }
    _velocityY = 0;
  }
}
