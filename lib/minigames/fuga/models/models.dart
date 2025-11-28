import 'package:equatable/equatable.dart';

/// Represents a cell in the game grid.
enum CellType {
  wall,
  path,
}

/// Represents the current turn in the game.
enum GameTurn {
  player,
  enemy,
}

/// Represents the phase of the player's turn.
enum TurnPhase {
  rolling,
  moving,
}

/// Represents the overall status of the game.
enum GameStatus {
  lore,
  playing,
  win,
  lose,
}

/// Represents a position on the grid (row, col).
/// Renamed from Position to GridPosition to avoid conflicts with Flame's Position.
class GridPosition extends Equatable {
  final int row;
  final int col;

  const GridPosition(this.row, this.col);

  @override
  List<Object> get props => [row, col];
}
