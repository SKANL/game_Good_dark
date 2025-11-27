import 'package:flutter/material.dart';

class GameControls extends StatelessWidget {
  const GameControls({
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onJump,
    required this.onStopMoving,
    super.key,
  });
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final VoidCallback onJump;
  final VoidCallback onStopMoving;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final buttonSize = isSmallScreen ? 60.0 : 70.0;
    final jumpButtonSize = isSmallScreen ? 70.0 : 80.0;
    final spacing = isSmallScreen ? 8.0 : 10.0;
    final padding = isSmallScreen ? 16.0 : 20.0;

    return SafeArea(
      child: Stack(
        children: [
          // Left and Right buttons (bottom left)
          Positioned(
            left: padding,
            bottom: padding,
            child: Row(
              children: [
                _buildControlButton(
                  icon: Icons.arrow_back,
                  onPressed: onMoveLeft,
                  onReleased: onStopMoving,
                  size: buttonSize,
                ),
                SizedBox(width: spacing),
                _buildControlButton(
                  icon: Icons.arrow_forward,
                  onPressed: onMoveRight,
                  onReleased: onStopMoving,
                  size: buttonSize,
                ),
              ],
            ),
          ),
          // Jump button (bottom right)
          Positioned(
            right: padding,
            bottom: padding,
            child: _buildJumpButton(
              icon: Icons.arrow_upward,
              onPressed: onJump,
              size: jumpButtonSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required VoidCallback onReleased,
    double size = 70,
  }) {
    return Listener(
      onPointerDown: (_) => onPressed(),
      onPointerUp: (_) => onReleased(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          border: Border.all(color: Colors.cyan, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.cyan,
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildJumpButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 70,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(color: Colors.cyan, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.cyan,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}
