import 'dart:ui';
import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/components/lighting/lighting_system.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:flame/components.dart';

/// Renders a darkness overlay and "carves" out holes for lights.
/// Used for TopDown and SideScroll perspectives.
class LightingLayerComponent extends Component with HasGameRef<BlackEchoGame> {
  LightingLayerComponent({required this.lightingSystem});

  final LightingSystem lightingSystem;

  // Darkness color (Ambient light)
  Color ambientColor = const Color(0xFF000000); // Pitch black by default

  @override
  int get priority => 100; // Render above world, below HUD

  @override
  void render(Canvas canvas) {
    // Only render in 2D modes
    final enfoque = gameRef.gameBloc.state.enfoqueActual;
    if (enfoque == Enfoque.firstPerson) return;

    final camera = gameRef.camera;
    // viewport variable removed as it was unused

    // 1. Create a layer for the lighting
    canvas.saveLayer(null, Paint());

    // 2. Draw the darkness (Ambient)
    // We draw a rectangle covering the entire viewport
    final visibleRect = camera.visibleWorldRect;

    // Add some padding to avoid culling issues at edges
    final drawRect = visibleRect.inflate(100);

    canvas.drawRect(drawRect, Paint()..color = ambientColor);

    // 3. Draw lights using BlendMode.dstOut (to remove darkness) or srcOver (additive)
    // "Carving" light out of darkness:
    // We want lights to reveal the world.
    // Approach: Draw lights onto the black layer using BlendMode.dstOut?
    // Or Draw lights with BlendMode.plus (additive) if we want colored lights?

    // Better approach for colored lights:
    // 1. Fill screen with black.
    // 2. Draw lights with BlendMode.srcIn or similar? No.
    // Standard 2D lighting:
    // Draw darkness.
    // Draw lights with BlendMode.dstOut (alpha punches hole).
    // This reveals the game world below.
    // BUT this doesn't support colored lights easily (just reveals).

    // Hybrid approach:
    // 1. Draw darkness.
    // 2. For each light, draw a gradient circle with BlendMode.dstOut (to reveal).
    // 3. Then draw the light's COLOR with BlendMode.screen or plus (to tint).

    final lights = lightingSystem.getNearestLights(
      camera.viewfinder.position,
      limit: 20,
    );

    for (final light in lights) {
      final pos = light.position;
      final radius = light.radius;
      final intensity = light.effectiveIntensity;

      // Skip if off-screen
      if (!drawRect.contains(pos.toOffset())) {
        // Simple check, could be better (circle intersection)
        if ((drawRect.center - pos.toOffset()).distance >
            radius + drawRect.width) {
          continue;
        }
      }

      // 1. Reveal the world (Punch hole in darkness)
      final revealPaint = Paint()
        ..shader = Gradient.radial(
          pos.toOffset(),
          radius,
          [
            const Color(0xFFFFFFFF), // Center (opaque white = full removal)
            const Color(0x00FFFFFF), // Edge (transparent = no removal)
          ],
          [0.0, 1.0],
        )
        ..blendMode = BlendMode.dstOut; // Remove destination (darkness)

      // Modulate opacity by intensity
      revealPaint.color = const Color(
        0xFFFFFFFF,
      ).withOpacity(intensity.clamp(0.0, 1.0));

      canvas.drawCircle(pos.toOffset(), radius, revealPaint);

      // 2. Add Light Color (Tint)
      if (light.color != const Color(0xFFFFFFFF)) {
        final colorPaint = Paint()
          ..shader = Gradient.radial(
            pos.toOffset(),
            radius,
            [
              light.color.withOpacity(0.6 * intensity),
              light.color.withOpacity(0),
            ],
            [0.0, 1.0],
          )
          ..blendMode = BlendMode.screen; // Additive-ish blending

        canvas.drawCircle(pos.toOffset(), radius, colorPaint);
      }
    }

    canvas.restore();
  }
}
