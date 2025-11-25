import 'package:echo_world/game/components/lighting/light_source_component.dart';
import 'package:flame/components.dart';

/// Manages all active lights in the game.
/// Allows efficient querying of lights for rendering.
class LightingSystem extends Component {
  final List<LightSourceComponent> _lights = [];

  List<LightSourceComponent> get lights => _lights;

  @override
  void update(double dt) {
    super.update(dt);
    // Clean up removed lights
    _lights.removeWhere((l) => l.parent == null);
  }

  void registerLight(LightSourceComponent light) {
    if (!_lights.contains(light)) {
      _lights.add(light);
    }
  }

  void removeLight(LightSourceComponent light) {
    _lights.remove(light);
  }

  /// Returns lights sorted by distance to a target position.
  /// Useful for optimizing rendering (only render nearest lights).
  List<LightSourceComponent> getNearestLights(
    Vector2 target, {
    int limit = 10,
  }) {
    if (_lights.isEmpty) return [];

    // Sort by distance squared (faster)
    _lights.sort((a, b) {
      final distA = a.position.distanceToSquared(target);
      final distB = b.position.distanceToSquared(target);
      return distA.compareTo(distB);
    });

    if (_lights.length <= limit) return _lights;
    return _lights.sublist(0, limit);
  }
}
