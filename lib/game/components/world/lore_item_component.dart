import 'dart:math';
import 'dart:ui' as ui;

import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/entities/player/player.dart';
import 'package:echo_world/lore/cubit/lore_bloc.dart';
import 'package:echo_world/lore/data/lore_data.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LoreItemComponent extends PositionComponent
    with CollisionCallbacks, HasGameRef<BlackEchoGame> {
  LoreItemComponent({
    required Vector2 position,
    required this.loreId,
  }) : super(
         position: position,
         size: Vector2.all(48), // Increased from 24
         anchor: Anchor.center,
       );

  final String loreId;
  double _time = 0;
  double _pulseTime = 0;

  @override
  Future<void> onLoad() async {
    print('[LORE] Loading LoreItem $loreId at $position');
    await add(CircleHitbox());

    // Check if already unlocked
    final loreState = gameRef.loreBloc.state;
    if (loreState.ecosDesbloqueados.contains(loreId)) {
      print('[LORE] $loreId already unlocked, removing');
      removeFromParent();
    } else {
      print('[LORE] $loreId is NEW, will be visible');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _pulseTime += dt * 2;

    // More pronounced floating
    position.y += sin(_time * 3) * dt * 10;
  }

  @override
  void render(ui.Canvas canvas) {
    final pulse = (sin(_pulseTime) + 1) / 2; // 0 to 1

    // Outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00FFFF)
          .withAlpha(((0.3 + pulse * 0.3) * 255).round())
      ..maskFilter = const MaskFilter.blur(ui.BlurStyle.normal, 15);

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x * 0.7,
      glowPaint,
    );

    // Main diamond
    final paint = Paint()
      ..color = Color.lerp(
        const Color(0xFF00FFFF),
        const Color(0xFFFFFFFF),
        pulse,
      )!.withAlpha((0.9 * 255).round())
      ..style = PaintingStyle.fill;

    final path = ui.Path();
    final w = size.x;
    final h = size.y;

    path.moveTo(w / 2, h * 0.2);
    path.lineTo(w * 0.8, h / 2);
    path.lineTo(w / 2, h * 0.8);
    path.lineTo(w * 0.2, h / 2);
    path.close();

    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(_time);
    canvas.translate(-w / 2, -h / 2);

    canvas.drawPath(path, paint);

    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w * 0.15,
      Paint()..color = Colors.white,
    );

    canvas.restore();

    // "?" icon
    final textPainter = TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          color: Color.lerp(Colors.cyan, Colors.white, pulse),
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (w - textPainter.width) / 2,
        (h - textPainter.height) / 2,
      ),
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      _collect();
    }
  }

  void _collect() {
    gameRef.loreBloc.add(DesbloquearEco(loreId));

    try {
      final entry = LoreData.getById(loreId);
      print('Lore Unlocked: ${entry.title}');
    } catch (e) {
      print('Error unlocking lore: $e');
    }

    removeFromParent();
  }
}
