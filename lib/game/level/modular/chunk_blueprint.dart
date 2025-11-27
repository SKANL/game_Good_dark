import 'package:echo_world/game/level/data/level_models.dart';
import 'package:flame/components.dart';

enum ChunkType {
  start,
  end,
  connector,
  arena,
  puzzle,
  safeZone,
}

/// Defines the blueprint for a level chunk.
class ChunkBlueprint {

  const ChunkBlueprint({
    required this.id,
    required this.type,
    required this.layout,
    required this.connectionPoints,
    this.difficultyWeight = 1,
    this.spawns = const [],
    this.tags = const [],
  });
  final String id;
  final ChunkType type;
  final List<String> layout;
  final Map<Direccion, Vector2> connectionPoints;
  final int difficultyWeight;
  final List<EntidadSpawn> spawns;
  final List<String> tags;

  /// Parses the layout strings into a Grid of CeldaData.
  Grid parseLayout() {
    final height = layout.length;
    final width = layout[0].length;
    final grid = List.generate(
      height,
      (_) => List<CeldaData>.filled(width, CeldaData.pared),
    );

    for (var y = 0; y < height; y++) {
      final row = layout[y];
      for (var x = 0; x < width; x++) {
        if (x >= row.length) break;
        final char = row[x];
        grid[y][x] = _parseChar(char);
      }
    }
    return grid;
  }

  CeldaData _parseChar(String char) {
    switch (char) {
      case '#':
        return CeldaData.pared;
      case '.':
        return CeldaData.suelo;
      case ' ':
        return CeldaData.abismo;
      case 'D':
        return const CeldaData(tipo: TipoCelda.pared, esDestructible: true);
      case 'T':
        return CeldaData.tunel;
      case 'A':
        return CeldaData.abismo;
      default:
        return CeldaData
            .suelo; // Default to floor for unknown chars (like spawns)
    }
  }
}
