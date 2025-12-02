import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:echo_world/multiplayer/games/echo_duel/echo_duel_game.dart';

class GameTimerComponent extends PositionComponent
    with HasGameReference<EchoDuelGame> {
  GameTimerComponent() : super(anchor: Anchor.topCenter);

  final TextPaint _textPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(blurRadius: 4, color: Colors.black, offset: Offset(2, 2)),
      ],
    ),
  );

  double _timeLeft = 180.0; // 3 minutes default
  bool _isGameOver = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    position = Vector2(game.size.x / 2, 20);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(size.x / 2, 20);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isGameOver) return;

    _timeLeft -= dt;
    if (_timeLeft <= 0) {
      _timeLeft = 0;
      _isGameOver = true;
      game.onMatchEnded();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final minutes = (_timeLeft / 60).floor();
    final seconds = (_timeLeft % 60).floor();
    final text = "$minutes:${seconds.toString().padLeft(2, '0')}";
    _textPaint.render(canvas, text, Vector2.zero(), anchor: Anchor.topCenter);
  }
}
