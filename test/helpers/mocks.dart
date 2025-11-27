import 'package:audioplayers/audioplayers.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:echo_world/game/cubit/checkpoint/cubit.dart';
import 'package:echo_world/game/game.dart';
import 'package:echo_world/loading/loading.dart';
import 'package:echo_world/lore/lore.dart';
import 'package:flame/cache.dart';
import 'package:flame_audio/bgm.dart';
import 'package:mocktail/mocktail.dart';

class MockPreloadCubit extends MockCubit<PreloadState>
    implements PreloadCubit {}

class MockAudioCache extends Mock implements AudioCache {}

class MockAudioCubit extends MockCubit<AudioState> implements AudioCubit {}

class MockGameBloc extends MockBloc<GameEvent, GameState> implements GameBloc {}

class MockLoreBloc extends MockBloc<LoreEvent, LoreState> implements LoreBloc {}

class MockCheckpointBloc extends MockBloc<CheckpointEvent, CheckpointState>
    implements CheckpointBloc {}

class MockImages extends Mock implements Images {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockBgm extends Mock implements Bgm {}
