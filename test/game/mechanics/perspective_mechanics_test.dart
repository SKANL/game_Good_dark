import 'dart:ui';

import 'package:echo_world/game/level/data/level_models.dart';
import 'package:echo_world/game/level/manager/level_manager.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock CheckpointBloc since LevelManager needs it
import 'package:echo_world/game/cubit/checkpoint/checkpoint_bloc.dart';

class MockCheckpointBloc extends Mock implements CheckpointBloc {}

void main() {
  group('LevelManagerComponent Perspective Physics', () {
    late LevelManagerComponent levelManager;
    late MockCheckpointBloc checkpointBloc;

    setUp(() {
      checkpointBloc = MockCheckpointBloc();
      levelManager = LevelManagerComponent(checkpointBloc: checkpointBloc);
    });

    test('isRectWalkable handles Abyss correctly based on perspective', () {
      // Setup a 1x1 grid with an Abyss
      final grid = [
        [CeldaData.abismo],
      ];
      final levelData = LevelDataMock(grid);
      levelManager.setChunkForTesting(levelData);

      final rect = const Rect.fromLTWH(0, 0, 32, 32);

      // Top-Down (checkAbyss: true) -> Should be blocked
      expect(
        levelManager.isRectWalkable(rect, checkAbyss: true),
        isFalse,
        reason: 'Abyss should block in Top-Down',
      );

      // Side-Scroll (checkAbyss: false) -> Should be passable
      expect(
        levelManager.isRectWalkable(rect, checkAbyss: false),
        isTrue,
        reason: 'Abyss should be passable in Side-Scroll',
      );
    });

    test('isRectWalkable handles Tunnel correctly based on crouching', () {
      // Setup a 1x1 grid with a Tunnel
      final grid = [
        [CeldaData.tunel],
      ];
      final levelData = LevelDataMock(grid);
      levelManager.setChunkForTesting(levelData);

      final rect = const Rect.fromLTWH(0, 0, 32, 32);

      // Standing -> Should be blocked
      expect(
        levelManager.isRectWalkable(rect, isCrouching: false),
        isFalse,
        reason: 'Tunnel should block when standing',
      );

      // Crouching -> Should be passable
      expect(
        levelManager.isRectWalkable(rect, isCrouching: true),
        isTrue,
        reason: 'Tunnel should be passable when crouching',
      );
    });
  });
}

class LevelDataMock extends LevelData {
  LevelDataMock(List<List<CeldaData>> grid)
    : super(
        ancho: grid[0].length,
        alto: grid.length,
        grid: grid,
        nombre: 'Test',
        dificultad: Dificultad.tutorial,
        sector: Sector.contencion,
      );
}
