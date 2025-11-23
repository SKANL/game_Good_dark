// import 'dart:math';

// import 'package:echo_world/game/level/level_models.dart';
// import 'package:echo_world/game/level/procedural/procedural_level.dart';
// import 'package:echo_world/game/level/procedural/room_module.dart';
// import 'package:echo_world/game/level/procedural/room_templates.dart';
// import 'package:echo_world/game/level/procedural/cellular_automata.dart';
// import 'package:echo_world/game/level/procedural/event_manager.dart';
// import 'package:echo_world/game/entities/enemies/enemies.dart';
// import 'package:flame/components.dart';
// import 'dart:ui';

// enum PacingState { combat, tension, relief }

// class LayoutBuilder {
//   final int widthInModules;
//   final int heightInModules;
//   final Random _random = Random();
//   final CellularAutomata _cellularAutomata = CellularAutomata();
//   final EventManager _eventManager = EventManager();

//   LayoutBuilder({this.widthInModules = 4, this.heightInModules = 4});

//   Color _getSectorAmbientLight(Sector sector) {
//     switch (sector) {
//       case Sector.contencion:
//         return const Color(0xFF1A1A2E); // Dark Blue
//       case Sector.laboratorios:
//         return const Color(0xFF1E2A25); // Dark Greenish
//       case Sector.salida:
//         return const Color(0xFF2E1A1A); // Dark Reddish
//     }
//   }

//   Color _getSectorFogColor(Sector sector) {
//     switch (sector) {
//       case Sector.contencion:
//         return const Color(0xFF16213E).withOpacity(0.3);
//       case Sector.laboratorios:
//         return const Color(0xFF1A3C34).withOpacity(0.3);
//       case Sector.salida:
//         return const Color(0xFF3E1616).withOpacity(0.3);
//     }
//   }

//   LevelData buildLevel({
//     required String name,
//     required Dificultad dificultad,
//     required Sector sector,
//     bool useOrganicTerrain = false,
//   }) {
//     // Roll for dynamic event
//     final event = _eventManager.rollEvent();
//     final eventMultiplier = _eventManager.getDifficultyMultiplier(event);

//     // Determine visual atmosphere based on sector
//     final ambientLight = _getSectorAmbientLight(sector);
//     final fogColor = _getSectorFogColor(sector);

//     // If organic terrain is requested, use cellular automata
//     if (useOrganicTerrain) {
//       return _buildOrganicLevel(
//         name,
//         dificultad,
//         sector,
//         event,
//         eventMultiplier,
//         ambientLight,
//         fogColor,
//       );
//     }

//     // Otherwise, use modular approach
//     // 1. Initialize grid of modules (null means empty)
//     final moduleGrid = List.generate(
//       heightInModules,
//       (_) => List<RoomModule?>.filled(widthInModules, null),
//     );

//     // 2. Random Walk to create a path
//     int currentX = 0;
//     int currentY = _random.nextInt(heightInModules);
//     final startModule = Point(currentX, currentY);

//     // Start room
//     moduleGrid[currentY][currentX] = RoomTemplates.emptyRoom;

//     // Pacing State Machine
//     var currentPacing = PacingState.tension;
//     int roomsSinceLastCombat = 0;
//     final reliefModules = <Point<int>>[];

//     // Simple path generation: move generally East until we hit the edge
//     while (currentX < widthInModules - 1) {
//       // Decide next move
//       final move = _random.nextDouble();
//       if (move < 0.6) {
//         currentX++;
//       } else if (move < 0.8) {
//         if (currentY > 0) currentY--;
//       } else {
//         if (currentY < heightInModules - 1) currentY++;
//       }

//       // Place a room if empty
//       if (moduleGrid[currentY][currentX] == null) {
//         // Update pacing
//         if (currentPacing == PacingState.combat) {
//           currentPacing = PacingState.relief; // Rest after combat
//           roomsSinceLastCombat = 0;
//         } else if (currentPacing == PacingState.relief) {
//           currentPacing = PacingState.tension; // Build tension
//         } else if (currentPacing == PacingState.tension) {
//           // Difficulty affects combat frequency
//           int threshold = 3;
//           double chance = 0.3;

//           if (dificultad == Dificultad.alta) {
//             threshold = 2; // More frequent combat
//             chance = 0.5;
//           } else if (dificultad == Dificultad.baja) {
//             threshold = 4; // Less frequent
//             chance = 0.2;
//           }

