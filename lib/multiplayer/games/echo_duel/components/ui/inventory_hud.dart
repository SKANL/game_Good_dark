import 'dart:async';

import 'package:echo_world/multiplayer/games/echo_duel/models/inventory_item.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class InventoryHud extends PositionComponent {
  final List<InventoryItem> items;
  final Function(InventoryItem) onItemPressed;

  InventoryHud({
    required this.items,
    required this.onItemPressed,
  }) : super(anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _updateLayout();
  }

  void updateItems(List<InventoryItem> newItems) {
    items.clear();
    items.addAll(newItems);
    _updateLayout();
  }

  void _updateLayout() {
    removeAll(children);

    double xOffset = 0;
    const spacing = 10.0;
    const buttonWidth = 100.0;
    const buttonHeight = 40.0;

    for (final item in items) {
      if (item.quantity <= 0) continue;

      final button = HudButtonComponent(
        button: RectangleComponent(
          size: Vector2(buttonWidth, buttonHeight),
          paint: Paint()..color = Colors.blueGrey.withOpacity(0.8),
          children: [
            TextComponent(
              text: '${item.name} (${item.quantity})',
              textRenderer: TextPaint(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              anchor: Anchor.center,
              position: Vector2(buttonWidth / 2, buttonHeight / 2),
            ),
          ],
        ),
        onPressed: () => onItemPressed(item),
        position: Vector2(xOffset, 0),
        size: Vector2(buttonWidth, buttonHeight),
      );

      add(button);
      xOffset += buttonWidth + spacing;
    }

    // Center the HUD
    final totalWidth = xOffset - spacing;
    size = Vector2(totalWidth, buttonHeight);
    // Position will be set by parent, usually bottom center
  }
}
