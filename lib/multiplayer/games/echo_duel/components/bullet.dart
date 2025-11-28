import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Bullet extends PositionComponent {
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
