import 'package:supabase_flutter/supabase_flutter.dart';

class MultiplayerRepository {
  final SupabaseClient _client;

  MultiplayerRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

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
    if (user == null) return;

    // Clean up previous channel if any
    if (_matchmakingChannel != null) {
      await leaveLobby();
    }

    _matchmakingChannel = _client.channel('lobby_$roomId');

    _matchmakingChannel!
        .onPresenceSync((payload) {
          final dynamic presenceState = _matchmakingChannel!.presenceState();
          final players = <Map<String, dynamic>>[];

          // Helper to process a single presence object
          void processPresence(dynamic presence) {
            // Case 1: Standard Map with 'payloads' list
            if (presence is Map && presence['payloads'] is List) {
              for (final payload in (presence['payloads'] as List)) {
                if (payload is Map<String, dynamic>) {
                  players.add(payload);
                }
              }
              return;
            }

            // Case 2: Direct Map structure (fallback)
            if (presence is Map<String, dynamic>) {
              players.add(presence);
              return;
            }

            // Case 3: Supabase Flutter SDK specific objects (PresenceState, Presence, etc.)
            try {
              // Check for 'presences' property (PresenceState)
              final dynamic presenceObj = presence;

              // If it has a 'presences' list
              try {
                final List<dynamic> presencesList =
                    presenceObj.presences as List<dynamic>;
                for (final p in presencesList) {
                  final dynamic payload = p.payload;
                  if (payload is Map<String, dynamic>) {
                    players.add(payload);
                  } else if (payload is Map) {
                    players.add(Map<String, dynamic>.from(payload));
                  }
                }
                return;
              } catch (e) {
                // Not a PresenceState
              }

              // If it is a direct Presence object with payload
              try {
                final dynamic payload = presenceObj.payload;
                if (payload is Map<String, dynamic>) {
                  players.add(payload);
                } else if (payload is Map) {
                  players.add(Map<String, dynamic>.from(payload));
                }
                return;
              } catch (e) {
                // Not a Presence object
              }
            } catch (e) {
              // Error inspecting object
            }
          }

          if (presenceState is List) {
            for (final presence in presenceState) {
              processPresence(presence);
            }
          } else if (presenceState is Map) {
            for (final presences in presenceState.values) {
              if (presences is List) {
                for (final presence in presences) {
                  processPresence(presence);
                }
              }
            }
          }

          onPlayersUpdated(players);
        })
        .onBroadcast(
          event: 'match_start',
          callback: (payload) {
            if (onMatchStart != null) {
              final matchId = payload['match_id'] as String;
              onMatchStart(matchId);
            }
          },
        )
        .subscribe((status, error) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await _matchmakingChannel!.track({
              'user_id': user.id,
              'username': user.userMetadata?['username'] ?? 'Unknown',
              'status': 'ready',
              'joined_at': DateTime.now().toIso8601String(),
            });
          }
        });
  }

  Future<void> broadcastMatchStart(String roomId) async {
    if (_matchmakingChannel == null) return;

    final matchId = "MATCH_${roomId}_${DateTime.now().millisecondsSinceEpoch}";

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
