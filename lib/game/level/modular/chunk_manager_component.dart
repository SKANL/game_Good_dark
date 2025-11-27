import 'dart:async';
import 'dart:collection';
import 'dart:ui';

import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/components/core/batch_geometry_renderer.dart';
import 'package:echo_world/game/components/core/component_pool.dart';
import 'package:echo_world/game/components/world/abyss_component.dart';
import 'package:echo_world/game/components/world/eco_narrativo_component.dart';
import 'package:echo_world/game/components/world/lore_item_component.dart';
import 'package:echo_world/game/components/world/tunnel_component.dart';
import 'package:echo_world/game/components/world/wall_component.dart';
import 'package:echo_world/game/entities/enemies/bruto.dart';
import 'package:echo_world/game/entities/enemies/cazador.dart';
import 'package:echo_world/game/entities/enemies/vigia.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

class ChunkManagerComponent extends Component with HasGameRef<BlackEchoGame> { // 4ms loading budget per frame

  ChunkManagerComponent({
    required this.levelData,
    required this.wallBatchRenderer,
    required this.cazadorPool,
    required this.vigiaPool,
    required this.brutoPool,
  });
  final LevelMapData levelData;
  final BatchGeometryRenderer wallBatchRenderer;

  final ComponentPool<CazadorComponent> cazadorPool;
  final ComponentPool<VigiaComponent> vigiaPool;
  final ComponentPool<BrutoComponent> brutoPool;

  static const double tileSize = 32;

  // Time-Slicing Queue
  final Queue<Component> _loadQueue = Queue<Component>();
  static const int _frameBudgetMs = 4;

  int _currentChunkIndex = -1;
  bool _hasProcessedItems = false;

  @override
  void update(double dt) {
    super.update(dt);
    _checkPlayerChunk();
    // Call async method without await to not block update loop
    // Components will be added over multiple frames
    _processLoadQueue();
  }

  Future<void> _processLoadQueue() async {
    if (_loadQueue.isEmpty) return;

    final stopwatch = Stopwatch()..start();

    while (_loadQueue.isNotEmpty) {
      if (stopwatch.elapsedMilliseconds >= _frameBudgetMs) {
        break; // Budget exceeded, continue next frame
      }

      final component = _loadQueue.removeFirst();
      // CRITICAL FIX: AWAIT the add() so component is mounted and queryable
      await gameRef.world.add(component);
      _hasProcessedItems = true;
    }

    // Only update batch if we actually added something AND the queue is empty
    if (_hasProcessedItems && _loadQueue.isEmpty) {
      wallBatchRenderer.markDirty();
      _hasProcessedItems = false; // Reset flag
    }

    stopwatch.stop();
  }

  void _checkPlayerChunk() {
    final playerPos = gameRef.player.position;
    final playerX = playerPos.x / tileSize;
    final playerY = playerPos.y / tileSize;

    var newIndex = -1;
    for (var i = 0; i < levelData.chunks.length; i++) {
      final chunk = levelData.chunks[i];
      if (playerX >= chunk.bounds.left &&
          playerX < chunk.bounds.right &&
          playerY >= chunk.bounds.top &&
          playerY < chunk.bounds.bottom) {
        newIndex = i;
        break;
      }
    }

    if (newIndex != -1 && newIndex != _currentChunkIndex) {
      _currentChunkIndex = newIndex;
      _updateVisibleChunks();
    }
  }

  void _updateVisibleChunks() {
    final chunksToLoad = <int>{};
    if (_currentChunkIndex > 0) chunksToLoad.add(_currentChunkIndex - 1);
    chunksToLoad.add(_currentChunkIndex);
    if (_currentChunkIndex < levelData.chunks.length - 1) {
      chunksToLoad.add(_currentChunkIndex + 1);
    }

    for (var i = 0; i < levelData.chunks.length; i++) {
      if (chunksToLoad.contains(i)) {
        _loadChunk(i);
      } else {
        _unloadChunk(i);
      }
    }

    // Force update to ensure unloaded chunks are removed
    wallBatchRenderer.markDirty();
  }

