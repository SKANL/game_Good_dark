import 'package:echo_world/game/cubit/game/game_bloc.dart';
import 'package:echo_world/game/entities/player/behaviors/gravity_behavior.dart';
import 'package:echo_world/game/entities/player/player.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

class JumpBehavior extends Behavior<PlayerComponent> {
  JumpBehavior({required this.gameBloc});
  final GameBloc gameBloc;

  static const double jumpForce = -420; // px/s

  void triggerJump() {
    final g = parent.findBehavior<GravityBehavior>();
    g.impulse(jumpForce);
  }
}
