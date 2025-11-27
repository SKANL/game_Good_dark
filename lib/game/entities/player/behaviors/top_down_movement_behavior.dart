import 'package:echo_world/game/cubit/game/game_bloc.dart';
import 'package:echo_world/game/entities/player/player.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

import 'package:echo_world/game/entities/player/behaviors/collision_handler.dart';

class TopDownMovementBehavior extends Behavior<PlayerComponent>
    with CollisionHandler {
  TopDownMovementBehavior({required this.gameBloc});
  final GameBloc gameBloc;

  double _stepAccum = 0;
  Vector2 _currentVelocity = Vector2.zero();

  Vector2 get velocity => _currentVelocity;

  @override
  void update(double dt) {
    final game = parent.gameRef;
    final dir = game.input.movement;

    // Reset velocity when no input
    if (dir == Vector2.zero()) {
      _currentVelocity = Vector2.zero();
      return;
    }

    final baseSpeed = gameBloc.state.estaAgachado ? 56.0 : 128.0;
    _currentVelocity = dir.normalized() * baseSpeed;
    final delta = _currentVelocity * dt;

    // Comprobación de colisiones (usando CollisionHandler)
    moveWithCollision(delta);

    // Emitir sonido de pasos según distancia recorrida
    _stepAccum += delta.length;
    final threshold = gameBloc.state.estaAgachado ? 22.0 : 34.0;
    if (_stepAccum >= threshold) {
      _stepAccum = 0;
      final nivel = gameBloc.state.estaAgachado
          ? NivelSonido.bajo
          : NivelSonido.medio;
      final ttl = gameBloc.state.estaAgachado ? 0.35 : 0.6;
      game.emitSound(parent.position.clone(), nivel, ttl: ttl);
    }
  }
}
