import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

/// Centralized palette for the game.
class GameColors {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color red = Color(0xFFFF0000);
  static const Color cyan = Color(0xFF00FFFF);
}

// Also provide paints used by Flame components
final Paint whitePaint = BasicPalette.white.paint();
final Paint redPaint = Paint()..color = GameColors.red;
final Paint cyanPaint = Paint()..color = GameColors.cyan;
