import 'package:equatable/equatable.dart';

class CheckpointState extends Equatable {
  const CheckpointState({
    required this.chunkActual,
    required this.muertesPorChunk,
    required this.totalMuertes,
  });

  factory CheckpointState.initial() {
    return const CheckpointState(
      chunkActual: 0,
      muertesPorChunk: {},
      totalMuertes: 0,
    );
  }

  factory CheckpointState.fromJson(Map<String, dynamic> json) {
    return CheckpointState(
      chunkActual: json['chunkActual'] as int? ?? 0,
      muertesPorChunk:
          (json['muertesPorChunk'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), v as int),
          ) ??
          {},
      totalMuertes: json['totalMuertes'] as int? ?? 0,
    );
  }

  /// Identificador del chunk actual
  final int chunkActual;

  /// Mapa de muertes por chunk: {chunkId: cantidadMuertes}
  final Map<int, int> muertesPorChunk;

  /// Total acumulado de muertes en toda la partida
  final int totalMuertes;

  CheckpointState copyWith({
    int? chunkActual,
    Map<int, int>? muertesPorChunk,
    int? totalMuertes,
  }) {
    return CheckpointState(
      chunkActual: chunkActual ?? this.chunkActual,
      muertesPorChunk: muertesPorChunk ?? Map.from(this.muertesPorChunk),
      totalMuertes: totalMuertes ?? this.totalMuertes,
    );
  }

  /// Obtiene el número de muertes en el chunk actual
  int get muertesEnChunkActual => muertesPorChunk[chunkActual] ?? 0;

  /// Determina si se debe activar el sistema de Misericordia
  /// (4ta muerte en el mismo chunk otorga escudo gratis)
  bool get debeActivarMisericordia => muertesEnChunkActual >= 3;

  Map<String, dynamic> toJson() {
    return {
      'chunkActual': chunkActual,
      'muertesPorChunk': muertesPorChunk.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'totalMuertes': totalMuertes,
    };
  }

  @override
  List<Object?> get props => [chunkActual, muertesPorChunk, totalMuertes];
}
