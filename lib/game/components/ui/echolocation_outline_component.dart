import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Componente que renderiza el contorno iluminado de una entidad
/// después de ser "tocado" por un pulso de ecolocalización.
/// Se desvanece gradualmente en 2.0 segundos.
class EcholocationOutlineComponent extends PositionComponent
  with HasGameRef<BlackEchoGame> {
  EcholocationOutlineComponent({
    required this.targetPath,
    required Vector2 position,
    this.duration = 2.0,
  }) : super(position: position, anchor: Anchor.topLeft);

  final Path targetPath;
  final double duration;
  double _elapsed = 0;

  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = const Color(0xFF00FFFF);

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // NO renderizar contornos visuales en first-person (el raycaster maneja la vista 3D)
    if (game.gameBloc.state.enfoqueActual == Enfoque.firstPerson) return;
    
    final alpha = (1.0 - (_elapsed / duration)).clamp(0.0, 1.0);
    final paint = _paint..color = _paint.color.withValues(alpha: alpha);
    canvas.drawPath(targetPath, paint);
  }
}
