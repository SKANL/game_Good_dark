import 'package:flame/components.dart';
import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import '../entities/colors.dart';
import 'fuga_pulse_component.dart';
import 'fuga_wall_component.dart';

/// Simple player represented as a circle. Movement handled externally or via
/// `moveTo`. Keeps responsibilities small: visual + ping action.
class FugaPlayerComponent extends CircleComponent with CollisionCallbacks {
  FugaPlayerComponent({required Vector2 position})
    : super(radius: 8, position: position, anchor: Anchor.center) {
    paint = Paint()..color = GameColors.white;
  }

  FlameGame? owner;

  double speed = 120; // units per second (tweak later)
  Vector2? _moveDirection; // normalized direction vector from virtual joystick
  Vector2? _prevPosition;

  /// collision radius in world units (same as radius)
  double get collisionRadius => radius;

  /// Sistema de cargas para Grito de Ruptura
  int _charges = 1; // Empezamos con 1 carga (según GDD Acto 1)
  int get charges => _charges;
  int get maxCharges => 3;

  bool canUseRupture() => _charges > 0;

  void useCharge() {
    if (_charges > 0) {
      _charges--;
    }
  }

  void addCharge() {
    if (_charges < maxCharges) {
      _charges++;
    }
  }

  /// Called by HUD or input system to set movement direction. Pass null to stop.
  void setMoveDirection(Vector2? dir) {
    _moveDirection = dir?.normalized();
  }

  void ping() {
    // spawn a pulse at center
    final p = FugaPulseComponent(origin: center);
    try {
      owner?.add(p);
    } catch (_) {}
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_moveDirection != null) {
      _prevPosition = position.clone();
      position += _moveDirection! * speed * dt;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is FugaWallComponent) {
      if (_prevPosition != null) {
        position.setFrom(_prevPosition!);
      }
    }
  }

  // legacy collision helper removed in favor of Flame hitboxes

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Add a circular hitbox matching this component's size
    // Add a circular hitbox sized to this component.
    add(CircleHitbox(radius: radius));
  }
}
