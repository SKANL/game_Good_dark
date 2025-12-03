import 'package:echo_world/minigames/escape/entities/game_constants.dart';

class EscapePlayer {
  double x;
  double y;
  double velocityX;
  double velocityY;
  final double width;
  final double height;

  // VARIABLES DE ESTADO NECESARIAS (según especificación)
  bool isJumping; // Bandera para evitar saltos infinitos
  int gravityDirection; // 1 para normal, -1 para invertida

  // Variables adicionales del juego
  bool controlsInverted;
  double speedMultiplier;

  EscapePlayer({
    required this.x,
    required this.y,
    this.velocityX = 0,
    this.velocityY = 0,
    this.width = GameConstants.tileSize * 0.8,
    this.height = GameConstants.tileSize * 0.8,
    this.isJumping = true,
    this.gravityDirection = 1,
    this.controlsInverted = false,
    this.speedMultiplier = 1.0,
  });

  void moveLeft() {
    final direction = controlsInverted ? 1 : -1;
    velocityX = direction * GameConstants.playerSpeed * speedMultiplier;
  }

  void moveRight() {
    final direction = controlsInverted ? -1 : 1;
    velocityX = direction * GameConstants.playerSpeed * speedMultiplier;
  }

  // Timers for game feel
  double coyoteTimer = 0;
  double jumpBufferTimer = 0;
  static const double coyoteDuration = 0.1; // 100ms
  static const double jumpBufferDuration = 0.1; // 100ms

  // 1. INPUT DE SALTO (según especificación)
  void jump() {
    // Instead of jumping immediately, we buffer the input
    jumpBufferTimer = jumpBufferDuration;
  }

  void updateTimers(double dt) {
    if (coyoteTimer > 0) coyoteTimer -= dt;
    if (jumpBufferTimer > 0) jumpBufferTimer -= dt;
  }

  /// Attempt to execute a jump if conditions are met
  bool tryExecuteJump() {
    // Jump if we have a buffered jump AND (we are on ground OR we have coyote time)
    if (jumpBufferTimer > 0 && (!isJumping || coyoteTimer > 0)) {
      velocityY = -GameConstants.jumpForce * gravityDirection;
      isJumping = true;
      coyoteTimer = 0; // Consume coyote time
      jumpBufferTimer = 0; // Consume jump buffer
      return true;
    }
    return false;
  }

  void stopMoving() {
    velocityX = 0;
  }

  // 2. APLICAR GRAVEDAD (según especificación)
  void applyGravity() {
    velocityY += GameConstants.gravity * gravityDirection;
  }

  // 3. APLICAR VELOCIDAD A POSICIÓN (según especificación)
  void update() {
    x += velocityX;
    y += velocityY;
  }

  void reset(double startX, double startY) {
    x = startX;
    y = startY;
    velocityX = 0;
    velocityY = 0;
    isJumping = true;
    gravityDirection = 1;
    controlsInverted = false;
    speedMultiplier = 1.0;
    coyoteTimer = 0;
    jumpBufferTimer = 0;
  }

  // Método para invertir gravedad
  void invertGravity() {
    gravityDirection = -gravityDirection;
  }
}
