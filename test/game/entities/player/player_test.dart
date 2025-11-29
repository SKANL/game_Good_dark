import 'dart:ui';

import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/cubit/audio/audio_cubit.dart';
import 'package:echo_world/game/cubit/game/game_bloc.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:echo_world/game/entities/player/behaviors/behaviors.dart';
import 'package:echo_world/game/entities/player/player.dart';
import 'package:echo_world/game/level/manager/level_manager.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/helpers.dart';

class MockLevelManager extends Mock implements LevelManagerComponent {}

// A subclass of BlackEchoGame that allows injecting dependencies
class TestBlackEchoGame extends BlackEchoGame {
  TestBlackEchoGame({
    required super.gameBloc,
    required super.checkpointBloc,
    required super.loreBloc,
    required this.mockLevelManager,
    AudioCubit? audioCubit,
  }) : super(audioCubit: audioCubit ?? MockAudioCubit());

  final LevelManagerComponent mockLevelManager;

  @override
  Future<void> onLoad() async {
    // Skip normal onLoad to avoid loading assets/audio
    // Manually set up what we need
    levelManager = mockLevelManager;
    await world.add(levelManager);
  }

  @override
  void update(double dt) {
    // Skip update to avoid audio checks
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(Rect.zero);
  });

  group('GravityBehavior', () {
    late GameBloc gameBloc;
    late MockLevelManager levelManager;

    setUp(() {
      gameBloc = MockGameBloc();
      levelManager = MockLevelManager();
      when(() => gameBloc.state).thenReturn(
        const GameState(
          energiaGrito: 100,
          ruidoMental: 0,
          enfoqueActual: Enfoque.sideScroll,
          estadoJugador: EstadoJugador.vivo,
          estadoJuego: EstadoJuego.jugando,
          estaAgachado: false,
          puedeAbsorber: false,
          sobrecargaActiva: false,
          agoniaActiva: false,
        ),
      );
      // Default: walkable everywhere
      when(() => levelManager.isRectWalkable(any())).thenReturn(true);
    });

    testWithGame<TestBlackEchoGame>(
      'falls when air is below',
      () => TestBlackEchoGame(
        gameBloc: gameBloc,
        checkpointBloc: MockCheckpointBloc(),
        loreBloc: MockLoreBloc(),
        mockLevelManager: levelManager,
      ),
      (game) async {
        final player = PlayerComponent(gameBloc: gameBloc);
        await game.world.add(player);
        await game.ready();

        final gravity = GravityBehavior();
        await player.add(gravity);
        await game.ready();

        // Initial update to start falling
        gravity.update(0.1);

        // Should have moved down
        expect(player.position.y, greaterThan(0));
      },
    );

    testWithGame<TestBlackEchoGame>(
      'stops at ground',
      () => TestBlackEchoGame(
        gameBloc: gameBloc,
        checkpointBloc: MockCheckpointBloc(),
        loreBloc: MockLoreBloc(),
        mockLevelManager: levelManager,
      ),
      (game) async {
        final player = PlayerComponent(gameBloc: gameBloc);
        player.position = Vector2(100, 100);
        await game.world.add(player);
        await game.ready();

        final gravity = GravityBehavior();
        await player.add(gravity);
        await game.ready();

        // Mock collision: ground at y=128 (tile 3 if size 32? no, let's say tile size 32)
        // Player size is 24. Half height 12.
        // If player is at 100, bottom is 112.
        // Let's say ground is at 128 (4 * 32).

        // We simulate that isRectWalkable returns false when checking below
        when(() => levelManager.isRectWalkable(any())).thenAnswer((invocation) {
          final rect = invocation.positionalArguments[0] as Rect;
          // If rect touches y >= 128, it's a collision
          if (rect.bottom >= 128) return false;
          return true;
        });

        // Fall with realistic steps to avoid tunneling
        // Ground at 128. Player at 100. Distance to ground = 28.
        // Gravity 900.
        // Time to fall 28px: d = 0.5 * g * t^2 => t = sqrt(2*28/900) = sqrt(0.062) = 0.25s.

        // Step 1: 0.1s. v=90. d=4.5. pos=104.5.
        // Wait, update uses v += g*dt; pos += v*dt. Symplectic Euler?
        // v_new = v_old + g*dt
        // pos_new = pos_old + v_new*dt

        // dt=0.1. v=90. pos=100 + 90*0.1 = 109.
        gravity.update(0.1);
        expect(player.position.y, 109.0);

        // dt=0.1. v=180. pos=109 + 180*0.1 = 127.
        // Bottom = 127 + 12 = 139.
        // 139 >= 128. Collision!
        // tileY = floor(139/32) = 4.
        // groundY = 4*32 - 12 = 116.
        // 127 <= 116 + 32 (148). True.
        // Snap to 116.
        gravity.update(0.1);

        // Hitbox is 80% of 24 = 19.2. Half height = 9.6.
        // Ground at 128. Expected Y = 128 - 9.6 = 118.4
        expect(player.position.y, closeTo(118.4, 0.1));
      },
    );
  });
}