//           if (roomsSinceLastCombat > threshold ||
//               _random.nextDouble() < chance) {
//             currentPacing = PacingState.combat; // Trigger combat
//           }
//         }

//         // Pick a template based on sector AND pacing
//         moduleGrid[currentY][currentX] = _pickRandomRoom(sector, currentPacing);

//         if (currentPacing == PacingState.relief) {
//           reliefModules.add(Point(currentX, currentY));
//         }

//         roomsSinceLastCombat++;
//       }
//     }
//     final endModule = Point(currentX, currentY);

//     // 3. Stitch modules into a single LevelData
//     return _stitchModules(
//       moduleGrid,
//       name,
//       dificultad,
//       sector,
//       startModule,
//       endModule,
//       ambientLight,
//       fogColor,
//       reliefModules,
//     );
//   }

//   RoomModule _pickRandomRoom(Sector sector, PacingState pacing) {
//     final roll = _random.nextDouble();

//     // 1. Relief/Safe Rooms
//     if (pacing == PacingState.relief) {
//       // 80% chance for a simple corridor or empty room
//       if (roll < 0.8) return RoomTemplates.emptyRoom;
//       return RoomTemplates.corridorHorizontal;
//     }

//     // 2. Combat Rooms
//     if (pacing == PacingState.combat) {
//       // Force a combat-heavy room
//       switch (sector) {
//         case Sector.contencion:
//           return RoomTemplates.combatArena;
//         case Sector.laboratorios:
//           return RoomTemplates.experimentChamber;
//         case Sector.salida:
//           return RoomTemplates.reactorCore; // Dangerous
//       }
//     }

//     // 3. Tension/Standard Rooms (Mixed)
//     // Common rooms (Corridors) - 30% chance
//     if (roll < 0.3) {
//       return _random.nextBool()
//           ? RoomTemplates.corridorHorizontal
//           : RoomTemplates.corridorVertical;
//     }

//     // Sector-specific rooms - 70% chance
//     switch (sector) {
//       case Sector.contencion:
//         if (roll < 0.6) return RoomTemplates.cellBlock;
//         if (roll < 0.8) return RoomTemplates.securityCheckpoint;
//         return RoomTemplates.combatArena;

//       case Sector.laboratorios:
//         if (roll < 0.6) return RoomTemplates.experimentChamber;
//         if (roll < 0.8) return RoomTemplates.dataArchive;
//         return RoomTemplates.crossRoad;

//       case Sector.salida:
//         if (roll < 0.6) return RoomTemplates.collapseZone;
//         if (roll < 0.8) return RoomTemplates.reactorCore;
//         return RoomTemplates.combatArena;
//     }
//   }

//   LevelData _stitchModules(
//     List<List<RoomModule?>> moduleGrid,
//     String name,
//     Dificultad dificultad,
//     Sector sector,
//     Point startModule,
//     Point endModule,
//     Color ambientLight,
//     Color fogColor,
//     List<Point<int>> reliefModules,
//   ) {
//     const modSize = RoomTemplates.moduleSize;
//     final totalWidth = widthInModules * modSize;
//     final totalHeight = heightInModules * modSize;

//     // Initialize full grid with walls
//     final fullGrid = List.generate(
//       totalHeight,
//       (_) => List.filled(totalWidth, CeldaData.pared),
//     );

//     final allSpawns = <EntidadSpawn>[];

//     for (var my = 0; my < heightInModules; my++) {
//       for (var mx = 0; mx < widthInModules; mx++) {
//         final module = moduleGrid[my][mx];
//         if (module == null) continue;

//         // Copy module grid to full grid
//         for (var y = 0; y < modSize; y++) {
//           for (var x = 0; x < modSize; x++) {
//             final globalX = mx * modSize + x;
//             final globalY = my * modSize + y;
//             fullGrid[globalY][globalX] = module.grid[y][x];
//           }
//         }

//         // Copy spawns with offset
//         for (var spawn in module.spawns) {
//           allSpawns.add(
//             EntidadSpawn(
//               tipoEnemigo: spawn.tipoEnemigo,
//               posicion:
//                   spawn.posicion +
//                   Vector2((mx * modSize).toDouble(), (my * modSize).toDouble()),
//             ),
//           );
//         }

