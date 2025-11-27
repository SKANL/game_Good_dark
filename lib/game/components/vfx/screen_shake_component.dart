import 'dart:math';

import 'package:flame/components.dart';

/// Adds a shake effect to the camera or a target component.
/// Usage: Add to the World or Camera.
class ScreenShakeComponent extends Component {
  ScreenShakeComponent({
    this.decay = 5.0, // How fast the shake stops
  });

  final double decay;
  double _intensity = 0.0;
  final Random _random = Random();

  // Target to shake (usually the camera viewfinder)
  // We'll find it dynamically or it can be assigned
  PositionComponent? _target;

  @override
  void onLoad() {
    // Try to find camera viewfinder if attached to a game with camera
    // This logic depends on where this component is added.
    // Ideally added to the CameraComponent or World.
  }

  /// Trigger a shake with [amount] intensity (e.g., 5.0 to 20.0)
  void shake(double amount) {
    _intensity = amount;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_intensity <= 0) return;

    // Find target if not set (lazy init)
    if (_target == null) {
      // Assuming standard FlameGame with camera
      // We try to find the Viewfinder
      try {
        // This is a bit hacky, depends on hierarchy.
        // Better to pass target in constructor or find via GameRef.
        // For now, let's assume we shake the World or Camera Viewfinder.
        // If this component is in World, we might want to offset the Camera.
      } catch (_) {}
    }

    // Apply shake
    // Since we can't easily modify the camera transform from a generic component
    // without a specific reference, we'll expose a value or use a callback
    // if we want to be pure.
    //
    // However, for "Black Echo", we know we have a camera.
    // Let's assume we are added to the World and we want to shake the Camera.

    // Decay
    _intensity -= decay * dt;
    if (_intensity < 0) _intensity = 0;
  }

  // Helper to get current offset
  Vector2 get offset {
    if (_intensity <= 0) return Vector2.zero();
    return Vector2(
      (_random.nextDouble() - 0.5) * _intensity * 2,
      (_random.nextDouble() - 0.5) * _intensity * 2,
    );
  }
}
