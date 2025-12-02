import 'package:echo_world/game/components/core/batch_geometry_renderer.dart';
import 'package:echo_world/game/components/world/abyss_component.dart';
import 'package:echo_world/game/components/world/wall_component.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:echo_world/game/level/manager/level_generator.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class MultiplayerLevelManager extends Component with HasGameRef {
  static const double tileSize = 32;
  final LevelGenerator _generator = LevelGenerator();
  late final BatchGeometryRenderer _wallBatchRenderer;
  final List<Component> _levelComponents = [];

  @override
  Future<void> onLoad() async {
    _wallBatchRenderer = BatchGeometryRenderer();
    await parent?.add(_wallBatchRenderer);

    // Generate a simple arena for now (Level 0 logic or custom)
    // We can use a fixed seed for all players to ensure same map
    // For Phase 2 MVP, we'll generate a small containment sector
    await _generateArena();
  }

  Future<void> _generateArena() async {
    // Use a fixed seed based on matchId if possible, or just a standard layout
    // For now, let's generate a standard level 0
    final chunk = await _generator.generateLevel(0, Sector.contencion);

    await _loadChunk(chunk);
  }

  Future<void> _loadChunk(LevelData chunk) async {
    _wallBatchRenderer.clearGeometries();

    for (var y = 0; y < chunk.alto; y++) {
      for (var x = 0; x < chunk.ancho; x++) {
        final celda = chunk.grid[y][x];
        final pos = Vector2(x * tileSize, y * tileSize);

        if (celda.tipo == TipoCelda.pared) {
          _wallBatchRenderer.addGeometry(
            position: pos,
            size: Vector2(tileSize, tileSize),
            color: const Color(0xFF222222),
            destructible: celda.esDestructible,
          );

          final wall = WallComponent(
            position: pos,
            size: Vector2(tileSize, tileSize),
            destructible: celda.esDestructible,
          );
          await parent?.add(wall);
          _levelComponents.add(wall);
        } else if (celda.tipo == TipoCelda.abismo) {
          final abyss = AbyssComponent(
            position: pos,
            size: Vector2(tileSize, tileSize),
          );
          await parent?.add(abyss);
          _levelComponents.add(abyss);
        }
      }
    }
    _wallBatchRenderer.markDirty();
  }

  @override
  void onRemove() {
    for (final c in _levelComponents) {
      c.removeFromParent();
    }
    _wallBatchRenderer.removeFromParent();
    super.onRemove();
  }
}
