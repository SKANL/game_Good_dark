import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/components/core/components.dart';
import 'package:echo_world/game/cubit/game/game_bloc.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:echo_world/game/cubit/game/game_event.dart';
import 'package:echo_world/game/entities/player/behaviors/behaviors.dart';
import 'package:echo_world/game/entities/player/behaviors/rupture_behavior.dart';
import 'package:echo_world/game/entities/enemies/cazador.dart';
import 'package:echo_world/game/entities/enemies/vigia.dart';
import 'package:echo_world/game/entities/enemies/bruto.dart';
import 'package:echo_world/game/entities/enemies/behaviors/hearing_behavior.dart';
import 'package:echo_world/game/audio/audio_manager.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:echo_world/game/components/lighting/light_source_component.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flutter/painting.dart';

class PlayerComponent extends PositionedEntity
    with CollisionCallbacks, HasGameRef<BlackEchoGame> {
  PlayerComponent({
    required this.gameBloc,
    Vector2? position,
    Vector2? size,
    Anchor anchor = Anchor.center,
    List<Behavior>? behaviors,
  }) : _paint = (Paint()
         ..color = const Color(0xFF00FFFF)
         ..style = PaintingStyle.stroke
         ..strokeWidth = 2.5),
       super(
         position: position ?? Vector2.zero(),
         size: size ?? Vector2.all(24),
         anchor: anchor,
         behaviors: behaviors ?? <Behavior>[],
       );
  // Heading in radians for FP mode
  double heading = 0;
  final GameBloc gameBloc;
  final Paint _paint;
  double _invulnerableTimer = 0;

  @override
  Future<void> onLoad() async {
    add(
      RectangleHitbox.relative(
        Vector2.all(0.8),
        parentSize: size,
        anchor: Anchor.center,
      ),
    );
    setEnfoque(gameBloc.state.enfoqueActual);

    // Add Player Light Source (Flashlight / Aura)
    add(
      LightSourceComponent(
        color: const Color(0xFF00FFFF), // Cyan aura
        intensity: 0.8,
        radius: 150,
        softness: 0.8,
        isPulsing: true,
        pulseSpeed: 2.0, // Heartbeat speed
        pulseMinIntensity: 0.7,
        pulseMaxIntensity: 1.0,
      ),
    );
  }

  /// Rectángulo de colisión estandarizado para todos los behaviors.
  /// Usa el 80% del tamaño visual para evitar enganches en esquinas.
  Rect get collisionRect {
    final reducedSize = size * 0.8;
    final half = reducedSize / 2;
    return Rect.fromLTWH(
      position.x - half.x,
      position.y - half.y,
      reducedSize.x,
      reducedSize.y,
    );
  }

  void setEnfoque(Enfoque nuevo) {
    // Limpiar behaviors de movimiento/acción
    final current = children.whereType<Behavior>().toList();
    for (final b in current) {
      remove(b);
    }

    switch (nuevo) {
      case Enfoque.topDown:
        add(TopDownMovementBehavior(gameBloc: gameBloc));
        add(EcholocationBehavior(gameBloc: gameBloc));
        add(RuptureBehavior(gameBloc: gameBloc));
        add(StealthBehavior(gameBloc: gameBloc));
      case Enfoque.sideScroll:
        add(SideScrollMovementBehavior(gameBloc: gameBloc));
        add(GravityBehavior());
        add(JumpBehavior(gameBloc: gameBloc));
        add(RuptureBehavior(gameBloc: gameBloc));
        add(StealthBehavior(gameBloc: gameBloc));
      case Enfoque.firstPerson:
        // Movimiento FP: solo adelante/atrás y rotación
        add(FirstPersonMovementBehavior(gameBloc: gameBloc));
        add(EcholocationBehavior(gameBloc: gameBloc));
        add(RuptureBehavior(gameBloc: gameBloc));
        add(StealthBehavior(gameBloc: gameBloc));
      default:
        // Enfoque.scan y otros futuros
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    if (gameBloc.state.enfoqueActual == Enfoque.firstPerson) return;

    // Debug: Draw collision rect
    if (debugMode) {
      canvas.drawRect(
        Rect.fromLTWH(
          (size.x - collisionRect.width) / 2,
          (size.y - collisionRect.height) / 2,
          collisionRect.width,
          collisionRect.height,
        ),
        Paint()
          ..color = const Color(0xFFFF0000).withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    if (_invulnerableTimer > 0) {
      // Flicker effect: 50% opacity every 0.1s
      if ((_invulnerableTimer * 10).toInt() % 2 == 0) return;
    }

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      _paint,
    );
  }

  void jump() {
    final jb = findBehavior<JumpBehavior>();
    jb.triggerJump();
  }

  Future<void> rupture() async {
    final rb = findBehavior<RuptureBehavior>();
    await rb.triggerRupture();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_invulnerableTimer > 0) {
      _invulnerableTimer -= dt;
    }

    // --- Dynamic Lighting Reaction ---
    final light = children.whereType<LightSourceComponent>().firstOrNull;
    if (light != null) {
      final state = gameBloc.state;

      // 1. Noise Reaction (Ruido Mental) -> Pulse Speed & Instability
      // Higher noise = faster, more erratic pulse
      final noise = state.ruidoMental;
      light.pulseSpeed = 2.0 + (noise / 100.0) * 8.0; // 2.0 to 10.0

      // 2. Energy Reaction (Energía Grito) -> Intensity & Radius
      // Low energy = dim light (dying battery feel)
      final energy = state.energiaGrito;
      final energyFactor = (energy / 100.0).clamp(0.2, 1.0);
      light.intensity = 0.8 * energyFactor;
      light.radius = 100.0 + (50.0 * energyFactor);

      // 3. Health/Damage Reaction -> Color Tint?
      // Maybe turn red if hit? For now, let's keep it Cyan but flicker if invulnerable
      if (_invulnerableTimer > 0) {
        light.color = const Color(0xFFFF0000); // Red alert
        light.intensity = 1.0; // Bright flash
      } else {
        light.color = const Color(0xFF00FFFF); // Normal Cyan
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // Colisión con Núcleo Resonante (Canibalismo Energético)
    if (other is NucleoResonanteComponent) {
      gameBloc.add(ColisionConNucleoIniciada());
      return;
    }

    // Colisión con Resonancias (Cazador, Vigía, Bruto)
    if (other is CazadorComponent ||
        other is VigiaComponent ||
        other is BrutoComponent) {
      final enemy = other as PositionedEntity;
      final hearing = enemy.findBehavior<HearingBehavior>();

      if (hearing.estadoActual == AIState.caza) {
        if (_invulnerableTimer > 0) return; // Ignore hits while invulnerable

        // Verificar si tiene escudo (energía >= 50)
        if (gameBloc.state.energiaGrito >= 50) {
          // SFX: reproducir sonido de escudo sónico
          AudioManager.instance.playSfx('rejection_shield', volume: 0.9);

          // Activar rechazo sónico (escudo)
          gameBloc.add(const RechazoSonicoActivado(50));

          // Aturdir al enemigo (BUFF: 4.0s)
          hearing.stun(4.0);

          // KNOCKBACK: Push enemy away
          final dir = (enemy.position - position).normalized();
          hearing.applyKnockback(dir, 500);

          // Invulnerabilidad post-escudo
          _invulnerableTimer = 2.0;

          // VFX: onda de choque expansiva
          parent?.add(RejectionVfxComponent(origin: position.clone()));

          // Emitir sonido alto para atraer otros enemigos
          game.emitSound(position.clone(), NivelSonido.alto, ttl: 1.5);
        } else if (gameBloc.state.energiaGrito > 0) {
          // MERCY SYSTEM: Desperate Push
          // Si tiene algo de energía pero < 50, sobrevive con 0 energía
          AudioManager.instance.playSfx('rejection_shield', volume: 0.6);

          // Consumir TODA la energía restante
          gameBloc.add(RechazoSonicoActivado(gameBloc.state.energiaGrito));

          // Aturdir brevemente (BUFF: 3.0s)
          hearing.stun(3.0);

          // KNOCKBACK: Push enemy away (weaker)
          final dir = (enemy.position - position).normalized();
          hearing.applyKnockback(dir, 300);

          // Invulnerabilidad breve
          _invulnerableTimer = 1.0;

          // VFX menor
          parent?.add(RejectionVfxComponent(origin: position.clone()));
        } else {
          // Game Over: energía insuficiente (0 exacto)
          gameBloc.add(JugadorAtrapado());
        }
      }
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    // Jugador sale del radio del Núcleo
    if (other is NucleoResonanteComponent) {
      gameBloc.add(ColisionConNucleoTerminada());
    }
  }
}
