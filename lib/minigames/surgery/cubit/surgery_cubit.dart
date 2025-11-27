import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:echo_world/minigames/surgery/entities/nerve_model.dart';
import 'package:echo_world/minigames/surgery/services/mock_gemini_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:echo_world/common/services/haptic_service.dart';

part 'surgery_state.dart';

class SurgeryCubit extends Cubit<SurgeryState> {
  SurgeryCubit() : super(const SurgeryState()) {
    _startGame();
  }
  final MockGeminiService _geminiService = MockGeminiService();
  Timer? _timer;

  Future<void> _startGame() async {
    emit(
      state.copyWith(
        gameStatus: GameStatus.loading,
        isLaserCharged: false,
        clearSelectedNerve: true,
        timeRemaining: 60,
      ),
    );

    // Load local descriptions and hotspots
    try {
      // Note: In a real app, inject this dependency or move to repository
      final raw = await rootBundle.loadString(
        'assets/minigames/surgery/descripciones.json',
      );
      final parsed = json.decode(raw) as Map<String, dynamic>;

      final senseMap = <String, List<String>>{};
      if (parsed.containsKey('senses')) {
        final senses = parsed['senses'] as Map<String, dynamic>;
        senses.forEach((key, value) {
          if (value is List) {
            senseMap[key] = value.map((e) => e.toString()).toList();
          }
        });
      }

      final tmp = <Nerve>[];
      if (parsed.containsKey('hotspots')) {
        final list = parsed['hotspots'] as List<dynamic>;

        final fixedPositions = <Map<String, double>>[
          {'x': 0.28, 'y': 0.18},
          {'x': 0.52, 'y': 0.12},
          {'x': 0.74, 'y': 0.22},
          {'x': 0.32, 'y': 0.44},
          {'x': 0.70, 'y': 0.68},
        ];

        fixedPositions.shuffle();

        for (var i = 0; i < list.length; i++) {
          final item = list[i];
          if (item is Map<String, dynamic>) {
            final id = item['id'] as String? ?? 'h_unknown_$i';
            final titulo = item['titulo'] as String? ?? 'Nervio ${i + 1}';
            final sentido = item['sentido'] as String? ?? 'unknown';

            var chosenDesc = 'Descripción no disponible.';
            if (senseMap.containsKey(sentido) &&
                senseMap[sentido]!.isNotEmpty) {
              final listDesc = List<String>.from(senseMap[sentido]!);
              listDesc.shuffle();
              chosenDesc = listDesc.first;
            }

            final pos = fixedPositions[i % fixedPositions.length];
            final posX = pos['x']!;
            final posY = pos['y']!;

            tmp.add(
              Nerve(
                id: id,
                name: titulo,
                description: chosenDesc,
                isVital: false,
                sense: sentido,
                posX: posX,
                posY: posY,
              ),
            );
          }
        }
      }

      var nerves = tmp;
      if (nerves.length > 5) nerves = nerves.sublist(0, 5);

      for (var i = 0; i < nerves.length; i++) {
        nerves[i].isTarget = (nerves[i].sense == 'vision');
      }

      emit(state.copyWith(nerves: nerves, gameStatus: GameStatus.playing));
    } catch (e) {
      final nerves = await _geminiService.fetchNerveData();
      emit(state.copyWith(nerves: nerves, gameStatus: GameStatus.playing));
    }

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeRemaining > 0) {
        emit(state.copyWith(timeRemaining: state.timeRemaining - 1));
      } else {
        _endGame(false, "Time is up. The patient's neural cascade failed.");
      }
    });
  }

  void selectNerve(Nerve nerve) {
    if (state.gameStatus != GameStatus.playing) return;
    emit(state.copyWith(selectedNerve: nerve));
  }

  void chargeLaser() {
    if (state.gameStatus != GameStatus.playing || state.selectedNerve == null) {
      return;
    }
    emit(state.copyWith(isLaserCharged: true));
    HapticService.mediumImpact();
  }

  void cutNerve() {
    if (state.gameStatus != GameStatus.playing ||
        !state.isLaserCharged ||
        state.selectedNerve == null) {
      return;
    }

    final selected = state.selectedNerve!;
    emit(state.copyWith(isLaserCharged: false));
    HapticService.heavyImpact();

    if (selected.isTarget) {
      selected.isCut = true;
      // Update the nerve in the list
      final updatedNerves = List<Nerve>.from(state.nerves);
      final index = updatedNerves.indexWhere((n) => n.id == selected.id);
      if (index != -1) {
        updatedNerves[index] = selected;
      }

      emit(
        state.copyWith(
          nerves: updatedNerves,
          clearSelectedNerve: true,
        ),
      );
      _endGame(true, 'Corte correcto. Entrada visual anulada permanentemente.');
      return;
    }

    final sense = selected.sense.toLowerCase();
    emit(state.copyWith(clearSelectedNerve: true));
    _endGame(
      false,
      'ERROR QUIRÚRGICO\nPÉRDIDA DE: EL SUJETO HA PERDIDO EL ${sense.toUpperCase()}',
    );
  }

  void _endGame(bool success, String message) {
    _timer?.cancel();
    emit(
      state.copyWith(
        gameStatus: success ? GameStatus.success : GameStatus.failure,
        endGameMessage: message,
      ),
    );
  }

  void advanceSubject() {
    var nextNum = state.subjectNumber;
    var nextLetter = state.subjectLetter;

    if (nextNum < 9) {
      nextNum++;
    } else {
      nextNum = 1;
      final code = nextLetter.codeUnitAt(0);
      if (code >= 65 && code < 90) {
        nextLetter = String.fromCharCode(code + 1);
      } else {
        nextLetter = 'A';
      }
    }
    emit(state.copyWith(subjectNumber: nextNum, subjectLetter: nextLetter));
  }

  void nextSubjectAndRestart() {
    advanceSubject();
    _startGame();
  }

  void restartGame() {
    _startGame();
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
