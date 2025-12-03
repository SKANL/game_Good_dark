import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:echo_world/minigames/escape/entities/game_constants.dart';
import 'package:echo_world/minigames/escape/game/game_engine.dart';
import 'package:echo_world/minigames/escape/widgets/game_painter.dart';
import 'package:echo_world/minigames/escape/widgets/game_controls.dart';
import 'package:echo_world/utils/unawaited.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameEngine _gameEngine;
  late Ticker _ticker;

  // Shake animation
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _gameEngine = GameEngine(
      onLevelComplete: _handleLevelComplete,
      onPlayerDeath: _handlePlayerDeath,
      onGameComplete: _handleGameComplete,
      onShowMessage: _handleShowMessage,
    );
    _ticker = createTicker(_onTick);
    _ticker.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        _showLevelMessage(_gameEngine.currentLevel.startMessage, Colors.cyan),
      );
    });
  }

  Duration? _lastElapsed;

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    // Calculate delta time in seconds
    double dt = 0.016; // Default to ~60fps
    if (_lastElapsed != null) {
      dt = (elapsed - _lastElapsed!).inMicroseconds / 1000000.0;
    }
    _lastElapsed = elapsed;

    // Clamp dt to avoid huge jumps on lag
    dt = dt.clamp(0.0, 0.1);

    setState(() {
      _gameEngine.update(dt);
    });
  }

  void _handleLevelComplete() {
    if (_gameEngine.currentLevelIndex < 9) {
      _showLevelMessage(
        'Level Complete!',
        Colors.green,
        onDismiss: () async {
          setState(() {
            _gameEngine.nextLevel();
          });
          await _showLevelMessage(_gameEngine.currentLevel.startMessage, Colors.cyan);
        },
      );
    }
  }

  void _triggerShake() {
    _shakeController.forward(from: 0).then((_) => _shakeController.reverse());
  }

  void _handlePlayerDeath(String message) {
    _triggerShake();
    _showLevelMessage(
      message,
      Colors.red,
      onDismiss: () async {
        setState(() {
          _gameEngine.resetLevel();
        });
      },
    );
  }

  void _handleGameComplete() {
    _showVictoryScreen();
  }

  void _handleShowMessage(String message, Color color) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showLevelMessage(message, color));
    });
  }

  Future<void> _showLevelMessage(
    String message,
    Color color, {
    Future<void> Function()? onDismiss,
  }) async {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    // Pausar el juego
    _ticker.stop();
    // Detener el movimiento del jugador
    _gameEngine.player.stopMoving();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
            margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 40),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha((0.9 * 255).round()),
              border: Border.all(color: color, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 24,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                  ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Reanudar el juego
                    _ticker.start();
                    if (onDismiss != null) {
                      await onDismiss();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 20 : 30,
                      vertical: isSmallScreen ? 10 : 15,
                    ),
                  ),
                  child: const Text('CONTINUAR'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVictoryScreen() {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    // Pausar el juego
    _ticker.stop();
    _gameEngine.player.stopMoving();

    final dialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 40),
            margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 40),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha((0.95 * 255).round()),
              border: Border.all(color: GameConstants.doorColor, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ESCAPE COMPLETO',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 36,
                    color: GameConstants.doorColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: isSmallScreen ? 2 : 4,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 20 : 30),
                Text(
                  'Sujeto 7 ha escapado del eco negro.\n\nLa oscuridad queda atrás.\n\nPor ahora.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 18,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 30 : 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameConstants.doorColor,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 30 : 40,
                      vertical: isSmallScreen ? 12 : 15,
                    ),
                  ),
                  child: Text(
                    'VOLVER AL MENÚ',
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    unawaited(dialogFuture);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: GameConstants.backgroundColor,
      body: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          final offset =
              sin(_shakeController.value * 3.14159 * 10) *
              _shakeAnimation.value;
          return Transform.translate(
            offset: Offset(offset, offset),
            child: child,
          );
        },
        child: Stack(
          children: [
            // Game Canvas
            CustomPaint(
              painter: GamePainter(gameEngine: _gameEngine),
              size: Size.infinite,
            ),
            // HUD
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NIVEL ${_gameEngine.currentLevelIndex + 1}',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontSize: isSmallScreen ? 16 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'SUJETO 7',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 16 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Controls
            GameControls(
              onMoveLeft: () => _gameEngine.player.moveLeft(),
              onMoveRight: () => _gameEngine.player.moveRight(),
              onJump: () => _gameEngine.player.jump(),
              onStopMoving: () => _gameEngine.player.stopMoving(),
            ),
          ],
        ),
      ),
    );
  }
}
