import 'package:echo_world/game/black_echo_game.dart';
import 'package:flame/game.dart';

import 'package:echo_world/game/cubit/audio/audio_cubit.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

class TestGame extends FlameGame {
  TestGame() {
    images.prefix = '';
  }
}

class TestBlackEchoGame extends BlackEchoGame {
  TestBlackEchoGame({
    required super.gameBloc,
    required super.checkpointBloc,
    required super.loreBloc,
    AudioCubit? audioCubit,
  }) : super(audioCubit: audioCubit ?? MockAudioCubit()) {
    images.prefix = '';
  }

  @override
  Future<void> onLoad() async {
    // Skip loading game components for UI tests
  }

  @override
  void update(double dt) {
    // Skip update logic for tests to avoid mocking deep audio structures
  }
}
