import 'package:echo_world/game/entities/enemies/cazador.dart';
import 'package:echo_world/game/entities/enemies/vigia.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:echo_world/game/level/modular/chunk_blueprint.dart';
import 'package:flame/components.dart';

class ChunkLibrary {
  static final List<ChunkBlueprint> allChunks = [
    // --- START CHUNKS (16x12) ---
    ChunkBlueprint(
      id: 'start_basic',
      type: ChunkType.start,
      layout: [
        '################',
        '#..............#',
        '#..............#',
        '#..............#',
        '#..............#',
        '#.............. ', // East (15, 5)
        '#.............. ', // East (15, 6)
        '#..............#',
        '#..............#',
        '#..............#',
        '#..............#',
        '################',
      ],
      connectionPoints: {
        Direccion.este: Vector2(15, 5),
      },
    ),

    // --- END CHUNKS (16x12) ---
    ChunkBlueprint(
      id: 'end_basic',
      type: ChunkType.end,
      layout: [
        '################',
        '#..............#',
        '#..............#',
        '#..............#',
        '#..............#',
        ' ..............E', // West (0, 5)
        ' ..............E', // West (0, 6)
        '#..............#',
        '#..............#',
        '#..............#',
        '#..............#',
        '################',
      ],
      connectionPoints: {
        Direccion.oeste: Vector2(0, 5),
      },
    ),

    // --- CONNECTOR CHUNKS (16x12) ---
    ChunkBlueprint(
      id: 'corridor_straight',
      type: ChunkType.connector,
      layout: [
        '################',
        '#..............#',
        '#..............#',
        '#..............#',
        '#..............#',
        ' .............. ', // West (0,5) - East (15,5)
        ' .............. ', // West (0,6) - East (15,6)
        '#..............#',
        '#..............#',
        '#..............#',
        '#..............#',
        '################',
      ],
      connectionPoints: {
        Direccion.oeste: Vector2(0, 5),
        Direccion.este: Vector2(15, 5),
      },
    ),

    ChunkBlueprint(
      id: 'corridor_zigzag',
      type: ChunkType.connector,
      layout: [
        '################',
        '#..............#',
        '#..##########..#',
        '#..#........#..#',
        '#..#........#..#',
        ' ..#........#.. ', // West (0,5) - East (15,5)
        ' ..#........#.. ', // West (0,6) - East (15,6)
        '#..#........#..#',
        '#..#........#..#',
        '#..##########..#',
        '#..............#',
        '################',
      ],
      connectionPoints: {
        Direccion.oeste: Vector2(0, 5),
        Direccion.este: Vector2(15, 5),
      },
      difficultyWeight: 2,
    ),

    ChunkBlueprint(
      id: 'junction_cross',
      type: ChunkType.connector,
      layout: [
        '#####......#####', // North (5-10, 0)
        '#####......#####',
        '#####......#####',
        '#..............#',
        '#..............#',
        ' .............. ', // West (0,5) - East (15,5)
        ' .............. ', // West (0,6) - East (15,6)
        '#..............#',
        '#..............#',
        '#####......#####',
        '#####......#####',
        '#####......#####', // South (5-10, 11)
      ],
      connectionPoints: {
        Direccion.oeste: Vector2(0, 5),
        Direccion.este: Vector2(15, 5),
        Direccion.norte: Vector2(7, 0),
        Direccion.sur: Vector2(7, 11),
      },
    ),

    // --- SIDE-SCROLL MECHANIC CHUNKS (16x12) ---
    ChunkBlueprint(
      id: 'side_scroll_gap',
      type: ChunkType.connector,
      tags: ['side_scroll'],
      layout: [
        '################',
        '#..............#',
        '#..............#',
        '#..............#',
        '#..............#',
        ' .....AAAA..... ', // West (0,5) - East (15,5)
        ' .....AAAA..... ', // West (0,6) - East (15,6)
        '#..............#',
        '#..............#',
        '#..............#',
        '#..............#',
        '################',
      ],
      connectionPoints: {
        Direccion.oeste: Vector2(0, 5),
        Direccion.este: Vector2(15, 5),
      },
      difficultyWeight: 2,
    ),

    ChunkBlueprint(
      id: 'side_scroll_tunnel',
      type: ChunkType.connector,
      tags: ['side_scroll'],
      layout: [
        '################',
        '#..............#',
        '#..............#',
        '#..............#',
        '#..............#',
        ' TTTTTTTTTTTTTT ', // West (0,5) - East (15,5)
        ' TTTTTTTTTTTTTT ', // West (0,6) - East (15,6)
        '#..............#',
        '#..............#',
        '#..............#',
        '#..............#',
        '################',
      ],
      connectionPoints: {
        Direccion.oeste: Vector2(0, 5),
        Direccion.este: Vector2(15, 5),
      },
      difficultyWeight: 2,
    ),

    // --- ARENA CHUNKS (16x12) ---
    ChunkBlueprint(
      id: 'small_arena',
      type: ChunkType.arena,
      layout: [
        '################',
        '#..............#',
        '#..##......##..#',
        '#..##......##..#',
        '#..............#',
        ' ......D....... ', // West (0,5) - East (15,5)
        ' ......D....... ', // West (0,6) - East (15,6)
        '#..............#',
        '#..##......##..#',
        '#..##......##..#',
        '#..............#',
        '################',
      ],
      connectionPoints: {
        Direccion.oeste: Vector2(0, 5),
        Direccion.este: Vector2(15, 5),
      },
      spawns: [
        EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(8, 6)),
        EntidadSpawn(tipoEnemigo: VigiaComponent, posicion: Vector2(8, 3)),
      ],
      difficultyWeight: 2,
    ),

