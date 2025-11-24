import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class RuptureVfxComponent extends PositionComponent {
  RuptureVfxComponent({required Vector2 origin}) : super(position: origin);

  double life = 0.5; // Initial life

  @override
  void update(double dt) {
    super.update(dt);
    life -= dt;
  }

  @override
  Future<void> onLoad() async {
    // Shockwave ring
    await add(
      ParticleSystemComponent(
        particle: ComputedParticle(
          lifespan: 0.5,
          renderer: (canvas, particle) {
            final radius = particle.progress * 128; // Expand to 4 tiles
            final opacity = 1 - particle.progress;
            final paint = Paint()
              ..color = const Color(0xFFFFFFFF).withOpacity(opacity)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4 * (1 - particle.progress);
            canvas.drawCircle(Offset.zero, radius, paint);
          },
        ),
      ),
    );

    // Debris particles
    await add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 60,
          lifespan: 0.6,
          generator: (i) {
            final random = Random();
            final angle = random.nextDouble() * 2 * pi;
            final speed = 200.0 + random.nextDouble() * 300.0;
            final dir = Vector2(cos(angle), sin(angle));
            return AcceleratedParticle(
              acceleration: -dir * 100, // Drag
              speed: dir * speed,
              child: CircleParticle(
                radius: 2.0 * random.nextDouble(),
                paint: Paint()..color = const Color(0xFF00FFFF), // Cyan debris
              ),
            );
          },
        ),
      ),
    );

    // Auto-remove after animation
    add(
      TimerComponent(
        period: 0.6,
        removeOnFinish: true,
        onTick: () => removeFromParent(),
      ),
    );
  }
}
