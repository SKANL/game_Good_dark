import 'dart:math' as math;
import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Retícula central (crosshair) para la perspectiva first-person.
/// Se renderiza en el centro exacto del viewport con animación pulsante.
class CrosshairComponent extends Component with HasGameRef<BlackEchoGame> {
  CrosshairComponent();

  double _pulseTime = 0.0;
  static const double pulseSpeed = 2.0; // Hz

  @override
  int get priority => 1000; // Renderizar por encima de todo
  
  @override
  void update(double dt) {
    super.update(dt);
    _pulseTime += dt * pulseSpeed;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Solo renderizar en first-person
    if (gameRef.gameBloc.state.enfoqueActual != Enfoque.firstPerson) return;

    // Obtener el centro del viewport y factor de escala relativo al alto lógico
    final viewportSize = gameRef.camera.viewport.virtualSize;
    final centerX = viewportSize.x / 2;
    final centerY = viewportSize.y / 2;
    final scale = (viewportSize.y / 360.0).clamp(0.7, 1.5);

    // Pulso suave (0.8 a 1.0)
    final pulse = 0.8 + (math.sin(_pulseTime * math.pi * 2) * 0.1);
    final alpha = 0.8 + (math.sin(_pulseTime * math.pi * 2) * 0.2);

    final paint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, alpha) // Blanco pulsante
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale.clamp(1, 3);

    // Dibujar cruz central con tamaño pulsante
    final crosshairSize = 10.0 * pulse * scale;
    final gap = 3.0 * scale;

    // Línea horizontal izquierda
    canvas.drawLine(
      Offset(centerX - crosshairSize - gap, centerY),
      Offset(centerX - gap, centerY),
      paint,
    );

    // Línea horizontal derecha
    canvas.drawLine(
      Offset(centerX + gap, centerY),
      Offset(centerX + crosshairSize + gap, centerY),
      paint,
    );

    // Línea vertical superior
    canvas.drawLine(
      Offset(centerX, centerY - crosshairSize - gap),
      Offset(centerX, centerY - gap),
      paint,
    );

    // Línea vertical inferior
    canvas.drawLine(
      Offset(centerX, centerY + gap),
      Offset(centerX, centerY + crosshairSize + gap),
      paint,
    );

    // Punto central con glow
    final glowPaint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, alpha * 0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawCircle(Offset(centerX, centerY), 3 * scale, glowPaint);
    
    // Punto central sólido
    final dotPaint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, alpha)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 1.5 * scale, dotPaint);
  }
}
