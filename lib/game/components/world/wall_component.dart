import 'dart:ui';

import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

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
      print('[WALL] Destroying wall at $position');

      // CRITICAL: Update level grid so wall becomes passable in ALL perspectives
      final tileX = (position.x / 32).floor();
      final tileY = (position.y / 32).floor();

      try {
        final grid = gameRef.levelManager.currentGrid;
        if (grid != null &&
            tileY >= 0 &&
            tileY < grid.length &&
            tileX >= 0 &&
            tileX < grid[0].length) {
          grid[tileY][tileX] = CeldaData.suelo;
          print('[WALL] Grid updated: ($tileX, $tileY) = FLOOR');
        }
      } catch (e) {
        print('[WALL] Grid update error: $e');
      }

      // Remove hitbox
      final hitbox = children.query<RectangleHitbox>().firstOrNull;
      if (hitbox != null) {
        hitbox.removeFromParent();
      }

      // Update batch renderer
      final batchRenderer = gameRef.world.children
          .query<Component>()
          .whereType<dynamic>()
          .firstWhere(
            (c) => c.runtimeType.toString() == 'BatchGeometryRenderer',
            orElse: () => null as dynamic,
          );

      if (batchRenderer != null) {
        try {
          (batchRenderer as dynamic).removeGeometry(position);
          (batchRenderer as dynamic).markDirty();
        } catch (e) {
          print('[WALL] Batch renderer error: $e');
        }
      }

      removeFromParent();
      print('[WALL] Fully destroyed and passable');
    }
  }

  @override
  void render(Canvas canvas) {
    if (gameRef.gameBloc.state.enfoqueActual == Enfoque.firstPerson) return;

    if (destructible) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFF8800).withAlpha((0.4 * 255).round())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRect(
        Rect.fromLTWH(-4, -4, size.x + 8, size.y + 8),
        glowPaint,
      );
    }

    final paint = Paint()
      ..color = destructible
          ? const Color(0xFFFF6600)
          : const Color(0xFF222222);
    canvas.drawRect(size.toRect(), paint);
  }
}
