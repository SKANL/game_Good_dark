import 'package:echo_world/game/components/abyss_component.dart';
import 'package:echo_world/game/components/eco_narrativo_component.dart';
import 'package:echo_world/game/components/batch_geometry_renderer.dart';
import 'package:echo_world/game/components/component_pool.dart';
import 'package:echo_world/game/components/transition_zone_component.dart';
import 'package:echo_world/game/components/wall_component.dart';
import 'package:echo_world/game/entities/enemies/enemies.dart';
import 'package:echo_world/game/level/level_models.dart';

import 'package:echo_world/game/cubit/checkpoint/cubit.dart';
import 'package:echo_world/game/black_echo_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'package:echo_world/game/level/level_generator.dart';

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
    final chunk = _generator.generateLevel(index, sector);
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
    for (final c in _levelComponents) {
      // Si es un enemigo, devolverlo al pool antes de remover
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
        // Otros componentes (abismos, transiciones) se destruyen normalmente
        c.removeFromParent();
      }
    }
    _levelComponents.clear();

    // Cargar geometría del chunk
    // OPTIMIZACIÓN: Paredes se agregan al batch renderer (1 draw call)
    // Solo WallComponents físicos invisibles para colisiones
    for (var y = 0; y < chunk.alto; y++) {
      for (var x = 0; x < chunk.ancho; x++) {
        final celda = chunk.grid[y][x];
        final pos = Vector2(x * tileSize, y * tileSize);

        if (celda.tipo == TipoCelda.pared) {
          // Agregar geometría al batch renderer para renderizado eficiente
          _wallBatchRenderer.addGeometry(
            position: pos,
            size: Vector2(tileSize, tileSize),
            color: celda.esDestructible
                ? const Color(0xFF444444) // Paredes destructibles más claras
                : const Color(0xFF222222), // Paredes normales
            destructible: celda.esDestructible,
          );

          // Crear WallComponent invisible solo para colisiones
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

        // Spawn Narrative Echo if present
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

    // Marcar el batch como dirty para que se re-renderice
    _wallBatchRenderer.markDirty();

    // Crear zonas de transición en los bordes del chunk
    await _crearZonasDeTransicion(chunk);

    // Spawnear entidades definidas en el chunk usando pools
    for (final spawn in chunk.entidadesIniciales) {
      final pos = Vector2(
        spawn.posicion.x * tileSize,
        spawn.posicion.y * tileSize,
      );

      // Usar pools en lugar de crear nuevas instancias
      if (spawn.tipoEnemigo == CazadorComponent) {
        final enemy = _cazadorPool.acquire();
        enemy.position = pos;
        await parent?.add(enemy);
        // Resetear DESPUÉS de agregar al árbol (behaviors ya están montados)
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

    // Fallback: Zona Este (derecha) completa
    const zoneThickness = tileSize * 2;
    final eastZone = TransitionZoneComponent(
      position: Vector2((chunk.ancho - 2) * tileSize, 0),
      size: Vector2(zoneThickness, chunk.alto * tileSize),
      targetChunkDirection: 'east',
    );
    await parent?.add(eastZone);
    _levelComponents.add(eastZone);
  }

  Future<void> siguienteChunk() async {
    _idx++;
    await _cargarNivel(_idx);

    // Reposicionar al jugador
    final game = gameRef as BlackEchoGame;
    final chunk = _current!;

    if (chunk.spawnPoint != null) {
      game.player.position = chunk.spawnPoint! * tileSize;
    } else {
      // Fallback: centro del mapa
      game.player.position = Vector2(
        (chunk.ancho / 2) * tileSize,
        (chunk.alto / 2) * tileSize,
      );
    }
  }
}

extension LevelManagerSnapshot on LevelManagerComponent {
  /// Acceso de solo lectura al grid del chunk actual
  List<List<CeldaData>>? get currentGrid => _current?.grid;
  LevelData? get currentChunk => _current;
}
