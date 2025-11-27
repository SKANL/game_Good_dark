import 'package:flutter/material.dart';
import '../entities/game_constants.dart';
import '../game/game_engine.dart';
import '../entities/trap.dart';
import '../entities/tile.dart';
import 'dart:math' as math;
import '../entities/player.dart';

class GamePainter extends CustomPainter {
  final GameEngine gameEngine;

  GamePainter({required this.gameEngine});

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate scale to fit game in screen
    double scaleX =
        size.width / (GameConstants.gridWidth * GameConstants.tileSize);
    double scaleY =
        size.height / (GameConstants.gridHeight * GameConstants.tileSize);
    double scale = scaleX < scaleY ? scaleX : scaleY;

    canvas.save();
    canvas.scale(scale);

    // Draw tiles
    for (var tile in gameEngine.currentLevel.tiles) {
      _drawTile(canvas, tile);
    }

    // Draw traps
    for (var trap in gameEngine.currentLevel.traps) {
      _drawTrap(canvas, trap);
    }

    // Draw player
    _drawPlayer(canvas, gameEngine.player);

    canvas.restore();
  }

  void _drawTile(Canvas canvas, Tile tile) {
    if (!tile.isVisible()) return;

    Paint paint = Paint();

    switch (tile.type) {
      case TileType.platform:
        paint.color = GameConstants.platformColor;
        break;
      case TileType.fakePlatform:
        paint.color = GameConstants.fakePlatformColor;
        break;
      case TileType.invisiblePlatform:
        return; // Don't draw
    }

    canvas.drawRect(
      Rect.fromLTWH(tile.x, tile.y, tile.width, tile.height),
      paint,
    );

    // Draw grid lines for retro look
    Paint gridPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(tile.x, tile.y, tile.width, tile.height),
      gridPaint,
    );
  }

  void _drawTrap(Canvas canvas, Trap trap) {
    if (!trap.isActive &&
        trap.type != TrapType.door &&
        trap.type != TrapType.fakeDoor) {
      return;
    }

    Paint paint = Paint();

    switch (trap.type) {
      case TrapType.spike:
        paint.color = GameConstants.spikeColor;
        _drawSpike(canvas, trap, paint);
        break;
      case TrapType.proximitySpike:
        if (trap.isTriggered) {
          paint.color = GameConstants.spikeColor;
          _drawSpike(canvas, trap, paint);
        }
        break;
      case TrapType.door:
        // En nivel 7, la puerta real es MORADA, en otros niveles es CYAN
        paint.color = gameEngine.currentLevelIndex == 6
            ? GameConstants
                  .fakeDoorColor // Nivel 7 = Morada
            : GameConstants.doorColor; // Otros = Cyan
        canvas.drawRect(
          Rect.fromLTWH(trap.x, trap.y, trap.width, trap.height),
          paint,
        );
        // Draw door pattern
        Paint patternPaint = Paint()
          ..color = Colors.black26
          ..strokeWidth = 2;
        canvas.drawLine(
          Offset(trap.x + trap.width / 2, trap.y),
          Offset(trap.x + trap.width / 2, trap.y + trap.height),
          patternPaint,
        );
        break;
      case TrapType.fakeDoor:
        // En nivel 7, la puerta falsa es CYAN, en otros niveles es MORADA
        paint.color = gameEngine.currentLevelIndex == 6
            ? GameConstants
                  .doorColor // Nivel 7 = Cyan
            : GameConstants.fakeDoorColor; // Otros = Morada
        canvas.drawRect(
          Rect.fromLTWH(trap.x, trap.y, trap.width, trap.height),
          paint,
        );
        Paint patternPaint = Paint()
          ..color = Colors.black26
          ..strokeWidth = 2;
        canvas.drawLine(
          Offset(trap.x + trap.width / 2, trap.y),
          Offset(trap.x + trap.width / 2, trap.y + trap.height),
          patternPaint,
        );
        break;
      case TrapType.fallingCeiling:
        paint.color = GameConstants.ceilingColor;
        canvas.drawRect(
          Rect.fromLTWH(trap.x, trap.y, trap.width, trap.height),
          paint,
        );
        // Draw warning lines
        Paint warningPaint = Paint()
          ..color = Colors.red.withValues(alpha: 0.3)
          ..strokeWidth = 2;
        for (double i = 0; i < trap.width; i += 10) {
          canvas.drawLine(
            Offset(trap.x + i, trap.y + trap.height),
            Offset(trap.x + i + 5, trap.y + trap.height),
            warningPaint,
          );
        }
        break;
      case TrapType.collapsingPlatform:
        double opacity =
            1.0 - (trap.collapseTimer / GameConstants.collapseDelay);
        paint.color = GameConstants.platformColor.withValues(
          alpha: opacity.clamp(0.0, 1.0),
        );
        canvas.drawRect(
          Rect.fromLTWH(trap.x, trap.y, trap.width, trap.height),
          paint,
        );
        break;
      default:
        // Invisible traps don't render
        break;
    }
  }

  void _drawSpike(Canvas canvas, Trap trap, Paint paint) {
    Path path = Path();
    path.moveTo(trap.x, trap.y + trap.height);
    path.lineTo(trap.x + trap.width / 2, trap.y);
    path.lineTo(trap.x + trap.width, trap.y + trap.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawPlayer(Canvas canvas, EscapePlayer player) {
    Paint paint = Paint()..color = GameConstants.playerColor;

    // Draw player as a square with a small indicator
    canvas.drawRect(
      Rect.fromLTWH(player.x, player.y, player.width, player.height),
      paint,
    );

    // Draw eye indicator
    Paint eyePaint = Paint()..color = Colors.cyan;
    double eyeSize = 4;
    canvas.drawCircle(
      Offset(player.x + player.width / 2, player.y + player.height / 3),
      eyeSize,
      eyePaint,
    );

    // Draw border
    Paint borderPaint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(player.x, player.y, player.width, player.height),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}
