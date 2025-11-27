import 'package:echo_world/minigames/fuga/entities/colors.dart';
import 'package:echo_world/minigames/fuga/game/fuga_game.dart';
import 'package:flutter/material.dart';

/// Mobile HUD overlay with a simple virtual joystick on the left and action
/// buttons on the right. The joystick sends normalized direction vectors to
/// the player via the `FugaGame.setPlayerDirection(dx, dy)` helper.
class Hud extends StatefulWidget {
  const Hud({required this.gameRef, super.key});

  final FugaGame gameRef;

  @override
  State<Hud> createState() => _HudState();
}

class _HudState extends State<Hud> {
  Offset? _joyCenter; // center point of joystick base in local coords
  Offset _knobOffset = Offset.zero; // current knob offset from center

  @override
  void initState() {
    super.initState();
    // Forzar actualización periódica para mostrar cambios en cargas
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {});
        return true;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final shortSide = isLandscape ? size.height : size.width;

    // Dynamic sizing
    final baseRadius = (shortSide * 0.15).clamp(40.0, 100.0);
    final buttonSize = (shortSide * 0.15).clamp(50.0, 90.0);
    final padding = (shortSide * 0.05).clamp(16.0, 32.0);

    return SafeArea(
      child: Stack(
        children: [
          // Left joystick area
          Positioned(
            left: padding,
            bottom: padding,
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  // center is fixed inside the control box
                  _joyCenter = Offset(baseRadius + 8, baseRadius + 8);
                  _knobOffset = Offset.zero;
                });
                widget.gameRef.setPlayerDirection(0, 0);
              },
              onPanUpdate: (details) {
                if (_joyCenter == null) return;
                final local = details.localPosition;
                final offset = local - _joyCenter!;
                final distance = offset.distance;
                final capped = distance > baseRadius
                    ? offset / (distance / baseRadius)
                    : offset;
                setState(() {
                  _knobOffset = capped;
                });
                // Normalized direction
                final ndx = capped.dx / baseRadius;
                final ndy = capped.dy / baseRadius;
                widget.gameRef.setPlayerDirection(ndx, ndy);
              },
              onPanEnd: (_) {
                setState(() {
                  _joyCenter = null;
                  _knobOffset = Offset.zero;
                });
                widget.gameRef.setPlayerDirection(0, 0);
              },
              child: SizedBox(
                width: baseRadius * 2 + 16,
                height: baseRadius * 2 + 16,
                child: CustomPaint(
                  painter: _JoystickPainter(
                    baseRadius: baseRadius,
                    knobOffset: _knobOffset,
                  ),
                ),
              ),
            ),
          ),

          // Right action buttons
          Positioned(
            right: padding,
            bottom: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Charge counter display
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GameColors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Builder(
                    builder: (context) {
                      final charges = widget.gameRef.player.charges;
                      return Text(
                        'Cargas: $charges/3',
                        style: const TextStyle(
                          color: GameColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.gameRef.player.ping();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.white,
                    foregroundColor: GameColors.black,
                    fixedSize: Size(buttonSize, buttonSize),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.wifi),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Grito de Ruptura: call game helper
                    widget.gameRef.triggerRupture();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.red,
                    foregroundColor: GameColors.white,
                    fixedSize: Size(buttonSize, buttonSize),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.music_note),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  _JoystickPainter({required this.baseRadius, required this.knobOffset});

  final double baseRadius;
  final Offset knobOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final basePaint = Paint()..color = Colors.white.withValues(alpha: 0.08);
    final knobPaint = Paint()..color = Colors.white.withValues(alpha: 0.16);

    canvas.drawCircle(center, baseRadius, basePaint);
    canvas.drawCircle(center + knobOffset, baseRadius / 2, knobPaint);
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) {
    return oldDelegate.knobOffset != knobOffset ||
        oldDelegate.baseRadius != baseRadius;
  }
}
