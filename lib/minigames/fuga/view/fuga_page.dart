import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/fuga_game.dart';

class FugaMinigame extends StatelessWidget {
  const FugaMinigame({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWidget(
      game: FugaGame(),
      overlayBuilderMap: {
        'Hud': (BuildContext context, FugaGame game) {
          return game.buildHud(context);
        },
      },
      initialActiveOverlays: const ['Hud'],
    );
  }
}
