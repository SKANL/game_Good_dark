import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import '../models/models.dart';
import 'fuga_state.dart';

const int mazeWidth = 21;
const int mazeHeight = 21;

class FugaCubit extends Cubit<FugaState> {
  FugaCubit() : super(const FugaState()) {
    initGame();
  }

  final Random _rng = Random();

  void initGame() {
    final maze = _generateMaze(mazeWidth, mazeHeight);
    _addMazeLoops(maze, passes: 3, chance: 0.12);

    final playerPos = const GridPosition(1, 1);

    // Find valid path cells for spawning
    final pathCells = <GridPosition>[];
    for (int r = 1; r < maze.length - 1; r++) {
      for (int c = 1; c < maze[0].length - 1; c++) {
        if (maze[r][c] == CellType.path) pathCells.add(GridPosition(r, c));
      }
    }

    final exitPos = _chooseFar(pathCells, playerPos, 10);
    final enemyPos = _chooseFar(
      pathCells.where((p) => p != exitPos).toList(),
      playerPos,
      8,
    );

    emit(
      FugaState(
        maze: maze,
        playerPos: playerPos,
        enemyPos: enemyPos,
        exitPos: exitPos,
        currentTurn: GameTurn.player,
        turnPhase: TurnPhase.rolling,
        gameStatus: GameStatus.lore,
        diceResult: 0,
        possibleMoves: const {},
        echoCharges: 0,
        echoActive: false,
      ),
    );
  }

  void startGame() {
    emit(state.copyWith(gameStatus: GameStatus.playing));
  }

  void restartGame() {
    initGame();
    startGame();
  }

  void rollDice() {
    if (state.currentTurn != GameTurn.player ||
        state.turnPhase != TurnPhase.rolling)
      return;

    final diceResult = _rng.nextInt(4) + 1;
    final possibleMoves = _calculatePossibleMoves(
      state.playerPos,
      diceResult,
      state.maze,
    );

    emit(
      state.copyWith(
        diceResult: diceResult,
        possibleMoves: possibleMoves,
        turnPhase: TurnPhase.moving,
      ),
    );
  }

  void passTurn() {
    if (state.currentTurn != GameTurn.player) return;
    _endPlayerTurn();
  }

  void activateEcho() {
    if (state.echoCharges < 6 || state.currentTurn != GameTurn.player) return;
    emit(state.copyWith(echoActive: true));
  }

  void movePlayer(GridPosition to) {
    if (state.currentTurn != GameTurn.player ||
        state.turnPhase != TurnPhase.moving)
      return;
    if (!state.possibleMoves.contains(to)) return;

    var newState = state.copyWith(playerPos: to);

    // If echo active, it turns off and charges reset
    if (state.echoActive) {
      newState = newState.copyWith(echoActive: false, echoCharges: 0);
    }

    // Check win
    if (to == state.exitPos) {
      emit(
        newState.copyWith(
          gameStatus: GameStatus.win,
          resultMessage: '!HAZ LOGRADO ESCAPAR DE LA CRIATURA¡',
        ),
      );
      return;
    }

    // If player moved onto enemy
    if (to == state.enemyPos) {
      emit(
        newState.copyWith(
          gameStatus: GameStatus.lose,
          resultMessage: '!TEAN ATRAPADO YA NO QUEDA ESPERANZA PARA TI¡',
        ),
      );
      return;
    }

    emit(newState);
    _endPlayerTurn();
  }

