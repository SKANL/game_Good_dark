import 'dart:ui';

import 'package:echo_world/game/entities/player/player.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

/// Mixin that provides collision detection and sliding logic for player movement.
mixin CollisionHandler on Behavior<PlayerComponent> {
  /// Attempts to move the player by [delta], handling collisions with the level.
  ///
  /// If the full movement is blocked, it attempts to slide along the X or Y axis.
  /// Returns the actual displacement vector applied.
  Vector2 moveWithCollision(Vector2 delta) {
    if (delta.isZero()) return Vector2.zero();

    final game = parent.gameRef;
    final currentRect = parent.collisionRect;

    // 1. Try full movement
    final proposedPos = parent.position + delta;
    final rectProposed = currentRect.shift(Offset(delta.x, delta.y));

    if (game.levelManager.isRectWalkable(rectProposed)) {
      parent.position.setFrom(proposedPos);
      return delta;
    }

    // 2. Try sliding along X
    if (delta.x != 0) {
      final rectX = currentRect.shift(Offset(delta.x, 0));
      if (game.levelManager.isRectWalkable(rectX)) {
        parent.position.x += delta.x;
        return Vector2(delta.x, 0);
      }
    }

    // 3. Try sliding along Y
    if (delta.y != 0) {
      final rectY = currentRect.shift(Offset(0, delta.y));
      if (game.levelManager.isRectWalkable(rectY)) {
        parent.position.y += delta.y;
        return Vector2(0, delta.y);
      }
    }

    // Blocked completely
    if (delta.length > 1.5) {
      // High speed collision -> Feedback
      // Only trigger if we haven't triggered recently (simple debounce could be added here or in behaviors)
      // For now, just trigger.

      // SFX
      // AudioManager.instance.playSfx('wall_bump', volume: 0.5); // Need to ensure this sound exists or use a placeholder

      // Screen Shake (subtle)
      game.shakeCamera(intensity: 2, duration: 0.15);
    }

    return Vector2.zero();
  }
}
