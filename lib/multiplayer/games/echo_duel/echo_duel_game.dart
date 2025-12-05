import 'dart:async';
import 'package:echo_world/multiplayer/games/echo_duel/components/bullet.dart';
import 'package:echo_world/multiplayer/games/echo_duel/components/echo_wave.dart';
import 'package:echo_world/multiplayer/games/echo_duel/components/multiplayer_player.dart';
import 'package:echo_world/multiplayer/games/echo_duel/components/multiplayer_level_manager.dart';
import 'package:echo_world/multiplayer/games/echo_duel/repository/echo_duel_repository.dart';
import 'package:flame/components.dart';
import 'package:echo_world/utils/unawaited.dart';

import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:echo_world/game/components/lighting/has_lighting.dart';
import 'package:echo_world/game/components/lighting/lighting_system.dart';
import 'package:echo_world/game/components/lighting/lighting_layer_component.dart';
import 'package:echo_world/multiplayer/games/echo_duel/components/ui/game_timer_component.dart';
import 'package:echo_world/multiplayer/games/echo_duel/components/ui/scoreboard_component.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';

class EchoDuelGame extends FlameGame with HasLighting {
  final String matchId;
  late final MultiplayerPlayer _localPlayer;
  late final JoystickComponent _joystick;
  late final HudButtonComponent _shootButton;
  late final EchoDuelRepository _repository;
  EchoDuelRepository get repository => _repository;
  final Map<String, MultiplayerPlayer> _remotePlayers = {};
  double _broadcastTimer = 0;

  @override
  late final LightingSystem lightingSystem;

  EchoDuelGame({required this.matchId});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Initialize Lighting System
    lightingSystem = LightingSystem();
    await world.add(lightingSystem);

    // Add Lighting Layer (Darkness)
    // Add Lighting Layer (Darkness)
    await world.add(
      LightingLayerComponent(
        lightingSystem: lightingSystem,
        getEnfoque: () => Enfoque.topDown,
      ),
    );

    // Initialize Level Manager (Arena)
    // Initialize Level Manager (Arena)
    await world.add(MultiplayerLevelManager());

    _repository = EchoDuelRepository(matchId: matchId);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anon';

    await _repository.joinGame(
      userId,
      _handleGameStateUpdate,
      _handlePlayerShoot,
      _handlePlayerHit,
    );

    // Joystick
    final knobPaint = BasicPalette.blue.withAlpha(200).paint();
    final backgroundPaint = BasicPalette.blue.withAlpha(100).paint();
    _joystick = JoystickComponent(
      knob: CircleComponent(radius: 20, paint: knobPaint),
      background: CircleComponent(radius: 50, paint: backgroundPaint),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );
    camera.viewport.add(_joystick);

    // Shoot Button
    _shootButton = HudButtonComponent(
      button: CircleComponent(
        radius: 30,
        paint: BasicPalette.red.withAlpha(200).paint(),
      ),
      margin: const EdgeInsets.only(right: 40, bottom: 60),
      onPressed: _shoot,
    );
    camera.viewport.add(_shootButton);

    // Local Player
    _localPlayer = MultiplayerPlayer(
      id: userId,
      isMe: true,
      position: size / 2,
    );
    world.add(_localPlayer);

    // UI Components
    // UI Components
    camera.viewport.add(ScoreboardComponent());
    camera.viewport.add(GameTimerComponent());

    camera.viewport.add(
      TextComponent(text: "MATCH: $matchId", position: Vector2(50, 50)),
    );

    // Camera Follow
    camera.follow(_localPlayer);
    camera.viewfinder.zoom = 1.0;
  }

  // ... (existing methods)

  void onMatchEnded() {
    print("Match Ended!");
    // Show Results Screen
    // For now, just show a text overlay
    add(
      TextComponent(
        text: "MATCH OVER",
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 48,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        anchor: Anchor.center,
        position: size / 2,
      ),
    );

    // Disable controls
    _joystick.removeFromParent();
    _shootButton.removeFromParent();

    // Auto-leave after 5 seconds
    unawaited(
      Future.delayed(const Duration(seconds: 5), () {
        // Navigate back to lobby (this needs access to Flutter context or a callback)
        // For now, just leave game session
        _repository.leaveGame();
      }),
    );
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

    world.add(bullet);

    // Create Echo
    world.add(EchoWave(position: _localPlayer.position.clone()));

    // Trigger hit scan
    _localPlayer.shoot(direction);

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

    world.add(bullet);

    // Create Echo for remote player
    world.add(EchoWave(position: Vector2(x, y), color: Colors.redAccent));
  }

  void _handleGameStateUpdate(Map<String, dynamic> payload) {
    final userId = payload['user_id'] as String;
    if (userId == _localPlayer.id) return;

    if (_remotePlayers.containsKey(userId)) {
      _remotePlayers[userId]!.onNewState(payload);
    } else {
      final x = (payload['x'] as num).toDouble();
      final y = (payload['y'] as num).toDouble();
      final newPlayer = MultiplayerPlayer(
        id: userId,
        isMe: false,
        position: Vector2(x, y),
      );
      _remotePlayers[userId] = newPlayer;
      world.add(newPlayer);
      // Initialize with first state
      newPlayer.onNewState(payload);
    }
  }

  void _handlePlayerHit(Map<String, dynamic> payload) {
    final victimId = payload['victim_id'] as String;
    final damage = (payload['damage'] as num).toDouble();

    if (victimId == _localPlayer.id) {
      // I was hit!
      _localPlayer.takeDamage(damage);
      print("I took $damage damage! Health: ${_localPlayer.health}");
      // TODO: Show damage indicator UI
    } else if (_remotePlayers.containsKey(victimId)) {
      // Someone else was hit
      _remotePlayers[victimId]!.takeDamage(damage);
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

    // DEBUG OVERLAY
    if (children.whereType<TextComponent>().isEmpty) {
      camera.viewport.add(
        TextComponent(
          text: 'DEBUG',
          position: Vector2(10, 100),
          textRenderer: TextPaint(
            style: const TextStyle(color: Colors.yellow, fontSize: 12),
          ),
        ),
      );
    } else {
      final debugText = camera.viewport.children
          .whereType<TextComponent>()
          .last;
      final lights = lightingSystem.lights.length;
      final camPos = camera.viewfinder.position;
      final playerPos = _localPlayer.position;
      debugText.text =
          '''
FPS: ${fps(dt)}
Lights: $lights
Cam: ${camPos.x.toStringAsFixed(1)}, ${camPos.y.toStringAsFixed(1)}
Player: ${playerPos.x.toStringAsFixed(1)}, ${playerPos.y.toStringAsFixed(1)}
World Children: ${world.children.length}
''';
    }
  }

  String fps(double dt) => (1 / dt).toStringAsFixed(0);

  @override
  void onRemove() {
    _repository.leaveGame();
    super.onRemove();
  }

  @override
  Color backgroundColor() => const Color(0xFF000000);
}
