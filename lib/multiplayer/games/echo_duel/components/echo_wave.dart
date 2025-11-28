import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class EchoWave extends PositionComponent {
  double radius = 0;
  final double maxRadius;
  final double speed;
  final Paint _paint;

  EchoWave({
    required Vector2 position,
    this.maxRadius = 200.0,
    this.speed = 300.0,
    Color color = Colors.cyanAccent,
  }) : _paint = Paint()
         ..color = color
         ..style = PaintingStyle.stroke
         ..strokeWidth = 2.0,
       super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    radius += speed * dt;

    // Fade out
    final alpha = ((1 - (radius / maxRadius)) * 255).clamp(0, 255).toInt();
    _paint.color = _paint.color.withAlpha(alpha);

    if (radius >= maxRadius) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, radius, _paint);
  }
}
