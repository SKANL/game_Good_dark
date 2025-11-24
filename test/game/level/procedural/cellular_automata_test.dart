import 'dart:math';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:echo_world/game/level/procedural/cellular_automata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CellularAutomata', () {
    late CellularAutomata automata;

    setUp(() {
      automata = CellularAutomata();
    });

    test('generates a grid of correct size', () {
      final grid = automata.generate(width: 20, height: 20);
      expect(grid.length, 20);
      expect(grid[0].length, 20);
    });

    test('generates a connected grid', () {
      // Generate a large enough grid to likely have disconnected regions initially
      final grid = automata.generate(width: 40, height: 40, fillPercent: 0.5);

      // Verify connectivity using flood fill
      final regions = _getRegions(grid);

      // Should be exactly 1 region (or 0 if completely empty/full, but unlikely)
      expect(regions.length, lessThanOrEqualTo(1));

      if (regions.isNotEmpty) {
        // Ensure the region has a significant number of cells
        expect(regions.first.length, greaterThan(10));
      }
    });
  });
}

// Helper to check regions (duplicated from implementation for testing)
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
        if (dx != 0 && dy != 0) continue; // Orthogonal

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