  Future<void> _loadChunk(int index) async {
    final chunk = levelData.chunks[index];
    if (chunk.isLoaded) return;

    chunk.isLoaded = true;

    final generationData = await compute(
      _generateChunkData,
      _ChunkGenerationArgs(
        grid: chunk.grid,
        entities: chunk.entities,
        startX: chunk.bounds.left.toInt(),
        levelWidth: levelData.ancho,
        tileSize: tileSize,
        yOffset: chunk.yOffset,
        chunkId: chunk.id, // Pass chunk ID for special handling
      ),
    );

    if (!chunk.isLoaded) return;

    final wallRects = <Rect>[];
    final destructibleWallRects = <Rect>[];
    final chunkOffset = Vector2(
      chunk.bounds.left * tileSize,
      chunk.bounds.top * tileSize,
    );

    for (final entityData in generationData.entities) {
      Component? component;
      final globalPos = entityData.position + chunkOffset;

      switch (entityData.type) {
        case EntityType.wall:
          final isDestructible =
              entityData.properties['destructible'] as bool? ?? false;

          final rect = Rect.fromLTWH(
            entityData.position.x,
            entityData.position.y,
            entityData.size.x,
            entityData.size.y,
          );

          if (isDestructible) {
            destructibleWallRects.add(rect);
          } else {
            wallRects.add(rect);
          }

          // CRITICAL FIX: Add WallComponent for ALL walls (like LevelManager does)
          // This ensures Echolocation can find and outline ALL walls, not just destructible ones
          final wall = WallComponent(
            position: globalPos,
            size: entityData.size,
            destructible: isDestructible,
          );
          await gameRef.world.add(wall);
          chunk.loadedComponents.add(wall);

        case EntityType.abyss:
          component = AbyssComponent(
            position: globalPos,
            size: entityData.size,
          );

        case EntityType.echo:
          component = EcoNarrativoComponent(
            ecoId: entityData.properties['id'] as String,
            position: globalPos + Vector2.all(tileSize / 2),
          );

        case EntityType.enemy:
          final enemyType = entityData.properties['enemyType'] as String;
          if (enemyType == 'CazadorComponent') {
            final e = cazadorPool.acquire();
            e.position = globalPos;
            e.reset();
            component = e;
          } else if (enemyType == 'VigiaComponent') {
            final e = vigiaPool.acquire();
            e.position = globalPos;
            e.reset();
            component = e;
          } else if (enemyType == 'BrutoComponent') {
            final e = brutoPool.acquire();
            e.position = globalPos;
            e.reset();
            component = e;
          }

        case EntityType.lore:
          final loreId = entityData.properties['loreId'] as String;
          component = LoreItemComponent(
            position: globalPos,
            loreId: loreId,
          );

        case EntityType.tunnel:
          component = TunnelComponent(
            position: globalPos,
            size: entityData.size,
          );
      }

      if (component != null) {
        _loadQueue.add(component);
        chunk.loadedComponents.add(component);
      }
    }

    if (wallRects.isNotEmpty) {
      wallBatchRenderer.addRects(
        rects: wallRects,
        offset: chunkOffset,
        color: const Color(0xFF222222),
      );
    }
    if (destructibleWallRects.isNotEmpty) {
      wallBatchRenderer.addRects(
        rects: destructibleWallRects,
        offset: chunkOffset,
        color: const Color(0xFF444444),
        destructible: true,
      );
    }

    // Force batch update now that walls are added
    wallBatchRenderer.markDirty();
  }

  void _unloadChunk(int index) {
    final chunk = levelData.chunks[index];
    if (!chunk.isLoaded) return;

    for (final c in chunk.loadedComponents) {
      if (_loadQueue.contains(c)) {
        _loadQueue.remove(c);
      } else {
        c.removeFromParent();
      }

      if (c is WallComponent) {
        wallBatchRenderer.removeGeometry(c.position);
      } else if (c is CazadorComponent)
        cazadorPool.release(c);
      else if (c is VigiaComponent)
        vigiaPool.release(c);
      else if (c is BrutoComponent)
        brutoPool.release(c);
    }

    chunk.loadedComponents.clear();
    chunk.isLoaded = false;
  }

  @override
  void onRemove() {
    for (var i = 0; i < levelData.chunks.length; i++) {
      _unloadChunk(i);
    }
    _loadQueue.clear();
    super.onRemove();
  }
}

// --- Isolate Logic ---

// Enum to differentiate entity types generated in the isolate
enum EntityType { wall, abyss, echo, enemy, lore, tunnel }

// Data class to hold information about an entity generated in the isolate
class EntityData { // For additional data like destructible, ecoId, enemyType

