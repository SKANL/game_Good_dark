import 'dart:collection';
import 'dart:math';

import 'package:echo_world/game/level/data/level_models.dart';
import 'package:echo_world/game/level/manager/level_manager.dart';
import 'package:flame/components.dart';

/// Nodo para el algoritmo A*
class Node implements Comparable<Node> {
  Node(this.position, {this.parent, this.g = 0, this.h = 0});
  final Point<int> position;
  final Node? parent;
  final double g;
  final double h;

  double get f => g + h;

  @override
  int compareTo(Node other) => f.compareTo(other.f);

  @override
  bool operator ==(Object other) =>
      other is Node &&
      position.x == other.position.x &&
      position.y == other.position.y;

  @override
  int get hashCode => position.x.hashCode ^ position.y.hashCode;
}

/// Encuentra un camino desde [start] hasta [end] usando A*.
/// Devuelve una lista de puntos en coordenadas del mundo (centro de tiles).
/// Devuelve una lista vacía si no hay camino.
List<Vector2> findPath(
  Vector2 start,
  Vector2 end,
  LevelManagerComponent levelManager,
) {
  const tileSize = LevelManagerComponent.tileSize;
  final startTile = Point<int>(
    (start.x / tileSize).floor(),
    (start.y / tileSize).floor(),
  );
  final endTile = Point<int>(
    (end.x / tileSize).floor(),
    (end.y / tileSize).floor(),
  );

  // Si start o end están fuera de límites o en pared, devolver vacío o ajustar
  if (!_isWalkable(endTile, levelManager)) return [];

  final openSet = SplayTreeSet<Node>();
  final closedSet = <Point<int>>{};

  openSet.add(Node(startTile, h: _heuristic(startTile, endTile)));

  while (openSet.isNotEmpty) {
    final current = openSet.first;
    openSet.remove(current);
    closedSet.add(current.position);

    if (current.position == endTile) {
      return _reconstructPath(current, tileSize);
    }

    for (final neighbor in _getNeighbors(current.position, levelManager)) {
      if (closedSet.contains(neighbor)) continue;

      final gScore =
          current.g + 1; // Coste uniforme de 1 por movimiento ortogonal
      final hScore = _heuristic(neighbor, endTile);
      final neighborNode = Node(
        neighbor,
        parent: current,
        g: gScore,
        h: hScore,
      );

      // Verificar si ya está en openSet con un coste menor
      final existingNode = openSet.lookup(neighborNode);
      if (existingNode != null && existingNode.g <= gScore) continue;

      if (existingNode != null) openSet.remove(existingNode);
      openSet.add(neighborNode);
    }
  }

  return [];
}

bool _isWalkable(Point<int> p, LevelManagerComponent levelManager) {
  final grid = levelManager.currentGrid;
  if (grid == null) return false;
  if (p.y < 0 || p.y >= grid.length || p.x < 0 || p.x >= grid[0].length) {
    return false;
  }
  return grid[p.y][p.x].tipo == TipoCelda.suelo;
}

double _heuristic(Point<int> a, Point<int> b) {
  // Distancia Manhattan para movimiento ortogonal
  return (a.x - b.x).abs() + (a.y - b.y).abs().toDouble();
}

List<Point<int>> _getNeighbors(
  Point<int> p,
  LevelManagerComponent levelManager,
) {
  final neighbors = <Point<int>>[];
  const directions = [
    Point(0, 1),
    Point(0, -1),
    Point(1, 0),
    Point(-1, 0),
  ];

  for (final dir in directions) {
    final next = Point(p.x + dir.x, p.y + dir.y);
    if (_isWalkable(next, levelManager)) {
      neighbors.add(next);
    }
  }
  return neighbors;
}

List<Vector2> _reconstructPath(Node endNode, double tileSize) {
  final path = <Vector2>[];
  var current = endNode;
  while (current.parent != null) {
    // Convertir a coordenadas de mundo (centro del tile)
    path.add(
      Vector2(
        (current.position.x * tileSize) + (tileSize / 2),
        (current.position.y * tileSize) + (tileSize / 2),
      ),
    );
    current = current.parent!;
  }
  // No incluimos el nodo inicial porque ya estamos ahí
  return path.reversed.toList();
}
