import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/fuga_cubit.dart';
import '../cubit/fuga_state.dart';
import '../models/models.dart';

class FugaView extends StatefulWidget {
  const FugaView({super.key});

  @override
  State<FugaView> createState() => _FugaViewState();
}

class _FugaViewState extends State<FugaView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _showLore(context));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showLore(BuildContext context) {
    final state = context.read<FugaCubit>().state;
    if (state.gameStatus == GameStatus.lore) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Justificación de la Simulación',
            style: TextStyle(color: Colors.white),
          ),
          content: const SingleChildScrollView(
            child: Text(
              'Las instalaciones de Aethel no solo eran un laboratorio, sino un campo de entrenamiento.\n\n'
              'Este juego es una recreación de esas pruebas, una simulación diseñada para medir la adaptabilidad bajo condiciones de incertidumbre.\n\n'
              'Tu movimiento es incierto (dado). Tu habilidad de Ecolocalización puede revelar momentáneamente la presencia de la Resonancia y la salida, pero su uso es limitado y revela tanto peligro como posibilidad. Actúa con cautela, Sujeto 7.',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.read<FugaCubit>().startGame();
                Navigator.of(context).pop();
              },
              child: const Text(
                'COMENZAR',
                style: TextStyle(color: Colors.tealAccent),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FugaCubit, FugaState>(
      listenWhen: (previous, current) =>
          previous.gameStatus != current.gameStatus &&
          (current.gameStatus == GameStatus.win ||
              current.gameStatus == GameStatus.lose),
      listener: (context, state) {
        final message =
            state.resultMessage ??
            (state.gameStatus == GameStatus.win
                ? '!HAZ LOGRADO ESCAPAR DE LA CRIATURA¡'
                : '!TEAN ATRAPADO YA NO QUEDA ESPERANZA PARA TI¡');

        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              state.gameStatus == GameStatus.win ? 'Victoria' : 'Derrota',
              style: TextStyle(
                color: state.gameStatus == GameStatus.win
                    ? Colors.tealAccent
                    : Colors.redAccent,
              ),
            ),
            content: Text(message, style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () {
                  context.read<FugaCubit>().restartGame();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'REINICIAR',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Exit minigame
                },
                child: const Text(
                  'SALIR',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildHeader(),
              const SizedBox(height: 8),
              Expanded(child: _buildBoard(context)),
              _buildBottomPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<FugaCubit, FugaState>(
      builder: (context, state) {
        final isPlayerTurn = state.currentTurn == GameTurn.player;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ECO NEGRO',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isPlayerTurn
                      ? Colors.tealAccent.shade700
                      : Colors.redAccent.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPlayerTurn ? 'Sujeto 7' : 'La Resonancia',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBoard(BuildContext context) {
    return BlocBuilder<FugaCubit, FugaState>(
      builder: (context, state) {
        // Assuming mazeWidth is available or we can get it from state.maze.length
        final gridSize = state.maze.isNotEmpty ? state.maze[0].length : 21;
        final screenWidth = MediaQuery.of(context).size.width;
        final boardSize = min(
          screenWidth - 12,
          MediaQuery.of(context).size.height * 0.68,
        );
        final cellSize = boardSize / gridSize;

        return Center(
          child: Container(
            color: Colors.transparent,
            width: boardSize,
            height: boardSize,
            child: InteractiveViewer(
              maxScale: 4.0,
              minScale: 0.5,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize,
                  childAspectRatio: 1,
                ),
                itemCount: gridSize * gridSize,
                itemBuilder: (context, index) {
                  final row = index ~/ gridSize;
                  final col = index % gridSize;

                  // Safety check
                  if (row >= state.maze.length || col >= state.maze[0].length)
                    return const SizedBox.shrink();

                  final cell = state.maze[row][col];
                  final pos = GridPosition(row, col);

                  final isWall = cell == CellType.wall;
                  final isPlayer = pos == state.playerPos;
                  final isEnemy =
                      pos == state.enemyPos &&
                      (state.currentTurn == GameTurn.enemy || state.echoActive);
                  final isExit = pos == state.exitPos && state.echoActive;
                  final isPossible =
                      state.possibleMoves.contains(pos) &&
                      state.currentTurn == GameTurn.player &&
                      state.turnPhase == TurnPhase.moving;

                  Color bg = isWall ? Colors.grey[850]! : Colors.grey[800]!;
                  Widget content = const SizedBox.shrink();

                  if (isExit) {
                    content = Container(
                      width: cellSize * 0.6,
                      height: cellSize * 0.6,
                      decoration: BoxDecoration(
                        color: Colors.tealAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  } else if (isPlayer) {
                    content = Container(
                      width: cellSize * 0.6,
                      height: cellSize * 0.6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.tealAccent,
                      ),
                    );
                  } else if (isEnemy) {
                    content = Container(
                      width: cellSize * 0.6,
                      height: cellSize * 0.6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent,
                      ),
                    );
                  }

                  return GestureDetector(
                    onTap: () {
                      if (isPossible) {
                        context.read<FugaCubit>().movePlayer(pos);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        border: Border.all(color: Colors.black87, width: 0.25),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isPossible)
                            FadeTransition(
                              opacity: Tween<double>(
                                begin: 0.4,
                                end: 0.9,
                              ).animate(_pulseController),
                              child: Container(
                                color: Colors.lightBlue.withValues(alpha: 0.28),
                              ),
                            ),
                          content,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomPanel() {
    return BlocBuilder<FugaCubit, FugaState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: Colors.grey[900],
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dice
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          state.diceResult == 0
                              ? '-'
                              : state.diceResult.toString(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: SizedBox(
                        width:
                            120, // Give it a fixed width inside FittedBox/Row
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                textStyle: const TextStyle(fontSize: 14),
                                backgroundColor: Colors.grey[800],
                                foregroundColor: Colors.white,
                              ),
                              onPressed:
                                  state.currentTurn == GameTurn.player &&
                                      state.turnPhase == TurnPhase.rolling
                                  ? () => context.read<FugaCubit>().rollDice()
                                  : null,
                              child: const Text(
                                'Lanzar Dado',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.tealAccent.shade700,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              onPressed:
                                  state.currentTurn == GameTurn.player &&
                                      state.echoCharges >= 6
                                  ? () =>
                                        context.read<FugaCubit>().activateEcho()
                                  : null,
                              child: Text(
                                'Echo (${state.echoCharges}/6)',
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Turn/pass info
                    SizedBox(
                      width: 85,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              color: state.currentTurn == GameTurn.player
                                  ? Colors.tealAccent.shade700
                                  : Colors.redAccent.shade700,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              state.currentTurn == GameTurn.player
                                  ? 'Sujeto 7'
                                  : 'Resonancia',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (state.turnPhase == TurnPhase.moving &&
                              state.currentTurn == GameTurn.player)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                                textStyle: const TextStyle(fontSize: 10),
                              ),
                              onPressed: () =>
                                  context.read<FugaCubit>().passTurn(),
                              child: const Text(
                                'Pasar',
                                style: TextStyle(fontFamily: 'monospace'),
                              ),
                            )
                          else
                            const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Status / hints
                SizedBox(
                  width: 300, // Constrain width for the status row
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Echo: ${state.echoActive ? 'ACTIVA' : 'INACTIVA'}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: state.echoActive
                                ? Colors.tealAccent
                                : Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'Fichas: Enemigo & Salida',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
