import 'package:echo_world/minigames/escape/entities/game_constants.dart';
import 'package:echo_world/minigames/escape/entities/level_data.dart';
import 'package:echo_world/minigames/escape/entities/player.dart';
import 'package:flutter/material.dart';

class GameEngine {
  late EscapePlayer player;
  late List<EscapeLevelData> levels;
  int currentLevelIndex = 0;
  EscapeLevelData get currentLevel => levels[currentLevelIndex];
  bool isLevelComplete = false;
  bool isDead = false;

  final VoidCallback onLevelComplete;
  final void Function(String) onPlayerDeath;
  final VoidCallback onGameComplete;
  final void Function(String, Color) onShowMessage;

  GameEngine({
    required this.onLevelComplete,
    required this.onPlayerDeath,
    required this.onGameComplete,
    required this.onShowMessage,
  }) {
    levels = EscapeLevelData.getAllLevels();
    player = EscapePlayer(
      x: currentLevel.startX,
      y: currentLevel.startY,
    );
  }

  void update(double dt) {
    // Don't update if level is complete or player is dead
    if (isLevelComplete || isDead) return;

    // Update timers
    player.updateTimers(dt);

    // ORDEN ESTRICTO DE EJECUCIÓN (según especificación):

    // 1. Intentar ejecutar salto (usa buffer y coyote time)
    player.tryExecuteJump();

    // 2. Aplicar Gravedad
    player.applyGravity();

    // 3. Aplicar Velocidad a Posición
    player.update();

    // 4. Estado por defecto: Asumir que está en el aire
    // Solo si no acabamos de saltar (para no cancelar el salto inmediatamente)
    if (player.velocityY != 0) {
      player.isJumping = true;
    }

    // 5. Resolución de Colisiones (CRÍTICO)
    _handleTileCollisions();

    // Update traps
    for (final trap in currentLevel.traps) {
      trap.update(player.x, player.y);
    }

    // Check trap collisions
    _handleTrapCollisions();

    // Check death conditions
    _checkDeathConditions();
  }

  void _handleTileCollisions() {
    // RESOLUCIÓN DE COLISIONES (según especificación)
    // Solo después de mover al personaje, chequea colisiones AABB

    for (final tile in currentLevel.tiles) {
      if (!tile.isSolid()) continue;

      // Check collision
      if (_checkAABB(
        player.x,
        player.y,
        player.width,
        player.height,
        tile.x,
        tile.y,
        tile.width,
        tile.height,
      )) {
        // Determine collision side
        final overlapLeft = (player.x + player.width) - tile.x;
        final overlapRight = (tile.x + tile.width) - player.x;
        final overlapTop = (player.y + player.height) - tile.y;
        final overlapBottom = (tile.y + tile.height) - player.y;

        final minOverlap = [
          overlapLeft,
          overlapRight,
          overlapTop,
          overlapBottom,
        ].reduce((a, b) => a < b ? a : b);

        // Si colisiona con el SUELO (gravedad normal) o TECHO (gravedad invertida)
        if (player.gravityDirection == 1) {
          // Gravedad normal: colisión con suelo
          if (minOverlap == overlapTop && player.velocityY > 0) {
            // Corregir la posición Y para que quede pegado al borde del bloque
            player.y = tile.y - player.height;
            // Establecer velocityY = 0
            player.velocityY = 0;
            // Establecer isJumping = false (permite volver a saltar)
            player.isJumping = false;
            player.coyoteTimer =
                EscapePlayer.coyoteDuration; // Reset coyote time
          } else if (minOverlap == overlapBottom && player.velocityY < 0) {
            // Hitting ceiling
            player.y = tile.y + tile.height;
            player.velocityY = 0;
          }
        } else {
          // Gravedad invertida: colisión con techo
          if (minOverlap == overlapBottom && player.velocityY < 0) {
            // Corregir la posición Y para que quede pegado al techo
            player.y = tile.y + tile.height;
            // Establecer velocityY = 0
            player.velocityY = 0;
            // Establecer isJumping = false (permite volver a saltar)
            player.isJumping = false;
          } else if (minOverlap == overlapTop && player.velocityY > 0) {
            // Hitting floor from above (in inverted gravity)
            player.y = tile.y - player.height;
            player.velocityY = 0;
          }
        }

        // Colisiones laterales (no afectan el salto)
        if (minOverlap == overlapLeft && player.velocityX > 0) {
          player.x = tile.x - player.width;
          player.velocityX = 0;
        } else if (minOverlap == overlapRight && player.velocityX < 0) {
          player.x = tile.x + tile.width;
          player.velocityX = 0;
        }
      }
    }
  }

