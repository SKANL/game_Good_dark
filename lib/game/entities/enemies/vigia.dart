import 'dart:math' as math;

import 'package:echo_world/game/audio/audio_manager.dart';
import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:echo_world/game/entities/enemies/behaviors/behaviors.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flutter/painting.dart';

/// Arquetipo Vigía: Enemigo estático que funciona como alarma.
/// Ignora sonidos bajos, tiene radio de audición masivo.
/// Al detectar al jugador, ejecuta ScreamBehavior atrayendo a todos los enemigos.
class VigiaComponent extends PositionedEntity
    with CollisionCallbacks, HasGameRef<BlackEchoGame> {
  VigiaComponent({
    required Vector2 position,
  }) : super(
         position: position,
         size: Vector2.all(32),
         anchor: Anchor.center,
         behaviors: [],
       );

  final Paint _paint = Paint()..color = const Color(0xFF8A2BE2); // Violeta

  /// Audio loop ID para el hum estático
  String? _staticHumLoopId;

  /// Resetea el estado del Vigia para reuso por ComponentPool
  void reset() {
    // Reiniciar FSM a ATORMENTADO (solo si ya fue cargado)
    try {
      findBehavior<HearingBehavior>().reset();
    } catch (_) {}
    try {
      findBehavior<HearingBehavior>().reset();
    } catch (_) {}
    // Audio loop se maneja en onMount/onRemove
    try {
      findBehavior<ScreamBehavior>().reset();
    } catch (_) {}
  }

  @override
  Future<void> onLoad() async {
    // Solo agregar componentes si no existen (para permitir reuso del pool)
    if (children.query<RectangleHitbox>().isEmpty) {
      await add(RectangleHitbox(size: size, anchor: Anchor.center));
    }

    if (children.query<HearingBehavior>().isEmpty) {
      // HearingBehavior con configuración especial para Vigía:
      // - radioBajo: 0 (ignora sonidos bajos)
      // - radioMedio: 1000 (radio masivo para sonidos medios/altos)
      await add(
        HearingBehavior(
          radioBajo: 0,
          radioMedio: 640,
          radioAlto: 640,
          velocidadPatrulla: 0, // Estático, no se mueve
          velocidadAlerta: 0,
          velocidadCaza: 0,
        ),
      );

      // ScreamBehavior que será activado por el HearingBehavior
      await add(ScreamBehavior());
    }
    // Iniciar loop de audio estático
    // MOVIDO A onMount para soportar pooling
  }

  @override
  void onMount() {
    super.onMount();
    _startAudioLoop();
  }

  Future<void> _startAudioLoop() async {
    if (_staticHumLoopId == null) {
      _staticHumLoopId = await AudioManager.instance.startPositionalLoop(
        soundId: 'vigia_static_hum_loop',
        sourcePosition: math.Point(position.x, position.y),
        listenerPosition: math.Point(
          gameRef.player.position.x,
          gameRef.player.position.y,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Actualizar posición del audio loop
    if (_staticHumLoopId != null) {
      AudioManager.instance.updatePositionalLoop(
        loopId: _staticHumLoopId!,
        sourcePosition: math.Point(position.x, position.y),
        listenerPosition: math.Point(
          gameRef.player.position.x,
          gameRef.player.position.y,
        ),
      );
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

    // Renderizar el Vigía: cuadrado naranja con borde (top-down/side-scroll)
    final rect = size.toRect();
    canvas.drawRect(
      rect,
      _paint..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = const Color(0xFF8A2BE2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Dibujar un "ojo" en el centro
    final eyeRadius = size.x * 0.15;
    canvas.drawCircle(
      Offset.zero,
      eyeRadius,
      Paint()..color = const Color(0xFFFFFFFF),
    );
  }

  @override
  void onRemove() {
    // Detener audio loop
    if (_staticHumLoopId != null) {
      AudioManager.instance.stopPositionalLoop(_staticHumLoopId!);
      _staticHumLoopId = null;
    }
    super.onRemove();
  }
}
