import 'package:equatable/equatable.dart';

// Perspectiva de juego actual
// OBSOLETO: 'scan' se mantiene por compatibilidad pero no se usa por defecto.
enum Enfoque {
  topDown,
  sideScroll,
  firstPerson,
  @deprecated
  scan,
}

// Condición de supervivencia del jugador
enum EstadoJugador { vivo, atrapado }

// Estado del motor de juego
enum EstadoJuego { jugando, pausado }

class GameState extends Equatable {
  const GameState({
    required this.energiaGrito,
    required this.ruidoMental,
    required this.enfoqueActual,
    required this.estadoJugador,
    required this.estadoJuego,
    required this.estaAgachado,
    required this.puedeAbsorber,
    required this.sobrecargaActiva,
    required this.agoniaActiva,
  });
  // ruidoMental > 75

  factory GameState.initial() {
    return const GameState(
      energiaGrito: 40,
      ruidoMental: 0,
      enfoqueActual: Enfoque.topDown,
      estadoJugador: EstadoJugador.vivo,
      estadoJuego: EstadoJuego.jugando,
      estaAgachado: false,
      puedeAbsorber: false,
      sobrecargaActiva: false,
      agoniaActiva: false,
    );
  }

  final int energiaGrito;
  final int ruidoMental;
  final Enfoque enfoqueActual;
  final EstadoJugador estadoJugador;
  final EstadoJuego estadoJuego;
  final bool estaAgachado;
  final bool puedeAbsorber;
  final bool sobrecargaActiva; // ruidoMental > 50
  final bool agoniaActiva;

  GameState copyWith({
    int? energiaGrito,
    int? ruidoMental,
    Enfoque? enfoqueActual,
    EstadoJugador? estadoJugador,
    EstadoJuego? estadoJuego,
    bool? estaAgachado,
    bool? puedeAbsorber,
    bool? sobrecargaActiva,
    bool? agoniaActiva,
  }) {
    return GameState(
      energiaGrito: energiaGrito ?? this.energiaGrito,
      ruidoMental: ruidoMental ?? this.ruidoMental,
      enfoqueActual: enfoqueActual ?? this.enfoqueActual,
      estadoJugador: estadoJugador ?? this.estadoJugador,
      estadoJuego: estadoJuego ?? this.estadoJuego,
      estaAgachado: estaAgachado ?? this.estaAgachado,
      puedeAbsorber: puedeAbsorber ?? this.puedeAbsorber,
      sobrecargaActiva: sobrecargaActiva ?? this.sobrecargaActiva,
      agoniaActiva: agoniaActiva ?? this.agoniaActiva,
    );
  }

  @override
  List<Object?> get props => [
    energiaGrito,
    ruidoMental,
    enfoqueActual,
    estadoJugador,
    estadoJuego,
    estaAgachado,
    puedeAbsorber,
    sobrecargaActiva,
    agoniaActiva,
  ];
}
