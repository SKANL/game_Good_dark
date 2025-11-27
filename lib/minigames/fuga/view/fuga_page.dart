import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:echo_world/common/widgets/glitch_overlay.dart';
import '../game/fuga_game.dart';

class FugaMinigame extends StatelessWidget {
  const FugaMinigame({super.key});

  @override
  Widget build(BuildContext context) {
    return GlitchOverlay(
      intensity:
          0.0, // Initial intensity, controlled by game logic if we expose a controller
      // For now, we might need a way to update this from the game.
      // A simple way is to use a ValueNotifier or Bloc.
      // Let's wrap it in a ValueListenableBuilder if we want dynamic updates.
      child: GameWidget(
        game: FugaGame(),
        overlayBuilderMap: {
          'Hud': (BuildContext context, FugaGame game) {
            return game.buildHud(context);
          },
        },
        initialActiveOverlays: const ['Hud'],
      ),
    );
  }
}
