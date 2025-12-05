import 'dart:ui';

import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/entities/enemies/behaviors/scream_behavior.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

/// Estados de la máquina de estados finitos (FSM) de la IA
enum AIState {
  atormentado, // Patrulla base, ignora sonidos bajos
  alerta, // Investiga sonido medio/alto, busca por tiempo limitado
  caza, // Persigue activamente al jugador
  aturdido, // Inmovilizado temporalmente (post-escudo)
}

/// Behavior central de IA para todas las Resonancias.
/// Implementa una FSM reactiva al sonido que consulta el SoundBus del juego.
class HearingBehavior extends Behavior<PositionedEntity>
    with HasGameRef<BlackEchoGame> {
  HearingBehavior({
    required this.radioBajo,
    required this.radioMedio,
    double? radioAlto,
    this.velocidadPatrulla = 140,
    this.velocidadAlerta = 180,
    this.velocidadCaza = 220,
  }) : radioAlto = radioAlto ?? radioMedio;

  // Configuración de audición (en px)
  final double radioBajo;
  final double radioMedio;
  final double radioAlto;

  // Velocidades por estado (en px/s)
  final double velocidadPatrulla;
  final double velocidadAlerta;
  final double velocidadCaza;

  // Estado actual de la FSM
  AIState estadoActual = AIState.atormentado;

  // Estado temporal para ALERTA
  Vector2? ultimaPosicionSonido;
  double _tiempoInvestigacion = 0;
  static const double _tiempoMaximoInvestigacion = 5;

  // Estado temporal para CAZA
  double _tiempoPersecucion = 0;
  static const double _tiempoMaximoPersecucion = 3;

  // Estado temporal para ATURDIDO
  double _tiempoAturdimiento = 0;
  double _duracionAturdimiento = 0;

  // Knockback physics
  Vector2 _knockbackVelocity = Vector2.zero();
  static const double _knockbackDecay = 0.9; // Friction

  @override
  void update(double dt) {
    // Apply Knockback physics WITH COLLISION VALIDATION
    if (!_knockbackVelocity.isZero()) {
      final game = parent.findParent<BlackEchoGame>();

      if (game != null) {
        // Calculate desired movement
        final desiredDelta = _knockbackVelocity * dt;

        // Step-by-step validation to prevent wall clipping
        // Max step size of 8px to avoid tunneling through thin walls
        const maxStepSize = 8.0;
        final totalDistance = desiredDelta.length;
        final steps = (totalDistance / maxStepSize).ceil().clamp(1, 10);
        final stepDelta = desiredDelta / steps.toDouble();

        // Try to move in small increments
        for (var i = 0; i < steps; i++) {
          final newPos = parent.position + stepDelta;
          final enemyRect = Rect.fromCenter(
            center: Offset(newPos.x, newPos.y),
            width: parent.size.x,
            height: parent.size.y,
          );

          // Validate collision with level geometry
          if (game.levelManager.isRectWalkable(enemyRect)) {
            // Safe to move
            parent.position = newPos;
          } else {
            // Hit a wall, stop knockback immediately
            _knockbackVelocity = Vector2.zero();
            break;
          }
        }
      } else {
        // Fallback: apply movement without validation (shouldn't happen)
        parent.position += _knockbackVelocity * dt;
      }

      // Apply drag (friction) based on time, not frames
      // Antes era 0.9 por frame, lo que es ~6.0 de drag (muy alto).
      // Usamos 3.0 para un deslizamiento más natural y largo.
      const drag = 3.0;
      _knockbackVelocity -= _knockbackVelocity * (drag * dt);

      if (_knockbackVelocity.length < 10) {
        _knockbackVelocity = Vector2.zero();
      }
      // Disable other movement while being knocked back strongly
      if (_knockbackVelocity.length > 50) {
        return;
      }
    }

    final soundBus = gameRef.soundBus;

    // Manejar aturdimiento (no hace nada hasta que termine)
    if (estadoActual == AIState.aturdido) {
      _tiempoAturdimiento += dt;
      if (_tiempoAturdimiento >= _duracionAturdimiento) {
        estadoActual = AIState.atormentado;
        _tiempoAturdimiento = 0;
      }
      return;
    }

    // Penalización: Agonía Resonante (> 75 ruidoMental)
    // Aumentar radios de audición pasivamente
    final multiplicadorAgonia = gameRef.gameBloc.state.ruidoMental > 75
        ? 1.5
        : 1.0;
    final radioBajoEfectivo = radioBajo * multiplicadorAgonia;
    final radioMedioEfectivo = radioMedio * multiplicadorAgonia;

    // Consultar estímulos sónicos cercanos
    final estimuloBajo = soundBus.queryStrongest(
      parent.position,
      radioBajoEfectivo,
    );
    final estimuloMedio = soundBus.queryStrongest(
      parent.position,
      radioMedioEfectivo,
    );

    // FSM: ATORMENTADO (estado base)
    if (estadoActual == AIState.atormentado) {
      // Ignorar sonidos bajos, solo reaccionar a medio/alto
      if (estimuloMedio != null) {
        ultimaPosicionSonido = estimuloMedio.posicion.clone();
        _tiempoInvestigacion = 0;

        // Si el enemigo tiene ScreamBehavior (es un Vigía), activar el grito
        try {
          final screamBehavior = parent.findBehavior<ScreamBehavior>();
          if (!screamBehavior.isScreaming) {
            screamBehavior.triggerScream();
          }
        } catch (e) {
          // El behavior no está disponible (no es un Vigía), se ignora
        }

        if (estimuloMedio.nivel == NivelSonido.alto) {
          estadoActual = AIState.caza;
        } else {
          estadoActual = AIState.alerta;
        }
      }
    }
    // FSM: ALERTA (investigación)
    else if (estadoActual == AIState.alerta) {
      _tiempoInvestigacion += dt;

      // Si detecta sonido bajo/medio cerca, escalar a CAZA
      if (estimuloBajo != null || estimuloMedio != null) {
        estadoActual = AIState.caza;
        _tiempoPersecucion = 0;
        return;
      }

      // Si llega a la ubicación o se agota el tiempo, volver a ATORMENTADO
      if (ultimaPosicionSonido != null) {
        final distancia = parent.position.distanceTo(ultimaPosicionSonido!);
        if (distancia < 16 ||
            _tiempoInvestigacion >= _tiempoMaximoInvestigacion) {
          estadoActual = AIState.atormentado;
          ultimaPosicionSonido = null;
        }
      }
    }
    // FSM: CAZA (persecución activa)
    else if (estadoActual == AIState.caza) {
      // Si detecta sonido, reiniciar el timer de persecución
      if (estimuloBajo != null || estimuloMedio != null) {
        _tiempoPersecucion = 0;
      } else {
        _tiempoPersecucion += dt;
      }

      // Si pierde el rastro, volver a ALERTA
      if (_tiempoPersecucion >= _tiempoMaximoPersecucion) {
        estadoActual = AIState.alerta;
        _tiempoInvestigacion = 0;
      }
    }

    super.update(dt);
  }

  void reset() {
    estadoActual = AIState.atormentado;
    ultimaPosicionSonido = null;
    _tiempoInvestigacion = 0;
    _tiempoPersecucion = 0;
    _tiempoAturdimiento = 0;
    _duracionAturdimiento = 0;
  }

  /// Método para aturdir al enemigo (llamado desde colisiones con escudo)
  void stun(double duracion) {
    estadoActual = AIState.aturdido;
    _tiempoAturdimiento = 0;
    _duracionAturdimiento = duracion;
  }

  /// Causa "Amnesia Táctica" al enemigo.
  /// Lo aturde y borra su memoria del jugador, forzando un estado de ALERTA al recuperarse.
  void confuse(double duracion) {
    stun(duracion);
    // Borrar target y memoria
    ultimaPosicionSonido = null;
    _tiempoPersecucion = 0;
    _tiempoInvestigacion = 0;

    // Forzar transición a ALERTA al terminar el stun (se maneja en update)
    // Usamos una flag o simplemente confiamos en que al no tener target,
    // si hay sonido volverá a ALERTA, o si no, a ATORMENTADO.
    // Para forzar ALERTA, podríamos establecer una posición de sonido falsa o
    // simplemente dejar que la lógica de update decida.
    // MEJORA: Al salir de stun, si estaba en CAZA, bajar a ALERTA.
  }

  /// Aplica un empuje físico al enemigo
  void pushBack(Vector2 direction, double force) {
    if (direction.isZero()) {
      // Si la dirección es cero (posiciones idénticas), elegir una aleatoria
      direction = Vector2(1, 0)..rotate(0.5); // Arbitrario
    }
    _knockbackVelocity = direction.normalized() * force;
    // También aturdir brevemente si el golpe es fuerte
    if (force > 200) {
      stun(0.5);
    }
  }

  /// Devuelve la velocidad actual según el estado FSM
  double get velocidadActual {
    switch (estadoActual) {
      case AIState.atormentado:
        return velocidadPatrulla;
      case AIState.alerta:
        return velocidadAlerta;
      case AIState.caza:
        return velocidadCaza;
      case AIState.aturdido:
        return 0;
    }
  }

  // Target de patrulla (asignado por PatrolBehavior)
  Vector2? patrolTarget;

  /// Devuelve el target de movimiento según el estado FSM
  Vector2? get targetActual {
    switch (estadoActual) {
      case AIState.atormentado:
        return patrolTarget;
      case AIState.alerta:
        return ultimaPosicionSonido;
      case AIState.caza:
        return gameRef.player.position; // Perseguir al jugador
      case AIState.aturdido:
        return null; // Sin movimiento
    }
  }
}
