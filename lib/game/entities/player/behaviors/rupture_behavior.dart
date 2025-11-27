import 'dart:ui';
import 'package:echo_world/game/audio/audio_manager.dart';
import 'package:echo_world/game/components/vfx/enemy_death_vfx_component.dart';
import 'package:echo_world/game/components/vfx/rupture_vfx_component.dart';
import 'package:echo_world/game/components/world/wall_component.dart';
import 'package:echo_world/game/cubit/game/game_bloc.dart';
import 'package:echo_world/game/entities/enemies/behaviors/resilience_behavior.dart';
import 'package:echo_world/game/entities/enemies/bruto.dart';
import 'package:echo_world/game/entities/enemies/cazador.dart';
import 'package:echo_world/game/entities/enemies/vigia.dart';
import 'package:echo_world/game/entities/player/player.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

class RuptureBehavior extends Behavior<PlayerComponent> {
  RuptureBehavior({required this.gameBloc});
  final GameBloc gameBloc;

  static const double radius = 128; // 4 tiles

  bool _isRupturing = false;
  double _cooldownTimer = 0;
  static const double _cooldownDuration = 0.5;

  @override
  void update(double dt) {
    if (_cooldownTimer > 0) {
      _cooldownTimer -= dt;
    }
    super.update(dt);
  }

  Future<void> triggerRupture() async {
    // COOLDOWN & STATE CHECK
    if (_isRupturing || _cooldownTimer > 0) return;

    // FORCE SYNC: Read latest state directly
    if (gameBloc.state.energiaGrito < 40) {
      // Optional: Play "failed" sound
      return;
    }

    _isRupturing = true;
    _cooldownTimer = _cooldownDuration;

    final game = parent.gameRef;

    // SFX: reproducir sonido de ruptura (no-posicional, global)
    await AudioManager.instance.playSfx('rupture_blast', volume: 0.5);

    // VFX simple: sacudir cámara y añadir partículas
    game.shakeCamera(duration: 0.3);
    await game.world.add(
      RuptureVfxComponent(origin: parent.position.clone()),
    );

    // Interacción: destruir paredes destructibles en radio
    // FIX: Query walls from world.children instead of levelManager.children
    // because ChunkManagerComponent adds walls directly to world
    final walls = game.world.children.query<WallComponent>();

    // DEBUG: Log wall query results
    print('[RUPTURE DEBUG] Total walls in world: ${walls.length}');
    print('[RUPTURE DEBUG] Player position: ${parent.position}');

    var wallsDestroyed = 0;
    for (final w in walls) {
      final center = w.position + w.size / 2;
      final distance = center.distanceTo(parent.position);

      // DEBUG: Log wall info
      if (distance <= radius + 50) {
        // Log walls slightly outside radius too
        print(
          '[RUPTURE DEBUG] Wall at ${w.position}, distance: $distance, destructible: ${w.destructible}',
        );
      }

      if (distance <= radius) {
        if (w.destructible) {
          w.destroy();
          wallsDestroyed++;
        }
      }
    }

    print('[RUPTURE DEBUG] Walls destroyed: $wallsDestroyed');

    // NUEVO: Derrotar enemigos en radio (con soporte para ResilienceBehavior)
    final enemies = game.world.children.query<PositionedEntity>();
    for (final enemy in enemies) {
      // Solo procesar enemigos (tienen behaviors)
      if (enemy is! CazadorComponent &&
          enemy is! VigiaComponent &&
          enemy is! BrutoComponent) {
        continue;
      }

      if (enemy.position.distanceTo(parent.position) <= radius) {
        // Verificar si el enemigo tiene ResilienceBehavior (solo Bruto lo tiene)
        var wasDefeated = true;

        if (enemy is BrutoComponent) {
          // Bruto tiene ResilienceBehavior: registrar hit
          final resilienceBehavior = enemy.findBehavior<ResilienceBehavior>();
          wasDefeated = resilienceBehavior.registerHit();
        }
        // Cazador y Vigía no tienen ResilienceBehavior, mueren en 1 hit (wasDefeated = true)

        if (wasDefeated) {
          // Determinar el color del enemigo para el VFX
          Color enemyColor;
          if (enemy is CazadorComponent) {
            enemyColor = const Color(0xFFFF0000); // Rojo
          } else if (enemy is VigiaComponent) {
            enemyColor = const Color(0xFFFFFF00); // Amarillo
          } else {
            enemyColor = const Color(0xFF8B4513); // Marrón (Bruto)
          }

          // Spawnear VFX de muerte (que a su vez spawneará el núcleo con delay)
          await game.world.add(
            EnemyDeathVfxComponent(
              enemyPosition: enemy.position.clone(),
              enemySize: enemy.size.clone(),
              enemyColor: enemyColor,
            ),
          );

          // Destruir enemigo inmediatamente (el VFX maneja el resto)
          enemy.removeFromParent();
        }
        // Si no fue derrotado (Bruto con 1 hit restante), sobrevive
      }
    }

    // Emisión de sonido fuerte por la ruptura
    game.emitSound(parent.position.clone(), NivelSonido.alto, ttl: 1.2);

    _isRupturing = false;
  }
}
