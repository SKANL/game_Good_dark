import 'package:equatable/equatable.dart';

/// Estado del lore desbloqueado por el jugador.
/// Persiste via HydratedBloc para mantener progreso entre sesiones.
class LoreState extends Equatable {
  const LoreState({
    required this.ecosDesbloqueados,
    required this.primeraSesion,
  });

  factory LoreState.initial() {
    return const LoreState(
      ecosDesbloqueados: {},
      primeraSesion: true,
    );
  }

  /// Reconstruye el estado desde JSON
  factory LoreState.fromJson(Map<String, dynamic> json) {
    return LoreState(
      ecosDesbloqueados: Set<String>.from(json['ecosDesbloqueados'] as List),
      primeraSesion: json['primeraSesion'] as bool,
    );
  }

  /// IDs de Ecos Narrativos que el jugador ha descubierto
  final Set<String> ecosDesbloqueados;

  /// Flag para saber si debe mostrarse la intro
  final bool primeraSesion;

  LoreState copyWith({
    Set<String>? ecosDesbloqueados,
    bool? primeraSesion,
  }) {
    return LoreState(
      ecosDesbloqueados: ecosDesbloqueados ?? this.ecosDesbloqueados,
      primeraSesion: primeraSesion ?? this.primeraSesion,
    );
  }

  /// Convierte el estado a JSON para persistencia
  Map<String, dynamic> toJson() {
    return {
      'ecosDesbloqueados': ecosDesbloqueados.toList(),
      'primeraSesion': primeraSesion,
    };
  }

  @override
  List<Object?> get props => [ecosDesbloqueados, primeraSesion];
}
