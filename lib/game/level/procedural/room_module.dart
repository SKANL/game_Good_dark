import 'package:echo_world/game/level/data/level_models.dart';

enum RoomExit { north, south, east, west }

/// Represents a small grid template that can be stitched into a larger level.
class RoomModule {

  const RoomModule({
    required this.width,
    required this.height,
    required this.grid,
    this.spawns = const [],
    this.exits = const [],
  });
  final int width;
  final int height;
  final List<List<CeldaData>> grid;
  final List<EntidadSpawn> spawns;
  final List<RoomExit> exits;

  /// Rotates the room 90 degrees clockwise (optional future feature)
  // RoomModule rotate() { ... }
}
