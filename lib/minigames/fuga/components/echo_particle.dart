import 'dart:ui';
import 'package:flame/components.dart';
import '../entities/colors.dart';

class EchoParticle extends PositionComponent {
  EchoParticle({
    required Vector2 position,
    required this.direction,
    this.speed = 50.0,
    this.lifeTime = 1.0,
  }) : super(position: position, size: Vector2.all(4));

  final Vector2 direction;
  final double speed;
  final double lifeTime;
  double _life = 0;
  final Paint _paint = Paint()..color = GameColors.cyan;

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    if (_life >= lifeTime) {
      removeFromParent();
      return;
    }

    position += direction * speed * dt;

    // Fade out
    final opacity = 1.0 - (_life / lifeTime);
    _paint.color = GameColors.cyan.withValues(alpha: opacity);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, _paint);
  }
}
