import 'dart:math';
import 'package:echo_world/game/level/data/level_models.dart';

class CellularAutomata {
  final Random _random = Random();

  /// Generates an organic terrain grid using cellular automata
  ///
  /// Algorithm:
  /// 1. Randomly fill grid with walls (fillPercent probability)
  /// 2. Run smoothing passes (each cell becomes wall if >=threshold neighbors are walls)
  /// 3. Result: organic, cave-like structures
  Grid generate({
    required int width,
    required int height,
    double fillPercent = 0.45,
    int smoothPasses = 4,
    int wallThreshold = 4,
  }) {
    // Step 1: Random initialization
    var grid = _randomFill(width, height, fillPercent);

    // Step 2: Smooth the grid multiple times
    for (var i = 0; i < smoothPasses; i++) {
      grid = _smooth(grid, wallThreshold);
    }

    // Step 3: Ensure borders are walls
    grid = _enforceBorders(grid);

    // Step 4: Ensure connectivity
    grid = _ensureConnectivity(grid);

    return grid;
  }

  Grid _randomFill(int width, int height, double fillPercent) {
    final grid = <List<CeldaData>>[];
    for (var y = 0; y < height; y++) {
      final row = <CeldaData>[];
      for (var x = 0; x < width; x++) {
        // Borders are always walls
        if (x == 0 || x == width - 1 || y == 0 || y == height - 1) {
          row.add(CeldaData.pared);
        } else {
          // Random fill based on fillPercent
          row.add(
            _random.nextDouble() < fillPercent
                ? CeldaData.pared
                : CeldaData.suelo,
          );
        }
      }
      grid.add(row);
    }
    return grid;
  }

  Grid _smooth(Grid grid, int wallThreshold) {
    final height = grid.length;
    final width = grid[0].length;
    final newGrid = <List<CeldaData>>[];

    for (var y = 0; y < height; y++) {
      final row = <CeldaData>[];
      for (var x = 0; x < width; x++) {
        final wallCount = _countWallNeighbors(grid, x, y);
        // If enough neighbors are walls, this cell becomes a wall
        row.add(wallCount >= wallThreshold ? CeldaData.pared : CeldaData.suelo);
      }
      newGrid.add(row);
    }

    return newGrid;
  }

  int _countWallNeighbors(Grid grid, int x, int y) {
    final height = grid.length;
    final width = grid[0].length;
    var count = 0;

    for (var ny = y - 1; ny <= y + 1; ny++) {
      for (var nx = x - 1; nx <= x + 1; nx++) {
        // Skip the center cell
        if (nx == x && ny == y) continue;

        // Out of bounds = treat as wall
        if (nx < 0 || nx >= width || ny < 0 || ny >= height) {
          count++;
        } else if (grid[ny][nx].tipo == TipoCelda.pared) {
          count++;
        }
      }
    }

    return count;
  }

  Grid _ensureConnectivity(Grid grid) {
    final regions = _getRegions(grid);
    if (regions.length <= 1) return grid;

    // Connect all regions to the largest one (or just sequentially)
    // Strategy: Connect Region A to Region B, B to C, etc.
    for (var i = 0; i < regions.length - 1; i++) {
      _connectRegions(grid, regions[i], regions[i + 1]);
    }

    return grid;
  }

  List<List<Point<int>>> _getRegions(Grid grid) {
    final regions = <List<Point<int>>>[];
    final height = grid.length;
    final width = grid[0].length;
    final visited = List.generate(height, (_) => List.filled(width, false));

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (!visited[y][x] && grid[y][x].tipo == TipoCelda.suelo) {
          final newRegion = _floodFill(grid, visited, x, y);
          regions.add(newRegion);
        }
      }
    }

    return regions;
  }

  List<Point<int>> _floodFill(
    Grid grid,
    List<List<bool>> visited,
    int startX,
    int startY,
  ) {
    final region = <Point<int>>[];
    final queue = <Point<int>>[Point(startX, startY)];
    visited[startY][startX] = true;

    final height = grid.length;
    final width = grid[0].length;

    while (queue.isNotEmpty) {
      final p = queue.removeLast();
      region.add(p);

      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          // Orthogonal only for safer regions? Or 8-way? Let's do 4-way for now
          if (dx != 0 && dy != 0) continue;

          final nx = p.x + dx;
          final ny = p.y + dy;

          if (nx >= 0 &&
              nx < width &&
              ny >= 0 &&
              ny < height &&
              !visited[ny][nx] &&
              grid[ny][nx].tipo == TipoCelda.suelo) {
            visited[ny][nx] = true;
            queue.add(Point(nx, ny));
          }
        }
      }
    }
    return region;
  }

  void _connectRegions(
    Grid grid,
    List<Point<int>> regionA,
    List<Point<int>> regionB,
  ) {
    // Find closest points between A and B
    var bestDist = double.maxFinite;
    var bestA = regionA.first;
    var bestB = regionB.first;

    // Optimization: Don't check every pair if regions are huge.
    // But for 100x100 maps, it's okay-ish.
    // Better: Pick random points and find closest subset.
    for (final pA in regionA) {
      for (final pB in regionB) {
        final dist = pow(pA.x - pB.x, 2) + pow(pA.y - pB.y, 2);
        if (dist < bestDist) {
          bestDist = dist.toDouble();
          bestA = pA;
          bestB = pB;
        }
      }
    }

    _createTunnel(grid, bestA, bestB);
  }

  void _createTunnel(Grid grid, Point<int> start, Point<int> end) {
    var current = start;
    while (current != end) {
      // Move towards end
      final dx = end.x - current.x;
      final dy = end.y - current.y;

      if (dx.abs() > dy.abs()) {
        current = Point(current.x + dx.sign, current.y);
      } else {
        current = Point(current.x, current.y + dy.sign);
      }

      // Carve tunnel (radius 1 for wider path)
      _carveCircle(grid, current.x, current.y, 1);
    }
  }

  void _carveCircle(Grid grid, int cx, int cy, int radius) {
    final height = grid.length;
    final width = grid[0].length;

    for (var y = cy - radius; y <= cy + radius; y++) {
      for (var x = cx - radius; x <= cx + radius; x++) {
        if (x > 0 && x < width - 1 && y > 0 && y < height - 1) {
          // Simple distance check
          if (pow(x - cx, 2) + pow(y - cy, 2) <= radius * radius + 1) {
            grid[y][x] = CeldaData.suelo;
          }
        }
      }
    }
  }

  Grid _enforceBorders(Grid grid) {
    final height = grid.length;
    final width = grid[0].length;

    for (var y = 0; y < height; y++) {
      grid[y][0] = CeldaData.pared;
      grid[y][width - 1] = CeldaData.pared;
    }

    for (var x = 0; x < width; x++) {
      grid[0][x] = CeldaData.pared;
      grid[height - 1][x] = CeldaData.pared;
    }

    return grid;
  }
}
