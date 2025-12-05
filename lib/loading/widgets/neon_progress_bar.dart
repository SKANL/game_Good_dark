import 'package:flutter/material.dart';

/// {@template neon_progress_bar}
/// A custom progress bar with neon/holographic styling.
///
/// Features:
/// - Cyan neon border with glow effect
/// - Gradient fill (cyan to blue)
/// - Semi-transparent dark background
/// - Smooth animations
///
/// [progress] should be between 0 and 1.
/// {@endtemplate}
class NeonProgressBar extends StatelessWidget {
  /// {@macro neon_progress_bar}
  const NeonProgressBar({
    required this.progress,
    super.key,
  }) : assert(
         progress >= 0.0 && progress <= 1.0,
         'Progress should be set between 0.0 and 1.0',
       );

  /// The current progress for the bar (0.0 to 1.0).
  final double progress;

  /// The duration of the animation on [NeonProgressBar]
  static const Duration intrinsicAnimationDuration = Duration(
    milliseconds: 300,
  );

  // Neon cyan color
  static const Color neonCyan = Color(0xFF00FFFF);
  // Neon blue color
  static const Color neonBlue = Color(0xFF0080FF);
  // Dark background
  static const Color darkBackground = Color(0xFF0A0A0A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 24,
      decoration: BoxDecoration(
        color: darkBackground.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: neonCyan,
          width: 2,
        ),
        boxShadow: [
          // Outer glow effect
          BoxShadow(
            color: neonCyan.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: progress),
          duration: intrinsicAnimationDuration,
          builder: (BuildContext context, double progress, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [neonCyan, neonBlue],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      // Inner glow effect
                      BoxShadow(
                        color: neonCyan.withOpacity(0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
