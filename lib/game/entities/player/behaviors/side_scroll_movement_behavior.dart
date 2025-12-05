import 'package:echo_world/game/cubit/game/game_bloc.dart';
import 'package:echo_world/game/entities/player/player.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:echo_world/game/entities/player/behaviors/gravity_behavior.dart';
import 'dart:ui';

class SideScrollMovementBehavior extends Behavior<PlayerComponent> {
  SideScrollMovementBehavior({required this.gameBloc});
  final GameBloc gameBloc;

  double _stepAccum = 0;
  Vector2 _currentVelocity = Vector2.zero();

  Vector2 get velocity => _currentVelocity;

  // isOnGround is handled by GravityBehavior, but we can expose a helper if needed.
  // For now, PlayerComponent checks GravityBehavior for isOnGround.
  bool get isOnGround =>
      parent.findBehavior<GravityBehavior>()?.isOnGround ?? false;

  @override
  void update(double dt) {
    final game = parent.gameRef;
    final dir = game.input.movement;
    final baseSpeed = gameBloc.state.estaAgachado ? 56.0 : 128.0;
    final vx = dir.x.clamp(-1, 1) * baseSpeed;
    _currentVelocity = Vector2(vx, 0); // Y handled by gravity
    final dx = vx * dt;
    // Comprobación de colisiones horizontal (side-scroll)
    final proposedX = parent.position + Vector2(dx, 0);

    // Usar el collisionRect del jugador pero desplazado a la posición propuesta
    final currentRect = parent.collisionRect;
    final rectX = currentRect.shift(Offset(dx, 0));

    if (game.levelManager.isRectWalkable(
      rectX,
      checkAbyss: false, // En SideScroll, el abismo es aire transitable
      isCrouching: gameBloc.state.estaAgachado,
    )) {
      parent.position.x = proposedX.x;
    }

    // Emitir pasos cada cierto desplazamiento horizontal
    _stepAccum += dx.abs();
    final threshold = gameBloc.state.estaAgachado ? 22.0 : 34.0;
    if (_stepAccum >= threshold) {
      _stepAccum = 0;

      // NO emitir sonido si el jugador está silenciado por muerte
      if (!parent.isSilencedByDeath) {
        final nivel = gameBloc.state.estaAgachado
            ? NivelSonido.bajo
            : NivelSonido.medio;
        final ttl = gameBloc.state.estaAgachado ? 0.35 : 0.6;
        game.emitSound(parent.position.clone(), nivel, ttl: ttl);
      }
    }
  }
}
