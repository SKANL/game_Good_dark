import 'package:echo_world/multiplayer/games/echo_duel/echo_duel_page.dart';
import 'package:echo_world/multiplayer/repository/multiplayer_repository.dart';
import 'package:echo_world/utils/unawaited.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LobbyPage extends StatefulWidget {
  final String gameType;
  final String roomId;
  final MultiplayerRepository repository;

  const LobbyPage({
    super.key,
    required this.gameType,
    required this.roomId,
    required this.repository,
  });

  static Route<void> route(String gameType, String roomId) {
    return MaterialPageRoute(
      builder: (_) => LobbyPage(
        gameType: gameType,
        roomId: roomId,
        repository: MultiplayerRepository(),
      ),
    );
  }

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  List<Map<String, dynamic>> _players = [];
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _joinLobby();
  }

  Future<void> _joinLobby() async {
    print(
      '[MULTIPLAYER_DEBUG] LobbyPage: _joinLobby called for room ${widget.roomId}',
    );
    await widget.repository.joinLobby(
      widget.roomId,
      (players) {
        print(
          '[MULTIPLAYER_DEBUG] LobbyPage: Received players update. Count: ${players.length}',
        );
        if (mounted) {
          setState(() {
            _players = players;
          });
          print('[MULTIPLAYER_DEBUG] LobbyPage: UI State updated');
        } else {
          print(
            '[MULTIPLAYER_DEBUG] LobbyPage: Widget not mounted, skipping update',
          );
        }
      },
      onMatchStart: (matchId) {
        print(
          '[MULTIPLAYER_DEBUG] LobbyPage: Match start event received: $matchId',
        );
        _handleMatchStart(matchId);
      },
    );
  }

  void _handleMatchStart(String matchId) {
    if (!mounted) return;
    setState(() => _isStarting = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("MATCH STARTING..."),
        backgroundColor: Colors.greenAccent,
        duration: Duration(seconds: 1),
      ),
    );

    unawaited(
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        if (widget.gameType.contains("Duelo")) {
          unawaited(
            Navigator.of(context).pushReplacement(EchoDuelPage.route(matchId)),
          );
        } else {
          // Fallback for other modes
          unawaited(
            Navigator.of(context).pushReplacement(EchoDuelPage.route(matchId)),
          );
        }
      }),
    );
  }

  Future<void> _startMatch() async {
    final matchId = await widget.repository.broadcastMatchStart(widget.roomId);
    if (matchId != null) {
      // Host must manually handle the start event as they don't receive their own broadcast
      _handleMatchStart(matchId);
    }
  }

  @override
  void dispose() {
    unawaited(widget.repository.leaveLobby());
    super.dispose();
  }

  int get _minPlayers {
    if (widget.gameType.contains("Duelo")) return 2;
    if (widget.gameType.contains("Control")) return 4;
    if (widget.gameType.contains("Asalto")) return 6;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final canStart = _players.length >= _minPlayers;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("ROOM: ${widget.roomId}"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.cyanAccent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(
              child: Text(
                "${_players.length}/$_minPlayers",
                style: TextStyle(
                  color: canStart ? Colors.greenAccent : Colors.redAccent,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            "SHARE CODE: ${widget.roomId}",
            style: const TextStyle(
              color: Colors.yellowAccent,
              fontFamily: 'Courier',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "WAITING FOR OPERATIVES...",
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Courier',
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          if (_players.isEmpty)
            const CircularProgressIndicator(color: Colors.cyanAccent),

          Expanded(
            child: ListView.builder(
              itemCount: _players.length,
              itemBuilder: (context, index) {
                final player = _players[index];
                final isMe =
                    player['user_id'] ==
                    Supabase.instance.client.auth.currentUser?.id;

                return ListTile(
                  leading: Icon(
                    Icons.person,
                    color: isMe ? Colors.greenAccent : Colors.cyan,
                  ),
                  title: Text(
                    (player['username'] as String?) ?? 'Unknown',
                    style: TextStyle(
                      color: isMe ? Colors.greenAccent : Colors.white,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Status: ${player['status'] ?? 'Unknown'}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: isMe
                      ? const Text(
                          "[YOU]",
                          style: TextStyle(color: Colors.green),
                        )
                      : null,
                );
              },
            ),
          ),

          if (_isStarting)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          else
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canStart
                      ? Colors.cyanAccent
                      : Colors.grey.shade900,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                ),
                onPressed: canStart ? _startMatch : null,
                child: Text(
                  canStart ? "START MATCH" : "WAITING FOR PLAYERS...",
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
