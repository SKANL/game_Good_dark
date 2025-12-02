import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flame/components.dart';

class EchoDuelRepository {
  final SupabaseClient _client;
  final String matchId;
  RealtimeChannel? _gameChannel;

  /// Offset to add to local time to get estimated server time.
  int _serverTimeOffset = 0;

  int get serverTime =>
      DateTime.now().millisecondsSinceEpoch + _serverTimeOffset;

  EchoDuelRepository({
    required this.matchId,
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  /// Syncs clock with Supabase (Simple NTP-like implementation)
  /// Since we don't have a dedicated time endpoint, we'll rely on the DB timestamp
  /// or just assume 0 for now until we have a better mechanism.
  /// For a true robust sync without edge functions, we'd need to ping the database.
  Future<void> syncClock() async {
    try {
      // Simple ping to DB to get server time
      await _client.rpc<void>('get_server_time'); // Requires Postgres function
      // If function doesn't exist, we might fail.
      // Fallback: Just use local time for now as Phase 1 MVP,
      // but structure is here for Phase 1.1 refinement.
      _serverTimeOffset = 0;
    } catch (e) {
      _serverTimeOffset = 0;
    }
  }

  Future<void> joinGame(
    String userId,
    void Function(Map<String, dynamic>) onGameStateUpdate,
    void Function(Map<String, dynamic>) onPlayerShoot,
    void Function(Map<String, dynamic>) onPlayerHit,
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
        .onBroadcast(
          event: 'player_hit',
          callback: (payload) {
            onPlayerHit(payload);
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
        'timestamp': serverTime,
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
        'timestamp': serverTime,
      },
    );
  }

  Future<void> broadcastPlayerHit(String victimId, double damage) async {
    await _gameChannel?.sendBroadcastMessage(
      event: 'player_hit',
      payload: {
        'victim_id': victimId,
        'damage': damage,
        'shooter_id': _client.auth.currentUser?.id,
        'timestamp': serverTime,
      },
    );
  }

  Future<void> leaveGame() async {
    await _gameChannel?.unsubscribe();
    _gameChannel = null;
  }
}
