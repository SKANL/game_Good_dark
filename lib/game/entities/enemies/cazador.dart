import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:echo_world/game/entities/enemies/behaviors/behaviors.dart';
import 'package:flame/collisions.dart';
import 'package:echo_world/game/components/lighting/light_source_component.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flutter/painting.dart';

/// Entidad enemiga "Cazador" (arquetipo estándar).
/// IA reactiva al sonido con FSM (ATORMENTADO → ALERTA → CAZA).
/// Render procedural como círculo rojo con contorno.
class CazadorComponent extends PositionedEntity with CollisionCallbacks {
  CazadorComponent({
    required super.position,
    this.radioBajo = 96, // 3 tiles
    this.radioMedio = 384, // 12 tiles
    this.radioAlto = 480, // 15 tiles
  }) : super(
         size: Vector2.all(28),
         anchor: Anchor.center,
         behaviors: [],
       );

  final double radioBajo;
  final double radioMedio;
  final double radioAlto;

  /// Resetea el estado del enemigo para reuso por ComponentPool
  void reset() {
    // Reiniciar FSM a ATORMENTADO (solo si ya fue cargado)
    try {
      findBehavior<HearingBehavior>().reset();
    } catch (_) {}
    try {
      findBehavior<PositionalAudioBehavior>().reset();
    } catch (_) {}
    try {
      findBehavior<PatrolBehavior>().reset();
    } catch (_) {}
    try {
      findBehavior<AIMovementBehavior>().reset();
    } catch (_) {}
    // ...otros behaviors si se añaden en el futuro
    add(
      LightSourceComponent(
        color: const Color(0xFFFF0000), // Red
        intensity: 1.0,
        radius: 80,
        softness: 0.5,
        isPulsing: true,
        pulseSpeed: 1.0, // Slow breathing
        pulseMinIntensity: 0.5,
        pulseMaxIntensity: 1.0,
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Solo agregar componentes si no existen (para permitir reuso del pool)
    if (children.query<RectangleHitbox>().isEmpty) {
      // Añadir hitbox circular para colisiones
      add(
        RectangleHitbox(
          size: size,
          anchor: Anchor.center,
        )..position = size / 2,
      );
    }

    // Añadir behaviors de IA solo si no existen
    if (children.query<HearingBehavior>().isEmpty) {
      await add(
        HearingBehavior(
          radioBajo: radioBajo,
          radioMedio: radioMedio,
          radioAlto: radioAlto,
        ),
      );
      await add(PatrolBehavior());
      await add(AIMovementBehavior());
      await add(
        PositionalAudioBehavior(),
      ); // Audio posicional reactivo a la FSM

      add(
        LightSourceComponent(
          color: const Color(0xFFFF0000), // Red
          intensity: 1.0,
          radius: 80,
          softness: 0.5,
          isPulsing: true,
          pulseSpeed: 1.0, // Slow breathing
          pulseMinIntensity: 0.5,
          pulseMaxIntensity: 1.0,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // NO renderizar en first-person: el raycaster proyecta los enemigos en 3D
    final game = findParent<BlackEchoGame>();
    if (game != null &&
        game.gameBloc.state.enfoqueActual == Enfoque.firstPerson) {
      return;
    }

    // Render procedural: círculo rojo con contorno blanco (top-down/side-scroll)
    final center = size / 2;
    final radius = size.x / 2;

    // Relleno rojo oscuro
    final fillPaint = Paint()
      ..color = const Color(0xFFFF2222)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.x, center.y), radius, fillPaint);

    // Contorno blanco
    final strokePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(center.x, center.y), radius, strokePaint);
  }
}
