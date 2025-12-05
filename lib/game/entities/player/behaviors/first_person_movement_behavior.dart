import 'dart:math' as math;

import 'package:echo_world/game/cubit/game/game_bloc.dart';
import 'package:echo_world/game/entities/player/behaviors/collision_handler.dart';
import 'package:echo_world/game/entities/player/player.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

/// Comportamiento de movimiento en primera persona.
///
/// **Controles:**
/// - Joystick X (horizontal): Rotación izquierda/derecha (modifica heading)
/// - Joystick Y (vertical): Movimiento adelante/atrás en dirección del heading
///
/// **Características:**
/// - Velocidad máxima: 128 px/s (normal) / 56 px/s (sigilo)
/// - Rotación: 1.5 rad/s (~86°/s) con aceleración suave
/// - El heading se sincroniza con PlayerComponent para el raycaster
class FirstPersonMovementBehavior extends Behavior<PlayerComponent>
    with CollisionHandler {
  FirstPersonMovementBehavior({required this.gameBloc});
  final GameBloc gameBloc;

  static const double maxSpeed = 64; // px/s (valor base)
  static const double stealthSpeed = 32; // px/s (base al agacharse)
  static const double turnSpeed = 1.2; // rad/s (base de rotación)

  // Sensibilidades (ajustables): multiplicadores aplicados sobre input
  static const double moveSensitivity = 1.5; // reducir avance global
  static const double turnSensitivity = 1.5; // reducir rotación global

  // Suavizado de rotación
  double _currentTurnVelocity = 0;
  static const double turnAcceleration = 6; // rad/s²

  double _stepAccum = 0;
  Vector2 _currentVelocity = Vector2.zero();
  Vector2 get velocity => _currentVelocity;

  @override
  void update(double dt) {
    final player = parent;
    final game = player.gameRef;
    final input = game.input;

    // Joystick: x = turn, y = forward/backward
    // Leer input y proteger magnitud
    final rawMove = input.movement;
    final move = rawMove.length > 1.0 ? rawMove.normalized() : rawMove;

    // Rotación con aceleración suave (aplicar sensibilidad)
    final targetTurnVelocity = move.x * turnSpeed * turnSensitivity;

    // Interpolar hacia la velocidad objetivo (suavizado)
    _currentTurnVelocity =
        _currentTurnVelocity +
        (targetTurnVelocity - _currentTurnVelocity) * turnAcceleration * dt;

    // Aplicar rotación suavizada
    player.heading += _currentTurnVelocity * dt;

    // Normalizar heading a [-π, π]
    while (player.heading > math.pi) {
      player.heading -= 2 * math.pi;
    }
    while (player.heading < -math.pi) {
      player.heading += 2 * math.pi;
    }

    // Movimiento: adelante/atrás en dirección del heading
    final isStealth = gameBloc.state.estaAgachado;
    final baseVelocity = isStealth ? stealthSpeed : maxSpeed;
    final speedMagnitude = baseVelocity * moveSensitivity;
    final speed =
        -move.y * speedMagnitude; // Invertir: joystick arriba = adelante

    // Update velocity vector for external checks (approximate based on heading)
    _currentVelocity = Vector2(
      speed * math.cos(player.heading),
      speed * math.sin(player.heading),
    );

    // Calcular desplazamiento en dirección del heading
    final dx = speed * dt * math.cos(player.heading);
    final dy = speed * dt * math.sin(player.heading);
    final moveDelta = Vector2(dx, dy);

    // Comprobación de colisiones (usando CollisionHandler)
    moveWithCollision(moveDelta);

    // Emitir sonido de pasos
    if (speed.abs() > 0.1) {
      _stepAccum += speed.abs() * dt;
      final threshold = isStealth ? 22.0 : 34.0;
      if (_stepAccum >= threshold) {
        _stepAccum = 0;

        // NO emitir sonido si el jugador está silenciado por muerte
        if (!player.isSilencedByDeath) {
          final nivel = isStealth ? NivelSonido.bajo : NivelSonido.medio;
          final ttl = isStealth ? 0.35 : 0.6;
          game.emitSound(player.position.clone(), nivel, ttl: ttl);
        }
      }
    }
  }
}
