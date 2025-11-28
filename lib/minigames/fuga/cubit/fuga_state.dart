import 'package:equatable/equatable.dart';
import '../models/models.dart';

class FugaState extends Equatable {
  const FugaState({
    this.maze = const [],
    this.playerPos = const GridPosition(1, 1),
    this.enemyPos = const GridPosition(19, 1),
    this.exitPos = const GridPosition(19, 19),
    this.currentTurn = GameTurn.player,
    this.turnPhase = TurnPhase.rolling,
    this.gameStatus = GameStatus.lore,
    this.resultMessage,
    this.diceResult = 0,
    this.possibleMoves = const {},
    this.echoCharges = 0,
    this.echoActive = false,
  });

  final List<List<CellType>> maze;
  final GridPosition playerPos;
  final GridPosition enemyPos;
  final GridPosition exitPos;
  final GameTurn currentTurn;
  final TurnPhase turnPhase;
  final GameStatus gameStatus;
  final String? resultMessage;
  final int diceResult;
  final Set<GridPosition> possibleMoves;
  final int echoCharges;
  final bool echoActive;

  FugaState copyWith({
    List<List<CellType>>? maze,
    GridPosition? playerPos,
    GridPosition? enemyPos,
    GridPosition? exitPos,
    GameTurn? currentTurn,
    TurnPhase? turnPhase,
    GameStatus? gameStatus,
    String? resultMessage,
    int? diceResult,
    Set<GridPosition>? possibleMoves,
    int? echoCharges,
    bool? echoActive,
  }) {
    return FugaState(
      maze: maze ?? this.maze,
      playerPos: playerPos ?? this.playerPos,
      enemyPos: enemyPos ?? this.enemyPos,
      exitPos: exitPos ?? this.exitPos,
      currentTurn: currentTurn ?? this.currentTurn,
      turnPhase: turnPhase ?? this.turnPhase,
      gameStatus: gameStatus ?? this.gameStatus,
      resultMessage: resultMessage ?? this.resultMessage,
      diceResult: diceResult ?? this.diceResult,
      possibleMoves: possibleMoves ?? this.possibleMoves,
      echoCharges: echoCharges ?? this.echoCharges,
      echoActive: echoActive ?? this.echoActive,
    );
  }

  @override
  List<Object?> get props => [
    maze,
    playerPos,
    enemyPos,
    exitPos,
    currentTurn,
    turnPhase,
    gameStatus,
    resultMessage,
    diceResult,
    possibleMoves,
    echoCharges,
    echoActive,
  ];
}
