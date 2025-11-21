import 'dart:math';

import 'package:echo_world/game/level/level_chunks.dart';
import 'package:echo_world/game/level/level_models.dart';
import 'package:echo_world/game/level/procedural/layout_builder.dart' as proc;

/// Handles the procedural generation of levels by selecting chunks
/// based on the current sector and difficulty progression.
class LevelGenerator {
  final Random _random = Random();
  final proc.LayoutBuilder _layoutBuilder = proc.LayoutBuilder(
    widthInModules: 4,
    heightInModules: 3,
  );

  /// Generates the next level based on the current index and sector.
  LevelData generateLevel(int levelIndex, Sector sector) {
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

    // 4. Endless Mode (Procedural) - Levels 15+
    // Use organic terrain for variety (50% chance)
    final useOrganic = _random.nextDouble() < 0.5;

    // Calculate dynamic difficulty
    Dificultad dynamicDifficulty;
    if (levelIndex < 20) {
      dynamicDifficulty = Dificultad.media;
    } else {
      dynamicDifficulty = Dificultad.alta;
    }

    return _layoutBuilder.buildLevel(
      name: 'Procedural Level ${levelIndex - 14}',
      dificultad: dynamicDifficulty,
      sector: sector,
      useOrganicTerrain: useOrganic,
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
