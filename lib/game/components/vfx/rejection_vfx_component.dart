import 'dart:math' as math;
import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// VFX del rechazo sónico (escudo defensivo).
/// Onda de choque expansiva sin sacudir la cámara.
class RejectionVfxComponent extends Component with HasGameRef<BlackEchoGame> {
  RejectionVfxComponent({required this.origin, this.duration = 0.5});

  final Vector2 origin;
  final double duration;
  double _elapsed = 0;

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final progress = math.min(_elapsed / duration, 1);
    final enfoque = game.gameBloc.state.enfoqueActual;
    
    // En first-person: renderizar como efecto de pantalla (flash de escudo)
    if (enfoque == Enfoque.firstPerson) {
      final viewport = game.camera.viewport.virtualSize;
      final alpha = (1.0 - progress) * 0.4; // Fade más intenso
      
      // Flash cian desde los bordes hacia el centro
      final paint = Paint()
        ..color = Color.fromRGBO(0, 255, 255, alpha)
        ..style = PaintingStyle.fill;
      
      // Viñeta inversa (más brillante en los bordes)
      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 1.5,
        colors: [
          const Color(0x00000000), // Transparent
          Color.fromRGBO(0, 255, 255, alpha * 0.8),
        ],
        stops: [1.0 - progress, 1.0],
      );
      
      paint.shader = gradient.createShader(
        Rect.fromLTWH(0, 0, viewport.x, viewport.y),
      );
      
      canvas.drawRect(
        Rect.fromLTWH(0, 0, viewport.x, viewport.y),
        paint,
      );
      
      // Líneas radiales desde el centro (efecto de impacto)
      final linePaint = Paint()
        ..color = Color.fromRGBO(0, 255, 255, alpha * 0.6)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      
      final centerX = viewport.x / 2;
      final centerY = viewport.y / 2;
      final lineLength = progress * (viewport.x / 2);
      
      for (var i = 0; i < 8; i++) {
        final angle = (i / 8) * 2 * math.pi;
        final endX = centerX + math.cos(angle) * lineLength;
        final endY = centerY + math.sin(angle) * lineLength;
        
        canvas.drawLine(
          Offset(centerX, centerY),
          Offset(endX, endY),
          linePaint,
        );
      }
      
      return;
    }
    
    // En top-down/side-scroll: renderizar como onda expansiva
    final radius = (80.0 * progress).toDouble();
    final alpha = (1.0 - progress) * 0.7;

    final paint = Paint()
      ..color = Color.fromRGBO(0, 255, 255, alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset(origin.x.toDouble(), origin.y.toDouble()), radius, paint);
  }
}
