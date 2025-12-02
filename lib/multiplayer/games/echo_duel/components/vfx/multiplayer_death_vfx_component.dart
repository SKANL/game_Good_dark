import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';

/// Visual effect for player death in multiplayer.
/// Spawns disintegration particles and then removes itself.
class MultiplayerDeathVfxComponent extends Component with HasGameReference {
  MultiplayerDeathVfxComponent({
    required this.position,
    this.color = const Color(0xFFFF0000),
  });

  final Vector2 position;
  final Color color;

  /// Total duration of the effect
  static const double _totalDuration = 0.8;

  double _elapsed = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _spawnDisintegrationParticles();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    // Self-destruct after duration
    if (_elapsed >= _totalDuration) {
      removeFromParent();
    }
  }

  void _spawnDisintegrationParticles() {
    // Main explosion particles
    final mainParticleSystem = ParticleSystemComponent(
      position: position.clone(),
      particle: Particle.generate(
        count: 40,
        lifespan: 0.6,
        generator: (i) {
          final angle = (i / 40) * 6.28318; // 2π radians
          final direction = Vector2(math.cos(angle), math.sin(angle));
          final speed = 150.0 + (i % 5) * 20.0; // Varied speed

          return AcceleratedParticle(
            acceleration: direction * 100, // Outward acceleration
            speed: direction * speed,
            child: CircleParticle(
              radius: 2.5,
              paint: Paint()
                ..color = color.withValues(alpha: 0.9)
                ..blendMode = BlendMode.plus,
            ),
          );
        },
      ),
    );

    // Secondary falling fragments (simulated gravity)
    final secondaryParticleSystem = ParticleSystemComponent(
      position: position.clone(),
      particle: Particle.generate(
        count: 25,
        lifespan: 0.5,
        generator: (i) {
          final horizontalDir = Vector2.random() - Vector2(0.5, 0.5);
          horizontalDir.y = -0.3; // Initial upward push

          return AcceleratedParticle(
            acceleration: Vector2(0, 400), // Simulated gravity
            speed: horizontalDir * 120,
            child: CircleParticle(
              radius: 1.5,
              paint: Paint()..color = color.withValues(alpha: 0.6),
            ),
          );
        },
      ),
    );

    // Smoke/Energy particles: slow fade out
    final smokeParticleSystem = ParticleSystemComponent(
      position: position.clone(),
      particle: Particle.generate(
        count: 15,
        lifespan: 0.8,
        generator: (i) {
          final direction = (Vector2.random() - Vector2(0.5, 0.5))..normalize();

          return AcceleratedParticle(
            acceleration: -direction * 30,
            speed: direction * 60,
            child: CircleParticle(
              radius: 4,
              paint: Paint()
                ..color = const Color(0xFF666666).withValues(alpha: 0.4),
            ),
          );
        },
      ),
    );

    // Add all particle systems to the world
    // Assuming game.world is available (FlameGame usually has it)
    // If not, we might need to cast game to FlameGame or specific game
    game.world.add(mainParticleSystem);
    game.world.add(secondaryParticleSystem);
    game.world.add(smokeParticleSystem);
  }
}
