import 'dart:math' as math;

import 'package:echo_world/game/audio/audio_manager.dart';
import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:echo_world/game/entities/enemies/behaviors/behaviors.dart';
import 'package:echo_world/game/level/level_models.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flutter/painting.dart';

/// Arquetipo Bruto: Enemigo tanque lento que requiere 2 [RUPTURA] para ser derrotado.
/// Puede destruir paredes débiles durante el estado CAZA.
/// Genera sonido bajo al moverse (pisadas audibles).
class BrutoComponent extends PositionedEntity
    with CollisionCallbacks, HasGameRef<BlackEchoGame> {
  BrutoComponent({
    required Vector2 position,
  }) : super(
         position: position,
         size: Vector2.all(32),
         anchor: Anchor.center,
         behaviors: [],
       );

  final Paint _paint = Paint()
    ..color = const Color(0xFF8B4513); // Marrón (tanque)

  /// Audio loop ID para pisadas
  String? _footstepLoopId;

  /// Tiempo acumulado para determinar cuándo emitir estímulo sonoro
  double _footstepTimer = 0;
  static const double _footstepInterval = 0.5; // Cada 0.5s

  /// Resetea el estado del Bruto para reuso por ComponentPool
  void reset() {
    // Reiniciar FSM de audición (solo si ya fue cargado)
    try {
      findBehavior<HearingBehavior>().reset();
    } catch (_) {}

    // Reiniciar resistencia (impactos necesarios para derrotarlo)
    try {
      findBehavior<ResilienceBehavior>().reset();
    } catch (_) {}

    // Reiniciar temporizador de pasos
    _footstepTimer = 0.0;

    // Audio loop se maneja en onMount/onRemove
  }

  @override
  Future<void> onLoad() async {
    // Solo agregar componentes si no existen (para permitir reuso del pool)
    if (children.query<RectangleHitbox>().isEmpty) {
      await add(RectangleHitbox(size: size, anchor: Anchor.center));
    }

    if (children.query<HearingBehavior>().isEmpty) {
      // HearingBehavior con velocidades reducidas (-20%)
      // Velocidades base: patrulla 96, alerta 128, caza 144
      // Velocidades Bruto: patrulla 76.8, alerta 102.4, caza 115.2
      await add(
        HearingBehavior(
          radioBajo: 160,
          radioMedio: 320,
          radioAlto: 640,
          velocidadPatrulla: 76.8, // -20%
          velocidadAlerta: 102.4, // -20%
          velocidadCaza: 115.2, // -20%
        ),
      );

      // MovementBehavior para patrulla y persecución
      await add(AIMovementBehavior());

      // ResilienceBehavior: requiere 2 impactos de [RUPTURA]
      await add(ResilienceBehavior(requiredHits: 2));

      // DestructionBehavior: puede destruir paredes durante CAZA
      await add(DestructionBehavior());
    }
    // Iniciar loop de audio de pisadas
    // MOVIDO A onMount para soportar pooling
  }

  @override
  void onMount() {
    super.onMount();
    _startAudioLoop();
  }

  Future<void> _startAudioLoop() async {
    if (_footstepLoopId == null) {
      _footstepLoopId = await AudioManager.instance.startPositionalLoop(
        soundId: 'bruto_footstep',
        sourcePosition: math.Point(position.x, position.y),
        listenerPosition: math.Point(
          gameRef.player.position.x,
          gameRef.player.position.y,
        ),
        volume: 0.6, // Volumen más bajo que otros enemigos
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Actualizar posición del audio loop
    if (_footstepLoopId != null) {
      AudioManager.instance.updatePositionalLoop(
        loopId: _footstepLoopId!,
        sourcePosition: math.Point(position.x, position.y),
        listenerPosition: math.Point(
          gameRef.player.position.x,
          gameRef.player.position.y,
        ),
      );
    }

    // Emitir estímulo sonoro bajo cada _footstepInterval segundos
    // (solo si el Bruto se está moviendo)
    final hearingBehavior = findBehavior<HearingBehavior>();
    if (hearingBehavior.estadoActual != AIState.atormentado) {
      _footstepTimer += dt;
      if (_footstepTimer >= _footstepInterval) {
        _footstepTimer = 0.0;
        gameRef.emitSound(
          position.clone(),
          NivelSonido.bajo,
          ttl: 0.5,
        );
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // NO renderizar en first-person: el raycaster proyecta los enemigos en 3D
    final game = findParent<BlackEchoGame>();
    if (game != null &&
        game.gameBloc.state.enfoqueActual == Enfoque.firstPerson) {
      return;
    }

    // Renderizar el Bruto: cuadrado marrón con borde grueso (top-down/side-scroll)
    final rect = size.toRect();

    // Fondo marrón
    canvas.drawRect(rect, _paint);

    // Borde negro más grueso (tanque pesado)
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Indicador visual de ResilienceBehavior (barras de vida)
    final resilienceBehavior = findBehavior<ResilienceBehavior>();
    final hitsRemaining = resilienceBehavior.hitsRemaining;

    // Dibujar barras horizontales (una por hit restante)
    for (var i = 0; i < hitsRemaining; i++) {
      final barY = 4.0 + (i * 6.0);
      canvas.drawRect(
        Rect.fromLTWH(4, barY, 24, 4),
        Paint()..color = const Color(0xFFFFFFFF),
      );
    }
  }

  @override
  void onRemove() {
    // Detener audio loop al morir
    if (_footstepLoopId != null) {
      AudioManager.instance.stopPositionalLoop(_footstepLoopId!);
    }
    super.onRemove();
  }
}
