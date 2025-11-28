import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flame/components.dart';

class EchoDuelRepository {
  final SupabaseClient _client;
  final String matchId;
  RealtimeChannel? _gameChannel;

  EchoDuelRepository({
    required this.matchId,
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  Future<void> joinGame(
    String userId,
    void Function(Map<String, dynamic>) onGameStateUpdate,
    void Function(Map<String, dynamic>) onPlayerShoot,
  ) async {
    _gameChannel = _client.channel('game_$matchId');

    _gameChannel!
        .onBroadcast(
          event: 'player_update',
          callback: (payload) {
            onGameStateUpdate(payload);
          },
        )
        .onBroadcast(
          event: 'player_shoot',
          callback: (payload) {
            onPlayerShoot(payload);
          },
        )
        .subscribe();
  }

  Future<void> broadcastPlayerUpdate({
    required String userId,
    required Vector2 position,
    required Vector2 velocity,
  }) async {
    await _gameChannel?.sendBroadcastMessage(
      event: 'player_update',
      payload: {
        'user_id': userId,
        'x': position.x,
        'y': position.y,
        'vx': velocity.x,
        'vy': velocity.y,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<void> broadcastShoot({
    required String userId,
    required Vector2 position,
    required Vector2 direction,
  }) async {
    await _gameChannel?.sendBroadcastMessage(
      event: 'player_shoot',
      payload: {
        'user_id': userId,
        'x': position.x,
        'y': position.y,
        'dx': direction.x,
        'dy': direction.y,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<void> leaveGame() async {
    await _gameChannel?.unsubscribe();
    _gameChannel = null;
  }
}
