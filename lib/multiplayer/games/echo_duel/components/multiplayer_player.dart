import 'dart:collection';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:echo_world/utils/unawaited.dart';
import 'package:echo_world/game/components/lighting/light_source_component.dart';
import 'package:echo_world/multiplayer/games/echo_duel/echo_duel_game.dart';
import 'package:echo_world/multiplayer/games/echo_duel/components/vfx/multiplayer_death_vfx_component.dart';

/// Represents a snapshot of the player's state at a specific point in time.
class PlayerSnapshot {
  final int timestamp;
  final Vector2 position;
  final Vector2 velocity;

  PlayerSnapshot({
    required this.timestamp,
    required this.position,
    required this.velocity,
  });
}

class MultiplayerPlayer extends PositionComponent
    with HasGameReference<EchoDuelGame> {
  final String id;
  final bool isMe;

  // Combat Stats
  double health = 100.0;
  final double maxHealth = 100.0;
  bool isDead = false;

  // Interpolation Buffer
  final Queue<PlayerSnapshot> _snapshots = Queue<PlayerSnapshot>();
  static const int _renderDelay = 100; // ms delay for interpolation window

  // Current movement state
  Vector2 velocity = Vector2.zero();
  final double speed = 200.0;

  MultiplayerPlayer({
    required this.id,
    required this.isMe,
    required Vector2 position,
  }) : super(position: position, size: Vector2(32, 32), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Simple circle for now (will be upgraded in Phase 2)
    add(
      CircleComponent(
        radius: 16,
        paint: Paint()..color = isMe ? Colors.green : Colors.red,
      ),
    );

    // Add Hitbox for combat
    add(CircleHitbox(radius: 16, anchor: Anchor.center, position: size / 2));

    // Add Player Light Source (Aura)
    add(
      LightSourceComponent(
        color: isMe
            ? const Color(0xFF00FFFF)
            : const Color(0xFFFF0000), // Cyan for me, Red for enemies
        intensity: 1.2,
        radius: 200,
        softness: 0.6,
        isPulsing: true,
        pulseSpeed: 2,
      ),
    );
  }

  /// Called when a new network update is received.
  void onNewState(Map<String, dynamic> payload) {
    if (isMe) return; // Local player predicts their own movement

    final x = (payload['x'] as num).toDouble();
    final y = (payload['y'] as num).toDouble();
    final vx = (payload['vx'] as num).toDouble();
    final vy = (payload['vy'] as num).toDouble();
    final timestamp = payload['timestamp'] as int;

    // Update health if present in payload (for eventual server validation)
    if (payload.containsKey('health')) {
      health = (payload['health'] as num).toDouble();
    }

    _snapshots.add(
      PlayerSnapshot(
        timestamp: timestamp,
        position: Vector2(x, y),
        velocity: Vector2(vx, vy),
      ),
    );

    // Keep buffer size manageable
    if (_snapshots.length > 20) {
      _snapshots.removeFirst();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isDead) return;

    if (isMe) {
      // Client-side prediction: Move immediately
      position += velocity * dt;
    } else {
      // Remote player: Interpolate
      _processInterpolation();
    }
  }

  void _processInterpolation() {
    if (_snapshots.isEmpty) return;

    // Calculate the render time (server time - delay)
    // Note: For now assuming local clock is roughly synced or using raw timestamps.
    // Phase 1.1 will add proper ClockSync.
    final int renderTime = DateTime.now().millisecondsSinceEpoch - _renderDelay;

    // Find the two snapshots surrounding the renderTime
    PlayerSnapshot? before;
    PlayerSnapshot? after;

    for (final snapshot in _snapshots) {
      if (snapshot.timestamp <= renderTime) {
        before = snapshot;
      } else {
        after = snapshot;
        break;
      }
    }

    // Case 1: We have both snapshots -> Interpolate
    if (before != null && after != null) {
      final double totalTime = (after.timestamp - before.timestamp).toDouble();
      final double elapsedTime = (renderTime - before.timestamp).toDouble();
      final double t = (elapsedTime / totalTime).clamp(0.0, 1.0);

      position = before.position + (after.position - before.position) * t;
      velocity = before.velocity; // Or interpolate velocity if needed
    }
    // Case 2: We only have old snapshots -> Extrapolate (Dead Reckoning)
    else if (before != null && after == null) {
      // Simple extrapolation: continue moving with last known velocity
      // Limit extrapolation to avoid flying off to infinity if packet loss is high
      if (renderTime - before.timestamp < 500) {
        // Calculate dt since the snapshot
        // This is tricky in update loop, simpler to just lerp to the last known position
        // or actually apply velocity.
        // For stability, let's just snap to the latest if we are lagging behind too much,
        // or stay at the last known position if we ran out of future data.
        // Better approach for simple extrapolation:
        // position = before.position;
        // But let's try to be smooth:
        position = before.position;
      }
    }
    // Case 3: We only have future snapshots -> Snap to first
    else if (before == null && after != null) {
      position = after.position;
    }

    // Cleanup old snapshots
    while (_snapshots.length > 2 &&
        _snapshots.elementAt(1).timestamp < renderTime) {
      _snapshots.removeFirst();
    }
  }

  void move(Vector2 delta) {
    if (isDead) return;
    velocity = delta * speed;
  }

  void shoot(Vector2 direction) {
    if (isDead) return;

    // Visuals: Emit Echo Wave (already handled by EchoDuelGame listener usually, but can be direct)
    // For hit reg: Raycast
    final rayStart = position + size / 2; // Center

    // Simple Raycast against other players
    // Note: Flame's raycastAll is better if we have a collision detection system set up.
    // EchoDuelGame should have HasCollisionDetection.

    // For now, let's iterate manually over other players for simplicity and control
    // or use game.collisionDetection.raycast(Ray2(...))

    // Let's assume we want to hit the FIRST enemy in line.
    MultiplayerPlayer? hitPlayer;
    double minDistance = double.infinity;

    for (final component in game.children) {
      if (component is MultiplayerPlayer &&
          component != this &&
          !component.isDead) {
        // Check intersection with player circle
        // Simplified: Line-Circle intersection
        // Or just check if ray passes close to center

        final toPlayer = component.position - position;
        final distProj = toPlayer.dot(direction.normalized());

        if (distProj > 0 && distProj < 500) {
          final perpDist =
              (toPlayer - direction.normalized() * distProj).length;
          if (perpDist < 16) {
            // Radius
            if (distProj < minDistance) {
              minDistance = distProj;
              hitPlayer = component;
            }
          }
        }
      }
    }

    if (hitPlayer != null) {
      // Hit registered!
      // Send hit event to server (or directly to victim via relay)
      game.repository.broadcastPlayerHit(hitPlayer.id, 10); // 10 damage
    }
  }

  void takeDamage(double amount) {
    if (isDead) return;
    health -= amount;

    // Visual Feedback: Flash White
    final circle = children.whereType<CircleComponent>().firstOrNull;
    if (circle != null) {
      final originalColor = circle.paint.color;
      circle.paint.color = Colors.white;

      // Reset color after 100ms
      unawaited(Future.delayed(const Duration(milliseconds: 100), () {
        if (!isDead && circle.isMounted) {
          circle.paint.color = originalColor;
        }
      }));
    }

    if (health <= 0) {
      health = 0;
      die();
    }
  }

  void die() {
    isDead = true;
    // Visuals: Death VFX
    game.add(
      MultiplayerDeathVfxComponent(
        position: position.clone(),
        color: isMe ? const Color(0xFF00FFFF) : const Color(0xFFFF0000),
      ),
    );
    removeFromParent(); // Or just hide/disable
  }
}