  void _handleTrapCollisions() {
    for (final trap in currentLevel.traps) {
      if (!trap.isActive) continue;

      bool collision = trap.checkCollision(
        player.x,
        player.y,
        player.width,
        player.height,
      );

      if (collision) {
        switch (trap.type) {
          case TrapType.spike:
          case TrapType.proximitySpike:
            if (trap.isTriggered || trap.type == TrapType.spike) {
              if (!isDead) {
                isDead = true;
                onPlayerDeath('Impaled by darkness...');
              }
            }
            break;
          case TrapType.door:
            if (!isLevelComplete) {
              isLevelComplete = true;
              trap.isActive = false; // Desactivar la puerta
              if (currentLevelIndex == 9) {
                onGameComplete();
              } else {
                onLevelComplete();
              }
            }
            break;
          case TrapType.fakeDoor:
            if (!isDead) {
              isDead = true;
              onPlayerDeath('The exit lied.');
            }
            break;
          case TrapType.fallingCeiling:
            if (!isDead) {
              isDead = true;
              onPlayerDeath('Crushed by the weight above...');
            }
            break;
          case TrapType.collapsingPlatform:
            trap.isTriggered = true;
            break;
          case TrapType.invertControls:
            if (!player.controlsInverted) {
              player.controlsInverted = true;
              trap.isActive = false;
              onShowMessage('Your mind twists...', Colors.purple);
            }
            break;
          case TrapType.invertGravity:
            player.invertGravity();
            trap.isActive = false;
            onShowMessage('The world turns.', Colors.orange);
            break;
          case TrapType.speedChange:
            if (trap.speedMultiplier != null) {
              player.speedMultiplier = trap.speedMultiplier!;
              trap.isActive = false;
            }
            break;
        }
      }

      // Check falling ceiling collision
      if (trap.type == TrapType.fallingCeiling) {
        // Trigger if player is below
        if (player.x + player.width > trap.x &&
            player.x < trap.x + trap.width &&
            player.y > trap.y) {
          trap.isTriggered = true;
        }
      }
    }
  }

  void _checkDeathConditions() {
    // Fall off screen
    final screenHeight = GameConstants.gridHeight * GameConstants.tileSize;
    if (player.y > screenHeight + 50 || player.y < -130) {
      // Ajustado para el offset de -80
      if (!isDead) {
        isDead = true;
        onPlayerDeath('Lost to the void...');
      }
    }

    // Limitar movimiento horizontal para no salirse de la pantalla
    final screenWidth = GameConstants.gridWidth * GameConstants.tileSize;
    if (player.x < 0) {
      player.x = 0;
      player.velocityX = 0;
    } else if (player.x + player.width > screenWidth) {
      player.x = screenWidth - player.width;
      player.velocityX = 0;
    }
  }

  bool _checkAABB(
    double x1,
    double y1,
    double w1,
    double h1,
    double x2,
    double y2,
    double w2,
    double h2,
  ) {
    return x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2;
  }

  void resetLevel() {
    isDead = false;
    isLevelComplete = false;
    player.reset(currentLevel.startX, currentLevel.startY);
    // Reset traps
    for (final trap in currentLevel.traps) {
      trap.isActive = true;
      trap.isTriggered = false;
      trap.collapseTimer = 0;
      if (trap.type == TrapType.fallingCeiling) {
        trap.y = EscapeLevelData.getAllLevels()[currentLevelIndex].traps
            .firstWhere((t) => t.type == TrapType.fallingCeiling)
            .y;
      }
    }
  }

  void nextLevel() {
    if (currentLevelIndex < levels.length - 1) {
      currentLevelIndex++;
      isDead = false;
      isLevelComplete = false;
      player.reset(currentLevel.startX, currentLevel.startY);
    }
  }
}
