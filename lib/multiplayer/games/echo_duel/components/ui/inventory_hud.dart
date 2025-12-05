import 'dart:async';

import 'package:echo_world/multiplayer/games/echo_duel/models/inventory_item.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class InventoryHud extends PositionComponent {
  final List<InventoryItem> items;
  final Function(InventoryItem) onItemPressed;

  // State to toggle visibility
  bool _isExpanded = false;
  late final HudButtonComponent _toggleButton;
  final List<HudButtonComponent> _itemButtons = [];

  InventoryHud({
    required this.items,
    required this.onItemPressed,
  }) : super(anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Create Toggle Button (Backpack)
    _toggleButton = HudButtonComponent(
      button: CircleComponent(
        radius: 20,
        paint: Paint()..color = Colors.cyanAccent.withOpacity(0.8),
        children: [
          // Simple icon representation
          RectangleComponent(
            size: Vector2(20, 14),
            position: Vector2(10, 13),
            paint: Paint()..color = Colors.black,
          ),
        ],
      ),
      onPressed: _toggleInventory,
      size: Vector2(40, 40),
    );
    add(_toggleButton);

    _updateLayout();
  }

  void _toggleInventory() {
    _isExpanded = !_isExpanded;
    _updateLayout();
  }

  void updateItems(List<InventoryItem> newItems) {
    items.clear();
    items.addAll(newItems);
    _updateLayout();
  }

  void _updateLayout() {
    // Clear old buttons
    for (final btn in _itemButtons) {
      if (btn.parent != null) btn.removeFromParent();
    }
    _itemButtons.clear();

    if (!_isExpanded) {
      // Collapsed state: just toggle button
      _toggleButton.position = Vector2(0, 0); // Relative to component center
      size = Vector2(40, 40);
      return;
    }

    double xOffset = 50; // Start after toggle button
    const spacing = 10.0;
    const buttonWidth = 100.0;
    const buttonHeight = 40.0;

    for (final item in items) {
      if (item.quantity <= 0) continue;

      final button = HudButtonComponent(
        button: RectangleComponent(
          size: Vector2(buttonWidth, buttonHeight),
          paint: Paint()
            ..color = Colors.blueGrey.withOpacity(0.9)
            ..style = PaintingStyle.fill,
          children: [
            // Border
            RectangleComponent(
              size: Vector2(buttonWidth, buttonHeight),
              paint: Paint()
                ..color = Colors.cyan
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1,
            ),
            TextComponent(
              text: '${item.name}',
              textRenderer: TextPaint(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'Courier',
                ),
              ),
              anchor: Anchor.topCenter,
              position: Vector2(buttonWidth / 2, 5),
            ),
            TextComponent(
              text: 'x${item.quantity}',
              textRenderer: TextPaint(
                style: const TextStyle(
                  color: Colors.yellowAccent,
                  fontSize: 10,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
              anchor: Anchor.bottomCenter,
              position: Vector2(buttonWidth / 2, buttonHeight - 5),
            ),
          ],
        ),
        onPressed: () => onItemPressed(item),
        position: Vector2(
          xOffset,
          -buttonHeight / 2 + 20,
        ), // Center vertically relative to toggle
        size: Vector2(buttonWidth, buttonHeight),
      );

      add(button);
      _itemButtons.add(button);
      xOffset += buttonWidth + spacing;
    }

    // Adjust container size/pos
    // For HUD, we usually rely on children position, but let's set size loosely
    // _toggleButton is at 0,0
    _toggleButton.position = Vector2(0, 0);
  }
}
