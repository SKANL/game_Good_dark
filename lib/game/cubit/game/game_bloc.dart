import 'package:bloc/bloc.dart';
import 'package:echo_world/game/cubit/checkpoint/cubit.dart';
import 'package:echo_world/game/cubit/game/game_event.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc({required this.checkpointBloc}) : super(GameState.initial()) {
    on<EnfoqueCambiado>(_onEnfoqueCambiado);
    on<GritoActivado>(_onGrito);
    on<ModoSigiloActivado>(
      (e, emit) => emit(state.copyWith(estaAgachado: true)),
    );
    on<ModoSigiloDesactivado>(
      (e, emit) => emit(state.copyWith(estaAgachado: false)),
    );
    on<AbsorcionConfirmada>(_onAbsorcion);
    on<JuegoPausado>(
      (e, emit) => emit(state.copyWith(estadoJuego: EstadoJuego.pausado)),
    );
    on<JuegoReanudado>(
      (e, emit) => emit(state.copyWith(estadoJuego: EstadoJuego.jugando)),
    );
    on<ReinicioSolicitado>(_onReinicio);
    on<JugadorAtrapado>(_onJugadorAtrapado);
    on<RechazoSonicoActivado>(_onRechazo);
    on<EcoNarrativoAbsorbido>(_onEcoNarrativo);
    on<ColisionConNucleoIniciada>(
      (e, emit) => emit(state.copyWith(puedeAbsorber: true)),
    );
    on<ColisionConNucleoTerminada>(
      (e, emit) => emit(state.copyWith(puedeAbsorber: false)),
    );
    on<SobrecargaSensorialActivada>(
      (e, emit) => emit(state.copyWith(sobrecargaActiva: true)),
    );
    on<SobrecargaSensorialDesactivada>(
      (e, emit) => emit(state.copyWith(sobrecargaActiva: false)),
    );
    on<AgoniaResonanteActivada>(
      (e, emit) => emit(state.copyWith(agoniaActiva: true)),
    );
    on<AgoniaResonanteDesactivada>(
      (e, emit) => emit(state.copyWith(agoniaActiva: false)),
    );
  }

  final CheckpointBloc checkpointBloc;

  void _onEnfoqueCambiado(EnfoqueCambiado event, Emitter<GameState> emit) {
    // Ciclo principal: TopDown -> SideScroll -> FirstPerson -> TopDown
    // OBSOLETO: El modo 'scan' no entra en el ciclo por defecto.
    final next = {
      Enfoque.topDown: Enfoque.sideScroll,
      Enfoque.sideScroll: Enfoque.firstPerson,
      Enfoque.firstPerson: Enfoque.topDown,
      // Enfoque.scan: Enfoque.topDown,
    }[state.enfoqueActual]!;
    emit(state.copyWith(enfoqueActual: next));
  }

  void _onGrito(GritoActivado event, Emitter<GameState> emit) {
    const cost = 40;
    if (state.energiaGrito >= cost) {
      emit(state.copyWith(energiaGrito: state.energiaGrito - cost));
    }
  }

  void _onAbsorcion(AbsorcionConfirmada event, Emitter<GameState> emit) {
    // +50 energia, +3 ruido
    final energia = (state.energiaGrito + 50).clamp(0, 100);
    final ruido = (state.ruidoMental + 3).clamp(0, 100);
    emit(
      state.copyWith(
        energiaGrito: energia,
        ruidoMental: ruido,
        puedeAbsorber: false,
      ),
    );
  }

  void _onReinicio(ReinicioSolicitado event, Emitter<GameState> emit) {
    // Determinar energía inicial basada en Misericordia
    final energiaInicial = event.conMisericordia ? 50 : 40;

    // Reiniciar el juego manteniendo el ruidoMental (es permanente)
    emit(
      GameState.initial().copyWith(
        ruidoMental: state.ruidoMental,
        energiaGrito: energiaInicial,
      ),
    );
  }

  void _onJugadorAtrapado(JugadorAtrapado event, Emitter<GameState> emit) {
    // Registrar la muerte en el CheckpointBloc
    checkpointBloc.add(const MuerteRegistrada());

    // Cambiar el estado a atrapado (Game Over)
    emit(state.copyWith(estadoJugador: EstadoJugador.atrapado));
  }

  void _onRechazo(RechazoSonicoActivado event, Emitter<GameState> emit) {
    final energia = state.energiaGrito - event.energiaConsumida;
    emit(state.copyWith(energiaGrito: energia.clamp(0, 100)));
  }

  void _onEcoNarrativo(EcoNarrativoAbsorbido event, Emitter<GameState> emit) {
    final ruido = (state.ruidoMental + event.costeRuido).clamp(0, 100);
    emit(state.copyWith(ruidoMental: ruido));
  }
}
