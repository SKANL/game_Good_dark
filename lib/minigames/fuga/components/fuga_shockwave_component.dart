import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../entities/colors.dart';

/// Shockwave visual effect for the Grito de Ruptura.
/// Uses a fragment shader for a high-quality pulse effect.
class FugaShockwaveComponent extends PositionComponent {
  FugaShockwaveComponent({
    required Vector2 origin,
    this.maxRadius = 300,
    this.growthSpeed = 1500,
  }) {
    position = origin.clone();
    anchor = Anchor.center;
    size = Vector2.all(maxRadius * 2.2); // Slightly larger to avoid clipping
  }

  final double maxRadius;
  final double growthSpeed;
  double currentRadius = 0;

  ui.FragmentProgram? _program;
  double _time = 0;

  @override
  Future<void> onLoad() async {
    try {
      _program = await ui.FragmentProgram.fromAsset('lib/shaders/pulse.frag');
    } catch (e) {
      debugPrint('Error loading pulse shader: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    currentRadius += growthSpeed * dt;

    if (currentRadius >= maxRadius) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_program == null) {
      // Fallback rendering
      final paint = Paint()
        ..color = GameColors.white.withValues(
          alpha: 1.0 - (currentRadius / maxRadius),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), currentRadius, paint);
      return;
    }

    final shader = _program!.fragmentShader();

    // Uniforms:
    // float uTime
    // vec2 uResolution
    // vec2 uCenter
    // float uRadius
    // float uThickness
    // vec4 uColor
    // sampler2D uTexture (unused here)

    shader.setFloat(0, _time); // uTime
    shader.setFloat(1, size.x); // uResolution.x
    shader.setFloat(2, size.y); // uResolution.y
    shader.setFloat(3, 0.5); // uCenter.x (normalized)
    shader.setFloat(4, 0.5); // uCenter.y (normalized)
    shader.setFloat(5, currentRadius / size.x); // uRadius (normalized)
    shader.setFloat(6, 0.05); // uThickness (normalized approx)

    // Color (White with fade)
    final opacity = (1.0 - (currentRadius / maxRadius)).clamp(0.0, 1.0);
    shader.setFloat(7, 1.0); // R
    shader.setFloat(8, 1.0); // G
    shader.setFloat(9, 1.0); // B
    shader.setFloat(10, opacity); // A

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size.toSize(), paint);
  }
}
