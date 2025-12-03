import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/components/core/components.dart';
import 'package:echo_world/game/components/lighting/light_source_component.dart';
import 'package:echo_world/game/components/vfx/particle_overlay_system.dart';
import 'package:echo_world/game/entities/enemies/bruto.dart';
import 'package:echo_world/game/entities/enemies/cazador.dart';
import 'package:echo_world/game/entities/enemies/vigia.dart';
import 'package:echo_world/game/entities/player/player.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:echo_world/game/level/manager/level_manager.dart';
import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// RaycastRendererComponent: Renderiza el mundo en falso 3D (raycasting).
///
/// ═══════════════════════════════════════════════════════════════════════
/// ARQUITECTURA DE FIRST-PERSON: CÓMO FUNCIONA EL SISTEMA
/// ═══════════════════════════════════════════════════════════════════════
///
/// **PROBLEMA RESUELTO:**
/// La implementación anterior usaba un CustomPainter de Flutter como overlay,
/// lo que creaba una vista "falsa" sobre el juego 2D. Esto NO cambiaba
/// la perspectiva del juego, solo dibujaba encima.
///
/// **SOLUCIÓN IMPLEMENTADA:**
/// Este componente se integra DIRECTAMENTE en el World de Flame y reemplaza
/// completamente la vista 2D con una proyección 3D raycasting.
///
/// **FLUJO DE RENDERIZADO:**
///
/// 1. **Cambio de Enfoque** (GameBloc)
///    - Usuario presiona [ENFOQUE] → GameBloc emite `enfoqueActual: firstPerson`
///    - BlackEchoGame._ajustarCamara() detecta el cambio
///
/// 2. **Configuración de Cámara** (BlackEchoGame)
///    - `cameraComponent.stop()` → La cámara NO sigue al jugador
///    - `world.add(RaycastRendererComponent())` → Se añade este componente
///
/// 3. **Sistema de Coordenadas**
///    - Raycaster usa posición ABSOLUTA del jugador en el mundo (tiles)
///    - Renderiza directamente en coordenadas de VIEWPORT (píxeles de pantalla)
///    - NO hay transformación de cámara → la vista es fija en la pantalla
///
/// 4. **Renderizado por Frame**
///    - Este componente lee `player.position` y `player.heading`
///    - Lanza rayos desde la posición del jugador en dirección del heading
///    - Detecta colisiones con el grid de nivel y entidades
///    - Dibuja columnas verticales en el canvas (efecto 3D)
///
/// 5. **Movimiento en FP**
///    - FirstPersonMovementBehavior actualiza `player.position` (movimiento)
///    - FirstPersonMovementBehavior actualiza `player.heading` (rotación)
///    - El raycaster lee estos valores cada frame → la vista se actualiza
///
/// **DIFERENCIAS CLAVE vs. TOP-DOWN/SIDE-SCROLL:**
/// - Top-Down: Cámara sigue al jugador, vista ortogonal cenital (X, Y)
/// - Side-Scroll: Cámara sigue al jugador, vista ortogonal lateral (X, Z)
/// - First-Person: Cámara FIJA, raycaster proyecta desde jugador (3D falso)
///
/// **ARQUITECTURA CRÍTICA:**
/// Este componente implementa la vista FP real del juego según el GDD.
/// A diferencia de un overlay de Flutter (CustomPainter), este componente
/// se añade directamente al World de Flame y renderiza el nivel con raycasting
/// procedural desde la posición y orientación del jugador.
///
/// **FUNCIONAMIENTO:**
/// 1. Lanza múltiples rayos (rayCount) en el FOV del jugador (60°).
/// 2. Cada rayo marcha en el mundo (grid de nivel) detectando colisiones con:
///    - Paredes (TipoCelda.pared)
///    - Núcleos Resonantes
///    - Enemigos (Cazador, Vigía, Bruto)
/// 3. Proyecta cada colisión como una línea vertical en el canvas (columna).
/// 4. Aplica sombreado por distancia y distingue entidades por color.
///
/// **INTEGRACIÓN:**
/// - Se añade al World cuando enfoqueActual == Enfoque.firstPerson.
/// - Se quita del World cuando se cambia a otro enfoque.
/// - El HUD de Flutter (_HudFirstPerson) solo muestra botones, no vista 3D.
///
/// **RENDIMIENTO:**
/// - Renderizado procedural (sin sprites ni texturas).
/// - Optimizado para móvil con rayCount y rayStep configurables.
/// - Priority -1000 para renderizar como fondo.
class RaycastRendererComponent extends Component
    with HasGameRef<BlackEchoGame> {
  RaycastRendererComponent() : super(priority: -1000);

  // Configuración del raycasting
  static const double fov = math.pi / 3; // 60° field of view
  static const int rayCount = 200; // Increased resolution
  static const double maxDepth = 20; // Profundidad máxima en tiles
  static const double rayStep = 0.05; // Paso de marcha para cada rayo

  double _time = 0;
  Vector2 _lastPosition = Vector2.zero();
  double _walkTime = 0;

  // Adaptive resolution
  int _currentRayCount = 200;
  double _frameTimeAccumulator = 0;
  int _frameCount = 0;

  // Texturas
  ui.Image? _wallTexture;

  // VFX System
  ParticleOverlaySystem? particleSystem;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      // Cargar la textura de la pared
      // Usamos una instancia local de Images con prefix 'assets/' porque
      // la imagen está en assets/levels/walls/, no en assets/images/
      final loader = Images(prefix: 'assets/');
      _wallTexture = await loader.load('levels/walls/wall_1.png');

      // Initialize Particle System
      particleSystem = ParticleOverlaySystem();
      add(particleSystem!);
    } catch (e) {
      debugPrint('Error loading resources: $e');
      // Fallback: _wallTexture quedará null y se usará el renderizado antiguo
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Head bob logic
    final player = game.player;
    final dist = player.position.distanceTo(_lastPosition);
    if (dist > 0.001) {
      // Player is moving
      _walkTime += dt * 10; // Adjust speed of bob
    } else {
      // Decay walk time to settle head bob
      _walkTime = _walkTime % (math.pi * 2);
      if (_walkTime > math.pi) {
        _walkTime += dt * 5;
      } else if (_walkTime > 0) {
        _walkTime -= dt * 5;
        if (_walkTime < 0) _walkTime = 0;
      }
    }
    _lastPosition = player.position.clone();

    // Adaptive resolution logic
    _frameTimeAccumulator += dt;
    _frameCount++;
    if (_frameTimeAccumulator >= 1.0) {
      final fps = _frameCount / _frameTimeAccumulator;
      if (fps < 45 && _currentRayCount > 50) {
        _currentRayCount -= 20; // Reduce quality
      } else if (fps > 55 && _currentRayCount < 300) {
        _currentRayCount += 10; // Increase quality
      }
      _frameTimeAccumulator = 0;
      _frameCount = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save(); // Save canvas state
    super.render(canvas);

    final player = game.player;
    final activeLights = game.lightingSystem.getNearestLights(
      player.position,
    );
    final grid = game.levelManager.currentGrid;

    if (grid == null) return;

    const tile = LevelManagerComponent.tileSize;

    // Usar el tamaño REAL del canvas del juego (toda la pantalla)
    final renderSize = game.canvasSize;

    // Asegurar que el raycast ocupe TODO el canvas sin dejar espacios
    canvas.clipRect(Rect.fromLTWH(0, 0, renderSize.x, renderSize.y));

    final posX = player.position.x / tile;
    final posY = player.position.y / tile;
    final heading = player.heading;

    // Head bob offset
    final bobOffset = math.sin(_walkTime) * 10.0; // 10 pixels amplitude

    // Crouch offset - lower the camera when crouched
    final isCrouched = game.gameBloc.state.estaAgachado;
    final crouchOffset = isCrouched ? -80.0 : 0.0;

    // Get dynamic lighting from current chunk
    final chunk = game.levelManager.currentChunk;
    // IMMERSION FIX: Restore "Blindness"
    // Remove the artificial boost. Use the chunk's ambient (usually dark) directly.
    final baseAmbient = chunk?.ambientLight ?? const Color(0xFF050505);
    // Ensure ambient is VERY dark for the "blind" feel
    final ambientColor = Color.fromARGB(
      255,
      (baseAmbient.red * 0.5).toInt(),
      (baseAmbient.green * 0.5).toInt(),
      (baseAmbient.blue * 0.5).toInt(),
    );

    final fogColor =
        chunk?.fogColor?.withAlpha(255) ??
        const Color(0xFF000510); // Darker fog

    // Cielo y suelo (fondo)
    final skyPaint = Paint()..color = ambientColor.withAlpha((0.8 * 255).round());
    final floorPaint = Paint()..color = ambientColor;

    // NO aplicar transformación: renderizar en espacio de canvas directamente
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        renderSize.x,
        renderSize.y / 2 + bobOffset + crouchOffset,
      ),
      skyPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        renderSize.y / 2 + bobOffset + crouchOffset,
        renderSize.x,
        renderSize.y / 2 - bobOffset - crouchOffset,
      ),
      floorPaint,
    );

    // Obtener efectos activos
    final echoes = game.world.children.query<EcholocationVfxComponent>();
    final ruptures = game.world.children.query<RuptureVfxComponent>();

    // --- VERTEX-BASED FLOOR & CEILING RENDERER ---
    _renderFloorAndCeilingVertices(
      canvas,
      renderSize,
      player,
      activeLights,
      echoes, // Pass active echoes for Sonic Wave
      bobOffset,
      crouchOffset,
      tile,
      ambientColor,
      fogColor,
    );

    // Obtener entidades del mundo
    final nucleos = game.world.children.query<NucleoResonanteComponent>();
    final cazadores = game.world.children.query<CazadorComponent>();
    final vigias = game.world.children.query<VigiaComponent>();
    final brutos = game.world.children.query<BrutoComponent>();

    final colWidth = renderSize.x / _currentRayCount;

    // Lanzar rayos
    final ruido = game.gameBloc.state.ruidoMental;
    final glitchChance = ruido > 25 ? (ruido - 25) / 75.0 : 0.0;
    final random = math.Random();

    // Flicker effect based on noise
    final flickerIntensity = (ruido / 100.0) * 0.2; // Up to 20% flicker
    final globalFlicker = 1.0 + (random.nextDouble() - 0.5) * flickerIntensity;

    // Rupture effect (screen shake & flash)
    var ruptureIntensity = 0.0;
    if (ruptures.isNotEmpty) {
      ruptureIntensity = ruptures.first.life / 0.5; // Aproximación
    }

    if (ruptureIntensity > 0) {
      final shake = (random.nextDouble() - 0.5) * 20 * ruptureIntensity;
      canvas.translate(shake, shake);
    }

    for (var i = 0; i < _currentRayCount; i++) {
      final rel = (i / (_currentRayCount - 1)) - 0.5; // -0.5 a 0.5

      // Glitch: Desplazamiento angular aleatorio
      var rayAng = heading + rel * fov;
      if (random.nextDouble() < glitchChance * 0.1) {
        rayAng += (random.nextDouble() - 0.5) * 0.2;
      }

      final dirX = math.cos(rayAng);
      final dirY = math.sin(rayAng);

      var dist = 0.01;
      var hitX = posX;
      var hitY = posY;
      var hit = false;
      var side = false; // Para sombreado
      dynamic entidadDetectada;
      var wallX =
          0.0; // Coordenada X exacta del impacto en la pared (0.0 - 1.0)

      // Marcha del rayo
      while (dist < maxDepth) {
        hitX = posX + dirX * dist;
        hitY = posY + dirY * dist;
        final mx = hitX.floor();
        final my = hitY.floor();

        // Fuera de bounds
        if (my < 0 || my >= grid.length || mx < 0 || mx >= grid[0].length) {
          break;
        }

        // Detectar núcleo
        for (final n in nucleos) {
          final dx = n.position.x / tile - hitX;
          final dy = n.position.y / tile - hitY;
          if (dx.abs() < 0.4 && dy.abs() < 0.4) {
            entidadDetectada = n;
            hit = true;
            break;
          }
        }
        if (hit) break;

        // Detectar cazador
        for (final c in cazadores) {
          final dx = c.position.x / tile - hitX;
          final dy = c.position.y / tile - hitY;
          if (dx.abs() < 0.4 && dy.abs() < 0.4) {
            entidadDetectada = c;
            hit = true;
            break;
          }
        }
        if (hit) break;

        // Detectar vigía
        for (final v in vigias) {
          final dx = v.position.x / tile - hitX;
          final dy = v.position.y / tile - hitY;
          if (dx.abs() < 0.4 && dy.abs() < 0.4) {
            entidadDetectada = v;
            hit = true;
            break;
          }
        }
        if (hit) break;

        // Detectar bruto
        for (final b in brutos) {
          final dx = b.position.x / tile - hitX;
          final dy = b.position.y / tile - hitY;
          if (dx.abs() < 0.4 && dy.abs() < 0.4) {
            entidadDetectada = b;
            hit = true;
            break;
          }
        }
        if (hit) break;

        // Detectar pared
        if (grid[my][mx].tipo == TipoCelda.pared) {
          hit = true;
          side = (hitX - mx).abs() < (hitY - my).abs();

          // Calcular coordenada exacta de textura
          if (side) {
            // Impacto en eje Y (lado horizontal)
            wallX = hitY - hitY.floor();
          } else {
            // Impacto en eje X (lado vertical)
            wallX = hitX - hitX.floor();
          }
          break;
        }

        dist += rayStep;
      }

      if (!hit) continue;

      // Corrección de fisheye
      final perp = dist * math.cos(rayAng - heading);
      final wallH =
          (renderSize.y) / (perp + 0.0001); // Usar altura completa del canvas
      final yTop = ((renderSize.y / 2) - wallH / 2 + bobOffset + crouchOffset)
          .clamp(
            0,
            renderSize.y,
          );
      final yBottom = (yTop + wallH).clamp(0, renderSize.y);

      // --- VOLUMETRIC FOG (Exponential) ---
      // Beer's Law: intensity = exp(-density * distance)
      // Density controls how "thick" the fog is.
      const fogDensity = 0.15;
      var fogFactor = math.exp(-fogDensity * perp);
      fogFactor = fogFactor.clamp(0.0, 1.0);

      // Apply flicker to fog factor for atmosphere
      fogFactor *= globalFlicker.clamp(0.9, 1.1);

      // Color según tipo de entidad
      Color color;
      var isWall = false;
      var maxSweepHeight = 0.0;
      var sweepIntensity = 0.0;

      if (entidadDetectada is NucleoResonanteComponent) {
        // Pulse effect
        final pulse = (math.sin(_time * 5) + 1) / 2;
        final baseColor = Color.lerp(
          const Color(0xFFFFD700),
          const Color(0xFFFFAA00),
          pulse,
        )!;
        color = Color.lerp(fogColor, baseColor, fogFactor)!;
      } else if (entidadDetectada is CazadorComponent) {
        color = Color.lerp(
          fogColor,
          const Color(0xFFFF2222),
          fogFactor,
        )!;
      } else if (entidadDetectada is VigiaComponent) {
        color = Color.lerp(
          fogColor,
          const Color(0xFF8A2BE2),
          fogFactor,
        )!;
      } else if (entidadDetectada is BrutoComponent) {
        color = Color.lerp(
          fogColor,
          const Color(0xFF4444FF),
          fogFactor,
        )!;
      } else {
        // Pared
        isWall = true;
        color = const Color(0xFF00FFFF); // Base wall color

        // ECHO EFFECT: Vertical Sweep (Wall Climb)
        // Simulates the sound wave hitting the wall and climbing up

        for (final echo in echoes) {
          final distToEcho = echo.position.distanceTo(
            Vector2(hitX * tile, hitY * tile),
          );
          final radius = echo.radius;

          // Check if the wave has reached the wall
          // We allow a "thickness" for the impact zone
          final delta = radius - distToEcho;

          if (delta > 0 && delta < 150.0) {
            // Wave climbs up to 150 units
            // Calculate intensity based on how "fresh" the hit is
            final intensity = (1.0 - (delta / 150.0)).clamp(0.0, 1.0);

            if (intensity > sweepIntensity) {
              sweepIntensity = intensity;
              maxSweepHeight = delta;
            }

            // Base wall highlight (impact point)
            color = Color.lerp(
              color,
              const Color(0xFFFFFFFF),
              intensity * 0.8,
            )!;
            fogFactor = math.max(fogFactor, intensity);
          }
        }

        // RUPTURE EFFECT: Reddish glow near rupture points
        for (final rupture in ruptures) {
          final distToRupture = rupture.position.distanceTo(
            Vector2(hitX * tile, hitY * tile),
          );
          // Rupture affects a radius of about 5 tiles (160 pixels)
          if (distToRupture < 160.0) {
            final intensity = (1.0 - (distToRupture / 160.0)).clamp(0.0, 1.0);
            // Pulse based on rupture life or time
            final pulse = (math.sin(_time * 10) + 1) / 2;
            final glowColor = Color.lerp(
              const Color(0xFFFF4400), // Red-Orange
              const Color(0xFFFF0000), // Red
              pulse,
            )!;

            // Blend the glow onto the wall
            color = Color.lerp(color, glowColor, intensity * 0.8)!;
            fogFactor = math.max(
              fogFactor,
              intensity,
            ); // Rupture lights up the fog
          }
        }
      }

      // Glitch: Color corrupto (override)
      if (random.nextDouble() < glitchChance * 0.05) {
        // Random neon colors with Violet preference
        final neonColors = [
          const Color(0xFF8A2BE2), // Violet (Theme)
          const Color(0xFFFF00FF), // Magenta
          const Color(0xFF00FF00), // Green
          const Color(0xFF00FFFF), // Cyan
          const Color(0xFF8A2BE2), // Violet again for higher weight
        ];
        color = neonColors[random.nextInt(neonColors.length)];
        fogFactor = 1.0; // Full brightness
        isWall = false; // Disable texture for glitch
      }

      // Glitch: Desplazamiento vertical (Wave + Random)
      var drawYTop = yTop.toDouble();
      var drawYBottom = yBottom.toDouble();

      if (glitchChance > 0) {
        // Wave effect based on time and x position
        final wave = math.sin(_time * 20 + i * 0.1) * (glitchChance * 10);
        drawYTop += wave;
        drawYBottom += wave;

        // Random tearing
        if (random.nextDouble() < glitchChance * 0.02) {
          final offset = (random.nextDouble() - 0.5) * 50;
          drawYTop += offset;
          drawYBottom += offset;
        }
      }

      final x = i * colWidth;
      final rectHeight = drawYBottom - drawYTop;

      // RENDERIZADO
      if (isWall && _wallTexture != null) {
        // Renderizar Textura
        final texW = _wallTexture!.width;
        final texH = _wallTexture!.height;

        // Calcular franja de textura
        final srcX = (wallX * texW).floorToDouble();
        final clampedSrcX = srcX.clamp(0.0, texW - 1.0);

        final srcRect = Rect.fromLTWH(clampedSrcX, 0, 1, texH.toDouble());
        final dstRect = Rect.fromLTWH(x, drawYTop, colWidth + 1, rectHeight);

        // --- REFLECTION PASS (Improved) ---
        // Draw a mirrored version with a gradient mask for fading
        if (drawYBottom < renderSize.y) {
          final reflectionHeight = rectHeight * 0.5; // Longer reflection
          final reflectionRect = Rect.fromLTWH(
            x,
            drawYBottom,
            colWidth + 1,
            reflectionHeight,
          );

          // Calculate Fresnel factor for reflection intensity
          // Reflections are stronger at grazing angles (further away)
          final fresnel = (perp / maxDepth).clamp(0.2, 0.8);

          final reflectionPaint = Paint()
            ..color = color.withAlpha(((0.3 * fresnel * fogFactor) * 255).round())
            ..maskFilter = const MaskFilter.blur(
              BlurStyle.normal,
              3,
            ); // Blurrier reflection

          // Draw reflection
          canvas.drawRect(reflectionRect, reflectionPaint);
        }

        // --- PHONG SHADING (Diffuse + Specular) ---

        // 1. Calculate Wall Normal
        // If side (Y-axis hit), normal is (0, 1) or (0, -1). If !side (X-axis hit), normal is (1, 0) or (-1, 0).
        // We can approximate the normal based on ray direction.
        double normalX = 0;
        double normalY = 0;
        if (side) {
          normalY = dirY > 0 ? -1 : 1; // Hitting horizontal wall
        } else {
          normalX = dirX > 0 ? -1 : 1; // Hitting vertical wall
        }

        // 2. Accumulate Colored Light
        var totalDiffuseR = 0.0, totalDiffuseG = 0.0, totalDiffuseB = 0.0;
        var totalSpecularR = 0.0;
        var totalSpecularG = 0.0;
        var totalSpecularB = 0.0;

        final hitPos = Vector2(hitX * tile, hitY * tile);

        for (final light in activeLights) {
          final distSq = hitPos.distanceToSquared(light.position);
          final radiusSq = light.radius * light.radius;
          if (distSq >= radiusSq) continue;

          // Line of Sight Check
          if (!_hasLineOfSight(light.position, hitPos, grid, tile)) continue;

          final distToLight = math.sqrt(distSq);
          final lightDirX = (light.position.x - hitPos.x) / distToLight;
          final lightDirY = (light.position.y - hitPos.y) / distToLight;

          // Diffuse: dot(normal, lightDir)
          final dotNL = (normalX * lightDirX + normalY * lightDirY).clamp(
            0.0,
            1.0,
          );

          // Specular: Blinn-Phong
          final viewDirX = -dirX;
          final viewDirY = -dirY;

          // Half vector H = (L + V) / |L + V|
          var hX = lightDirX + viewDirX;
          var hY = lightDirY + viewDirY;
          final hLen = math.sqrt(hX * hX + hY * hY);
          if (hLen > 0) {
            hX /= hLen;
            hY /= hLen;
          }

          final dotNH = (normalX * hX + normalY * hY).clamp(0.0, 1.0);
          final specular = math.pow(dotNH, 32); // Sharper highlight

          // Attenuation: Smoothstep
          final normalizedDist = distToLight / light.radius;
          final attLinear = (1.0 - normalizedDist).clamp(0.0, 1.0);
          final attenuation = attLinear * attLinear * (3 - 2 * attLinear);

          // Get light color
          final lightR = light.color.red / 255.0;
          final lightG = light.color.green / 255.0;
          final lightB = light.color.blue / 255.0;

          // Accumulate colored diffuse
          final diffuseContrib = dotNL * attenuation * light.effectiveIntensity;
          totalDiffuseR += diffuseContrib * lightR;
          totalDiffuseG += diffuseContrib * lightG;
          totalDiffuseB += diffuseContrib * lightB;

          // Accumulate colored specular
          final specularContrib =
              specular * attenuation * light.effectiveIntensity * 3.0;
          totalSpecularR += specularContrib * lightR;
          totalSpecularG += specularContrib * lightG;
          totalSpecularB += specularContrib * lightB;
        }

        // 3. Combine with Ambient
        // Ambient is affected by fog
        var r = (ambientColor.red / 255.0) * fogFactor;
        var g = (ambientColor.green / 255.0) * fogFactor;
        var b = (ambientColor.blue / 255.0) * fogFactor;

        // Add Diffuse (modulated by wall color)
        // Use the calculated 'color' (which includes ability tints) as the wall albedo
        final wallR = color.red / 255.0;
        final wallG = color.green / 255.0;
        final wallB = color.blue / 255.0;

        // Add Colored Diffuse
        r += totalDiffuseR * wallR;
        g += totalDiffuseG * wallG;
        b += totalDiffuseB * wallB;

        // Add Colored Specular
        r += totalSpecularR;
        g += totalSpecularG;
        b += totalSpecularB;

        // Add Fresnel Effect (Rim lighting)
        // Fresnel = (1 - dot(N, V))^power
        // View dir is -rayDir
        final dotNV = (normalX * -dirX + normalY * -dirY).clamp(0.0, 1.0);
        final fresnel = math.pow(1.0 - dotNV, 3);
        // Add a subtle rim light based on fog color or ambient
        r += fresnel * 0.2 * fogFactor;
        g += fresnel * 0.2 * fogFactor;
        b += fresnel * 0.2 * fogFactor;

        // Add Emissive (Ability Glow - Additive)
        // BOOST: Make ability lights MUCH more visible on walls
        if (fogFactor > 0.9) {
          // Strong emissive boost for ability-lit walls
          r += wallR * 1.5;
          g += wallG * 1.5;
          b += wallB * 1.5;
        } else if (fogFactor > 0.7) {
          // Medium boost for partially lit walls
          r += wallR * 0.8;
          g += wallG * 0.8;
          b += wallB * 0.8;
        }

        final finalColor = Color.fromARGB(
          255,
          (r.clamp(0.0, 1.0) * 255).toInt(),
          (g.clamp(0.0, 1.0) * 255).toInt(),
          (b.clamp(0.0, 1.0) * 255).toInt(),
        );

        // Draw Texture with Lighting
        final paint = Paint()
          ..color = Colors.white
          ..filterQuality = FilterQuality.low
          ..colorFilter = ColorFilter.mode(finalColor, BlendMode.modulate);

        canvas.drawImageRect(_wallTexture!, srcRect, dstRect, paint);

        // Add Colored Glow Overlay (Additive Pass)
        if (fogFactor > 0.9) {
          // Calculate dominant light color from accumulated lighting
          final totalLight =
              totalDiffuseR + totalDiffuseG + totalDiffuseB + 0.001;
          final avgLightR = (totalDiffuseR / totalLight).clamp(0.0, 1.0);
          final avgLightG = (totalDiffuseG / totalLight).clamp(0.0, 1.0);
          final avgLightB = (totalDiffuseB / totalLight).clamp(0.0, 1.0);

          final glowPaint = Paint()
            ..color = Color.fromARGB(
              (255 * 0.6).toInt(), // Boosted opacity
              (avgLightR * 255).toInt(),
              (avgLightG * 255).toInt(),
              (avgLightB * 255).toInt(),
            )
            ..blendMode = BlendMode.plus;

          canvas.drawRect(dstRect, glowPaint);
        }

        // --- VERTICAL SWEEP OVERLAY (Sonic Climb) ---
        if (sweepIntensity > 0.1) {
          // Calculate screen height of the sweep
          // wallH is the full wall height in pixels. Wall is 'tile' size in world.
          final pixelsPerUnit = wallH / tile;
          final sweepHeightPixels = maxSweepHeight * pixelsPerUnit;

          final sweepRect = Rect.fromLTWH(
            x,
            drawYBottom - sweepHeightPixels,
            colWidth + 1,
            sweepHeightPixels,
          );

          // Gradient from bottom (bright) to top (transparent)
          final sweepPaint = Paint()
            ..shader = ui.Gradient.linear(
              Offset(x, drawYBottom),
              Offset(x, drawYBottom - sweepHeightPixels),
              [
                const Color(0xFF00FFFF).withAlpha(((sweepIntensity * 0.6) * 255).round()),
                const Color(0xFF00FFFF).withAlpha(0),
              ],
            )
            ..blendMode = BlendMode.plus;

          canvas.drawRect(sweepRect, sweepPaint);
        }
      } else {
        // Renderizado Fallback / Entidades
        final paint = Paint()
          ..color = color
          ..strokeWidth = colWidth + 1;

        canvas.drawLine(
          Offset(x + colWidth / 2, drawYTop),
          Offset(x + colWidth / 2, drawYBottom),
          paint,
        );
      }
    }

    // Render Echolocation Light Pulse
    for (final echo in echoes) {
      final distFromPlayer = echo.position.distanceTo(player.position);

      // Only render if the echo is at/near the player position
      if (distFromPlayer < 50) {
        final normalizedRadius = echo.radius / echo.maxRadius;

        // Create expanding ring effect
        final centerX = renderSize.x / 2;
        final centerY = renderSize.y / 2 + bobOffset + crouchOffset;

        // Calculate screen radius based on world radius
        final screenRadiusMax = math.min(renderSize.x, renderSize.y) * 0.7;
        final screenRadius = normalizedRadius * screenRadiusMax;

        final echoPaint = Paint()
          ..color = const Color(0xFF00FFFF).withAlpha(
            ((1.0 - normalizedRadius).clamp(0.0, 1.0) * 255).round(),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(Offset(centerX, centerY), screenRadius, echoPaint);

        final pulsePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * (1.0 - normalizedRadius)
          ..color = const Color(
            0xFF00FFFF,
          ).withAlpha((0.5 * (1.0 - normalizedRadius) * 255).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawCircle(Offset(centerX, centerY), screenRadius, pulsePaint);
      }
    }
    canvas.restore(); // Restore canvas state
  }

  /// Checks if there is a direct line of sight between two points in the grid.
  /// Returns true if unblocked, false if a wall obstructs the view.
  bool _hasLineOfSight(
    Vector2 start,
    Vector2 end,
    List<List<CeldaData>> grid,
    double tileSize,
  ) {
    final dist = start.distanceTo(end);
    if (dist < 1.0) return true; // Too close to be blocked

    final dir = (end - start).normalized();
    var current = start.clone();
    // Step size: smaller than a tile to catch corners, but not too small for performance
    final step = tileSize * 0.5;
    var travelled = 0.0;

    // Move start slightly away to avoid self-collision if start is inside a wall (unlikely for lights)
    current += dir * (tileSize * 0.1);

    while (travelled < dist - tileSize * 0.5) {
      // Stop before hitting the target wall itself
      current += dir * step;
      travelled += step;

      final cx = (current.x / tileSize).floor();
      final cy = (current.y / tileSize).floor();

      if (cy >= 0 && cy < grid.length && cx >= 0 && cx < grid[0].length) {
        if (grid[cy][cx].tipo == TipoCelda.pared) {
          return false; // Blocked by a wall
        }
      }
    }
    return true;
  }

  /// Renders floor and ceiling using a vertex grid for perspective-correct lighting.
  void _renderFloorAndCeilingVertices(
    Canvas canvas,
    Vector2 renderSize,
    PlayerComponent player,
    List<LightSourceComponent> lights,
    Iterable<EcholocationVfxComponent> echoes, // Added echoes
    double bobOffset,
    double crouchOffset,
    double tileSize,
    Color ambientColor,
    Color fogColor,
  ) {
    final horizonY = renderSize.y / 2 + bobOffset + crouchOffset;

    // Grid parameters
    const gridRows = 20; // Depth resolution
    const gridCols = 10; // Horizontal resolution

    // We will build a mesh for the floor.
    // The mesh is a trapezoid in screen space (wide at bottom, narrow at horizon).
    // But to map world coordinates correctly, we need to cast rays for each vertex.

    final vertices = <Offset>[];
    final colors = <Color>[];
    final indices = <int>[];

    // Generate vertices
    for (var row = 0; row <= gridRows; row++) {
      // Depth factor (0.0 at horizon, 1.0 at bottom)
      // Use non-linear spacing for better quality near camera
      final t = row / gridRows;
      final depthT = t * t; // Quadratic distribution

      // Screen Y
      final screenY = horizonY + (renderSize.y - horizonY) * depthT;

      // Calculate World Distance for this row
      // y = H / z  => z = H / y
      // H is camera height (approx renderSize.y / 2)
      // y is pixels from horizon
      final pixelsFromHorizon = screenY - horizonY;
      if (pixelsFromHorizon <= 0.1) continue;

      final worldDist =
          (renderSize.y * 0.5) * tileSize / pixelsFromHorizon; // Approx

      // Calculate World Width at this distance
      // width = z * tan(fov/2) * 2
      final worldWidth = worldDist * math.tan(fov / 2) * 2;

      for (var col = 0; col <= gridCols; col++) {
        final u = col / gridCols; // 0.0 to 1.0 (Left to Right)

        // Screen X
        final screenX = u * renderSize.x;

        // World Position Calculation
        // Relative to player
        final relX = (u - 0.5) * worldWidth;
        final relY = worldDist;

        // Rotate by player heading
        final sinH = math.sin(player.heading);
        final cosH = math.cos(player.heading);

        final wX = player.position.x + (relY * cosH - relX * sinH);
        final wY = player.position.y + (relY * sinH + relX * cosH);

        // Calculate Lighting at (wX, wY)
        var r = ambientColor.red / 255.0;
        var g = ambientColor.green / 255.0;
        var b = ambientColor.blue / 255.0;

        // Fog
        const fogDensity = 0.15;
        var fogFactor = math.exp(-fogDensity * (worldDist / tileSize));
        fogFactor = fogFactor.clamp(0.0, 1.0);

        // Dynamic Lights
        for (final light in lights) {
          final dx = wX - light.position.x;
          final dy = wY - light.position.y;
          final distSq = dx * dx + dy * dy;
          final radiusSq = light.radius * light.radius;

          if (distSq < radiusSq) {
            final dist = math.sqrt(distSq);
            final normDist = dist / light.radius;
            final att = math.pow(1.0 - normDist, 2).toDouble().clamp(0.0, 1.0);

            r += (light.color.red / 255.0) * att * light.effectiveIntensity;
            g += (light.color.green / 255.0) * att * light.effectiveIntensity;
            b += (light.color.blue / 255.0) * att * light.effectiveIntensity;
          }
        }

        // Sonic Wave (Gaussian Falloff)
        for (final echo in echoes) {
          final dx = wX - echo.position.x;
          final dy = wY - echo.position.y;
          final dist = math.sqrt(dx * dx + dy * dy);

          // Gaussian Falloff: exp(-pow(dist - radius, 2) / decay)
          // Decay controls the width of the ring.
          const decay = 800.0; // Adjust for ring width
          final diff = dist - echo.radius;
          final gaussian = math.exp(-(diff * diff) / decay);

          if (gaussian > 0.01) {
            // Additive blending for the wave
            // Echo color is usually Cyan/White
            r += gaussian * 0.8;
            g += gaussian * 1.0; // Slightly more green for Cyan
            b += gaussian * 1.0;
          }
        }

        // Apply Fog
        r = r * fogFactor + (fogColor.red / 255.0) * (1 - fogFactor);
        g = g * fogFactor + (fogColor.green / 255.0) * (1 - fogFactor);
        b = b * fogFactor + (fogColor.blue / 255.0) * (1 - fogFactor);

        vertices.add(Offset(screenX, screenY));
        colors.add(
          Color.fromARGB(
            255,
            (r.clamp(0.0, 1.0) * 255).toInt(),
            (g.clamp(0.0, 1.0) * 255).toInt(),
            (b.clamp(0.0, 1.0) * 255).toInt(),
          ),
        );
      }
    }

    // Generate Indices (Triangle Strip)
    // For each row
    for (var row = 0; row < gridRows - 1; row++) {
      // -1 because we skip the very first row if pixelsFromHorizon is small
      for (var col = 0; col < gridCols; col++) {
        final i = row * (gridCols + 1) + col;
        final nextRowI = (row + 1) * (gridCols + 1) + col;

        // Triangle 1
        indices.add(i);
        indices.add(nextRowI);
        indices.add(i + 1);

        // Triangle 2
        indices.add(i + 1);
        indices.add(nextRowI);
        indices.add(nextRowI + 1);
      }
    }

    if (vertices.isNotEmpty) {
      final v = ui.Vertices(
        ui.VertexMode.triangles,
        vertices,
        colors: colors,
        indices: indices,
      );
      canvas.drawVertices(v, BlendMode.modulate, Paint());
    }
  }

  @override
  int get priority => -1000; // Renderizar antes que todo (fondo)
}