//         // Open connections between adjacent modules
//         // (This is a simplified approach; a real system would check exits)
//         // Horizontal connection (East)
//         if (mx < widthInModules - 1 && moduleGrid[my][mx + 1] != null) {
//           _openWall(
//             fullGrid,
//             (mx + 1) * modSize - 1,
//             my * modSize + modSize ~/ 2,
//             true,
//           );
//         }
//         // Vertical connection (South)
//         if (my < heightInModules - 1 && moduleGrid[my + 1][mx] != null) {
//           _openWall(
//             fullGrid,
//             mx * modSize + modSize ~/ 2,
//             (my + 1) * modSize - 1,
//             false,
//           );
//         }
//       }
//     }

//     // Place Narrative Echoes in Relief Modules
//     for (final point in reliefModules) {
//       // Find a random floor tile in this module
//       // Try 10 times
//       for (var i = 0; i < 10; i++) {
//         final lx = _random.nextInt(modSize);
//         final ly = _random.nextInt(modSize);
//         final gx = point.x * modSize + lx;
//         final gy = point.y * modSize + ly;

//         if (fullGrid[gy][gx].tipo == TipoCelda.suelo) {
//           // Place echo
//           // Create a new CeldaData with the echo ID
//           // We need to copy properties of the existing cell (height, etc)
//           final oldCell = fullGrid[gy][gx];
//           fullGrid[gy][gx] = CeldaData(
//             tipo: oldCell.tipo,
//             altura: oldCell.altura,
//             esDestructible: oldCell.esDestructible,
//             ecoNarrativoId: 'eco_${sector.name}_${_random.nextInt(100)}',
//           );
//           break; // Placed one echo per relief module
//         }
//       }
//     }

//     // Calculate spawn and exit points (center of start/end modules)
//     final spawnPoint = Vector2(
//       (startModule.x * modSize + modSize / 2).toDouble(),
//       (startModule.y * modSize + modSize / 2).toDouble(),
//     );

//     final exitPoint = Vector2(
//       (endModule.x * modSize + modSize / 2).toDouble(),
//       (endModule.y * modSize + modSize / 2).toDouble(),
//     );

//     return ProceduralLevel(
//       ancho: totalWidth,
//       alto: totalHeight,
//       grid: fullGrid,
//       entidadesIniciales: allSpawns,
//       nombre: name,
//       dificultad: dificultad,
//       sector: sector,
//       spawnPoint: spawnPoint,
//       exitPoint: exitPoint,
//       exitHint: 'Sigue los pasillos hacia el este...',
//       ambientLight: ambientLight,
//       fogColor: fogColor,
//     );
//   }

//   void _openWall(List<List<CeldaData>> grid, int x, int y, bool horizontal) {
//     if (horizontal) {
//       // Open 2 tiles for a doorway
//       grid[y][x] = CeldaData.suelo;
//       grid[y][x + 1] = CeldaData.suelo;
//       grid[y - 1][x] = CeldaData.suelo; // Wider
//       grid[y - 1][x + 1] = CeldaData.suelo;
//     } else {
//       grid[y][x] = CeldaData.suelo;
//       grid[y + 1][x] = CeldaData.suelo;
//       grid[y][x - 1] = CeldaData.suelo;
//       grid[y + 1][x - 1] = CeldaData.suelo;
//     }
//   }

//   /// Builds a level using cellular automata for organic, cave-like terrain
//   LevelData _buildOrganicLevel(
//     String name,
//     Dificultad dificultad,
//     Sector sector,
//     LevelEvent event,
//     double eventMultiplier,
//     Color ambientLight,
//     Color fogColor,
//   ) {
//     const modSize = RoomTemplates.moduleSize;
//     final totalWidth = widthInModules * modSize;
//     final totalHeight = heightInModules * modSize;

//     // Generate organic terrain using cellular automata
//     final grid = _cellularAutomata.generate(
//       width: totalWidth,
//       height: totalHeight,
//       fillPercent: 0.45,
//       smoothPasses: 4,
//     );

//     // Spawn enemies in open areas based on difficulty
//     final spawns = <EntidadSpawn>[];
//     final baseEnemyCount = _getEnemyCount(dificultad);
//     final enemyCount = (baseEnemyCount * eventMultiplier).round();

