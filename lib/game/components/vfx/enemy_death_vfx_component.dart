import 'dart:math' as math;
import 'dart:ui';
import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/components/world/nucleo_resonante_component.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';

///
/// Comportamiento:
/// 1. Genera partículas de desintegración en la posición del enemigo
/// 2. Espera un delay de 0.4s
/// 3. Spawns el NucleoResonanteComponent con efecto de aparición suave
/// 4. Se autodestruye
class EnemyDeathVfxComponent extends Component with HasGameRef<BlackEchoGame> {
  EnemyDeathVfxComponent({
    required this.enemyPosition,
    required this.enemySize,
    this.enemyColor = const Color(0xFFFF0000),
  });

  final Vector2 enemyPosition;
  final Vector2 enemySize;
  final Color enemyColor;

  /// Duración total del efecto (incluye delay para spawn del núcleo)
  static const double _totalDuration = 0.8;
  static const double _nucleusSpawnDelay = 0.4;

  double _elapsed = 0;
  bool _nucleusSpawned = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _spawnDisintegrationParticles();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    // Spawnear el núcleo después del delay
    if (!_nucleusSpawned && _elapsed >= _nucleusSpawnDelay) {
      _nucleusSpawned = true;
      _spawnNucleus();
    }

    // Autodestruirse al finalizar
    if (_elapsed >= _totalDuration) {
      removeFromParent();
    }
  }

  void _spawnDisintegrationParticles() {
    // Partículas principales: explosión radial
    // Las partículas se muestran en todas las perspectivas (efecto universal)
    final mainParticleSystem = ParticleSystemComponent(
      position: enemyPosition.clone(),
      particle: Particle.generate(
        count: 40,
        lifespan: 0.6,
        generator: (i) {
          final angle = (i / 40) * 6.28318; // 2π radianes
          final direction = Vector2(math.cos(angle), math.sin(angle));
          final speed = 150.0 + (i % 5) * 20.0; // Velocidad variada

          return AcceleratedParticle(
            acceleration: direction * 100, // Aceleración hacia afuera
            speed: direction * speed,
            child: CircleParticle(
              radius: 2.5,
              paint: Paint()
                ..color = enemyColor.withValues(alpha: 0.9)
                ..blendMode = BlendMode.plus,
            ),
          );
        },
      ),
    );

    // Partículas secundarias: fragmentos que caen (simulando gravedad)
    final secondaryParticleSystem = ParticleSystemComponent(
      position: enemyPosition.clone(),
      particle: Particle.generate(
        count: 25,
        lifespan: 0.5,
        generator: (i) {
          final horizontalDir = Vector2.random() - Vector2(0.5, 0.5);
          horizontalDir.y = -0.3; // Empuje inicial hacia arriba

          return AcceleratedParticle(
            acceleration: Vector2(0, 400), // Gravedad simulada
            speed: horizontalDir * 120,
            child: CircleParticle(
              radius: 1.5,
              paint: Paint()..color = enemyColor.withValues(alpha: 0.6),
            ),
          );
        },
      ),
    );

    // Partículas de humo/energía: fade out lento
    final smokeParticleSystem = ParticleSystemComponent(
      position: enemyPosition.clone(),
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

    // Añadir todos los sistemas de partículas al mundo
    gameRef.world.add(mainParticleSystem);
    gameRef.world.add(secondaryParticleSystem);
    gameRef.world.add(smokeParticleSystem);
  }

  void _spawnNucleus() {
    // Verificar si el jugador ya alcanzó el límite de fragmentos (20)
    final loreBloc = gameRef.loreBloc;
    final fragmentosActuales = loreBloc.state.fragmentosMemoria;
    final yaAlcanzoLimite = fragmentosActuales >= 20;

    // RNG: 50% de probabilidad de que sea un fragmento de memoria
    // SOLO si no se ha alcanzado el límite
    final random = math.Random();
    final isMemoryFragment = !yaAlcanzoLimite && random.nextDouble() < 0.5;

    // Crear el núcleo con efecto de fade-in
    final nucleus = NucleoResonanteComponent(
      position: enemyPosition.clone(),
      isMemoryFragment: isMemoryFragment,
    );

    // Añadir al mundo
    gameRef.world.add(nucleus);

    // NOTA: OpacityEffect requiere OpacityProvider.
    // NucleoResonanteComponent no lo implementa (es PositionComponent).
    // El fade-in se puede lograr con un ScaleEffect como alternativa:
    nucleus.scale = Vector2.zero();
    nucleus.add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.3),
      ),
    );
  }
}
