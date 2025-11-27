import 'dart:ui';

import 'package:echo_world/minigames/fuga/entities/colors.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';

/// A pulse expands from origin and notifies the game about its radius so
/// walls and other entities can react. Geometry-only: no assets.
class FugaPulseComponent extends PositionComponent
    with HasGameReference<FlameGame> {
  FugaPulseComponent({
    required this.origin,
    this.maxRadius = 250,
    this.growthSpeed = 200,
  }) {
    position = origin.clone();
    anchor = Anchor.center;
  }

  final Vector2 origin;
  final double maxRadius;
  final double growthSpeed;
  double currentRadius = 0;

  final Paint _paint = Paint()..color = GameColors.white.withValues(alpha: 0.9);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(
      Offset.zero,
      currentRadius,
      _paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    currentRadius += growthSpeed * dt;
    // Notify game to check what was hit
    try {
      (game as dynamic).onPulse(origin, currentRadius);
    } catch (_) {}

    if (currentRadius >= maxRadius) {
      removeFromParent();
    }
  }
}
