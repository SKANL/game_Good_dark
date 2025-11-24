import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';

class LandingDustComponent extends Component {
  LandingDustComponent({required this.position});

  final Vector2 position;

  @override
  Future<void> onLoad() async {
    await add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 10,
          lifespan: 0.4,
          generator: (i) {
            final random = Random();
            // Spread horizontally
            final dx = (random.nextDouble() - 0.5) * 20;
            // Upward velocity with some variation
            final dy = -random.nextDouble() * 10 - 5;

            return AcceleratedParticle(
              position: position + Vector2(dx, 0),
              speed: Vector2(dx * 2, dy), // Move out and up
              acceleration: Vector2(0, 50), // Gravity affects dust
              child: CircleParticle(
                radius: 1.5,
                paint: Paint()
                  ..color = const Color(0xFFCCCCCC).withOpacity(0.6),
              ),
            );
          },
        ),
      ),
    );

    // Auto-remove
    add(
      TimerComponent(
        period: 0.5,
        removeOnFinish: true,
        onTick: () => removeFromParent(),
      ),
    );
  }
}
