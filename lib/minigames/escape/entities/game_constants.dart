import 'package:flutter/material.dart';

class GameConstants {
  static const double tileSize = 24;
  static const double gravity = 0.5;
  static const double playerSpeed = 4;
  static const double jumpForce = 10;
  static const int gridWidth = 32;
  static const int gridHeight = 18;

  static const Color backgroundColor = Colors.black;
  static const Color platformColor = Color(0xFF404040);
  static const Color fakePlatformColor = Color(0x80404040);
  static const Color doorColor = Colors.cyan;
  static const Color fakeDoorColor = Colors.purple;
  static const Color spikeColor = Colors.red;
  static const Color playerColor = Colors.white;
  static const Color ceilingColor = Color(0xFF303030);

  static const double proximityDistance = 100;
  static const double ceilingFallSpeed = 5;
  static const double collapseDelay = 0.5;
}

enum TileType {
  platform,
  fakePlatform,
  invisiblePlatform,
}

enum TrapType {
  spike,
  proximitySpike,
  door,
  fakeDoor,
  fallingCeiling,
  collapsingPlatform,
  invertControls,
  invertGravity,
  speedChange,
}
