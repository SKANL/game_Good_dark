import 'dart:math' as math;
import 'package:echo_world/game/black_echo_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

class InputManager extends Component with HasGameRef<BlackEchoGame> {
  late final JoystickComponent _joystick;

  /// Zona muerta (deadzone) para evitar movimientos involuntarios
  static const double _deadzone = 0.15;

  /// Obtiene el movimiento del joystick con zona muerta aplicada y suavizado
  Vector2 get movement {
    // Tomar delta crudo y proteger contra valores fuera de rango
    final raw = _joystick.delta.clone();
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
    _joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 28,
        paint: Paint()..color = const Color(0x9900FFFF),
      ),
      background: CircleComponent(
        radius: 56,
        paint: Paint()..color = const Color(0x6600FFFF),
      ),
      margin: const EdgeInsets.only(left: 20, bottom: 20),
      priority: 20000, // Máximo para renderizar sobre absolutamente todo
    );
    // _joystick.positionType = PositionType.viewport; // Removed as it is not a valid setter
    // Agregar al game directamente, no al viewport
    // Esto evita que el joystick afecte el layout del viewport de renderizado
    await game.add(_joystick);
  }
}
