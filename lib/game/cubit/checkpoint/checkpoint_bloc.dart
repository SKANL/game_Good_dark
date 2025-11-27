import 'package:echo_world/game/cubit/checkpoint/checkpoint_event.dart';
import 'package:echo_world/game/cubit/checkpoint/checkpoint_state.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// BLoC que gestiona el sistema de checkpoints y el tracking de muertes.
/// Usa HydratedBloc para persistir el estado entre sesiones.
class CheckpointBloc extends HydratedBloc<CheckpointEvent, CheckpointState> {
  CheckpointBloc() : super(CheckpointState.initial()) {
    on<ChunkCambiado>(_onChunkCambiado);
    on<MuerteRegistrada>(_onMuerteRegistrada);
    on<CheckpointReseteado>(_onCheckpointReseteado);
  }

  void _onChunkCambiado(ChunkCambiado event, Emitter<CheckpointState> emit) {
    // Auto-save: actualizar el chunk actual
    emit(state.copyWith(chunkActual: event.nuevoChunkId));
  }

  void _onMuerteRegistrada(
    MuerteRegistrada event,
    Emitter<CheckpointState> emit,
  ) {
    // Incrementar contador de muertes en el chunk actual
    final chunkId = state.chunkActual;
    final muertesActuales = state.muertesPorChunk[chunkId] ?? 0;
    final nuevoMapa = Map<int, int>.from(state.muertesPorChunk);
    nuevoMapa[chunkId] = muertesActuales + 1;

    emit(
      state.copyWith(
        muertesPorChunk: nuevoMapa,
        totalMuertes: state.totalMuertes + 1,
      ),
    );
  }

  void _onCheckpointReseteado(
    CheckpointReseteado event,
    Emitter<CheckpointState> emit,
  ) {
    // Reiniciar todo el estado (nueva partida)
    emit(CheckpointState.initial());
  }

  @override
  CheckpointState? fromJson(Map<String, dynamic> json) {
    try {
      return CheckpointState.fromJson(json);
    } catch (_) {
      return null; // Si falla la deserialización, usar estado inicial
    }
  }

  @override
  Map<String, dynamic>? toJson(CheckpointState state) {
    try {
      return state.toJson();
    } catch (_) {
      return null; // Si falla la serialización, no persistir
    }
  }
}
