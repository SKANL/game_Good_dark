import 'dart:ui';
import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/components/ui/echolocation_outline_component.dart';
import 'package:echo_world/game/components/world/eco_narrativo_component.dart';
import 'package:echo_world/game/components/world/wall_component.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:echo_world/game/entities/enemies/bruto.dart';
import 'package:echo_world/game/entities/enemies/cazador.dart';
import 'package:echo_world/game/entities/enemies/vigia.dart';
import 'package:echo_world/game/components/lighting/light_source_component.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

class EcholocationVfxComponent extends PositionComponent
    with HasGameRef<BlackEchoGame> {
  EcholocationVfxComponent({required Vector2 origin, this.maxRadius = 320})
    : radius = 0,
      super(position: origin, anchor: Anchor.center);

  final double maxRadius;
  double radius;
  double _alpha = 1;
  final Set<int> _illuminatedEntities = {}; // Track para evitar duplicados

  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = const Color(0xFF00FFFF);

  late final LightSourceComponent _light;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _light = LightSourceComponent(
      color: const Color(0xFF00FFFF),
      intensity: 1.0,
      radius: 0,
      softness: 0.2,
      isPulsing: false,
    );
    add(_light);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final oldRadius = radius;
    radius += 220 * dt; // speed
    _alpha = (1 - (radius / maxRadius)).clamp(0.0, 1.0);

    // Update light properties
    _light.radius = radius;
    _light.intensity = _alpha * 1.5; // Boost intensity slightly

    // Detectar entidades que el pulso acaba de alcanzar
    if (radius < maxRadius) {
      _detectAndIlluminate(oldRadius, radius);
    }

    if (radius >= maxRadius) {
      removeFromParent();
    }
  }

  void _detectAndIlluminate(double oldRadius, double newRadius) {
    // Buscar paredes en el rango del anillo
    final walls = gameRef.world.children.query<WallComponent>();

    // DEBUG: Log on first detection
    if (oldRadius == 0) {
      print('[ECHOLOCATION DEBUG] Total walls in world: ${walls.length}');
      print('[ECHOLOCATION DEBUG] Pulse origin: $position');
    }

    for (final wall in walls) {
      final wallCenter = wall.position + wall.size / 2;
      final distance = wallCenter.distanceTo(position);

      // Si el anillo del pulso tocó la pared en este frame
      if (distance > oldRadius && distance <= newRadius) {
        final entityId = wall.hashCode;
        if (!_illuminatedEntities.contains(entityId)) {
          _illuminatedEntities.add(entityId);
          _createOutline(wall);
        }
      }
    }

    // Buscar enemigos en el rango del anillo
    final enemies = gameRef.world.children.query<PositionedEntity>().where(
      (e) =>
          e is CazadorComponent || e is VigiaComponent || e is BrutoComponent,
    );
    for (final enemy in enemies) {
      final distance = enemy.position.distanceTo(position);

      if (distance > oldRadius && distance <= newRadius) {
        final entityId = enemy.hashCode;
        if (!_illuminatedEntities.contains(entityId)) {
          _illuminatedEntities.add(entityId);
          _createOutline(enemy);
        }
      }
    }

    // Revelar Ecos Narrativos en el rango del anillo
    final ecos = gameRef.world.children.query<EcoNarrativoComponent>();
    for (final eco in ecos) {
      final distance = eco.position.distanceTo(position);

      if (distance > oldRadius && distance <= newRadius) {
        eco.revelar();
      }
    }
  }

  void _createOutline(PositionComponent target) {
    // Crear path del contorno basado en la geometría del target
    Path path;

    if (target is WallComponent) {
      // Rectángulo simple para paredes
      path = Path()..addRect(Rect.fromLTWH(0, 0, target.size.x, target.size.y));
    } else {
      // Círculo para enemigos
      final radius = target.size.x / 2;
      path = Path()
        ..addOval(
          Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        );
    }

    // Añadir el componente de contorno iluminado
    gameRef.world.add(
      EcholocationOutlineComponent(
        targetPath: path,
        position: target.position.clone(),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final enfoque = gameRef.gameBloc.state.enfoqueActual;

    // En first-person: renderizar como efecto de pantalla completa (flash/pulso)
    if (enfoque == Enfoque.firstPerson) {
      final viewport = gameRef.camera.viewport.virtualSize;

      // Pulso cian que se expande desde el centro
      final centerX = viewport.x / 2;
      final centerY = viewport.y / 2;

      // Radio normalizado (0.0 a 1.0)
      final normalizedRadius = radius / maxRadius;

      // Calcular radio en píxeles de viewport
      final screenRadius = normalizedRadius * (viewport.x / 2);

      // Color con transparencia decreciente
      final alpha = _alpha * 0.3; // Más sutil en FP
      final color = _paint.color.withValues(alpha: alpha);

      // Dibujar anillo pulsante
      final ringPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(
        Offset(centerX, centerY),
        screenRadius,
        ringPaint,
      );

      // Dibujar flash de pantalla (muy sutil)
      if (normalizedRadius < 0.3) {
        final flashPaint = Paint()
          ..color = color.withValues(alpha: alpha * 0.1)
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(0, 0, viewport.x, viewport.y),
          flashPaint,
        );
      }

      return;
    }

    // En top-down/side-scroll: renderizar como círculo expandiéndose
    final color = _paint.color.withValues(alpha: _alpha);
    canvas.drawCircle(Offset.zero, radius, _paint..color = color);
  }
}
