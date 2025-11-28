import 'dart:math' as math;
import 'package:echo_world/game/black_echo_game.dart';
import 'package:flame/components.dart';

class InputManager extends Component with HasGameRef<BlackEchoGame> {
  /// Zona muerta (deadzone) para evitar movimientos involuntarios
  static const double _deadzone = 0.15;

  /// Obtiene el movimiento del joystick con zona muerta aplicada y suavizado
  Vector2 get movement {
    // Usar el input virtual que viene desde Flutter (GamePage)
    // Esto desacopla el input del renderizado de Flame, solucionando problemas de visibilidad
    final raw = game.virtualJoystickInput.clone();
    var magnitude = raw.length;

    // Si está dentro de la zona muerta, no hay movimiento
    if (magnitude < _deadzone) {
      return Vector2.zero();
    }

    // Asegurar que la magnitud esté en [0,1]. En algunos entornos el delta
    // puede venir en píxeles o en un rango mayor a 1; lo normalizamos aquí.
    if (magnitude > 1.0) {
      raw.setFrom(raw.normalized());
      magnitude = 1.0;
    }

    // Normalizar y aplicar curva de suavizado
    // Mapear de [deadzone, 1.0] a [0.0, 1.0]
    final normalizedMagnitude = ((magnitude - _deadzone) / (1.0 - _deadzone))
        .clamp(0.0, 1.0);

    // Aplicar curva cuadrática para mejor control (menos sensible cerca del centro)
    final smoothedMagnitude = math.pow(normalizedMagnitude, 1.5).toDouble();

    // Devolver el vector con magnitud suavizada y en el rango [-1,1]
    return raw.normalized() * smoothedMagnitude;
  }

  @override
  Future<void> onLoad() async {
    // Ya no necesitamos JoystickComponent de Flame
    // El input viene externamente desde game.virtualJoystickInput
  }
}
