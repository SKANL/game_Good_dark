import 'dart:math';

import 'package:echo_world/game/level/data/level_chunks.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:echo_world/game/level/modular/modular_level_builder.dart';

/// Handles the procedural generation of levels by selecting chunks
/// based on the current sector and difficulty progression.
class LevelGenerator {
  final Random _random = Random();
  final ModularLevelBuilder _modularBuilder = ModularLevelBuilder();

  /// Generates the next level based on the current index and sector.
  Future<LevelData> generateLevel(int levelIndex, Sector sector) async {
    // Phase 1: Smoother Progression

    // 1. Tutorial (Fixed) - Levels 0-2
    if (levelIndex < 3) {
      return _getTutorialChunk(levelIndex);
    }

    // 2. Early Game (Simple Chunks) - Levels 3-6
    if (levelIndex < 7) {
      final pool = _getChunkPool(Sector.contencion);
      return pool[_random.nextInt(pool.length)];
    }

    // 3. Mid Game (Complex Chunks) - Levels 7-14
    if (levelIndex < 15) {
      // Mix of Laboratorios and Salida chunks depending on exact level
      final targetSector = levelIndex < 13
          ? Sector.laboratorios
          : Sector.salida;
      final pool = _getChunkPool(targetSector);
      return pool[_random.nextInt(pool.length)];
    }

    // 4. Endless Mode (Modular Composition) - Levels 15+
    // Calculate dynamic difficulty
    Dificultad dynamicDifficulty;
    if (levelIndex < 20) {
      dynamicDifficulty = Dificultad.media;
    } else {
      dynamicDifficulty = Dificultad.alta;
    }

    // Generate a modular level with 5-10 chunks
    final length = 5 + _random.nextInt(6); // 5 to 10 chunks

    return await _modularBuilder.buildLevel(
      length: length,
      dificultad: dynamicDifficulty,
      sector: sector,
      name: 'Modular Level ${levelIndex - 14}',
    );
  }

  LevelData _getTutorialChunk(int index) {
    switch (index) {
      case 0:
        return ChunkInicioSeguro();
      case 1:
        return ChunkAbismoSalto();
      case 2:
        return ChunkSigiloCazador();
      default:
        return ChunkInicioSeguro();
    }
  }

  List<LevelData> _getChunkPool(Sector sector) {
    switch (sector) {
      case Sector.contencion:
        return [
          ChunkCorredorEmboscada(),
          ChunkSalaSegura(),
          ChunkPuzzleAbismos(),
        ];
      case Sector.laboratorios:
        return [
          ChunkVigiaTest(),
          ChunkSilencioTotal(),
          ChunkParalelo(),
          ChunkDestruccionTactica(),
          ChunkAlarmaEnCadena(),
          ChunkLaberintoVertical(),
        ];
      case Sector.salida:
        return [
          ChunkBrutoTest(),
          ChunkArenaBruto(),
          ChunkInfierno(),
        ];
    }
  }
}
