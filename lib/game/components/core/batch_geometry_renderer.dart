import 'dart:ui';

import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

/// Sistema de batch rendering para optimizar el dibujado de geometría estática.
///
/// En lugar de renderizar cada pared individualmente (muchos draw calls),
/// este componente agrupa toda la geometría estática en un solo Canvas
/// y lo renderiza de una vez (1 draw call).
///
/// Esto mejora dramáticamente el rendimiento en dispositivos móviles.
class BatchGeometryRenderer extends Component with HasGameRef<FlameGame> {
  BatchGeometryRenderer();

  /// Canvas pre-renderizado con toda la geometría estática
  Picture? _geometryPicture;

  /// Indica si la geometría ha cambiado y necesita re-renderizarse
  bool _needsRebuild = true;

  /// Lista de geometrías para renderizar (posición, tamaño, color)
  final List<_GeometryData> _geometries = [];

  /// Marca que la geometría necesita ser reconstruida
  void markDirty() {
    _needsRebuild = true;
  }

  /// Añade una geometría al batch (pared, plataforma, etc.)
  /// NOTA: No marca el batch como sucio automáticamente. Debe llamarse a [markDirty] manualmente.
  void addGeometry({
    required Vector2 position,
    required Vector2 size,
    required Color color,
    bool destructible = false,
  }) {
    _geometries.add(
      _GeometryData(
        position: position,
        size: size,
        color: color,
        destructible: destructible,
      ),
    );
    // _needsRebuild = true; // REMOVED: Manual control requested
  }

  /// Añade múltiples rectángulos al batch con un offset compartido.
  /// Útil para cargar chunks enteros de una vez.
  /// NOTA: No marca el batch como sucio automáticamente. Debe llamarse a [markDirty] manualmente.
  void addRects({
    required List<Rect> rects,
    required Vector2 offset,
    required Color color,
    bool destructible = false,
  }) {
    for (final rect in rects) {
      _geometries.add(
        _GeometryData(
          position: Vector2(rect.left + offset.x, rect.top + offset.y),
          size: Vector2(rect.width, rect.height),
          color: color,
          destructible: destructible,
        ),
      );
    }
    // _needsRebuild = true; // REMOVED: Manual control requested
  }

  /// Remueve una geometría del batch (cuando una pared es destruida)
  void removeGeometry(Vector2 position) {
    _geometries.removeWhere((geo) => geo.position == position);
    _needsRebuild = true;
  }

  /// Limpia todas las geometrías
  void clearGeometries() {
    _geometries.clear();
    _needsRebuild = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Reconstruir el batch si es necesario
    if (_needsRebuild) {
      _rebuildBatch();
      _needsRebuild = false;
    }
  }

  void _rebuildBatch() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    // Dibujar todas las geometrías en un solo canvas
    for (final geo in _geometries) {
      final paint = Paint()
        ..color = geo.color
        ..style = PaintingStyle.fill;

      // Dibujar rectángulo
      canvas.drawRect(
        Rect.fromLTWH(
          geo.position.x,
          geo.position.y,
          geo.size.x,
          geo.size.y,
        ),
        paint,
      );

      // Si es destructible, dibujar un borde punteado
      if (geo.destructible) {
        final borderPaint = Paint()
          ..color = geo.color.withAlpha((0.5 * 255).round())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawRect(
          Rect.fromLTWH(
            geo.position.x,
            geo.position.y,
            geo.size.x,
            geo.size.y,
          ),
          borderPaint,
        );
      }
    }

    // Finalizar el Picture
    _geometryPicture = recorder.endRecording();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // NO renderizar geometría 2D en first-person: el raycaster proyecta las paredes en 3D
    // Check if we are in BlackEchoGame to access gameBloc
    if (game is BlackEchoGame) {
      if ((game as BlackEchoGame).gameBloc.state.enfoqueActual ==
          Enfoque.firstPerson) {
        return;
      }
    }

    // Renderizar el batch completo en un solo draw call (solo en top-down/side-scroll)
    if (_geometryPicture != null) {
      canvas.drawPicture(_geometryPicture!);
    }
  }

  /// Obtiene estadísticas del batch (para debugging)
  BatchStats get stats => BatchStats(
    geometryCount: _geometries.length,
    needsRebuild: _needsRebuild,
  );
}

/// Datos de una geometría individual
class _GeometryData {
  const _GeometryData({
    required this.position,
    required this.size,
    required this.color,
    this.destructible = false,
  });

  final Vector2 position;
  final Vector2 size;
  final Color color;
  final bool destructible;
}

/// Estadísticas del batch renderer
class BatchStats {
  const BatchStats({
    required this.geometryCount,
    required this.needsRebuild,
  });

  final int geometryCount;
  final bool needsRebuild;

  @override
  String toString() =>
      'BatchStats(geometries: $geometryCount, '
      'needsRebuild: $needsRebuild)';
}
