import 'package:echo_world/game/cubit/game/game_bloc.dart';
import 'package:echo_world/game/cubit/game/game_event.dart';
import 'package:echo_world/game/entities/player/player.dart';
import 'package:flame_behaviors/flame_behaviors.dart';
import 'package:flame/components.dart';

class StealthBehavior extends Behavior<PlayerComponent> {
  StealthBehavior({required this.gameBloc});
  final GameBloc gameBloc;

  double _regenTimer = 0;
  static const double _regenInterval = 1.0; // 1 second
  static const int _regenAmount = 5; // 5 energy per second

  Vector2 _lastPosition = Vector2.zero();
  bool _isMoving = false;

  @override
  void update(double dt) {
    // Check movement
    final dist = parent.position.distanceTo(_lastPosition);
    _isMoving = dist > 0.1;
    _lastPosition = parent.position.clone();

    // Meditative Recharge: Crouched + Not Moving
    if (gameBloc.state.estaAgachado && !_isMoving) {
      _regenTimer += dt;
      if (_regenTimer >= _regenInterval) {
        _regenTimer = 0;
        // Emit regeneration event
        if (gameBloc.state.energiaGrito < 100) {
          gameBloc.add(const EnergiaRegenerada(_regenAmount));
        }
      }
    } else {
      _regenTimer = 0; // Reset if moving or standing
    }
  }
}
