import 'dart:math';

import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/components/core/batch_geometry_renderer.dart';
import 'package:echo_world/game/components/core/component_pool.dart';
import 'package:echo_world/game/components/world/abyss_component.dart';
import 'package:echo_world/game/components/world/eco_narrativo_component.dart';
import 'package:echo_world/game/components/world/transition_zone_component.dart';
import 'package:echo_world/game/components/world/wall_component.dart';
import 'package:echo_world/game/cubit/checkpoint/checkpoint_bloc.dart';
import 'package:echo_world/game/cubit/checkpoint/checkpoint_event.dart';
import 'package:echo_world/game/entities/enemies/bruto.dart';
import 'package:echo_world/game/entities/enemies/cazador.dart';
import 'package:echo_world/game/entities/enemies/vigia.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:echo_world/game/level/manager/level_generator.dart';
import 'package:echo_world/game/level/modular/chunk_manager_component.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class LevelManagerComponent extends Component with HasGameRef {
  LevelManagerComponent({required this.checkpointBloc});

  final CheckpointBloc checkpointBloc;
  static const double tileSize = 32;

  final LevelGenerator _generator = LevelGenerator();
  int _idx = 0;
  LevelData? _current; // Chunk actual cargado (expuesto para vistas)
  List<List<CeldaData>>? get currentGrid => _current?.grid;

  // Referencias a componentes del nivel para poder limpiarlos
  final List<Component> _levelComponents = [];

  // ===== COMPONENT POOLS (Optimización de rendimiento) =====
  // Pools para enemigos - reduce GC pressure en transiciones de chunks
  late final ComponentPool<CazadorComponent> _cazadorPool;
  late final ComponentPool<VigiaComponent> _vigiaPool;
  late final ComponentPool<BrutoComponent> _brutoPool;

  // ===== BATCH RENDERER (Optimización de draw calls) =====
  // Renderiza todas las paredes en 1 Picture en lugar de N draw calls
  late final BatchGeometryRenderer _wallBatchRenderer;

  @override
  Future<void> onLoad() async {
    // Inicializar batch renderer
    _wallBatchRenderer = BatchGeometryRenderer();
    await parent?.add(_wallBatchRenderer);

    // Inicializar pools con configuración optimizada para móvil
    _cazadorPool = ComponentPool<CazadorComponent>(
      factory: () => CazadorComponent(position: Vector2.zero()),
      maxSize: 20,
      preloadSize: 5,
    );

    _vigiaPool = ComponentPool<VigiaComponent>(
      factory: () => VigiaComponent(position: Vector2.zero()),
      maxSize: 10,
      preloadSize: 3,
    );

    _brutoPool = ComponentPool<BrutoComponent>(
      factory: () => BrutoComponent(position: Vector2.zero()),
      maxSize: 10,
      preloadSize: 2,
    );

    // Cargar primer nivel
    await _cargarNivel(_idx);
  }

  Future<void> _cargarNivel(int index) async {
    final sector = _getSectorForLevel(index);
    final chunk = await _generator.generateLevel(index, sector);
    await _cargarChunk(chunk);
  }

  Sector _getSectorForLevel(int index) {
    if (index < 7) return Sector.contencion;
    if (index < 13) return Sector.laboratorios;
    return Sector.salida;
  }

  Future<void> _cargarChunk(LevelData chunk) async {
    // Guardar referencia del chunk actual
    _current = chunk;
    // Auto-save: notificar al CheckpointBloc que cambiamos de chunk
    checkpointBloc.add(ChunkCambiado(_idx));

    // Limpiar batch renderer anterior
    _wallBatchRenderer.clearGeometries();

    // Liberar componentes del nivel anterior (devolverlos a los pools)
    // Si usábamos ChunkManager, él ya limpió. Si no, limpiamos manual.
    for (final c in _levelComponents) {
      if (c is CazadorComponent) {
        c.removeFromParent();
        _cazadorPool.release(c);
      } else if (c is VigiaComponent) {
        c.removeFromParent();
        _vigiaPool.release(c);
      } else if (c is BrutoComponent) {
        c.removeFromParent();
        _brutoPool.release(c);
      } else {
        c.removeFromParent();
      }
    }
    _levelComponents.clear();

    // Remove old ChunkManager if exists
    final oldManager = parent?.children
        .whereType<ChunkManagerComponent>()
        .firstOrNull;
    if (oldManager != null) oldManager.removeFromParent();

    // Check if it's a Modular Level (LevelMapData)
    if (chunk is LevelMapData) {
      // Use ChunkManager for dynamic loading
      final manager = ChunkManagerComponent(
        levelData: chunk,
        wallBatchRenderer: _wallBatchRenderer,
        cazadorPool: _cazadorPool,
        vigiaPool: _vigiaPool,
        brutoPool: _brutoPool,
      );
      await parent?.add(manager);
      _levelComponents.add(manager);

      // Force initial update to load first chunks
      manager.update(0);
    } else {
      // Legacy/Static Chunk Loading (for Tutorial/Early levels)

      // Cargar geometría del chunk
      for (var y = 0; y < chunk.alto; y++) {
        for (var x = 0; x < chunk.ancho; x++) {
          final celda = chunk.grid[y][x];
          final pos = Vector2(x * tileSize, y * tileSize);

          if (celda.tipo == TipoCelda.pared) {
            _wallBatchRenderer.addGeometry(
              position: pos,
              size: Vector2(tileSize, tileSize),
              color: celda.esDestructible
                  ? const Color(0xFF444444)
                  : const Color(0xFF222222),
              destructible: celda.esDestructible,
            );

            final wall = WallComponent(
              position: pos,
              size: Vector2(tileSize, tileSize),
              destructible: celda.esDestructible,
            );
            await parent?.add(wall);
            _levelComponents.add(wall);
          } else if (celda.tipo == TipoCelda.abismo) {
            final abyss = AbyssComponent(
              position: pos,
              size: Vector2(tileSize, tileSize),
            );
            await parent?.add(abyss);
            _levelComponents.add(abyss);
          }

          if (celda.ecoNarrativoId != null) {
            final eco = EcoNarrativoComponent(
              ecoId: celda.ecoNarrativoId!,
              position: pos + Vector2.all(tileSize / 2),
            );
            await parent?.add(eco);
            _levelComponents.add(eco);
          }
        }
      }
      _wallBatchRenderer.markDirty();

      // Spawnear entidades
      for (final spawn in chunk.entidadesIniciales) {
        final pos = Vector2(
          spawn.posicion.x * tileSize,
          spawn.posicion.y * tileSize,
        );

        if (spawn.tipoEnemigo == CazadorComponent) {
          final enemy = _cazadorPool.acquire();
          enemy.position = pos;
          await parent?.add(enemy);
          enemy.reset();
          _levelComponents.add(enemy);
        } else if (spawn.tipoEnemigo == VigiaComponent) {
          final enemy = _vigiaPool.acquire();
          enemy.position = pos;
          await parent?.add(enemy);
          enemy.reset();
          _levelComponents.add(enemy);
        } else if (spawn.tipoEnemigo == BrutoComponent) {
          final enemy = _brutoPool.acquire();
          enemy.position = pos;
          await parent?.add(enemy);
          enemy.reset();
          _levelComponents.add(enemy);
        }
      }
    }

    // Crear zonas de transición en los bordes del chunk
    await _crearZonasDeTransicion(chunk);
  }

  @override
  void onRemove() {
    // Limpiar pools al destruir el LevelManager
    _cazadorPool.clear();
    _vigiaPool.clear();
    _brutoPool.clear();
    super.onRemove();
  }

  /// Verifica si un rectángulo en coordenadas del mundo está libre para
  /// que una entidad lo ocupe (sin paredes ni abismos).
  ///
  /// `rect` está en unidades de píxeles (coordenadas del juego). Devuelve
  /// `true` si todas las celdas ocupadas por `rect` son transitables.
  bool isRectWalkable(Rect rect) {
    final grid = _current?.grid;
    if (grid == null) return true; // si no hay grid, no bloqueamos

    final ts = tileSize;

    // Calcular índices de tiles cubiertos por el rect
    final startX = (rect.left / ts).floor().clamp(0, grid[0].length - 1);
    final endX = ((rect.right - 0.0001) / ts).floor().clamp(
      0,
      grid[0].length - 1,
    );
    final startY = (rect.top / ts).floor().clamp(0, grid.length - 1);
    final endY = ((rect.bottom - 0.0001) / ts).floor().clamp(
      0,
      grid.length - 1,
    );

    for (var y = startY; y <= endY; y++) {
      for (var x = startX; x <= endX; x++) {
        final cel = grid[y][x];
        if (cel.tipo != TipoCelda.suelo) {
          // pared o abismo -> no transitables
          return false;
        }
      }
    }
    return true;
  }

  /// Crea zonas de transición en los bordes del chunk para detectar
  /// cuándo el jugador debe avanzar al siguiente nivel
  Future<void> _crearZonasDeTransicion(LevelData chunk) async {
    // Si hay un punto de salida definido, usarlo
    if (chunk.exitPoint != null) {
      final exitPos = chunk.exitPoint! * tileSize;
      final zone = TransitionZoneComponent(
        position: exitPos,
        size: Vector2(tileSize, tileSize),
        targetChunkDirection: 'east',
      );
      await parent?.add(zone);
      _levelComponents.add(zone);
      return;
    }

    // Fallback: Zona Este (derecha) completa (SOLO para niveles estáticos)
    if (chunk is! LevelMapData) {
      const zoneThickness = tileSize * 2;
      final eastZone = TransitionZoneComponent(
        position: Vector2((chunk.ancho - 2) * tileSize, 0),
        size: Vector2(zoneThickness, chunk.alto * tileSize),
        targetChunkDirection: 'east',
      );
      await parent?.add(eastZone);
      _levelComponents.add(eastZone);
    }
  }

  Future<void> siguienteChunk() async {
    _idx++;
    await _cargarNivel(_idx);

    // Reposicionar al jugador
    final game = gameRef as BlackEchoGame;
    final chunk = _current!;

    if (chunk.spawnPoint != null) {
      // Validate spawn point from data
      final safe = _findValidSpawn(
        chunk.grid,
        chunk.spawnPoint!.x.toInt(),
        chunk.spawnPoint!.y.toInt(),
      );
      game.player.position = safe * tileSize;
    } else {
      // Fallback: center of map
      final centerX = chunk.ancho ~/ 2;
      final centerY = chunk.alto ~/ 2;
      final safe = _findValidSpawn(chunk.grid, centerX, centerY);
      game.player.position = safe * tileSize;
    }
  }

  /// Searches for the nearest valid floor tile starting from [startX], [startY].
  /// Returns the center of the tile as a Vector2.
  Vector2 _findValidSpawn(List<List<CeldaData>> grid, int startX, int startY) {
    // Check bounds first
    if (startY < 0 ||
        startY >= grid.length ||
        startX < 0 ||
        startX >= grid[0].length) {
      return Vector2(startX + 0.5, startY + 0.5);
    }

    // If already valid, return it
    if (grid[startY][startX].tipo == TipoCelda.suelo) {
      return Vector2(startX + 0.5, startY + 0.5);
    }

    // BFS to find nearest floor
    final queue = <Point<int>>[Point(startX, startY)];
    final visited = <Point<int>>{Point(startX, startY)};
    // 8 directions for better coverage
    final directions = [
      const Point(0, 1),
      const Point(0, -1),
      const Point(1, 0),
      const Point(-1, 0),
      const Point(1, 1),
      const Point(1, -1),
      const Point(-1, 1),
      const Point(-1, -1),
    ];

    // Limit search radius
    int checks = 0;
    const maxChecks = 200;

    while (queue.isNotEmpty && checks < maxChecks) {
      final current = queue.removeAt(0);
      checks++;

      if (current.y >= 0 &&
          current.y < grid.length &&
          current.x >= 0 &&
          current.x < grid[0].length) {
        if (grid[current.y][current.x].tipo == TipoCelda.suelo) {
          return Vector2(current.x + 0.5, current.y + 0.5);
        }
      }

      for (final dir in directions) {
        final next = Point(current.x + dir.x, current.y + dir.y);
        if (!visited.contains(next)) {
          visited.add(next);
          queue.add(next);
        }
      }
    }

    // Absolute fallback
    return Vector2(startX + 0.5, startY + 0.5);
  }
}

extension LevelManagerSnapshot on LevelManagerComponent {
  /// Acceso de solo lectura al grid del chunk actual
  List<List<CeldaData>>? get currentGrid => _current?.grid;
  LevelData? get currentChunk => _current;
}
