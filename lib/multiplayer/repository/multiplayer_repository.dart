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
    String gameType,
    void Function(List<User>) onPlayersUpdated,
  ) async {
    final user = currentUser;
    if (user == null) return;

    _matchmakingChannel = _client.channel('lobby_$gameType');

    _matchmakingChannel!
        .onPresenceSync((payload) {
          final dynamic presenceState = _matchmakingChannel!.presenceState();
          final users = <User>[];

          if (presenceState is List) {
            for (final presence in presenceState) {
              final dynamic p = presence;
              if (p.payloads != null) {
                for (final payload in (p.payloads as List<dynamic>)) {
                  if (payload is Map<String, dynamic> &&
                      payload.containsKey('user')) {
                    // users.add(User.fromJson(payload['user']));
                  }
                }
              }
            }
          } else if (presenceState is Map) {
            for (final presences in presenceState.values) {
              for (final presence in (presences as List<dynamic>)) {
                if (presence is Map<String, dynamic> &&
                    presence.containsKey('user')) {
                  // users.add(User.fromJson(presence['user']));
                }
              }
            }
          }

          onPlayersUpdated(users);
        })
        .subscribe((status, error) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await _matchmakingChannel!.track({
              'user_id': user.id,
              'username': user.userMetadata?['username'] ?? 'Unknown',
              'status': 'searching',
            });
          }
        });
  }

  Stream<List<Map<String, dynamic>>> get lobbyStream {
    return const Stream.empty();
  }

  Future<void> leaveLobby() async {
    await _matchmakingChannel?.unsubscribe();
    _matchmakingChannel = null;
  }
}
