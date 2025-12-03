import 'dart:math' as math;
import 'dart:ui';

import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/components/core/raycast_renderer_component.dart';
import 'package:echo_world/game/components/vfx/rupture_vfx_component.dart';
import 'package:flame/components.dart';

/// Represents a single 3D particle in the world.
class Particle3D {

  Particle3D({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.maxLife,
  }) : life = 0;
  Vector3 position; // X, Y (World), Z (Height)
  Vector3 velocity;
  Color color;
  double size;
  double life;
  double maxLife;

  bool get isDead => life >= maxLife;
}

/// Manages and renders 3D particles on top of the raycast view.
class ParticleOverlaySystem extends Component with HasGameRef<BlackEchoGame> {
  final List<Particle3D> _particles = [];
  final math.Random _random = math.Random();

  // Configuration
  static const int maxParticles = 500;

  @override
  void update(double dt) {
    super.update(dt);

    // Spawn particles from Ruptures
    final ruptures = game.world.children.query<RuptureVfxComponent>();
    for (final rupture in ruptures) {
      if (_random.nextDouble() < 0.3) {
        // 30% chance per frame per rupture
        _spawnRuptureParticle(rupture.position);
      }
    }

    // Update particles
    for (var i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.life += dt;

      if (p.isDead) {
        _particles.removeAt(i);
        continue;
      }

      // Physics
      p.position.add(p.velocity * dt);

      // Floating upward (embers)
      p.velocity.z += 2.0 * dt;

      // Fade out
      final lifeRatio = p.life / p.maxLife;
      if (lifeRatio > 0.8) {
        p.color = p.color.withAlpha(((1.0 - (lifeRatio - 0.8) * 5) * 255).round());
      }
    }
  }

  void _spawnRuptureParticle(Vector2 pos) {
    final x = pos.x + (_random.nextDouble() - 0.5) * 20.0;
    final y = pos.y + (_random.nextDouble() - 0.5) * 20.0;
    final z = _random.nextDouble() * 20.0; // Low to ground

    _particles.add(
      Particle3D(
        position: Vector3(x, y, z),
        velocity: Vector3(
          (_random.nextDouble() - 0.5) * 20,
          (_random.nextDouble() - 0.5) * 20,
          30.0 + _random.nextDouble() * 30, // Fast upward
        ),
        color: const Color(0xFFFF4400).withAlpha((0.8 * 255).round()), // Red/Orange
        size: 3.0 + _random.nextDouble() * 4.0,
        maxLife: 0.5 + _random.nextDouble() * 0.5, // Short life
      ),
    );
  }

  /// Adds a burst of particles at a specific location
  void addBurst(Vector2 position, Color color, int count) {
    for (var i = 0; i < count; i++) {
      _particles.add(
        Particle3D(
          position: Vector3(position.x, position.y, 20), // Start low
          velocity: Vector3(
            (_random.nextDouble() - 0.5) * 100,
            (_random.nextDouble() - 0.5) * 100,
            20.0 + _random.nextDouble() * 50,
          ),
          color: color,
          size: 4.0 + _random.nextDouble() * 4.0,
          maxLife: 1.0 + _random.nextDouble() * 1.0,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    // We need to project particles to screen space
    // This logic duplicates some of RaycastRenderer's projection math
    // Ideally, we'd share the camera transform, but for now we recalculate.

    final player = game.player;
    final renderSize = game.canvasSize;
    const fov = RaycastRendererComponent.fov;
    final halfHeight = renderSize.y / 2;

    // Sort by distance (far to near) for proper blending
    _particles.sort((a, b) {
      final distA = _distSq(player.position, a.position);
      final distB = _distSq(player.position, b.position);
      return distB.compareTo(distA);
    });

    for (final p in _particles) {
      // 1. Transform to Player Space
      final dx = p.position.x - player.position.x;
      final dy = p.position.y - player.position.y;

      // Project onto player's forward and right vectors
      // Forward = (cos(heading), sin(heading))
      // Right = (-sin(heading), cos(heading))

      // LocalX = Distance along forward vector
      // LocalY = Distance along right vector

      final localX =
          dx * math.cos(player.heading) + dy * math.sin(player.heading);
      final localY =
          -dx * math.sin(player.heading) + dy * math.cos(player.heading);

      // Clip if behind player
      if (localX < 1.0) continue;

      // 2. Project to Screen
      // ScreenX: Based on angle or simple perspective
      // x = (y / x) * scale ? No.
      // We use the same math as the floor renderer:
      // worldWidth = worldDist * tan(fov/2) * 2
      // u = (relX / worldWidth) + 0.5

      final worldWidth = localX * math.tan(fov / 2) * 2;
      final u = (localY / worldWidth) + 0.5;

      if (u < 0 || u > 1) continue; // Off screen horizontally

      final screenX = u * renderSize.x;

      // ScreenY:
      // Z is height.
      // In raycaster, wall height = (renderSize.y) / perpDist
      // So projected Z = (Z / perpDist) * scale?
      // Center of screen is Z=0 (horizon)? No, camera height is implicit.
      // Let's assume camera is at Z=50.
      // screenY = horizon - (p.z - cameraZ) / localX * scale

      const cameraZ = 50.0; // Arbitrary eye height
      final scale = renderSize.y; // Scaling factor

      // Perspective projection for height
      final projectedHeight = (p.position.z - cameraZ) / localX * scale;
      final screenY = halfHeight - projectedHeight;

      // Size attenuation
      final projectedSize = p.size / localX * 100.0;

      if (projectedSize < 1.0) continue;

      canvas.drawCircle(
        Offset(screenX, screenY),
        projectedSize,
        Paint()..color = p.color,
      );
    }
  }

  double _distSq(Vector2 p1, Vector3 p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    return dx * dx + dy * dy;
  }
}