    // --- PERSPECTIVE INCENTIVE CHUNKS (16x12) ---
    // Each contains a LoreItem reward for using the correct perspective
    ChunkBlueprint(
      id: 'stealth_tunnel_guarded',
      type: ChunkType.connector,
      tags: ['side_scroll', 'stealth'],
      layout: [
        '################',
        '#..............#',
        '#..............#',
        '#..............#',
        '#..V.......V...#',
        ' TTTTTTTTTTTTTT ', // West (0,5) - East (15,5) - Tunnel requires crouch
        ' TTTTTTTTTTTTTT ', // West (0,6) - East (15,6)
        '#..V.......V...#',
        '#..............#',
        '#..............#',
        '#..............#',
        '################',
      ],
      connectionPoints: {
        Direccion.oeste: Vector2(0, 5),
        Direccion.este: Vector2(15, 5),
      },
      spawns: [
        EntidadSpawn(tipoEnemigo: VigiaComponent, posicion: Vector2(3, 4)),
        EntidadSpawn(tipoEnemigo: VigiaComponent, posicion: Vector2(11, 4)),
        EntidadSpawn(tipoEnemigo: VigiaComponent, posicion: Vector2(3, 7)),
        EntidadSpawn(tipoEnemigo: VigiaComponent, posicion: Vector2(11, 7)),
        // LoreItem will be spawned programmatically at center of tunnel
      ],
      difficultyWeight: 3,
    ),

    ChunkBlueprint(
      id: 'destructible_gate',
      type: ChunkType.connector,
      tags: ['rupture'],
      layout: [
        '################',
        '#..............#',
        '#..............#',
        '#..............#',
        '#..............#',
        ' ......DD...... ', // West (0,5) - East (15,5) - Destructible wall blocks path
        ' ......DD...... ', // West (0,6) - East (15,6)
        '#..............#',
        '#..............#',
        '#..............#',
        '#..............#',
        '################',
      ],
      connectionPoints: {
        Direccion.oeste: Vector2(0, 5),
        Direccion.este: Vector2(15, 5),
      },
      difficultyWeight: 2,
    ),
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