  void _endPlayerTurn() {
    int newCharges = state.echoCharges;
    bool newEchoActive = state.echoActive;

    if (!state.echoActive) {
      newCharges = (state.echoCharges + 1).clamp(0, 6);
    } else {
      newEchoActive = false;
      newCharges = 0;
    }

    emit(
      state.copyWith(
        echoCharges: newCharges,
        echoActive: newEchoActive,
        diceResult: 0,
        possibleMoves: const {},
        turnPhase: TurnPhase.rolling,
        currentTurn: GameTurn.enemy,
      ),
    );

    // Perform enemy action after short delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!isClosed) _enemyTurn();
    });
  }

  void _enemyTurn() {
    if (state.gameStatus != GameStatus.playing) return;

    var currentEnemyPos = state.enemyPos;
    final path = _bfsPath(currentEnemyPos, state.playerPos, state.maze);

    if (path.length >= 2) {
      currentEnemyPos = path[1]; // move 1 step along path
    }

    var newState = state.copyWith(enemyPos: currentEnemyPos);

    // Check if enemy caught player (same cell)
    if (currentEnemyPos == state.playerPos) {
      emit(
        newState.copyWith(
          gameStatus: GameStatus.lose,
          resultMessage: '!TEAN ATRAPADO YA NO QUEDA ESPERANZA PARA TI¡',
        ),
      );
      return;
    }

    // If enemy is adjacent (one block) to player -> immediate lose
    if (_manhattan(currentEnemyPos, state.playerPos) == 1) {
      emit(
        newState.copyWith(
          gameStatus: GameStatus.lose,
          resultMessage: '!TEAN ATRAPADO YA NO QUEDA ESPERANZA PARA TI¡',
        ),
      );
      return;
    }

    // End enemy turn
    emit(
      newState.copyWith(
        currentTurn: GameTurn.player,
        turnPhase: TurnPhase.rolling,
      ),
    );
  }

  // --- Helpers ---

  GridPosition _chooseFar(
    List<GridPosition> candidates,
    GridPosition from,
    int minDist,
  ) {
    final shuffled = List<GridPosition>.from(candidates)..shuffle();
    for (final p in shuffled) {
      if (_manhattan(p, from) >= minDist) return p;
    }
    return candidates.isNotEmpty ? candidates.first : from;
  }

  int _manhattan(GridPosition a, GridPosition b) =>
      (a.row - b.row).abs() + (a.col - b.col).abs();

  List<List<CellType>> _generateMaze(int width, int height) {
    final w = width % 2 == 0 ? width + 1 : width;
    final h = height % 2 == 0 ? height + 1 : height;
    final maze = List.generate(
      h,
      (_) => List.generate(w, (_) => CellType.wall),
    );
    final stack = <GridPosition>[];
    final startPos = const GridPosition(1, 1);
    maze[startPos.row][startPos.col] = CellType.path;
    stack.add(startPos);

    while (stack.isNotEmpty) {
      final current = stack.last;
      final neighbors = <Map<String, dynamic>>[];
      final directions = <Map<String, int>>[
        {'r': -2, 'c': 0, 'wr': -1, 'wc': 0},
        {'r': 2, 'c': 0, 'wr': 1, 'wc': 0},
        {'r': 0, 'c': -2, 'wr': 0, 'wc': -1},
        {'r': 0, 'c': 2, 'wr': 0, 'wc': 1},
      ];

      for (final dir in directions) {
        final nRow = current.row + (dir['r']!);
        final nCol = current.col + (dir['c']!);
        if (nRow > 0 &&
            nRow < h - 1 &&
            nCol > 0 &&
            nCol < w - 1 &&
            maze[nRow][nCol] == CellType.wall) {
          neighbors.add({
            'row': nRow,
            'col': nCol,
            'wall': GridPosition(
              current.row + (dir['wr']!),
              current.col + (dir['wc']!),
            ),
          });
        }
      }

      if (neighbors.isNotEmpty) {
        final pick = neighbors[_rng.nextInt(neighbors.length)];
        final row = pick['row'] as int;
        final col = pick['col'] as int;
        final wall = pick['wall'] as GridPosition;
        maze[wall.row][wall.col] = CellType.path;
        maze[row][col] = CellType.path;
        stack.add(GridPosition(row, col));
      } else {
        stack.removeLast();
      }
    }
    return maze;
  }

  void _addMazeLoops(
    List<List<CellType>> maze, {
    int passes = 3,
    double chance = 0.10,
  }) {
    final h = maze.length;
    final w = maze[0].length;
    for (int p = 0; p < passes; p++) {
      for (int r = 1; r < h - 1; r++) {
        for (int c = 1; c < w - 1; c++) {
          if (maze[r][c] == CellType.wall) {
            int paths = 0;
            if (maze[r - 1][c] == CellType.path) paths++;
            if (maze[r + 1][c] == CellType.path) paths++;
            if (maze[r][c - 1] == CellType.path) paths++;
            if (maze[r][c + 1] == CellType.path) paths++;

            if (paths >= 2 && _rng.nextDouble() < chance) {
              maze[r][c] = CellType.path;
            }
          }
        }
      }
    }
  }

  Set<GridPosition> _calculatePossibleMoves(
    GridPosition start,
    int steps,
    List<List<CellType>> grid,
  ) {
    final h = grid.length;
    final w = grid[0].length;
    final visited = <GridPosition>{};
    final q = <GridPosition>[];
    final dist = <GridPosition, int>{};

    q.add(start);
    visited.add(start);
    dist[start] = 0;

    final dirs = [
      const GridPosition(-1, 0),
      const GridPosition(1, 0),
      const GridPosition(0, -1),
      const GridPosition(0, 1),
    ];

    while (q.isNotEmpty) {
      final cur = q.removeAt(0);
      final dcur = dist[cur]!;
      if (dcur >= steps) continue;

      for (final dir in dirs) {
        final nr = cur.row + dir.row;
        final nc = cur.col + dir.col;
        if (nr > 0 &&
            nr < h - 1 &&
            nc > 0 &&
            nc < w - 1 &&
            grid[nr][nc] == CellType.path) {
          final np = GridPosition(nr, nc);
          if (!visited.contains(np)) {
            visited.add(np);
            dist[np] = dcur + 1;
            q.add(np);
          }
        }
      }
    }

    visited.remove(start);
    return visited.where((p) => dist[p]! <= steps).toSet();
  }

  List<GridPosition> _bfsPath(
    GridPosition start,
    GridPosition goal,
    List<List<CellType>> grid,
  ) {
    final h = grid.length;
    final w = grid[0].length;
    final q = <GridPosition>[];
    final cameFrom = <GridPosition, GridPosition?>{};

    q.add(start);
    cameFrom[start] = null;

    final dirs = [
      const GridPosition(-1, 0),
      const GridPosition(1, 0),
      const GridPosition(0, -1),
      const GridPosition(0, 1),
    ];

    while (q.isNotEmpty) {
      final cur = q.removeAt(0);
      if (cur == goal) break;

      for (final d in dirs) {
        final nr = cur.row + d.row;
        final nc = cur.col + d.col;
        if (nr > 0 &&
            nr < h - 1 &&
            nc > 0 &&
            nc < w - 1 &&
            grid[nr][nc] == CellType.path) {
          final np = GridPosition(nr, nc);
          if (!cameFrom.containsKey(np)) {
            cameFrom[np] = cur;
            q.add(np);
          }
        }
      }
    }

    if (!cameFrom.containsKey(goal)) return [start];

    final path = <GridPosition>[];
    GridPosition? cur = goal;
    while (cur != null) {
      path.insert(0, cur);
      cur = cameFrom[cur];
    }
    return path;
  }
}
