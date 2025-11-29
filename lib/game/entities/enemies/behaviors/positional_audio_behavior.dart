import 'dart:math' as math;
import 'package:echo_world/game/audio/audio_manager.dart';
import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/entities/enemies/behaviors/hearing_behavior.dart';
import 'package:flame/components.dart';
import 'package:flame_behaviors/flame_behaviors.dart';

/// Behavior que gestiona el audio posicional de un enemigo
/// Reacciona al estado de la FSM para reproducir los sonidos correctos
class PositionalAudioBehavior extends Behavior<PositionedEntity>
    with HasGameRef<BlackEchoGame> {
  String? _currentLoopId;
  AIState _lastKnownState = AIState.atormentado;

  final AudioManager _audioManager = AudioManager.instance;

  @override
  void update(double dt) {
    super.update(dt);

    // Buscar el HearingBehavior para conocer el estado actual
    final hearing = parent.findBehavior<HearingBehavior>();

    final currentState = hearing.estadoActual;
    final playerPos = gameRef.player.position;

    // Transiciones de audio según el estado
    if (currentState != _lastKnownState) {
      _onStateChanged(currentState, playerPos);
      _lastKnownState = currentState;
    }

    // Actualizar posición del loop activo
    if (_currentLoopId != null) {
      _audioManager.updatePositionalLoop(
        loopId: _currentLoopId!,
        sourcePosition: math.Point(parent.position.x, parent.position.y),
        listenerPosition: math.Point(playerPos.x, playerPos.y),
        maxDistance: 480,
      );
    }
  }

  void _onStateChanged(AIState newState, Vector2 playerPos) {
    // Detener loop anterior
    if (_currentLoopId != null) {
      _audioManager.stopPositionalLoop(_currentLoopId!);
      _currentLoopId = null;
    }

    // AUDIO DISABLED FOR PERFORMANCE
    /*
    switch (newState) {
      case AIState.atormentado:
        // ...
        break;
      case AIState.alerta:
        // ...
        break;
      case AIState.caza:
        // ...
        break;
      case AIState.aturdido:
        break;
    }
    */
  }

  void reset() {
    if (_currentLoopId != null) {
      _audioManager.stopPositionalLoop(_currentLoopId!);
      _currentLoopId = null;
    }
    _lastKnownState = AIState.atormentado;
  }

  @override
  void onRemove() {
    if (_currentLoopId != null) {
      _audioManager.stopPositionalLoop(_currentLoopId!);
    }
    super.onRemove();
  }
}
