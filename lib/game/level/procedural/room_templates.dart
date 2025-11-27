import 'package:echo_world/game/entities/enemies/enemies.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:echo_world/game/level/procedural/room_module.dart';
import 'package:flame/components.dart';

class RoomTemplates {
  static const int moduleSize = 10; // 10x10 tiles per module

  // --- BASIC ROOMS ---

  static RoomModule get emptyRoom => RoomModule(
    width: moduleSize,
    height: moduleSize,
    grid: List.generate(
      moduleSize,
      (y) => List.generate(
        moduleSize,
        (x) => (x == 0 || x == moduleSize - 1 || y == 0 || y == moduleSize - 1)
            ? CeldaData.pared
            : CeldaData.suelo,
      ),
    ),
    exits: [RoomExit.north, RoomExit.south, RoomExit.east, RoomExit.west],
  );

  static RoomModule get corridorHorizontal => RoomModule(
    width: moduleSize,
    height: moduleSize,
    grid: List.generate(
      moduleSize,
      (y) => List.generate(
        moduleSize,
        (x) {
          if (y == 0 || y == moduleSize - 1) return CeldaData.pared;
          return CeldaData.suelo;
        },
      ),
    ),
    exits: [RoomExit.east, RoomExit.west],
  );

  static RoomModule get corridorVertical => RoomModule(
    width: moduleSize,
    height: moduleSize,
    grid: List.generate(
      moduleSize,
      (y) => List.generate(
        moduleSize,
        (x) {
          if (x == 0 || x == moduleSize - 1) return CeldaData.pared;
          return CeldaData.suelo;
        },
      ),
    ),
    exits: [RoomExit.north, RoomExit.south],
  );

  static RoomModule get crossRoad => RoomModule(
    width: moduleSize,
    height: moduleSize,
    grid: List.generate(
      moduleSize,
      (y) => List.generate(
        moduleSize,
        (x) {
          // Corners are walls
          if ((x == 0 || x == moduleSize - 1) &&
              (y == 0 || y == moduleSize - 1)) {
            return CeldaData.pared;
          }
          return CeldaData.suelo;
        },
      ),
    ),
    exits: [RoomExit.north, RoomExit.south, RoomExit.east, RoomExit.west],
  );

  // --- COMBAT ROOMS ---

  static RoomModule get combatArena => RoomModule(
    width: moduleSize,
    height: moduleSize,
    grid: List.generate(
      moduleSize,
      (y) => List.generate(
        moduleSize,
        (x) {
          if (x == 0 || x == moduleSize - 1 || y == 0 || y == moduleSize - 1) {
            return CeldaData.pared;
          }
          // Central pillar
          if (x >= 4 && x <= 5 && y >= 4 && y <= 5) return CeldaData.pared;
          return CeldaData.suelo;
        },
      ),
    ),
    spawns: [
      EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(2, 2)),
      EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(7, 7)),
    ],
    exits: [RoomExit.north, RoomExit.south, RoomExit.east, RoomExit.west],
  );
  // --- SECTOR 1: CONTENCIÓN (Claustrophobic, Cells) ---

  static RoomModule get cellBlock => RoomModule(
    width: moduleSize,
    height: moduleSize,
    grid: List.generate(
      moduleSize,
      (y) => List.generate(
        moduleSize,
        (x) {
          // Central corridor
          if (x >= 4 && x <= 5) return CeldaData.suelo;
          // Outer walls
          if (x == 0 || x == moduleSize - 1 || y == 0 || y == moduleSize - 1) {
            return CeldaData.pared;
          }
          // Cell walls (every 2 tiles)
          if (y % 3 == 0) return CeldaData.pared;
          // Cell doors (open)
          if ((x == 3 || x == 6) && y % 3 != 0) return CeldaData.suelo;
          // Cell interiors
          return CeldaData.suelo;
        },
      ),
    ),
    exits: [RoomExit.north, RoomExit.south],
  );

  static RoomModule get securityCheckpoint => RoomModule(
    width: moduleSize,
    height: moduleSize,
    grid: List.generate(
      moduleSize,
      (y) => List.generate(
        moduleSize,
        (x) {
          if (x == 0 || x == moduleSize - 1 || y == 0 || y == moduleSize - 1) {
            return CeldaData.pared;
          }
          // Security desk/barrier
          if (y == 5 && (x < 4 || x > 5)) return CeldaData.pared;
          return CeldaData.suelo;
        },
      ),
    ),
    spawns: [
      EntidadSpawn(tipoEnemigo: VigiaComponent, posicion: Vector2(5, 4)),
    ],
    exits: [RoomExit.north, RoomExit.south, RoomExit.east, RoomExit.west],
  );

  // --- SECTOR 2: LABORATORIOS (Open, Hazardous) ---

  static RoomModule get experimentChamber => RoomModule(
    width: moduleSize,
    height: moduleSize,
    grid: List.generate(
      moduleSize,
      (y) => List.generate(
        moduleSize,
        (x) {
          if (x == 0 || x == moduleSize - 1 || y == 0 || y == moduleSize - 1) {
            return CeldaData.pared;
          }
          // Central test subject container
          if (x >= 4 && x <= 5 && y >= 4 && y <= 5) return CeldaData.pared;
          return CeldaData.suelo;
        },
      ),
    ),
    spawns: [
      EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(2, 2)),
      EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(7, 7)),
    ],
    exits: [RoomExit.north, RoomExit.south, RoomExit.east, RoomExit.west],
  );

  static RoomModule get dataArchive => RoomModule(
    width: moduleSize,
    height: moduleSize,
    grid: List.generate(
      moduleSize,
      (y) => List.generate(
        moduleSize,
        (x) {
          if (x == 0 || x == moduleSize - 1 || y == 0 || y == moduleSize - 1) {
            return CeldaData.pared;
          }
          // Server rows
          if (x % 2 == 0 && y > 2 && y < 8) return CeldaData.pared;
          return CeldaData.suelo;
        },
      ),
    ),
    exits: [RoomExit.north, RoomExit.south],
  );

  // --- SECTOR 3: SALIDA (Chaotic, Destroyed) ---

  static RoomModule get collapseZone => RoomModule(
    width: moduleSize,
    height: moduleSize,
    grid: List.generate(
      moduleSize,
      (y) => List.generate(
        moduleSize,
        (x) {
          if (x == 0 || x == moduleSize - 1 || y == 0 || y == moduleSize - 1) {
            return CeldaData.pared;
          }
          // Random debris (deterministic pattern for template)
          if ((x * y) % 5 == 0) return CeldaData.pared;
          return CeldaData.suelo;
        },
      ),
    ),
    spawns: [
      EntidadSpawn(tipoEnemigo: BrutoComponent, posicion: Vector2(5, 5)),
    ],
    exits: [RoomExit.north, RoomExit.south, RoomExit.east, RoomExit.west],
  );

  static RoomModule get reactorCore => RoomModule(
    width: moduleSize,
    height: moduleSize,
    grid: List.generate(
      moduleSize,
      (y) => List.generate(
        moduleSize,
        (x) {
          if (x == 0 || x == moduleSize - 1 || y == 0 || y == moduleSize - 1) {
            return CeldaData.pared;
          }
          // Circular core
          final dx = x - 4.5;
          final dy = y - 4.5;
          if (dx * dx + dy * dy < 4) return CeldaData.pared;
          return CeldaData.suelo;
        },
      ),
    ),
    exits: [RoomExit.north, RoomExit.south, RoomExit.east, RoomExit.west],
  );
}
