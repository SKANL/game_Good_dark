import 'game_constants.dart';

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
    double direction = controlsInverted ? 1 : -1;
    velocityX = direction * GameConstants.playerSpeed * speedMultiplier;
  }

  void moveRight() {
    double direction = controlsInverted ? -1 : 1;
    velocityX = direction * GameConstants.playerSpeed * speedMultiplier;
  }

  // 1. INPUT DE SALTO (según especificación)
  void jump() {
    if (!isJumping) {
      velocityY = -GameConstants.jumpForce * gravityDirection;
      isJumping = true;
    }
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
  }

  // Método para invertir gravedad
  void invertGravity() {
    gravityDirection = -gravityDirection;
  }
}
