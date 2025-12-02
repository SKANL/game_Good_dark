import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:echo_world/multiplayer/games/echo_duel/echo_duel_game.dart';
import 'package:echo_world/multiplayer/games/echo_duel/components/multiplayer_player.dart';

class ScoreboardComponent extends PositionComponent
    with HasGameReference<EchoDuelGame> {
  ScoreboardComponent()
    : super(position: Vector2(20, 20), anchor: Anchor.topLeft);

  final TextPaint _textPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontFamily: 'Poppins', // Assuming Poppins is available
      shadows: [
        Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
      ],
    ),
  );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Sort players by kills (descending)
    // Note: We need to track kills in MultiplayerPlayer or Game
    // For now, let's assume we can access a list of players

    final players = game.world.children.whereType<MultiplayerPlayer>().toList();
    // Sort logic here if we had kills

    double yOffset = 0;
    for (final player in players) {
      final text =
          "${player.id.substring(0, math.min(5, player.id.length))}: ${player.health.toInt()} HP";
      _textPaint.render(canvas, text, Vector2(0, yOffset));
      yOffset += 20;
    }
  }
}
