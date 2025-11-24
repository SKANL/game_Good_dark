import 'dart:math';
import 'dart:ui';

import 'package:echo_world/game/level/data/level_models.dart';
import 'package:echo_world/game/level/modular/chunk_blueprint.dart';
import 'package:echo_world/game/level/modular/chunk_library.dart';
import 'package:flame/components.dart';

class ModularLevelBuilder {
  final Random _random = Random();

  /// Generates a level asynchronously to prevent UI blocking.
  Future<LevelMapData> buildLevel({
    required int length,
    required Dificultad dificultad,
    required Sector sector,
    String name = 'Modular Level',
  }) async {
    final placedChunks = <_PlacedChunk>[];

    // 1. Start Chunk (Always at 0,0)
    var currentPos = const Point(0, 0);
    var currentChunk = ChunkLibrary.getStartChunk();
    placedChunks.add(_PlacedChunk(currentChunk, currentPos));

    // Track occupied positions
    final occupied = <Point<int>>{const Point(0, 0)};

    // 2. Generate Path
    for (var i = 0; i < length; i++) {
      // Determine valid next directions
      final candidates = <Direccion>[];

      // Check East
      if (!occupied.contains(Point(currentPos.x + 1, currentPos.y)) &&
          currentChunk.connectionPoints.containsKey(Direccion.este)) {
        candidates.add(Direccion.este);
      }
      // Check North (y - 1)
      if (!occupied.contains(Point(currentPos.x, currentPos.y - 1)) &&
          currentChunk.connectionPoints.containsKey(Direccion.norte)) {
        candidates.add(Direccion.norte);
      }
      // Check South (y + 1)
      if (!occupied.contains(Point(currentPos.x, currentPos.y + 1)) &&
          currentChunk.connectionPoints.containsKey(Direccion.sur)) {
        candidates.add(Direccion.sur);
      }

      if (candidates.isEmpty) break; // Dead end

      // Pick a direction
      Direccion nextDir;
      if (candidates.contains(Direccion.este) && _random.nextDouble() < 0.6) {
        nextDir = Direccion.este;
      } else {
        nextDir = candidates[_random.nextInt(candidates.length)];
      }

      // Find a compatible chunk
      Direccion requiredEntry;
      switch (nextDir) {
        case Direccion.este:
          requiredEntry = Direccion.oeste;
          break;
        case Direccion.norte:
          requiredEntry = Direccion.sur;
          break;
        case Direccion.sur:
          requiredEntry = Direccion.norte;
          break;
        case Direccion.oeste:
          requiredEntry = Direccion.este;
          break;
      }

      ChunkType type = _random.nextBool()
          ? ChunkType.connector
          : ChunkType.arena;
      if (i == length - 1)
        type = ChunkType.connector; // Last one before End should be simple

      // Filter library
      final validBlueprints = ChunkLibrary.allChunks.where((c) {
        return c.type == type &&
            c.connectionPoints.containsKey(requiredEntry) &&
            c.connectionPoints.length > 1;
      }).toList();

      if (validBlueprints.isEmpty) {
        // Fallback to any connector
        final connectors = ChunkLibrary.allChunks.where((c) {
          return c.type == ChunkType.connector &&
              c.connectionPoints.containsKey(requiredEntry);
        }).toList();
        if (connectors.isNotEmpty) {
          currentChunk = connectors[_random.nextInt(connectors.length)];
        } else {
          break; // Should not happen if library is complete
        }
      } else {
        currentChunk = validBlueprints[_random.nextInt(validBlueprints.length)];
      }

      // Update state
      switch (nextDir) {
        case Direccion.este:
          currentPos = Point(currentPos.x + 1, currentPos.y);
          break;
        case Direccion.norte:
          currentPos = Point(currentPos.x, currentPos.y - 1);
          break;
        case Direccion.sur:
          currentPos = Point(currentPos.x, currentPos.y + 1);
          break;
        default:
          break;
      }

      placedChunks.add(_PlacedChunk(currentChunk, currentPos));
      occupied.add(currentPos);
    }

    // 4. Stitching
    return _stitch2D(placedChunks, name, dificultad, sector);
  }

