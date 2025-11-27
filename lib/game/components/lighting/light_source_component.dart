import 'dart:math' as math;
import 'dart:ui';
import 'package:echo_world/game/black_echo_game.dart';
import 'package:flame/components.dart';

enum LightType { omni, spot }

/// A component that represents a dynamic light source in the game world.
/// Can be attached to any PositionComponent (Player, Enemy, Item).
class LightSourceComponent extends Component with HasGameRef<BlackEchoGame> {
  LightSourceComponent({
    this.color = const Color(0xFFFFFFFF),
    this.intensity = 1.0,
    this.radius = 100.0,
    this.type = LightType.omni,
    this.softness = 0.5,
    this.isPulsing = false,
    this.pulseSpeed = 1.0,
    this.pulseMinIntensity = 0.8,
    this.pulseMaxIntensity = 1.2,
  });

  Color color;
  double intensity;
  double radius;
  LightType type;

  /// How soft the light edge is (0.0 = hard edge, 1.0 = very soft)
  double softness;

  // Pulse effects
  bool isPulsing;
  double pulseSpeed;
  double pulseMinIntensity;
  double pulseMaxIntensity;

  double _time = 0;
  double _currentPulseFactor = 1;

  /// Returns the effective intensity including pulse effects
  double get effectiveIntensity => intensity * _currentPulseFactor;

  /// Returns the world position of the light.
  /// If attached to a PositionComponent, uses its position.
  Vector2 get position {
    if (parent is PositionComponent) {
      return (parent! as PositionComponent).position;
    }
    return Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isPulsing) {
      _time += dt * pulseSpeed;
      // Sine wave from -1 to 1
      final sine = math.sin(_time);
      // Map to 0..1
      final normalized = (sine + 1) / 2;
      // Lerp between min and max
      _currentPulseFactor =
          pulseMinIntensity +
          (pulseMaxIntensity - pulseMinIntensity) * normalized;
    } else {
      _currentPulseFactor = 1.0;
    }
  }

  @override
  void onMount() {
    super.onMount();
    // Auto-register with the lighting system
    // We access the game ref safely
    gameRef.lightingSystem.registerLight(this);
  }

  @override
  void onRemove() {
    gameRef.lightingSystem.removeLight(this);
    super.onRemove();
  }
}
