import 'dart:async';
import 'package:echo_world/multiplayer/games/echo_duel/components/bullet.dart';
import 'package:echo_world/multiplayer/games/echo_duel/components/echo_wave.dart';
import 'package:echo_world/multiplayer/games/echo_duel/components/multiplayer_player.dart';
import 'package:echo_world/multiplayer/games/echo_duel/repository/echo_duel_repository.dart';
import 'package:flame/components.dart';

import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Using HasDraggablesBridge if available, or just HasDraggables if it's a mixin.
// If HasDraggables is deprecated, we might need HasDraggableComponents.
// For now, I'll try to use HasDraggables as it was working before the corruption.
// If it fails, I'll switch.
class EchoDuelGame extends FlameGame {
  final String matchId;
  late final MultiplayerPlayer _localPlayer;
  late final JoystickComponent _joystick;
  late final HudButtonComponent _shootButton;
  late final EchoDuelRepository _repository;
  final Map<String, MultiplayerPlayer> _remotePlayers = {};
  double _broadcastTimer = 0;

  EchoDuelGame({required this.matchId});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    _repository = EchoDuelRepository(matchId: matchId);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';

    await _repository.joinGame(
      userId,
      _handleGameStateUpdate,
      _handlePlayerShoot,
    );

    // Joystick
    final knobPaint = BasicPalette.blue.withAlpha(200).paint();
    final backgroundPaint = BasicPalette.blue.withAlpha(100).paint();
    _joystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    add(_joystick);

    // Shoot Button
    _shootButton = HudButtonComponent(
      button: CircleComponent(
        radius: 30,
        paint: BasicPalette.red.withAlpha(200).paint(),
      ),
      margin: const EdgeInsets.only(right: 40, bottom: 60),
      onPressed: _shoot,
    );
    add(_shootButton);

    // Local Player
    _localPlayer = MultiplayerPlayer(
      id: userId,
      isMe: true,
      position: size / 2,
    );
    add(_localPlayer);

    add(TextComponent(text: "MATCH: $matchId", position: Vector2(50, 50)));
  }

  void _shoot() {
    final direction = _joystick.relativeDelta.isZero()
        ? Vector2(1, 0)
        : _joystick.relativeDelta;
    final bullet = Bullet(
      ownerId: _localPlayer.id,
      position: _localPlayer.position.clone(),
      direction: direction,
    );
    add(bullet);

    // Create Echo
    add(EchoWave(position: _localPlayer.position.clone()));

    _repository.broadcastShoot(
      userId: _localPlayer.id,
      position: _localPlayer.position,
      direction: direction,
    );
  }

  void _handlePlayerShoot(Map<String, dynamic> payload) {
    final userId = payload['user_id'] as String;
    if (userId == _localPlayer.id) return;

    final x = (payload['x'] as num).toDouble();
    final y = (payload['y'] as num).toDouble();
    final dx = (payload['dx'] as num).toDouble();
    final dy = (payload['dy'] as num).toDouble();

    final bullet = Bullet(
      ownerId: userId,
      position: Vector2(x, y),
      direction: Vector2(dx, dy),
    );
    add(bullet);

    // Create Echo for remote player
    add(EchoWave(position: Vector2(x, y), color: Colors.redAccent));
  }

  void _handleGameStateUpdate(Map<String, dynamic> payload) {
    final userId = payload['user_id'] as String;
    if (userId == _localPlayer.id) return;

    final x = (payload['x'] as num).toDouble();
    final y = (payload['y'] as num).toDouble();
    final position = Vector2(x, y);

    if (_remotePlayers.containsKey(userId)) {
      _remotePlayers[userId]!.position = position;
    } else {
      final newPlayer = MultiplayerPlayer(
        id: userId,
        isMe: false,
        position: position,
      );
      _remotePlayers[userId] = newPlayer;
      add(newPlayer);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_joystick.delta.isZero()) {
      _localPlayer.move(_joystick.relativeDelta);

      _broadcastTimer += dt;
      if (_broadcastTimer > 0.05) {
        // Broadcast every 50ms
        _repository.broadcastPlayerUpdate(
          userId: _localPlayer.id,
          position: _localPlayer.position,
          velocity: _localPlayer.velocity,
        );
        _broadcastTimer = 0;
      }
    } else {
      _localPlayer.move(Vector2.zero());
    }
  }

  @override
  void onRemove() {
    _repository.leaveGame();
    super.onRemove();
  }

  @override
  Color backgroundColor() => const Color(0xFF000000);
}
