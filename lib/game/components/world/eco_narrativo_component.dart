import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/cubit/game/game_event.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:echo_world/game/entities/player/player.dart';
import 'package:echo_world/lore/cubit/cubit.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Componente visible que representa un Eco Narrativo (lore point).
/// Solo se revela al usar [ECO]. Al colisionar con el jugador, desbloquea
/// el lore asociado y aumenta el ruidoMental.
class EcoNarrativoComponent extends PositionComponent
  with CollisionCallbacks, HasGameRef<BlackEchoGame> {
  EcoNarrativoComponent({
    required this.ecoId,
    required Vector2 position,
  }) : super(
         position: position,
         size: Vector2.all(20),
         anchor: Anchor.center,
       );

  /// ID único del eco para el LoreBloc
  final String ecoId;

  /// Controla si el eco ha sido absorbido (usado una sola vez)
  bool _absorbido = false;

  /// Controla si el eco está visible (revelado por [ECO])
  bool _revelado = false;

  /// Temporizador de visibilidad tras [ECO] (2.0s)
  double _tiempoVisible = 0;

  static const double _duracionVisibilidad = 2;

  final Paint _paintGlifo = Paint()
    ..color =
        const Color(0xFF8A2BE2) // Púrpura
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  final Paint _paintFill = Paint()..color = const Color(0x33000000); // Sombra sutil

  @override
  Future<void> onLoad() async {
    await add(CircleHitbox(radius: size.x * 0.5, anchor: Anchor.center));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_revelado) {
      _tiempoVisible += dt;
      if (_tiempoVisible >= _duracionVisibilidad) {
        _revelado = false;
        _tiempoVisible = 0.0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // NO renderizar en first-person: el raycaster maneja la vista 3D
    if (gameRef.gameBloc.state.enfoqueActual == Enfoque.firstPerson) return;
    
    // Solo renderizar si está revelado por ECO
    if (!_revelado) return;

    final opacity = 1.0 - (_tiempoVisible / _duracionVisibilidad);
    _paintGlifo.color = const Color(0xFF8A2BE2).withValues(alpha: opacity);
    _paintFill.color = const Color(0x33000000).withValues(alpha: opacity * 0.5);

    // Círculo de fondo
    canvas.drawCircle(Offset.zero, size.x * 0.5, _paintFill);
    canvas.drawCircle(Offset.zero, size.x * 0.5, _paintGlifo);

    // Glifo "§" (símbolo de narrativa)
    final textPainter = TextPainter(
      text: TextSpan(
        text: '§',
        style: TextStyle(
          color: const Color(0xFF8A2BE2).withValues(alpha: opacity),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }

  /// Llamado externamente cuando [ECO] se activa
  void revelar() {
    _revelado = true;
    _tiempoVisible = 0.0;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (_absorbido) return;

    if (other is PlayerComponent) {
      // Solo permitir absorción si el eco está revelado
      if (!_revelado) return;

      _absorbido = true;

      // Enviar evento al GameBloc (aumenta ruidoMental +1)
      gameRef.gameBloc.add(EcoNarrativoAbsorbido(ecoId, 1));

      // Desbloquear en LoreBloc
      gameRef.loreBloc.add(DesbloquearEco(ecoId));

      // Destruir el componente
      removeFromParent();
    }
  }
}
