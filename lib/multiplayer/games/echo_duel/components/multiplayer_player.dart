import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class MultiplayerPlayer extends PositionComponent {
  final String id;
  final bool isMe;
  Vector2 velocity = Vector2.zero();
  final double speed = 200.0;

  MultiplayerPlayer({
    required this.id,
    required this.isMe,
    required Vector2 position,
  }) : super(position: position, size: Vector2(32, 32), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Simple circle for now
    add(
      CircleComponent(
        radius: 16,
        paint: Paint()..color = isMe ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
  }

  void move(Vector2 delta) {
    velocity = delta * speed;
  }
}
