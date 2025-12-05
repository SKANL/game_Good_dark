import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:flame/collisions.dart';
import 'package:echo_world/multiplayer/games/echo_duel/components/multiplayer_player.dart';
import 'package:echo_world/multiplayer/games/echo_duel/echo_duel_game.dart';

class Bullet extends PositionComponent
    with CollisionCallbacks, HasGameReference<EchoDuelGame> {
  final String ownerId;
  final Vector2 velocity;
  final double speed = 400.0;

  Bullet({
    required this.ownerId,
    required Vector2 position,
    required Vector2 direction,
  }) : velocity = direction.normalized() * 400.0,
       super(position: position, size: Vector2(8, 8), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(
      CircleComponent(
        radius: 4,
        paint: Paint()..color = Colors.yellow,
      ),
    );

    // Active hitbox to detect passive players
    add(
      CircleHitbox(
        radius: 4,
        anchor: Anchor.center,
        position: size / 2,
        collisionType: CollisionType.active,
      ),
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is MultiplayerPlayer && other.id != ownerId) {
      // Hit an enemy
      game.repository.broadcastPlayerHit(other.id, 10);
      removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;

    // Remove if out of bounds (assuming 2000x2000 map for now)
    if (position.x < -1000 ||
        position.x > 1000 ||
        position.y < -1000 ||
        position.y > 1000) {
      removeFromParent();
    }
  }
}
