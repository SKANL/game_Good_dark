import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class AbyssComponent extends PositionComponent with HasGameRef<BlackEchoGame> {
  AbyssComponent({required Vector2 position, required Vector2 size})
    : super(position: position, size: size, anchor: Anchor.topLeft);

  final Paint _fill = Paint()..color = const Color(0xFF101010);
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = const Color(0xFF005566);

  @override
  void render(Canvas canvas) {
    // NO renderizar abismo visual en first-person (el raycaster maneja la geometría)
    if (gameRef.gameBloc.state.enfoqueActual == Enfoque.firstPerson) return;
    
    final rect = Offset.zero & Size(size.x, size.y);
    canvas.drawRect(rect, _fill);
    canvas.drawRect(rect, _stroke);
  }
}
