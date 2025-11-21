import 'package:echo_world/game/level/level_models.dart';

/// Concrete implementation of LevelData for procedurally generated levels
class ProceduralLevel extends LevelData {
  const ProceduralLevel({
    required super.ancho,
    required super.alto,
    required super.grid,
    super.entidadesIniciales = const [],
    super.dificultad = Dificultad.tutorial,
    super.sector = Sector.contencion,
    super.nombre = 'Procedural Chunk',
    super.spawnPoint,
    super.exitPoint,
    super.exitHint,
    super.ambientLight,
    super.fogColor,
  });
}
