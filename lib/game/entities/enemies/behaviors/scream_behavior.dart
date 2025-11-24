import 'package:echo_world/game/audio/audio_manager.dart';
import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

/// Behavior que hace que el enemigo emita un grito de alarma
/// cuando detecta al jugador. Este grito atrae a todos los demás enemigos.
class ScreamBehavior extends Behavior<PositionedEntity>
    with HasGameRef<BlackEchoGame> {
  ScreamBehavior({
    this.screamDuration = 3.0,
    this.screamRadius = 300.0,
  });

  /// Duración del grito en segundos
  final double screamDuration;

  /// Radio de atracción del grito (afecta a todos los enemigos en este radio)
  final double screamRadius;

  /// Flag para saber si está gritando actualmente
  bool _isScreaming = false;

  /// Timer para controlar la duración del grito
  double _currentScreamTime = 0;

  /// Activa el grito de alarma
  void triggerScream() {
    if (_isScreaming) return; // Ya está gritando

    _isScreaming = true;
    _currentScreamTime = screamDuration;

    AudioManager.instance.playSfx('vigia_alarm_scream');

    // Emitir estímulo de sonido ALTO para atraer a todos los enemigos
    gameRef.emitSound(
      parent.position,
      NivelSonido.alto,
      ttl: screamDuration,
    );
  }

  void reset() {
    _isScreaming = false;
    _currentScreamTime = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isScreaming) {
      _currentScreamTime -= dt;

      if (_currentScreamTime <= 0) {
        _isScreaming = false;
      }
    }
  }

  /// Verifica si el enemigo está gritando
  bool get isScreaming => _isScreaming;
}
