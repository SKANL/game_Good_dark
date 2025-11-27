import 'game_constants.dart';

class Tile {
  Tile({
    required this.x,
    required this.y,
    required this.type,
    this.width = GameConstants.tileSize,
    this.height = GameConstants.tileSize,
  });
  final double x;
  final double y;
  final double width;
  final double height;
  final TileType type;

  bool isSolid() {
    return type == TileType.platform || type == TileType.invisiblePlatform;
  }

  bool isVisible() {
    return type != TileType.invisiblePlatform;
  }
}
