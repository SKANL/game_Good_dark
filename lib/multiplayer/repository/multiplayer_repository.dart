import 'package:supabase_flutter/supabase_flutter.dart';

class MultiplayerRepository {
  final SupabaseClient _client;

  MultiplayerRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  // --- Auth ---
  // --- Auth ---
  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Ensure player profile exists
    if (response.user != null) {
      await _ensurePlayerProfile(response.user!);
    }

    return response;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    // Player profile is usually created by Trigger, but we can double check or fetch it
    if (response.user != null) {
      // Optional: Check if profile exists or wait for trigger
    }

    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Map<String, dynamic>?> getPlayerProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('players')
          .select()
          .eq('user_id', user.id)
          .single();
      return data;
    } catch (e) {
      return null;
    }
  }

  Future<void> _ensurePlayerProfile(User user) async {
    final profile = await getPlayerProfile();
    if (profile == null) {
      // Create profile if missing (fallback if trigger failed)
      await _client.from('players').insert({
        'user_id': user.id,
        'username':
            user.userMetadata?['username'] ??
            user.email?.split('@')[0] ??
            'Unknown',
        'email': user.email,
        'coins': 0,
      });
    }
  }

  // --- Inventory ---
  Future<List<Map<String, dynamic>>> getInventory() async {
    final user = currentUser;
    if (user == null) return [];

    final response = await _client
        .from('player_inventory')
        .select()
        .eq('user_id', user.id);

    return List<Map<String, dynamic>>.from(response);
  }

  // --- Matchmaking (Realtime Presence) ---
  RealtimeChannel? _matchmakingChannel;

  Future<void> joinLobby(
    String roomId,
    void Function(List<Map<String, dynamic>>) onPlayersUpdated, {
    void Function(String matchId)? onMatchStart,
  }) async {
    final user = currentUser;
    if (user == null) {
      print('[MULTIPLAYER_DEBUG] joinLobby: User is null, cannot join.');
      return;
    }

    print('[MULTIPLAYER_DEBUG] joinLobby: Joining room $roomId as ${user.id}');

    // Clean up previous channel if any
    if (_matchmakingChannel != null) {
      print('[MULTIPLAYER_DEBUG] joinLobby: Cleaning up previous channel');
      await leaveLobby();
    }

    _matchmakingChannel = _client.channel('lobby_$roomId');
    print('[MULTIPLAYER_DEBUG] joinLobby: Channel initialized: lobby_$roomId');

    _matchmakingChannel!
        .onPresenceSync((payload) {
          print('[MULTIPLAYER_DEBUG] onPresenceSync: Event received');
          final dynamic presenceState = _matchmakingChannel!.presenceState();
          print(
            '[MULTIPLAYER_DEBUG] onPresenceSync: Raw State: $presenceState',
          );

          final players = <Map<String, dynamic>>[];

          // Helper to process a single presence object
          void processPresence(dynamic presence) {
            print('[MULTIPLAYER_DEBUG] processPresence: Processing $presence');
            if (presence is Map && presence['payloads'] is List) {
              for (final payload in (presence['payloads'] as List)) {
                print(
                  '[MULTIPLAYER_DEBUG] processPresence: Found payload: $payload',
                );
                if (payload is Map<String, dynamic>) {
                  players.add(payload);
                }
              }
            } else if (presence is Map<String, dynamic>) {
              // Fallback or direct map structure
              print(
                '[MULTIPLAYER_DEBUG] processPresence: Direct map structure found: $presence',
              );
              players.add(presence);
            } else {
              print(
                '[MULTIPLAYER_DEBUG] processPresence: Unknown format: ${presence.runtimeType}',
              );
            }
          }

          if (presenceState is List) {
            print('[MULTIPLAYER_DEBUG] onPresenceSync: State is List');
            for (final presence in presenceState) {
              processPresence(presence);
            }
          } else if (presenceState is Map) {
            print('[MULTIPLAYER_DEBUG] onPresenceSync: State is Map');
            for (final presences in presenceState.values) {
              if (presences is List) {
                for (final presence in presences) {
                  processPresence(presence);
                }
              }
            }
          } else {
            print(
              '[MULTIPLAYER_DEBUG] onPresenceSync: Unknown state type: ${presenceState.runtimeType}',
            );
          }

          print(
            '[MULTIPLAYER_DEBUG] onPresenceSync: Parsed ${players.length} players',
          );
          onPlayersUpdated(players);
        })
        .onBroadcast(
          event: 'match_start',
          callback: (payload) {
            print(
              '[MULTIPLAYER_DEBUG] onBroadcast: match_start received with payload: $payload',
            );
            if (onMatchStart != null) {
              final matchId = payload['match_id'] as String;
              onMatchStart(matchId);
            }
          },
        )
        .subscribe((status, error) async {
          print('[MULTIPLAYER_DEBUG] subscribe: Status changed to $status');
          if (error != null) {
            print('[MULTIPLAYER_DEBUG] subscribe: Error: $error');
          }

          if (status == RealtimeSubscribeStatus.subscribed) {
            print('[MULTIPLAYER_DEBUG] subscribe: Tracking user presence...');
            await _matchmakingChannel!.track({
              'user_id': user.id,
              'username': user.userMetadata?['username'] ?? 'Unknown',
              'status': 'ready',
              'joined_at': DateTime.now().toIso8601String(),
            });
            print('[MULTIPLAYER_DEBUG] subscribe: Track called');
          }
        });
  }

  Future<void> broadcastMatchStart(String roomId) async {
    if (_matchmakingChannel == null) return;

    final matchId = "MATCH_${roomId}_${DateTime.now().millisecondsSinceEpoch}";
    print(
      '[MULTIPLAYER_DEBUG] broadcastMatchStart: Sending match_start for $matchId',
    );

    await _matchmakingChannel!.sendBroadcastMessage(
      event: 'match_start',
      payload: {'match_id': matchId},
    );
  }

  Future<void> leaveLobby() async {
    await _matchmakingChannel?.unsubscribe();
    _matchmakingChannel = null;
  }
}
