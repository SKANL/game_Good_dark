import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/collisions.dart';
import '../entities/colors.dart';

/// Simple wall represented by a rectangle. It reacts to pings by flashing.
class FugaWallComponent extends PositionComponent with CollisionCallbacks {
  FugaWallComponent({
    required Vector2 position,
    required Vector2 size,
    this.isFragile = false,
  }) {
    this.position = position;
    this.size = size;
    anchor = Anchor.topLeft;
  }

  final bool isFragile;
  double _opacity = 0.0;
  final double _fadeSpeed = 0.7; // seconds to fade

  final Paint _basePaint = Paint()..color = GameColors.white;

  void onPing() {
    _opacity = 1.0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = _basePaint
      ..color = _basePaint.color.withValues(alpha: _opacity);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_opacity > 0) {
      _opacity -= dt / _fadeSpeed;
      if (_opacity < 0) _opacity = 0;
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Add a rectangular hitbox matching the wall's size
    add(RectangleHitbox(size: size));
  }
}