  Future<LevelMapData> _stitch2D(
    List<_PlacedChunk> placedChunks,
    String name,
    Dificultad dificultad,
    Sector sector,
  ) async {
    // Calculate bounds
    final chunkWorldPositions = <_PlacedChunk, Point<int>>{};
    var globalPos = const Point(0, 0); // Top-Left of Start Chunk
    chunkWorldPositions[placedChunks[0]] = globalPos;

    int minTileX = 0, maxTileX = 0, minTileY = 0, maxTileY = 0;

    // Update bounds for Start
    final startLayout = placedChunks[0].blueprint.layout;
    maxTileX = startLayout[0].length;
    maxTileY = startLayout.length;

    for (var i = 0; i < placedChunks.length - 1; i++) {
      final current = placedChunks[i];
      final next = placedChunks[i + 1];

      // Find the connection direction between them
      final dx = next.gridPos.x - current.gridPos.x;
      final dy = next.gridPos.y - current.gridPos.y;

      Direccion exitDir;
      if (dx == 1)
        exitDir = Direccion.este;
      else if (dx == -1)
        exitDir = Direccion.oeste;
      else if (dy == 1)
        exitDir = Direccion.sur;
      else
        exitDir = Direccion.norte;

      final exitPoint = current.blueprint.connectionPoints[exitDir]!;

      Direccion entryDir;
      switch (exitDir) {
        case Direccion.este:
          entryDir = Direccion.oeste;
          break;
        case Direccion.oeste:
          entryDir = Direccion.este;
          break;
        case Direccion.sur:
          entryDir = Direccion.norte;
          break;
        case Direccion.norte:
          entryDir = Direccion.sur;
          break;
      }

      final entryPoint = next.blueprint.connectionPoints[entryDir]!;

      // Calculate Next Global Pos (Top-Left)
      final nextGlobalX =
          chunkWorldPositions[current]!.x +
          exitPoint.x.toInt() -
          entryPoint.x.toInt();
      final nextGlobalY =
          chunkWorldPositions[current]!.y +
          exitPoint.y.toInt() -
          entryPoint.y.toInt();

      final nextPos = Point(nextGlobalX, nextGlobalY);
      chunkWorldPositions[next] = nextPos;

      // Update bounds
      final nextW = next.blueprint.layout[0].length;
      final nextH = next.blueprint.layout.length;

      if (nextGlobalX < minTileX) minTileX = nextGlobalX;
      if (nextGlobalX + nextW > maxTileX) maxTileX = nextGlobalX + nextW;
      if (nextGlobalY < minTileY) minTileY = nextGlobalY;
      if (nextGlobalY + nextH > maxTileY) maxTileY = nextGlobalY + nextH;
    }

    // Normalize positions (shift so min is 0)
    final shiftX = -minTileX;
    final shiftY = -minTileY;
    final totalW = maxTileX - minTileX;
    final totalH = maxTileY - minTileY;

    // Create Grid
    final grid = List.generate(
      totalH,
      (_) => List<CeldaData>.filled(totalW, CeldaData.pared),
    );

    final chunkInstances = <ChunkInstance>[];
    final allSpawns = <EntidadSpawn>[];
    Vector2? spawnPoint;
    Vector2? exitPoint;

    for (var i = 0; i < placedChunks.length; i++) {
      final pc = placedChunks[i];
      final rawPos = chunkWorldPositions[pc]!;
      final finalX = rawPos.x + shiftX;
      final finalY = rawPos.y + shiftY;

      final blueprint = pc.blueprint;
      final layout = blueprint.parseLayout();
      final h = layout.length;
      final w = layout[0].length;

      final instanceGrid = List.generate(
        h,
        (_) => List<CeldaData>.filled(w, CeldaData.pared),
      );
      final instanceSpawns = <EntidadSpawn>[];

      // Copy to global grind and instance
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final cell = layout[y][x];
          if (finalY + y >= 0 &&
              finalY + y < totalH &&
              finalX + x >= 0 &&
              finalX + x < totalW) {
            grid[finalY + y][finalX + x] = cell;
          }
          instanceGrid[y][x] = cell;
        }
      }

      // Spawns
      for (final spawn in blueprint.spawns) {
        final globalPos =
            spawn.posicion + Vector2(finalX.toDouble(), finalY.toDouble());
        allSpawns.add(
          EntidadSpawn(tipoEnemigo: spawn.tipoEnemigo, posicion: globalPos),
        );
        instanceSpawns.add(
          EntidadSpawn(tipoEnemigo: spawn.tipoEnemigo, posicion: globalPos),
        );
      }

