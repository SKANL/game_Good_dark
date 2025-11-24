import 'dart:math' as math;
import 'package:echo_world/game/black_echo_game.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/painting.dart';

/// Componente de efectos visuales para la absorción de un núcleo.
/// Genera partículas doradas que se mueven hacia el jugador.
/// En first-person, las partículas también se renderizan (efecto visual universal).
class AbsorptionVfxComponent extends Component with HasGameRef<BlackEchoGame> {
  AbsorptionVfxComponent({
    required this.nucleusPosition,
    required this.playerPosition,
  });

  final Vector2 nucleusPosition;
  final Vector2 playerPosition;
  bool _spawned = false;

  @override
  Future<void> onLoad() async {
    if (_spawned) return;
    _spawned = true;

    // Single ParticleSystem for all particles
    await add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 30,
          lifespan: 0.8,
          generator: (i) {
            // Start in a circle around the nucleus
            final angle = (math.pi * 2 / 30) * i;
            final offset = Vector2(math.cos(angle), math.sin(angle)) * 20;
            final startPos = nucleusPosition + offset;

            // Calculate direction to player
            final toPlayer = (playerPosition - startPos)..normalize();

            return ComputedParticle(
              renderer: (canvas, particle) {
                // Move towards player with acceleration
                final currentPos =
                    startPos +
                    (toPlayer * 600 * particle.progress * particle.progress);
                final paint = Paint()
                  ..color = const Color(
                    0xFFFFD700,
                  ).withOpacity(1 - particle.progress);
                canvas.drawCircle(currentPos.toOffset(), 3, paint);
              },
            );
          },
        ),
      ),
    );

    // Auto-remove after animation
    add(
      TimerComponent(
        period: 0.8,
        removeOnFinish: true,
        onTick: () => removeFromParent(),
      ),
    );
  }
}
