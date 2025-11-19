import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/components/components.dart';
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
import 'package:echo_world/game/level/level_models.dart';
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

  @override
  Future<void> onLoad() async {
    await add(RectangleHitbox(size: size, anchor: Anchor.center));
    setEnfoque(gameBloc.state.enfoqueActual);
  }

  void setEnfoque(Enfoque nuevo) {
    // Limpiar behaviors de movimiento/acción
    final current = children.whereType<Behavior>().toList();
    for (final b in current) {
      remove(b);
    }
    // OBSOLETO: Si existen behaviors que no se usan en ningún enfoque, comentar aquí para futura eliminación.

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
    // NO renderizar en first-person: el raycaster proyecta la vista desde el jugador
    if (gameBloc.state.enfoqueActual == Enfoque.firstPerson) return;

    // Render simple del jugador: círculo cyan (solo en top-down y side-scroll)
    canvas.drawCircle(Offset.zero, size.x * 0.5, _paint);
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
        // Verificar si tiene escudo (energía >= 50)
        if (gameBloc.state.energiaGrito >= 50) {
          // SFX: reproducir sonido de escudo sónico
          AudioManager.instance.playSfx('rejection_shield', volume: 0.9);

          // Activar rechazo sónico (escudo)
          gameBloc.add(const RechazoSonicoActivado(50));

          // Aturdir al enemigo
          hearing.stun(2.5);

          // VFX: onda de choque expansiva
          parent?.add(RejectionVfxComponent(origin: position.clone()));

          // Emitir sonido alto para atraer otros enemigos
          game.emitSound(position.clone(), NivelSonido.alto, ttl: 1.5);
        } else {
          // Game Over: energía insuficiente
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