  EntityData({
    required this.type,
    required this.position,
    required this.size,
    this.properties = const {},
  });
  final EntityType type;
  final Vector2 position;
  final Vector2 size;
  final Map<String, dynamic>
  properties;
}

// Data class to hold the result of chunk generation
class ChunkGenerationData {

  ChunkGenerationData({required this.entities});
  final List<EntityData> entities;
}

// Arguments for the _generateChunkData function
class _ChunkGenerationArgs {

  _ChunkGenerationArgs({
    required this.grid,
    required this.entities,
    required this.startX,
    required this.levelWidth,
    required this.tileSize,
    required this.yOffset,
    required this.chunkId,
  });
  final Grid grid;
  final List<EntidadSpawn> entities;
  final int startX;
  final int levelWidth;
  final double tileSize;
  final int yOffset;
  final String chunkId;
}

// Top-level function to be run in an isolate for chunk data generation
ChunkGenerationData _generateChunkData(_ChunkGenerationArgs args) {
  final entities = <EntityData>[];
  final chunkH = args.grid.length;
  final chunkW = args.grid[0].length;

  // 1. Grid Entities (Walls, Abysses, Echoes)
  for (var y = 0; y < chunkH; y++) {
    for (var x = 0; x < chunkW; x++) {
      // We now calculate LOCAL positions relative to the chunk
      final celda = args.grid[y][x];
      final pos = Vector2(
        x * args.tileSize,
        y * args.tileSize,
      );
      final size = Vector2(args.tileSize, args.tileSize);

      if (celda.tipo == TipoCelda.pared) {
        entities.add(
          EntityData(
            type: EntityType.wall,
            position: pos,
            size: size,
            properties: {'destructible': celda.esDestructible},
          ),
        );
      } else if (celda.tipo == TipoCelda.abismo) {
        entities.add(
          EntityData(
            type: EntityType.abyss,
            position: pos,
            size: size,
          ),
        );
      } else if (celda.tipo == TipoCelda.tunel) {
        // Spawn TunnelComponent for visual feedback
        entities.add(
          EntityData(
            type: EntityType.tunnel,
            position: pos,
            size: size,
          ),
        );
      }

      if (celda.ecoNarrativoId != null) {
        entities.add(
          EntityData(
            type: EntityType.echo,
            position: pos,
            size: size,
            properties: {'id': celda.ecoNarrativoId},
          ),
        );
      }
    }
  }

  // 2. Spawned Entities (Enemies)
  for (final spawn in args.entities) {
    // Convert Global Spawn Position to Local
    // spawn.posicion is in tiles (Global)
    // args.startX/yOffset are in tiles (Global Top-Left of Chunk)
    final localX = spawn.posicion.x - args.startX;
    final localY = spawn.posicion.y - args.yOffset;

    final pos = Vector2(localX * args.tileSize, localY * args.tileSize);
    final size = Vector2(args.tileSize, args.tileSize);

    var enemyType = '';
    if (spawn.tipoEnemigo == CazadorComponent) {
      enemyType = 'CazadorComponent';
    } else if (spawn.tipoEnemigo == VigiaComponent) {
      enemyType = 'VigiaComponent';
    } else if (spawn.tipoEnemigo == BrutoComponent) {
      enemyType = 'BrutoComponent';
    }

    if (enemyType.isNotEmpty) {
      entities.add(
        EntityData(
          type: EntityType.enemy,
          position: pos,
          size: size,
          properties: {'enemyType': enemyType},
        ),
      );
    }
  }

  // 3. LoreItems (Special Chunks)
  // Spawn LoreItem in specific chunks
  if (args.chunkId == 'stealth_tunnel_guarded') {
    // Place LoreItem at center of tunnel
    entities.add(
      EntityData(
        type: EntityType.lore,
        position: Vector2(8 * args.tileSize, 5.5 * args.tileSize),
        size: Vector2(args.tileSize, args.tileSize),
        properties: {'loreId': 'lore_4'}, // Sujeto 7
      ),
    );
  } else if (args.chunkId == 'destructible_gate') {
    // Place LoreItem behind destructible wall
    entities.add(
      EntityData(
        type: EntityType.lore,
        position: Vector2(10 * args.tileSize, 6 * args.tileSize),
        size: Vector2(args.tileSize, args.tileSize),
        properties: {'loreId': 'lore_5'}, // El Incidente
      ),
    );
  }

  return ChunkGenerationData(entities: entities);
}
