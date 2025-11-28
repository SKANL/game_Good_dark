import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:echo_world/game/entities/player/behaviors/behaviors.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:echo_world/game/audio/audio_manager.dart';
import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/components/core/components.dart';
import 'package:echo_world/game/components/lighting/light_source_component.dart';
import 'package:echo_world/game/cubit/game/game_bloc.dart';
import 'package:echo_world/game/cubit/game/game_event.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:echo_world/game/entities/enemies/behaviors/hearing_behavior.dart';
import 'package:echo_world/game/entities/enemies/bruto.dart';
import 'package:echo_world/game/entities/enemies/cazador.dart';
import 'package:echo_world/game/entities/enemies/vigia.dart';

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
  String? _footstepLoopId; // Track footstep loop for instant stop

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
        intensity: 1.2, // Increased for 3D visibility
        radius: 400, // Increased for 3D visibility
        softness: 0.6,
        isPulsing: true,
        pulseSpeed: 2, // Heartbeat speed
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

  void jump() {
    final jb = children.whereType<JumpBehavior>().firstOrNull;
    jb?.triggerJump();
  }

  Future<void> rupture() async {
    final rb = children.whereType<RuptureBehavior>().firstOrNull;
    await rb?.triggerRupture();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_invulnerableTimer > 0) {
      _invulnerableTimer -= dt;
    }

    // --- Footstep Logic ---
    bool isMoving = false;

    // Check TopDown
    final td = children.whereType<TopDownMovementBehavior>().firstOrNull;
    if (td != null && td.velocity.length2 > 0.5) isMoving = true;

    // Check SideScroll
    final ss = children.whereType<SideScrollMovementBehavior>().firstOrNull;
    if (ss != null && ss.velocity.x.abs() > 0.5 && ss.isOnGround)
      isMoving = true;

    // Check FirstPerson
    final fp = children.whereType<FirstPersonMovementBehavior>().firstOrNull;
    if (fp != null && fp.velocity.length2 > 0.5) isMoving = true;

    // Start or stop footstep loop based on movement
    if (isMoving) {
      if (_footstepLoopId == null) {
        // Start footstep loop (fire-and-forget, no await in update)
        final soundId = gameBloc.state.estaAgachado
            ? 'footstep_stealth_01'
            : 'footstep_normal_01';
        final volume = gameBloc.state.estaAgachado ? 4.5 : 5.0;

        // Determine playback rate based on current focus
        // TopDown (enfoque 1) = 2x speed, others = normal speed
        final playbackRate = (td != null) ? 2.0 : 1.0;

        AudioManager.instance
            .startFootstepLoop(
              soundId: soundId,
              volume: volume,
              playbackRate: playbackRate,
            )
            .then((_) {
              _footstepLoopId = 'footstep_active';
            });
      }
    } else {
      // Stop footstep loop immediately when not moving
      if (_footstepLoopId != null) {
        AudioManager.instance.stopFootstepLoop();
        _footstepLoopId = null;
      }
    }

    // --- Ambient Sound Logic ---
    final noise = gameBloc.state.ruidoMental;
    if (noise > 75) {
      AudioManager.instance.playAmbient('amb_whispers_loop', volume: 0.4);
    } else if (noise > 40) {
      AudioManager.instance.playAmbient('amb_tinnitus_loop', volume: 0.2);
    } else {
      AudioManager.instance.stopAmbient();
    }

    // --- Dynamic Lighting Reaction ---
    final light = children.whereType<LightSourceComponent>().firstOrNull;
    if (light != null) {
      final state = gameBloc.state;

      // 1. Noise Reaction
      final noise = state.ruidoMental;
      light.pulseSpeed = 2.0 + (noise / 100.0) * 8.0;

      // 2. Energy Reaction
      final energy = state.energiaGrito;
      final energyFactor = (energy / 100.0).clamp(0.2, 1.0);
      light.intensity = 0.8 * energyFactor;
      light.radius = 100.0 + (50.0 * energyFactor);

      // 3. Health/Damage Reaction
      if (_invulnerableTimer > 0) {
        light.color = const Color(0xFFFF0000);
        light.intensity = 1.0;
      } else {
        light.color = const Color(0xFF00FFFF);
      }
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
          ..color = const Color(0xFFFF0000).withValues(alpha: 0.5)
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

          // Aturdir al enemigo (BUFF: 4.0s)
          hearing.stun(4);

          // KNOCKBACK: Push enemy away
          final dir = (enemy.position - position).normalized();
          hearing.pushBack(dir, 500);

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
          hearing.stun(3);

          // KNOCKBACK: Push enemy away (weaker)
          final dir = (enemy.position - position).normalized();
          hearing.pushBack(dir, 300);

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
