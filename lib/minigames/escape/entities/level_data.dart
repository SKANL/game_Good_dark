import 'game_constants.dart';
import 'package:echo_world/minigames/escape/entities/tile.dart';
import 'package:echo_world/minigames/escape/entities/trap.dart';

class EscapeLevelData {
  EscapeLevelData({
    required this.levelNumber,
    required this.startMessage,
    required this.startX,
    required this.startY,
    required this.tiles,
    required this.traps,
  });
  final int levelNumber;
  final String startMessage;
  final double startX;
  final double startY;
  final List<Tile> tiles;
  final List<Trap> traps;

  static List<EscapeLevelData> getAllLevels() {
    return [
      _level1(),
      _level2(),
      _level3(),
      _level4(),
      _level5(),
      _level6(),
      _level7(),
      _level8(),
      _level9(),
      _level10(),
    ];
  }

  static double _gridX(int x) => x * GameConstants.tileSize;
  static double _gridY(int y) =>
      y * GameConstants.tileSize -
      80; // Subir todo 80px para evitar que el HUD tape

  static EscapeLevelData _level1() {
    final tiles = <Tile>[];
    final traps = <Trap>[];

    // Suelo completo
    for (var i = 0; i < GameConstants.gridWidth; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(16), type: TileType.platform));
    }

    // Plataformas colapsables (puente)
    for (var i = 8; i <= 15; i++) {
      traps.add(
        Trap(
          x: _gridX(i),
          y: _gridY(12),
          type: TrapType.collapsingPlatform,
        ),
      );
    }

    // Puerta
    traps.add(Trap(x: _gridX(28), y: _gridY(15), type: TrapType.door));

    return EscapeLevelData(
      levelNumber: 1,
      startMessage: 'The first echo... Move.',
      startX: _gridX(2),
      startY: _gridY(14),
      tiles: tiles,
      traps: traps,
    );
  }

  static EscapeLevelData _level2() {
    final tiles = <Tile>[];
    final traps = <Trap>[];

    // Suelo
    for (var i = 0; i < GameConstants.gridWidth; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(16), type: TileType.platform));
    }

    // Plataforma falsa
    tiles.add(Tile(x: _gridX(19), y: _gridY(14), type: TileType.fakePlatform));

    // Pinchos
    for (final i in [8, 9, 10, 14, 15]) {
      traps.add(Trap(x: _gridX(i), y: _gridY(15), type: TrapType.spike));
    }

    // Puerta
    traps.add(Trap(x: _gridX(28), y: _gridY(15), type: TrapType.door));

    return EscapeLevelData(
      levelNumber: 2,
      startMessage: 'The floor seems... hungry.',
      startX: _gridX(2),
      startY: _gridY(14),
      tiles: tiles,
      traps: traps,
    );
  }

  static EscapeLevelData _level3() {
    final tiles = <Tile>[];
    final traps = <Trap>[];

    // Suelo
    for (var i = 0; i < GameConstants.gridWidth; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(16), type: TileType.platform));
    }

    // Techo que cae
    traps.add(
      Trap(
        x: _gridX(10),
        y: _gridY(0),
        width: GameConstants.tileSize * 8,
        height: GameConstants.tileSize * 4,
        type: TrapType.fallingCeiling,
      ),
    );

    // Puerta
    traps.add(Trap(x: _gridX(28), y: _gridY(15), type: TrapType.door));

    return EscapeLevelData(
      levelNumber: 3,
      startMessage: 'The silence above is heavy.',
      startX: _gridX(2),
      startY: _gridY(14),
      tiles: tiles,
      traps: traps,
    );
  }

  static EscapeLevelData _level4() {
    final tiles = <Tile>[];
    final traps = <Trap>[];

    // Suelo principal
    for (var i = 0; i < GameConstants.gridWidth; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(16), type: TileType.platform));
    }

    // Plataforma elevada (inicio)
    for (var i = 0; i <= 6; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(12), type: TileType.platform));
    }

    // Plataformas intermedias (escalones)
    for (var i = 10; i <= 14; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(14), type: TileType.platform));
    }

    for (var i = 18; i <= 22; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(13), type: TileType.platform));
    }

    // Invertir controles (en la plataforma inicial)
    traps.add(
      Trap(
        x: _gridX(4),
        y: _gridY(11),
        type: TrapType.invertControls,
      ),
    );

    // Pinchos estratégicos en el suelo
    for (final i in [8, 9, 16, 17, 24, 25, 26]) {
      traps.add(Trap(x: _gridX(i), y: _gridY(15), type: TrapType.spike));
    }

    // Puerta
    traps.add(Trap(x: _gridX(28), y: _gridY(15), type: TrapType.door));

    return EscapeLevelData(
      levelNumber: 4,
      startMessage: 'Left is right... up is down?',
      startX: _gridX(2),
      startY: _gridY(10),
      tiles: tiles,
      traps: traps,
    );
  }

  static EscapeLevelData _level5() {
    final tiles = <Tile>[];
    final traps = <Trap>[];

    // Suelo
    for (var i = 0; i < GameConstants.gridWidth; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(16), type: TileType.platform));
    }

    // Escalera de plataformas
    for (var i = 8; i <= 12; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(14), type: TileType.platform));
    }
    for (var i = 16; i <= 20; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(12), type: TileType.platform));
    }

    // Plataforma colapsable
    traps.add(
      Trap(x: _gridX(20), y: _gridY(11), type: TrapType.collapsingPlatform),
    );

    // Pinchos de proximidad
    for (final i in [22, 23, 24]) {
      traps.add(
        Trap(x: _gridX(i), y: _gridY(15), type: TrapType.proximitySpike),
      );
    }

    // Puerta
    traps.add(Trap(x: _gridX(28), y: _gridY(15), type: TrapType.door));

    return EscapeLevelData(
      levelNumber: 5,
      startMessage: 'The very ground recoils...',
      startX: _gridX(2),
      startY: _gridY(14),
      tiles: tiles,
      traps: traps,
    );
  }

  static EscapeLevelData _level6() {
    final tiles = <Tile>[];
    final traps = <Trap>[];

    // Suelo
    for (var i = 0; i < GameConstants.gridWidth; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(16), type: TileType.platform));
    }

    // Techo
    for (var i = 0; i < GameConstants.gridWidth; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(0), type: TileType.platform));
    }

    // Invertir gravedad (inicio)
    traps.add(Trap(x: _gridX(6), y: _gridY(15), type: TrapType.invertGravity));

    // Cambio de velocidad
    traps.add(
      Trap(
        x: _gridX(15),
        y: _gridY(5),
        type: TrapType.speedChange,
        speedMultiplier: 0.5,
      ),
    );
    traps.add(
      Trap(
        x: _gridX(16),
        y: _gridY(5),
        type: TrapType.speedChange,
        speedMultiplier: 0.5,
      ),
    );

    // Invertir gravedad (retorno)
    traps.add(Trap(x: _gridX(26), y: _gridY(1), type: TrapType.invertGravity));

    // Puerta
    traps.add(Trap(x: _gridX(28), y: _gridY(15), type: TrapType.door));

    return EscapeLevelData(
      levelNumber: 6,
      startMessage: 'The world turns upside down.',
      startX: _gridX(2),
      startY: _gridY(14),
      tiles: tiles,
      traps: traps,
    );
  }

  static EscapeLevelData _level7() {
    final tiles = <Tile>[];
    final traps = <Trap>[];

    // Piso superior - PERO con huecos donde estarán las plataformas colapsables
    for (var i = 0; i < GameConstants.gridWidth; i++) {
      // Omitir las posiciones 23-26 (donde estarán las plataformas colapsables)
      if (i < 23 || i > 26) {
        tiles.add(Tile(x: _gridX(i), y: _gridY(7), type: TileType.platform));
      }
    }

    // Piso inferior
    for (var i = 0; i < GameConstants.gridWidth; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(16), type: TileType.platform));
    }

    // 4 bloques colapsables en el PISO SUPERIOR (posiciones 23-26)
    // Estos están a 5 bloques de distancia de la puerta (28 - 5 = 23)
    // Cuando los pises, caerás hacia la puerta morada de abajo
    for (var i = 23; i <= 26; i++) {
      traps.add(
        Trap(
          x: _gridX(i),
          y: _gridY(7), // Mismo nivel que el piso superior
          type: TrapType.collapsingPlatform,
        ),
      );
    }

    // Pinchos estratégicos en el suelo inferior
    for (final i in [8, 12, 16]) {
      traps.add(Trap(x: _gridX(i), y: _gridY(15), type: TrapType.spike));
    }

    // Puerta AZUL arriba (FALSA - te mata)
    traps.add(Trap(x: _gridX(28), y: _gridY(6), type: TrapType.fakeDoor));
    traps.add(Trap(x: _gridX(28), y: _gridY(6), type: TrapType.spike));

    // Puerta MORADA abajo (VERDADERA - salida real)
    traps.add(Trap(x: _gridX(28), y: _gridY(15), type: TrapType.door));

    return EscapeLevelData(
      levelNumber: 7,
      startMessage: 'Sometimes the easiest path is a lie.',
      startX: _gridX(2),
      startY: _gridY(5),
      tiles: tiles,
      traps: traps,
    );
  }

  static EscapeLevelData _level8() {
    final tiles = <Tile>[];
    final traps = <Trap>[];

    // Suelo
    for (var i = 0; i < GameConstants.gridWidth; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(16), type: TileType.platform));
    }

    // Techo gigante que cae
    traps.add(
      Trap(
        x: _gridX(4),
        y: _gridY(0),
        width: GameConstants.tileSize * 28,
        height: GameConstants.tileSize * 4,
        type: TrapType.fallingCeiling,
      ),
    );

    // Pinchos de proximidad
    for (final i in [10, 17, 24]) {
      traps.add(
        Trap(x: _gridX(i), y: _gridY(15), type: TrapType.proximitySpike),
      );
    }

    // Puerta
    traps.add(Trap(x: _gridX(30), y: _gridY(15), type: TrapType.door));

    return EscapeLevelData(
      levelNumber: 8,
      startMessage: 'The silence is closing in...',
      startX: _gridX(2),
      startY: _gridY(14),
      tiles: tiles,
      traps: traps,
    );
  }

  static EscapeLevelData _level9() {
    final tiles = <Tile>[];
    final traps = <Trap>[];

    // Suelo
    for (var i = 0; i < GameConstants.gridWidth; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(16), type: TileType.platform));
    }

    // Puente invisible (el camino seguro)
    for (var i = 5; i <= 29; i++) {
      tiles.add(
        Tile(x: _gridX(i), y: _gridY(13), type: TileType.invisiblePlatform),
      );
    }

    // Plataformas visibles (trampa)
    for (var i = 8; i <= 12; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(14), type: TileType.platform));
    }
    traps.add(
      Trap(x: _gridX(16), y: _gridY(14), type: TrapType.collapsingPlatform),
    );

    // Puerta
    traps.add(Trap(x: _gridX(28), y: _gridY(8), type: TrapType.door));

    return EscapeLevelData(
      levelNumber: 9,
      startMessage: 'An ascent into madness.',
      startX: _gridX(2),
      startY: _gridY(14),
      tiles: tiles,
      traps: traps,
    );
  }

  static EscapeLevelData _level10() {
    final tiles = <Tile>[];
    final traps = <Trap>[];

    // Suelo
    for (var i = 0; i < GameConstants.gridWidth; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(16), type: TileType.platform));
    }

    // Techo
    for (var i = 0; i < GameConstants.gridWidth; i++) {
      tiles.add(Tile(x: _gridX(i), y: _gridY(0), type: TileType.platform));
    }

    // Techo que cae al inicio
    traps.add(
      Trap(
        x: _gridX(2),
        y: _gridY(0),
        width: GameConstants.tileSize * 6,
        height: GameConstants.tileSize * 3,
        type: TrapType.fallingCeiling,
      ),
    );

    // Plataformas
    for (var i = 10; i <= 14; i++) {
      traps.add(
        Trap(x: _gridX(i), y: _gridY(12), type: TrapType.collapsingPlatform),
      );
    }

    // Pinchos de proximidad
    for (final i in [16, 18, 20]) {
      traps.add(
        Trap(x: _gridX(i), y: _gridY(15), type: TrapType.proximitySpike),
      );
    }

    // Invertir gravedad
    traps.add(Trap(x: _gridX(22), y: _gridY(15), type: TrapType.invertGravity));

    // Invertir controles (en el techo)
    traps.add(Trap(x: _gridX(24), y: _gridY(1), type: TrapType.invertControls));

    // Normalizar gravedad
    traps.add(Trap(x: _gridX(27), y: _gridY(1), type: TrapType.invertGravity));

    // Puerta
    traps.add(Trap(x: _gridX(28), y: _gridY(7), type: TrapType.door));

    return EscapeLevelData(
      levelNumber: 10,
      startMessage: 'One final echo... Escape now!',
      startX: _gridX(2),
      startY: _gridY(14),
      tiles: tiles,
      traps: traps,
    );
  }
}
