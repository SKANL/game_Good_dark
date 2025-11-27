import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../entities/game_constants.dart';
import '../game/game_engine.dart';
import '../widgets/game_painter.dart';
import '../widgets/game_controls.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late GameEngine _gameEngine;
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _gameEngine = GameEngine(
      onLevelComplete: _handleLevelComplete,
      onPlayerDeath: _handlePlayerDeath,
      onGameComplete: _handleGameComplete,
      onShowMessage: _handleShowMessage,
    );
    _ticker = createTicker(_onTick);
    _ticker.start();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLevelMessage(_gameEngine.currentLevel.startMessage, Colors.cyan);
    });
  }

  void _onTick(Duration elapsed) {
    setState(() {
      _gameEngine.update();
    });
  }

  void _handleLevelComplete() {
    if (_gameEngine.currentLevelIndex < 9) {
      _showLevelMessage(
        'Level Complete!',
        Colors.green,
        onDismiss: () {
          setState(() {
            _gameEngine.nextLevel();
          });
          _showLevelMessage(_gameEngine.currentLevel.startMessage, Colors.cyan);
        },
      );
    }
  }

  void _handlePlayerDeath(String message) {
    _showLevelMessage(
      message,
      Colors.red,
      onDismiss: () {
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
    _showLevelMessage(message, color);
  }

  void _showLevelMessage(
    String message,
    Color color, {
    VoidCallback? onDismiss,
  }) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    // Pausar el juego
    _ticker.stop();
    // Detener el movimiento del jugador
    _gameEngine.player.stopMoving();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
            margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 40),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.9),
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
                  onPressed: () {
                    Navigator.pop(context);
                    // Reanudar el juego
                    _ticker.start();
                    onDismiss?.call();
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

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 20 : 40),
            margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 20 : 40),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.95),
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
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: GameConstants.backgroundColor,
      body: Stack(
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
    );
  }
}
