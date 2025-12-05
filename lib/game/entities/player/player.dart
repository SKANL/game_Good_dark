import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
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

  Future<bool> rupture() async {
    final rb = children.whereType<RuptureBehavior>().firstOrNull;
    if (rb == null) return false;
    return await rb.triggerRupture();
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
    // Moved to BlackEchoGame for centralized atmosphere management

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

    // --- Continuous Collision Check (Enemies) ---
    // Check for collisions manually to handle continuous contact during invulnerability
    if (_invulnerableTimer <= 0) {
      final enemies = gameRef.world.children.query<PositionedEntity>();
      for (final other in enemies) {
        if (other is CazadorComponent ||
            other is VigiaComponent ||
            other is BrutoComponent) {
          // Simple distance check (radius based) for performance
          // Assuming average enemy radius ~16 and player ~12 -> 28 threshold
          if (position.distanceTo(other.position) < 28) {
            final enemy = other;
            final hearing = enemy.findBehavior<HearingBehavior>();

            if (hearing.estadoActual == AIState.caza) {
              _handleEnemyCollision(enemy, hearing);
              break; // Handle one collision per frame max
            }
          }
        }
      }
    }
  }

  void _handleEnemyCollision(PositionedEntity enemy, HearingBehavior hearing) {
    // 1. DEFENSA PERFECTA (Escudo Sónico)
    // Condición: Energía >= 50
    if (gameBloc.state.energiaGrito >= 50) {
      // SFX: reproducir sonido de escudo sónico
      AudioManager.instance.playSfx('rejection_shield', volume: 0.9);

      // Consumir energía
      gameBloc.add(RechazoSonicoActivado(50));

      // Aturdir al enemigo (BUFF: 4.0s)
      // hearing.stun(4); // Removed single target stun

      // KNOCKBACK: Push enemy away (AoE for Shield too)
      // OLD: final dir = (enemy.position - position).normalized();
      // OLD: hearing.pushBack(dir, 500);

      // --- EFECTO DE ÁREA (AoE) ESCUDO ---
      // Empujar a todos los enemigos cercanos (Radio 180 - Menor que Mercy pero suficiente para despejar)
      final enemies = gameRef.world.children.query<PositionedEntity>();
      for (final e in enemies) {
        if (e is CazadorComponent ||
            e is BrutoComponent ||
            e is VigiaComponent) {
          final dist = position.distanceTo(e.position);
          if (dist < 180) {
            final eHearing = e.findBehavior<HearingBehavior>();

            // Stun largo (4s) para el escudo
            eHearing.stun(4.0);

            // Empuje
            final pushDir = (e.position - position).normalized();
            eHearing.pushBack(pushDir, 500);
          }
        }
      }

      // Invulnerabilidad post-escudo
      _invulnerableTimer = 2.0;

      // VFX: onda de choque expansiva
      parent?.add(RejectionVfxComponent(origin: position.clone()));

      // Camera Shake (Leve)
      gameRef.camera.viewfinder.add(
        MoveEffect.by(
          Vector2(5, 5),
          EffectController(
            duration: 0.2,
            alternate: true,
            repeatCount: 3,
          ),
        ),
      );

      // Emitir sonido alto para atraer otros enemigos (riesgo táctico)
      game.emitSound(position.clone(), NivelSonido.alto, ttl: 1.5);
    }
    // 2. SOBRECARGA DE RESONANCIA (Mercy 2.0)
    // Condición: 0 < Energía < 50
    else if (gameBloc.state.energiaGrito > 0) {
      // SFX: Sonido de escudo pero más agudo/distorsionado (si fuera posible)
      AudioManager.instance.playSfx('rejection_shield', volume: 1.0);

      // Consumir TODA la energía restante
      gameBloc.add(RechazoSonicoActivado(gameBloc.state.energiaGrito));

      // --- EFECTO DE ÁREA (AoE) ---
      // Buscar TODOS los enemigos cercanos en un radio de 250px
      final enemies = gameRef.world.children.query<PositionedEntity>();

      for (final e in enemies) {
        if (e is CazadorComponent ||
            e is BrutoComponent ||
            e is VigiaComponent) {
          final dist = position.distanceTo(e.position);
          if (dist < 250) {
            final eHearing = e.findBehavior<HearingBehavior>();

            // AMNESIA TÁCTICA: Confundir al enemigo
            eHearing.confuse(3.0);

            // EMPUJE MASIVO
            final pushDir = (e.position - position).normalized();
            eHearing.pushBack(
              pushDir,
              600,
            ); // Fuerza mayor que el escudo normal
          }
        }
      }

      // Invulnerabilidad (2.0s para huir)
      _invulnerableTimer = 2.0;

      // VFX: Sobrecarga (RejectionVfx más grande o doble)
      parent?.add(
        RejectionVfxComponent(origin: position.clone(), radius: 250),
      );

      // GAME FEEL: Flash Blanco (Overlay)
      gameRef.triggerFlash();

      // GAME FEEL: Camera Shake (Intenso)
      gameRef.camera.viewfinder.add(
        MoveEffect.by(
          Vector2(10, 10),
          EffectController(
            duration: 0.1,
            alternate: true,
            repeatCount: 5,
          ),
        ),
      );
    }
    // 3. MUERTE (Game Over)
    // Condición: Energía == 0
    else {
      // Game Over instantáneo
      gameBloc.add(JugadorAtrapado());
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
    // MOVIDO A UPDATE: Para manejar contacto continuo si el jugador es invulnerable al inicio.
    /*
    if (other is CazadorComponent ||
        other is VigiaComponent ||
        other is BrutoComponent) {
       ... logic moved ...
    }
    */
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
