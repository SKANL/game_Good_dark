import 'package:echo_world/game/entities/enemies/bruto.dart';
import 'package:echo_world/game/entities/enemies/cazador.dart';
import 'package:echo_world/game/entities/enemies/vigia.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:echo_world/game/level/modular/chunk_blueprint.dart';
import 'package:flame/components.dart';

class ChunkLibrary {
  static final List<ChunkBlueprint> allChunks = [
    // --- START CHUNKS ---
    ChunkBlueprint(
      id: 'start_basic',
      type: ChunkType.start,
      layout: [
        '##############################',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................ ', // Opened East (29, 9)
        '#............................ ', // Opened East (29, 10)
        '#............................ ', // Opened East (29, 11)
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '##############################',
      ],
      connectionPoints: {
        Direccion.este: Vector2(29, 10),
      },
    ),

    // --- END CHUNKS ---
    ChunkBlueprint(
      id: 'end_basic',
      type: ChunkType.end,
      layout: [
        '##############################',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        ' ...........................E#', // Opened West (0, 9)
        ' ............................#', // Opened West (0, 10)
        ' ............................#', // Opened West (0, 11)
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '#............................#',
        '##############################',
      ],
      connectionPoints: {
        Direccion.oeste: Vector2(0, 10),
      },
    ),

    // --- CONNECTOR CHUNKS (LARGE 30x20) ---
    ChunkBlueprint(
      id: 'lab_complex_corridors',
      type: ChunkType.connector,
      layout: [
        '##############################',
        '#............................#',
        '#..########..########..####..#',
        '#..#......#..#......#..#..#..#',
        '#..#......#..#......#..#..#..#',
        '#..#......#..#......#..#..#..#',
        '#..####.####..####.####..#..#',
        '#............................#',
        '#............................#',
        ' ............................ ', // West (0,9) - East (29,9)
        ' ............................ ', // West (0,10) - East (29,10)
        ' ............................ ', // West (0,11) - East (29,11)
        '#............................#',
        '#............................#',
        '#..####.####..####.####..#..#',
        '#..#......#..#......#..#..#..#',
        '#..#......#..#......#..#..#..#',
        '#..#......#..#......#..#..#..#',
        '#..########..########..####..#',
        '##############################',
      ],
      connectionPoints: {
        Direccion.oeste: Vector2(0, 10),
        Direccion.este: Vector2(29, 10),
      },
      difficultyWeight: 2,
    ),

    ChunkBlueprint(
      id: 'hub_junction',
      type: ChunkType.connector,
      layout: [
        '##########........##########', // North (10-19, 0)
        '##########........##########',
        '##########........##########',
        '#..........................#',
        '#..........................#',
        '#...####............####...#',
        '#...####............####...#',
        '#..........................#',
        '#..........................#',
        ' .......................... ', // West (0,9) - East (29,9)
        ' .......................... ', // West (0,10) - East (29,10)
        ' .......................... ', // West (0,11) - East (29,11)
        '#..........................#',
        '#..........................#',
        '#...####............####...#',
        '#...####............####...#',
        '#..........................#',
        '#..........................#',
        '##########........##########',
        '##########........##########', // South (10-19, 19)
      ],
      connectionPoints: {
        Direccion.oeste: Vector2(0, 10),
        Direccion.este: Vector2(29, 10),
        Direccion.norte: Vector2(14, 0),
        Direccion.sur: Vector2(14, 19),
      },
      difficultyWeight: 1,
    ),

    // --- ARENA CHUNKS (LARGE 30x20) ---
    ChunkBlueprint(
      id: 'grand_hall_combat',
      type: ChunkType.arena,
      layout: [
        '##############################',
        '#............................#',
        '#............................#',
        '#..##....####....####....##..#',
        '#..##....####....####....##..#',
        '#............................#',
        '#............................#',
        '#......D..............D......#',
        '#......D..............D......#',
        ' ......D..............D...... ', // West (0,9) - East (29,9)
        ' ......D..............D...... ', // West (0,10) - East (29,10)
        ' ......D..............D...... ', // West (0,11) - East (29,11)
        '#......D..............D......#',
        '#......D..............D......#',
        '#............................#',
        '#............................#',
        '#..##....####....####....##..#',
        '#..##....####....####....##..#',
        '#............................#',
        '##############################',
      ],
      connectionPoints: {
        Direccion.oeste: Vector2(0, 10),
        Direccion.este: Vector2(29, 10),
      },
      spawns: [
        EntidadSpawn(tipoEnemigo: BrutoComponent, posicion: Vector2(15, 10)),
        EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(5, 5)),
        EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(25, 15)),
        EntidadSpawn(tipoEnemigo: VigiaComponent, posicion: Vector2(15, 5)),
      ],
      difficultyWeight: 3,
    ),

    /*
    // --- OLD SMALL CHUNKS (OBSOLETE) ---
    ChunkBlueprint(
      id: 'connector_corridor_h',
      type: ChunkType.connector,
      layout: [
        '################',
        '................',
        '................',
        '................',
        '################',
      ],
      connectionPoints: {
        Direccion.oeste: Vector2(0, 2),
        Direccion.este: Vector2(15, 2),
      },
    ),
    // ... (other old chunks commented out)
    */
  ];

  static ChunkBlueprint getStartChunk() {
    return allChunks.firstWhere((c) => c.type == ChunkType.start);
  }

  static ChunkBlueprint getEndChunk() {
    return allChunks.firstWhere((c) => c.type == ChunkType.end);
  }

  static List<ChunkBlueprint> getChunksByType(ChunkType type) {
    return allChunks.where((c) => c.type == type).toList();
  }
}
