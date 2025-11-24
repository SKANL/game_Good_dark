import 'dart:math';

import 'package:echo_world/game/black_echo_game.dart';
import 'package:echo_world/game/cubit/game/game_bloc.dart';
import 'package:echo_world/game/cubit/game/game_event.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:flame/components.dart';

/// Sistema de penalizaciones por ruido mental.
/// Escucha el GameBloc y aplica efectos progresivos según umbrales.
///
/// Umbrales:
/// - > 25: Distorsión Auditiva (estímulos falsos)
/// - > 50: Sobrecarga Sensorial ([ECO] aumenta ruido)
/// - > 75: Agonía Resonante (enemigos con radio aumentado)
/// - == 100: Colapso (Game Over)
class RuidoMentalSystemComponent extends Component
    with HasGameRef<BlackEchoGame> {
  RuidoMentalSystemComponent({required this.gameBloc});

  final GameBloc gameBloc;
  final Random _rng = Random();
  double _falsoEstimuloTimer = 0;
  static const double _falsoEstimuloInterval = 8; // Cada 8 segundos

  // Flags para rastrear threshold activations
  bool _sobrecargaActiva = false;
  bool _agoniaActiva = false;

  @override
  void update(double dt) {
    super.update(dt);

    final state = gameBloc.state;

    // Penalización 1: Distorsión Auditiva (> 25)
    if (state.ruidoMental > 25) {
      _falsoEstimuloTimer += dt;
      if (_falsoEstimuloTimer >= _falsoEstimuloInterval) {
        _falsoEstimuloTimer = 0.0;
        _generarEstimuloFalso();
      }
    }

    // Penalización 2: Sobrecarga Sensorial (> 50)
    // Cuando el jugador usa ECO, genera más ruido mental
    if (state.ruidoMental > 50 && !_sobrecargaActiva) {
      _sobrecargaActiva = true;
      gameBloc.add(SobrecargaSensorialActivada());
    } else if (state.ruidoMental <= 50 && _sobrecargaActiva) {
      _sobrecargaActiva = false;
      gameBloc.add(SobrecargaSensorialDesactivada());
    }

    // Penalización 3: Agonía Resonante (> 75)
    // Enemigos tienen radio auditivo aumentado (el HearingBehavior lee el GameState)
    if (state.ruidoMental > 75 && !_agoniaActiva) {
      _agoniaActiva = true;
      gameBloc.add(AgoniaResonanteActivada());
    } else if (state.ruidoMental <= 75 && _agoniaActiva) {
      _agoniaActiva = false;
      gameBloc.add(AgoniaResonanteDesactivada());
    }

    // Penalización 4: Colapso (== 100)
    if (state.ruidoMental >= 100) {
      gameBloc.add(JugadorAtrapado());
    }
  }

  void _generarEstimuloFalso() {
    // Generar un estímulo bajo en una posición aleatoria cerca del jugador
    final player = gameRef.player;
    final offset = Vector2(
      (_rng.nextDouble() - 0.5) * 400, // ±200px
      (_rng.nextDouble() - 0.5) * 400,
    );
    final posicionFalsa = player.position + offset;

    // Emitir sonido falso que confunde a los enemigos
    gameRef.emitSound(posicionFalsa, NivelSonido.bajo, ttl: 0.5);
  }
}