      if (blueprint.type == ChunkType.start) {
        // Initial guess: (2, h/2) relative to chunk
        final initialX = finalX + 2;
        final initialY = finalY + (h ~/ 2);
        spawnPoint = _findValidSpawn(grid, initialX, initialY);
      }
      // Last chunk is exit
      if (i == placedChunks.length - 1) {
        exitPoint = Vector2(finalX + w / 2.0, finalY + h / 2.0);
      }

      chunkInstances.add(
        ChunkInstance(
          id: '${blueprint.id}_$i',
          bounds: Rect.fromLTWH(
            finalX.toDouble(),
            finalY.toDouble(),
            w.toDouble(),
            h.toDouble(),
          ),
          grid: instanceGrid,
          entities: instanceSpawns,
          yOffset: finalY,
        ),
      );
    }

    // Carve Connections (FORCED CARVING)
    // This pass ensures that connections are physically open, even if the blueprint has walls.
    for (var i = 0; i < placedChunks.length - 1; i++) {
      final current = placedChunks[i];
      final next = placedChunks[i + 1];
      final currentInstance = chunkInstances[i];
      final nextInstance = chunkInstances[i + 1];

      final dx = next.gridPos.x - current.gridPos.x;
      final dy = next.gridPos.y - current.gridPos.y;

      Direccion exitDir;
      if (dx == 1)
        exitDir = Direccion.este;
      else if (dx == -1)
        exitDir = Direccion.oeste;
      else if (dy == 1)
        exitDir = Direccion.sur;
      else
        exitDir = Direccion.norte;

      _forceCarveConnection(grid, currentInstance, nextInstance, exitDir);
    }

    return LevelMapData(
      chunks: chunkInstances,
      ancho: totalW,
      alto: totalH,
      grid: grid,
      entidadesIniciales: allSpawns,
      nombre: name,
      dificultad: dificultad,
      sector: sector,
      spawnPoint: spawnPoint,
      exitPoint: exitPoint,
      exitHint: 'Explora las profundidades...',
      ambientLight: const Color(0xFF1A1A2E),
      fogColor: const Color(0xFF16213E).withOpacity(0.3),
    );
  }

  /// Aggressively carves a path between two chunks in the global grid.
  /// This prevents "invisible walls" or blocked paths due to blueprint mismatches.
  void _forceCarveConnection(
    List<List<CeldaData>> grid,
    ChunkInstance from,
    ChunkInstance to,
    Direccion dir,
  ) {
    // Determine the boundary area in global coordinates
    int startX, endX, startY, endY;
    const int corridorWidth = 3; // Ensure at least 3 tiles wide passage

    switch (dir) {
      case Direccion.este:
        // Connection is on the Right of 'from' and Left of 'to'
        // We find the overlapping Y range
        final fromRight = from.bounds.right.toInt();
        final toLeft = to.bounds.left.toInt();
        // The "seam" is between fromRight-1 and toLeft
        // We carve a box around this seam.

        // Find the center Y of the connection based on the chunks' relative positions
        // This is tricky because we don't have the exact connection point stored in the instance.
        // But we know the chunks are aligned.
        // Let's carve the intersection of their Y bounds.
        final overlapTop = max(from.bounds.top.toInt(), to.bounds.top.toInt());
        final overlapBottom = min(
          from.bounds.bottom.toInt(),
          to.bounds.bottom.toInt(),
        );
        final centerY = (overlapTop + overlapBottom) ~/ 2;

        startX = fromRight - 2;
        endX = toLeft + 2;
        startY = centerY - (corridorWidth ~/ 2);
        endY = centerY + (corridorWidth ~/ 2);
        break;

      case Direccion.oeste:
        // Connection is on the Left of 'from' and Right of 'to'
        final fromLeft = from.bounds.left.toInt();
        final toRight = to.bounds.right.toInt();

        final overlapTop = max(from.bounds.top.toInt(), to.bounds.top.toInt());
        final overlapBottom = min(
          from.bounds.bottom.toInt(),
          to.bounds.bottom.toInt(),
        );
        final centerY = (overlapTop + overlapBottom) ~/ 2;

        startX = toRight - 2;
        endX = fromLeft + 2;
        startY = centerY - (corridorWidth ~/ 2);
        endY = centerY + (corridorWidth ~/ 2);
        break;

      case Direccion.sur:
        // Connection is on the Bottom of 'from' and Top of 'to'
        final fromBottom = from.bounds.bottom.toInt();
        final toTop = to.bounds.top.toInt();

        final overlapLeft = max(
          from.bounds.left.toInt(),
          to.bounds.left.toInt(),
        );
        final overlapRight = min(
          from.bounds.right.toInt(),
          to.bounds.right.toInt(),
        );
        final centerX = (overlapLeft + overlapRight) ~/ 2;

        startY = fromBottom - 2;
        endY = toTop + 2;
        startX = centerX - (corridorWidth ~/ 2);
        endX = centerX + (corridorWidth ~/ 2);
        break;

      case Direccion.norte:
        // Connection is on the Top of 'from' and Bottom of 'to'
        final fromTop = from.bounds.top.toInt();
        final toBottom = to.bounds.bottom.toInt();

        final overlapLeft = max(
          from.bounds.left.toInt(),
          to.bounds.left.toInt(),
        );
        final overlapRight = min(
          from.bounds.right.toInt(),
          to.bounds.right.toInt(),
        );
        final centerX = (overlapLeft + overlapRight) ~/ 2;

        startY = toBottom - 2;
        endY = fromTop + 2;
        startX = centerX - (corridorWidth ~/ 2);
        endX = centerX + (corridorWidth ~/ 2);
        break;
    }

    // Apply the carving to the global grid
    for (var y = startY; y <= endY; y++) {
      for (var x = startX; x <= endX; x++) {
        if (y >= 0 && y < grid.length && x >= 0 && x < grid[0].length) {
          grid[y][x] = CeldaData.suelo;

          // Also update the local grids of the chunks if they overlap this point
          // This ensures that when the chunk is loaded individually, it also has the hole.
          _updateLocalGridIfInside(from, x, y);
          _updateLocalGridIfInside(to, x, y);
        }
      }
    }
  }

  void _updateLocalGridIfInside(ChunkInstance chunk, int globalX, int globalY) {
    final localX = globalX - chunk.bounds.left.toInt();
    final localY = globalY - chunk.bounds.top.toInt();

    if (localX >= 0 &&
        localX < chunk.grid[0].length &&
        localY >= 0 &&
        localY < chunk.grid.length) {
      chunk.grid[localY][localX] = CeldaData.suelo;
    }
  }

  /// Searches for the nearest valid floor tile starting from [startX], [startY].
  /// Returns the center of the tile as a Vector2.
  Vector2 _findValidSpawn(List<List<CeldaData>> grid, int startX, int startY) {
    // BFS to find nearest floor
    final queue = <Point<int>>[Point(startX, startY)];
    final visited = <Point<int>>{Point(startX, startY)};
    // 8 directions for better coverage
    final directions = [
      const Point(0, 0), // Check start first
      const Point(0, 1), const Point(0, -1),
      const Point(1, 0), const Point(-1, 0),
      const Point(1, 1), const Point(1, -1),
      const Point(-1, 1), const Point(-1, -1),
    ];

    // Limit search radius to avoid infinite loops in bad maps
    int checks = 0;
    const maxChecks = 100;

    while (queue.isNotEmpty && checks < maxChecks) {
      final current = queue.removeAt(0);
      checks++;

      if (current.y >= 0 &&
          current.y < grid.length &&
          current.x >= 0 &&
          current.x < grid[0].length) {
        if (grid[current.y][current.x].tipo == TipoCelda.suelo) {
          // Return center of tile
          return Vector2(current.x + 0.5, current.y + 0.5);
        }
      }

      for (final dir in directions) {
        if (dir.x == 0 && dir.y == 0) continue;
        final next = Point(current.x + dir.x, current.y + dir.y);
        if (!visited.contains(next)) {
          visited.add(next);
          queue.add(next);
        }
      }
    }

    // Fallback if no floor found (should be impossible in a valid level)
    // Return original but centered
    return Vector2(startX + 0.5, startY + 0.5);
  }
}

class _PlacedChunk {
  final ChunkBlueprint blueprint;
  final Point<int> gridPos;
  _PlacedChunk(this.blueprint, this.gridPos);
}
