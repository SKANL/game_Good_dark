import 'dart:ui';
import 'package:flame/components.dart';
import '../entities/colors.dart';

/// Shockwave visual effect for the Grito de Ruptura.
/// Expands rapidly with high visual impact (white, thick stroke).
class FugaShockwaveComponent extends PositionComponent {
  FugaShockwaveComponent({
    required Vector2 origin,
    this.maxRadius = 300,
    this.growthSpeed = 1500, // muy rápido para efecto impactante
  }) {
    position = origin.clone();
    anchor = Anchor.center;
  }

  final double maxRadius;
  final double growthSpeed;
  double currentRadius = 0;

  final Paint _paint = Paint()
    ..color = GameColors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Dibuja múltiples anillos para efecto de distorsión
    final opacity = 1.0 - (currentRadius / maxRadius);
    _paint.color = GameColors.white.withValues(alpha: opacity);

    canvas.drawCircle(Offset.zero, currentRadius, _paint);
    // Anillo interno para más impacto
    if (currentRadius > 10) {
      canvas.drawCircle(
        Offset.zero,
        currentRadius * 0.7,
        _paint..strokeWidth = 2,
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    currentRadius += growthSpeed * dt;

    if (currentRadius >= maxRadius) {
      removeFromParent();
    }
  }
}
