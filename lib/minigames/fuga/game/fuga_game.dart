import 'package:flame/game.dart';
import 'package:flame/extensions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:echo_world/common/services/haptic_service.dart';
import 'package:echo_world/game/audio/audio_manager.dart';
import 'package:echo_world/game/components/vfx/screen_shake_component.dart';
import '../components/fuga_player_component.dart';
import '../components/fuga_wall_component.dart';
import '../components/fuga_shockwave_component.dart';
import '../view/hud.dart';

/// Core game class. Responsible for wiring components and providing
/// simple level loading. Keep responsibilities small (single responsibility).
class FugaGame extends FlameGame {
  late FugaPlayerComponent player;
  // World bounds computed from level geometry; used to clamp the camera
  Vector2 _worldSize = Vector2.all(1000);
  double cameraSmooth = 6.0; // smoothing factor (higher = snappier)
  late ScreenShakeComponent screenShake;

  // Fijar el tamaño del juego para que la cámara funcione correctamente
  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Background is black by default (host app sets scaffold)

    // Spawn player al centro de la pantalla
    // We create the player but defer setting a final position until the
    // game receives its first resize (size will be non-zero). This avoids
    // placing the player at Vector2.zero when `onLoad` runs before layout.
    player = FugaPlayerComponent(position: Vector2.zero());
    player.owner = this;
    await add(player);

    // Add Screen Shake
    screenShake = ScreenShakeComponent();
    await add(screenShake);

    // Load a simple level
    _loadLevel1();

    // Don't assume size is ready here; we'll position the player and camera
    // in `onGameResize` when the real size is available.
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Smooth camera follow using linear interpolation (lerp) and clamp to world
    final current = camera.viewfinder.position;
    final target = player.position.clone();

    // clamp target so camera doesn't show outside world
    final half = size / 2;
    // Ensure clamp bounds are valid even when the world is smaller than the viewport.
    final minX = half.x;
    final maxX = math.max(half.x, _worldSize.x - half.x);
    final minY = half.y;
    final maxY = math.max(half.y, _worldSize.y - half.y);
    final clampedTarget = Vector2(
      target.x.clamp(minX, maxX),
      target.y.clamp(minY, maxY),
    );
    final factor = (dt * cameraSmooth).clamp(0.0, 1.0);
    // perform lerp manually (avoid relying on a possibly unavailable static lerp)
    final delta = clampedTarget.clone()..sub(current);
    delta.scale(factor);
    final next = current.clone()..add(delta);

    // Apply shake offset
    final shakeOffset = screenShake.offset;
    camera.viewfinder.position = next + shakeOffset;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // When the game receives a size (after layout), center the player
    // and immediately move the camera viewfinder to that position so the
    // camera is correctly centered from the first frame.
    try {
      if (size.x > 0 && size.y > 0) {
        player.position = size / 2;
        camera.viewfinder.position = player.position.clone();
      }
    } catch (_) {
      // player might not be ready yet; ignore and let update handle it
    }
  }

  Widget buildHud(BuildContext context) {
    return Hud(gameRef: this);
  }

  /// Helper used by HUD to set the player's movement direction from normalized
  /// dx/dy values in the range [-1,1]. If both dx and dy are zero, movement
  /// will stop (null direction).
  void setPlayerDirection(double dx, double dy) {
    if (dx == 0 && dy == 0) {
      player.setMoveDirection(null);
    } else {
      player.setMoveDirection(Vector2(dx, dy));
    }
  }

  /// Trigger the Grito de Ruptura - destroys fragile walls and creates shockwave.
  void triggerRupture() {
    // Check if player has charges available
    if (!player.canUseRupture()) {
      return; // No charges, no rupture
    }

    // Consume charge
    player.useCharge();

    // Spawn shockwave visual effect
    final shockwave = FugaShockwaveComponent(
      origin: player.position,
      maxRadius: 300,
      growthSpeed: 1500,
    );
    add(shockwave);

    // Audio & Haptics
    AudioManager.instance.playSfx('rupture_blast');
    HapticService.heavyImpact();
    screenShake.shake(15.0); // Strong shake

    // Destroy fragile walls within 5 meters (radius según GDD)
    const ruptureRadius =
        150.0; // 5 metros en unidades del juego (ajustar según escala)
    final wallsToRemove = <FugaWallComponent>[];

    for (final c in children) {
      if (c is FugaWallComponent && c.isFragile) {
        final wallCenter = c.position + c.size / 2;
        final dist = wallCenter.distanceTo(player.position);
        if (dist <= ruptureRadius) {
          wallsToRemove.add(c);
        }
      }
    }

    // Remove fragile walls
    for (final wall in wallsToRemove) {
      wall.removeFromParent();
    }

    // TODO: Aturdir enemigos en radio de 8 metros (cuando existan)
    // TODO: Generar evento de sonido masivo (75m de detección para IA)
  }

  void _loadLevel1() {
    // Simple walls for act 1: containment cell and a fragile wall
    // Center corridor
    final wall1 = FugaWallComponent(
      position: Vector2(100, 100),
      size: Vector2(600, 16),
      isFragile: false,
    );
    final wall2 = FugaWallComponent(
      position: Vector2(100, 484),
      size: Vector2(600, 16),
      isFragile: false,
    );

    // left and right
    final left = FugaWallComponent(
      position: Vector2(100, 116),
      size: Vector2(16, 368),
    );
    final right = FugaWallComponent(
      position: Vector2(684, 116),
      size: Vector2(16, 368),
    );

    // Fragile wall at far end
    final fragile = FugaWallComponent(
      position: Vector2(340, 116),
      size: Vector2(120, 16),
      isFragile: true,
    );

    addAll([wall1, wall2, left, right, fragile]);

    // Compute world bounds so camera can be clamped
    double maxX = 0, maxY = 0;
    for (final c in children) {
      if (c is PositionComponent) {
        maxX = math.max(maxX, c.position.x + c.size.x);
        maxY = math.max(maxY, c.position.y + c.size.y);
      }
    }
    // Ensure at least the viewport size
    _worldSize = Vector2(
      math.max(maxX + 100, size.x),
      math.max(maxY + 100, size.y),
    );
  }

  /// Called by PulseComponent when the pulse expands; radius is world units.
  void onPulse(Vector2 origin, double radius, {bool fromPlayer = true}) {
    // For now iterate simple children and tell walls they were pinged
    for (final c in children) {
      if (c is FugaWallComponent) {
        final wallCenter = c.position + c.size / 2;
        final dist = wallCenter.distanceTo(origin);
        // Heuristic: if distance to center is within radius plus diagonal, count as hit
        if (dist <= radius + c.size.length / 2) {
          c.onPing();
        }
      }
    }
  }
}
