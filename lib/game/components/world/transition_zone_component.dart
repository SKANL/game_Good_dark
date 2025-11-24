import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/entities/player/player.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Zona de transición que detecta cuando el jugador entra
/// y solicita la carga del siguiente chunk.
class TransitionZoneComponent extends PositionComponent
  with CollisionCallbacks, HasGameRef<BlackEchoGame> {
  TransitionZoneComponent({
    required super.position,
    required super.size,
    required this.targetChunkDirection,
  }) : super(anchor: Anchor.topLeft);

  final String targetChunkDirection; // 'north', 'south', 'east', 'west'
  bool _hasTriggered = false;

  @override
  Future<void> onLoad() async {
    await add(RectangleHitbox());
    // Render invisible en producción, pero visible en debug
    priority = -1; // Detrás de todo
  }

  @override
  void render(Canvas canvas) {
    // Debug: renderizar la zona con transparencia
    if (gameRef.debugMode) {
      final paint = Paint()
        ..color = const Color(0x3300FF00)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & Size(size.x, size.y), paint);
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerComponent && !_hasTriggered) {
      _hasTriggered = true;
      _triggerTransition();
    }
  }

  Future<void> _triggerTransition() async {
    // Aquí se activaría la transición al siguiente chunk
    // Por ahora, usar el método existente de LevelManager
    await gameRef.levelManager.siguienteChunk();

    // Reset del trigger después de un delay
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _hasTriggered = false;
  }
}
