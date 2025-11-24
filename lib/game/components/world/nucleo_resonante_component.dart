import 'dart:ui';
import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

/// Comportamiento: Emite EstimuloDeSonido (Bajo) constante.
class NucleoResonanteComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<BlackEchoGame> {
  NucleoResonanteComponent({required super.position})
    : super(
        size: Vector2.all(20),
        anchor: Anchor.center,
      );

  // Temporizador para emitir sonido periódicamente
  double _soundTimer = 0;
  static const double _soundInterval = 0.8;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Hitbox circular para detección de colisión con jugador
    add(
      CircleHitbox(
        radius: size.x / 2,
        anchor: Anchor.center,
      )..position = size / 2,
    );

    // Efecto de pulso visual (escala 1.0 ↔ 1.3)
    add(
      ScaleEffect.by(
        Vector2.all(1.3),
        EffectController(
          duration: 0.8,
          alternate: true,
          infinite: true,
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Emitir sonido bajo periódicamente para atraer al jugador
    _soundTimer += dt;
    if (_soundTimer >= _soundInterval) {
      _soundTimer = 0.0;
      gameRef.emitSound(position.clone(), NivelSonido.bajo, ttl: 0.6);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // NO renderizar núcleo visual en first-person (el raycaster lo proyecta en 3D)
    if (gameRef.gameBloc.state.enfoqueActual == Enfoque.firstPerson) return;

    // Render procedural: círculo dorado (#FFD700) en top-down/side-scroll
    final center = size / 2;
    final radius = size.x / 2;

    // Relleno dorado
    final fillPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.x, center.y), radius, fillPaint);

    // Contorno naranja brillante para destacar
    final strokePaint = Paint()
      ..color = const Color(0xFFFF8C00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(center.x, center.y), radius, strokePaint);
  }
}
