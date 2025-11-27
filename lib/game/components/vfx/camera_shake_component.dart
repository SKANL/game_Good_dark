import 'dart:math';

import 'package:echo_world/game/black_echo_game.dart';
import 'package:flame/components.dart';

class CameraShakeComponent extends Component with HasGameRef<BlackEchoGame> {
  CameraShakeComponent({required this.duration, required this.intensity});

  final double duration; // seconds
  final double intensity; // pixels

  double _t = 0;
  Vector2? _originalPos;
  final _rng = Random();

  @override
  Future<void> onLoad() async {
    // _originalPos is initialized in update to capture current camera position
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t >= duration) {
      if (_originalPos != null) {
        game.camera.viewfinder.position.setFrom(_originalPos!);
        _originalPos = null;
      }
      removeFromParent();
    } else {
      _originalPos ??= game.camera.viewfinder.position.clone();

      final offset = Vector2(
        (_rng.nextDouble() - 0.5) * intensity,
        (_rng.nextDouble() - 0.5) * intensity,
      );

      game.camera.viewfinder.position.setFrom(_originalPos! + offset);
    }
  }
}
