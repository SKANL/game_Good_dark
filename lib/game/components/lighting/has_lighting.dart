import 'package:echo_world/game/components/lighting/lighting_system.dart';
import 'package:flame/game.dart';

mixin HasLighting on FlameGame {
  LightingSystem get lightingSystem;
}
