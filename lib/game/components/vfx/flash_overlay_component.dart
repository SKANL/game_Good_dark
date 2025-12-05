import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';

class FlashOverlayComponent extends PositionComponent with HasGameRef {
  FlashOverlayComponent({
    this.color = const Color(0xFFFFFFFF),
    this.duration = 0.15,
  }) : super(priority: 1000); // High priority to draw over everything

  final Color color;
  final double duration;

  @override
  Future<void> onLoad() async {
    // Cover the entire viewport
    this.size = size;
    children.whereType<RectangleComponent>().forEach((r) => r.size = size);
  }
}