//     for (var i = 0; i < enemyCount; i++) {
//       // Find a random open tile for enemy spawn
//       final spawnPos = _findRandomOpenTile(grid);
//       if (spawnPos != null) {
//         spawns.add(
//           EntidadSpawn(
//             tipoEnemigo: _pickRandomEnemyType(sector),
//             posicion: spawnPos,
//           ),
//         );
//       }
//     }

//     // Find safe spawn and exit
//     final spawnPoint = _findSafeSpawnPoint(grid);
//     final exitPoint = _placeExit(grid, spawnPoint);

//     return ProceduralLevel(
//       ancho: totalWidth,
//       alto: totalHeight,
//       grid: grid,
//       entidadesIniciales: spawns,
//       nombre: name,
//       dificultad: dificultad,
//       sector: sector,
//       spawnPoint: spawnPoint,
//       exitPoint: exitPoint,
//       exitHint: 'Busca la corriente de aire...',
//       ambientLight: ambientLight,
//       fogColor: fogColor,
//     );
//   }

//   int _getEnemyCount(Dificultad dificultad) {
//     switch (dificultad) {
//       case Dificultad.tutorial:
//         return 0;
//       case Dificultad.baja:
//         return 2;
//       case Dificultad.media:
//         return 4;
//       case Dificultad.alta:
//         return 6;
//     }
//   }

//   Vector2? _findRandomOpenTile(Grid grid) {
//     final height = grid.length;
//     final width = grid[0].length;

//     // Try up to 100 times to find an  open tile
//     for (var attempt = 0; attempt < 100; attempt++) {
//       final x = _random.nextInt(width);
//       final y = _random.nextInt(height);

//       if (grid[y][x].tipo == TipoCelda.suelo) {
//         return Vector2(x.toDouble(), y.toDouble());
//       }
//     }

//     return null; // Failed to find open tile
//   }

//   Type _pickRandomEnemyType(Sector sector) {
//     // Import actual enemy types from the game
//     const cazador = CazadorComponent;
//     const vigia = VigiaComponent;
//     const bruto = BrutoComponent;

//     switch (sector) {
//       case Sector.contencion:
//         // Early game: mostly Cazadores
//         return _random.nextDouble() < 0.8 ? cazador : vigia;

//       case Sector.laboratorios:
//         // Mid game: mix of all types
//         final roll = _random.nextDouble();
//         if (roll < 0.4) return cazador;
//         if (roll < 0.7) return vigia;
//         return bruto;

//       case Sector.salida:
//         // Late game: more Brutos and Vigías
//         final roll = _random.nextDouble();
//         if (roll < 0.3) return cazador;
//         if (roll < 0.6) return vigia;
//         return bruto;
//     }
//   }

//   Vector2 _findSafeSpawnPoint(Grid grid) {
//     final height = grid.length;
//     final width = grid[0].length;

//     // Try to find a point with 3x3 clearance
//     for (var i = 0; i < 100; i++) {
//       final x = _random.nextInt(width - 2) + 1;
//       final y = _random.nextInt(height - 2) + 1;

//       if (_hasSpaceAround(grid, x, y, 1)) {
//         return Vector2(x.toDouble(), y.toDouble());
//       }
//     }

//     // Fallback: just any floor tile
//     final fallback = _findRandomOpenTile(grid);
//     return fallback ?? Vector2(1, 1); // Absolute fallback
//   }

//   bool _hasSpaceAround(Grid grid, int x, int y, int radius) {
//     for (var dy = -radius; dy <= radius; dy++) {
//       for (var dx = -radius; dx <= radius; dx++) {
//         if (y + dy < 0 ||
//             y + dy >= grid.length ||
//             x + dx < 0 ||
//             x + dx >= grid[0].length) {
//           return false;
//         }
//         if (grid[y + dy][x + dx].tipo == TipoCelda.pared) {
//           return false;
//         }
//       }
//     }
//     return true;
//   }

//   Vector2 _placeExit(Grid grid, Vector2 spawn) {
//     // Find a point far from spawn
//     Vector2 bestExit = spawn;
//     double maxDist = 0;

//     for (var i = 0; i < 50; i++) {
//       final pos = _findRandomOpenTile(grid);
//       if (pos != null) {
//         final dist = pos.distanceTo(spawn);
//         if (dist > maxDist) {
//           maxDist = dist;
//           bestExit = pos;
//         }
//       }
//     }

//     return bestExit;
//   }
// }
