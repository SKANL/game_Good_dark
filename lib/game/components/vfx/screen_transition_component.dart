import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class ScreenTransitionComponent extends Component with HasGameRef<FlameGame> {
  ScreenTransitionComponent({
    required this.onTransition,
    this.duration = 0.5,
    this.color = const Color(0xFF000000),
  });

  final VoidCallback onTransition;
  final double duration;
  final Color color;

  double _time = 0;
  bool _transitionTriggered = false;
  late final double _halfDuration = duration / 2;

  @override
  int get priority => 2000;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    if (_time >= _halfDuration && !_transitionTriggered) {
      onTransition();
      _transitionTriggered = true;
    }

    if (_time >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Calculate opacity: 0 -> 1 -> 0
    double opacity = 0.0;
    if (_time < _halfDuration) {
      opacity = _time / _halfDuration;
    } else {
      opacity = 1.0 - ((_time - _halfDuration) / _halfDuration);
    }
    opacity = opacity.clamp(0.0, 1.0);

    if (opacity <= 0) return;

    // Draw full screen rect
    final size = game.canvasSize;
    // Ensure we cover the whole screen even if camera moves (though this is HUD-like)
    // Since we are a Component (not PositionComponent attached to HUD), we might be affected by camera if added to world.
    // But we will add this to the GAME directly (like RaycastRenderer), so coordinate system is canvas.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = color.withOpacity(opacity),
    );
  }
}
