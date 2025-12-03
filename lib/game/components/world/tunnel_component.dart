import 'dart:math';

import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TunnelComponent extends PositionComponent with HasGameRef<BlackEchoGame> {
  TunnelComponent({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size, anchor: Anchor.topLeft);

  double _pulseTime = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTime += dt * 2;
  }

  @override
  void render(Canvas canvas) {
    // Don't render in First-Person mode
    if (gameRef.gameBloc.state.enfoqueActual == Enfoque.firstPerson) return;

    final pulse = (sin(_pulseTime) + 1) / 2; // 0 to 1

    // Floor (darker)
    final floorPaint = Paint()..color = const Color(0xFF0A0A0A);
    canvas.drawRect(size.toRect(), floorPaint);

    // Striped floor pattern (to show it's passable)
    final stripePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < size.x; i += 8) {
      canvas.drawRect(
        Rect.fromLTWH(i.toDouble(), 0, 4, size.y),
        stripePaint,
      );
    }

    // ROOF/CEILING bar (top 25% of tile) - makes it clear it's a LOW passage
    final roofHeight = size.y * 0.3;
    final roofPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, roofHeight),
      roofPaint,
    );

    // Roof detail lines
    final roofDetailPaint = Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, roofHeight / 2),
      Offset(size.x, roofHeight / 2),
      roofDetailPaint,
    );

    // Cyan glow on SIDES (to indicate passage direction)
    final glowPaint = Paint()
      ..color = const Color(0xFF00FFFF).withAlpha(((0.4 + pulse * 0.3) * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Left and right edges
    canvas.drawLine(Offset(0, roofHeight), Offset(0, size.y), glowPaint);
    canvas.drawLine(
      Offset(size.x, roofHeight),
      Offset(size.x, size.y),
      glowPaint,
    );

    // Bottom glow line
    final bottomGlowPaint = Paint()
      ..color = const Color(0xFF00FFFF).withAlpha((0.6 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.y - 1),
      Offset(size.x, size.y - 1),
      bottomGlowPaint,
    );

    // "CROUCH" text indicator (small)
    final textPainter = TextPainter(
      text: TextSpan(
        text: '↓',
        style: TextStyle(
          color: Color.lerp(Colors.cyan, Colors.white, pulse),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        size.y - roofHeight - 4,
      ),
    );
  }
}
