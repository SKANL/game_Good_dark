// Not needed for test files
// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:echo_world/game/game.dart';
import 'package:echo_world/loading/cubit/cubit.dart';
import 'package:flame/cache.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

import 'package:echo_world/game/cubit/checkpoint/checkpoint_bloc.dart';
import 'package:echo_world/game/cubit/checkpoint/checkpoint_state.dart';
import 'package:echo_world/lore/lore.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

class _FakeAssetSource extends Fake implements AssetSource {}

class _FakeImage extends Fake implements ui.Image {}

class _MockStorage extends Mock implements Storage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // https://github.com/material-foundation/flutter-packages/issues/286#issuecomment-1406343761
  HttpOverrides.global = null;

  setUpAll(() {
    final storage = _MockStorage();
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          MethodChannel('xyz.luan/audioplayers'),
          (message) => null,
        );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (message) async => switch (message.method) {
            ('getTemporaryDirectory' || 'getApplicationSupportDirectory') =>
              Directory.systemTemp.createTempSync('fake').path,
            _ => null,
          },
        );
  });

  group('GamePage', () {
    late PreloadCubit preloadCubit;
    late Images images;
    late LoreBloc loreBloc;

    setUpAll(() {
      registerFallbackValue(_FakeAssetSource());
    });

    setUp(() {
      images = MockImages();
      when(() => images.fromCache(any())).thenReturn(_FakeImage());

      preloadCubit = MockPreloadCubit();
      when(() => preloadCubit.audio).thenReturn(AudioCache(prefix: ''));
      when(() => preloadCubit.images).thenReturn(images);

      loreBloc = MockLoreBloc();
      when(() => loreBloc.state).thenReturn(LoreState.initial());
    });

    testWidgets('is routable', (tester) async {
      await tester.pumpApp(
        Builder(
          builder: (context) => Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () => Navigator.of(context).push(GamePage.route()),
            ),
          ),
        ),
        preloadCubit: preloadCubit,
        loreBloc: loreBloc,
      );

      await tester.tap(find.byType(FloatingActionButton));

      await tester.pump();
      await tester.pump();

      expect(find.byType(GamePage), findsOneWidget);

      await tester.pumpWidget(Container());
    });

    testWidgets('renders GameView', (tester) async {
      await tester.pumpApp(
        const GamePage(),
        preloadCubit: preloadCubit,
        loreBloc: loreBloc,
      );
      expect(find.byType(GameView), findsOneWidget);
    });
  });

  group('GameView', () {
    late AudioCubit audioCubit;
    late GameBloc gameBloc;
    late LoreBloc loreBloc;
    late CheckpointBloc checkpointBloc;

    setUp(() {
      audioCubit = MockAudioCubit();
      when(() => audioCubit.state).thenReturn(AudioState());

      final effectPlayer = MockAudioPlayer();
      when(() => audioCubit.effectPlayer).thenReturn(effectPlayer);
      final bgm = MockBgm();
      when(() => audioCubit.bgm).thenReturn(bgm);
      when(() => bgm.play(any())).thenAnswer((_) async {});
      when(bgm.pause).thenAnswer((_) async {});

      gameBloc = MockGameBloc();
      when(() => gameBloc.state).thenReturn(GameState.initial());

      loreBloc = MockLoreBloc();
      when(() => loreBloc.state).thenReturn(LoreState.initial());

      checkpointBloc = MockCheckpointBloc();
      when(() => checkpointBloc.state).thenReturn(CheckpointState.initial());
    });

    testWidgets('toggles mute button correctly', (tester) async {
      final controller = StreamController<AudioState>();
      whenListen(audioCubit, controller.stream, initialState: AudioState());

      final game = TestBlackEchoGame(
        gameBloc: gameBloc,
        checkpointBloc: checkpointBloc,
        loreBloc: loreBloc,
      );
      await tester.pumpApp(
        GameView(game: game),
        audioCubit: audioCubit,
        gameBloc: gameBloc,
        loreBloc: loreBloc,
        checkpointBloc: checkpointBloc,
      );

      expect(find.byIcon(Icons.volume_up), findsOneWidget);

      controller.add(AudioState(volume: 0));
      await tester.pump();

      expect(find.byIcon(Icons.volume_off), findsOneWidget);

      controller.add(AudioState());
      await tester.pump();

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });

    testWidgets('calls correct method based on state', (tester) async {
      final controller = StreamController<AudioState>();
      when(audioCubit.toggleVolume).thenAnswer((_) async {});
      whenListen(audioCubit, controller.stream, initialState: AudioState());

      final game = TestBlackEchoGame(
        gameBloc: gameBloc,
        checkpointBloc: checkpointBloc,
        loreBloc: loreBloc,
      );
      await tester.pumpApp(
        GameView(game: game),
        audioCubit: audioCubit,
        gameBloc: gameBloc,
        loreBloc: loreBloc,
        checkpointBloc: checkpointBloc,
      );

      await tester.tap(find.byIcon(Icons.volume_up));
      controller.add(AudioState(volume: 0));
      await tester.pump();
      verify(audioCubit.toggleVolume).called(1);

      await tester.tap(find.byIcon(Icons.volume_off));
      controller.add(AudioState());
      await tester.pump();
      verify(audioCubit.toggleVolume).called(1);
    });
  });
}
