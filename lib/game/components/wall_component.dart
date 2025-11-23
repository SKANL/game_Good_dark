import 'dart:ui'; // For Canvas
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';

/// WallComponent ahora solo maneja colisiones.
/// El renderizado se hace vía BatchGeometryRenderer en LevelManager
/// para optimizar draw calls (1 Picture vs N drawRect).
class WallComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<BlackEchoGame> {
  WallComponent({
    required Vector2 position,
    required Vector2 size,
    this.destructible = false,
  }) : super(position: position, size: size, anchor: Anchor.topLeft);

  final bool destructible;

  @override
  Future<void> onLoad() async {
    await add(RectangleHitbox());
  }

  void destroy() {
    if (destructible) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Don't render 2D walls in First-Person mode
    if (gameRef.gameBloc.state.enfoqueActual == Enfoque.firstPerson) return;

    // Fallback render: ALWAYS render for now to fix visibility bug.
    // BatchGeometryRenderer seems to be failing or out of sync.
    // We draw a simple rect.
    final paint = Paint()
      ..color = destructible
          ? const Color(0xFF444444)
          : const Color(0xFF222222);
    canvas.drawRect(size.toRect(), paint);
  }
}
