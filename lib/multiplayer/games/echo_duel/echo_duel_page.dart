import 'package:echo_world/multiplayer/games/echo_duel/echo_duel_game.dart';
import 'package:flame/game.dart' hide Route;
import 'package:flutter/material.dart';

class EchoDuelPage extends StatelessWidget {
  final String matchId;

  const EchoDuelPage({super.key, required this.matchId});

  static Route<void> route(String matchId) {
    return MaterialPageRoute(
      builder: (_) => EchoDuelPage(matchId: matchId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: EchoDuelGame(matchId: matchId),
      ),
    );
  }
}
