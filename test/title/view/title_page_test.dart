import 'package:echo_world/title/title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../helpers/helpers.dart';

class MockVideoPlayerPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements VideoPlayerPlatform {
  @override
  Future<void> init() async {}

  @override
  Future<int> create(DataSource dataSource) async => 0;

  @override
  Future<void> setLooping(int textureId, bool looping) async {}

  @override
  Future<void> play(int textureId) async {}

  @override
  Future<void> setVolume(int textureId, double volume) async {}

  @override
  Future<void> dispose(int textureId) async {}

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return Stream.value(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 1),
        size: const Size(1920, 1080),
      ),
    );
  }
}

void main() {
  setUp(() {
    VideoPlayerPlatform.instance = MockVideoPlayerPlatform();
  });

  group('TitlePage', () {
    testWidgets('renders MenuPrincipal', (tester) async {
      await tester.pumpApp(const TitlePage());
      expect(find.byType(MenuPrincipal), findsOneWidget);
    });
  });

  group('MenuPrincipal', () {
    testWidgets('renders 5 BotonSprite widgets', (tester) async {
      await tester.pumpApp(const TitlePage());
      // Advance time to allow video init and animation to complete
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(BotonSprite), findsNWidgets(5));
    });

    testWidgets('starts the game when start button is tapped', (tester) async {
      final navigator = MockNavigator();
      when(navigator.canPop).thenReturn(true);
      when(
        () => navigator.pushReplacement<void, void>(any()),
      ).thenAnswer((_) async {});

      await tester.pumpApp(const TitlePage(), navigator: navigator);
      await tester.pump(const Duration(seconds: 2));

      // Tap the first button (Start)
      await tester.tap(find.byType(BotonSprite).first);
      await tester.pump(); // Process navigation

      verify(() => navigator.pushReplacement<void, void>(any())).called(1);
    });
  });
}
