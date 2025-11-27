import 'game_constants.dart';

class Trap {
  Trap({
    required this.x,
    required this.y,
    required this.type,
    this.width = GameConstants.tileSize,
    this.height = GameConstants.tileSize,
    this.isActive = true,
    this.isTriggered = false,
    this.triggerDistance = GameConstants.proximityDistance,
    this.speedMultiplier,
    this.collapseTimer = 0,
  });
  double x;
  double y;
  final double width;
  final double height;
  final TrapType type;
  bool isActive;
  bool isTriggered;
  double triggerDistance;
  double? speedMultiplier;
  double collapseTimer;

  void update(double playerX, double playerY) {
    switch (type) {
      case TrapType.proximitySpike:
        final distance = _distance(playerX, playerY, x, y);
        if (distance < triggerDistance) {
          isTriggered = true;
        }
      case TrapType.fallingCeiling:
        if (isTriggered) {
          y += GameConstants.ceilingFallSpeed;
        }
      case TrapType.collapsingPlatform:
        if (isTriggered) {
          collapseTimer += 0.016;
          if (collapseTimer > GameConstants.collapseDelay) {
            isActive = false;
          }
        }
      default:
        break;
    }
  }

  double _distance(double x1, double y1, double x2, double y2) {
    return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2);
  }

  bool checkCollision(double px, double py, double pw, double ph) {
    return px < x + width && px + pw > x && py < y + height && py + ph > y;
  }
}
