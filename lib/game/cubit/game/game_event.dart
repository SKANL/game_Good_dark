import 'package:equatable/equatable.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();
  @override
  List<Object?> get props => [];
}

class EnfoqueCambiado extends GameEvent {}

class GritoActivado extends GameEvent {}

class ModoSigiloActivado extends GameEvent {}

class ModoSigiloDesactivado extends GameEvent {}

class AbsorcionConfirmada extends GameEvent {}

class JuegoPausado extends GameEvent {}

class JuegoReanudado extends GameEvent {}

/// Evento para reiniciar el juego después de una muerte
class ReinicioSolicitado extends GameEvent {
  const ReinicioSolicitado({this.conMisericordia = false});

  /// Si es true, el jugador reinicia con energiaGrito: 50 (escudo gratis)
  final bool conMisericordia;

  @override
  List<Object?> get props => [conMisericordia];
}

// Eventos desde el motor (Flame)
class EcoActivado extends GameEvent {}

class JugadorAtrapado extends GameEvent {}

class RechazoSonicoActivado extends GameEvent {
  const RechazoSonicoActivado(this.energiaConsumida);
  final int energiaConsumida; // 50
  @override
  List<Object?> get props => [energiaConsumida];
}

class EcoNarrativoAbsorbido extends GameEvent {
  const EcoNarrativoAbsorbido(this.ecoId, this.costeRuido);
  final String ecoId;
  final int costeRuido; // 1
  @override
  List<Object?> get props => [ecoId, costeRuido];
}

class ColisionConNucleoIniciada extends GameEvent {}

class ColisionConNucleoTerminada extends GameEvent {}

// Eventos de penalidades de ruido mental
class SobrecargaSensorialActivada extends GameEvent {}

class SobrecargaSensorialDesactivada extends GameEvent {}

class AgoniaResonanteActivada extends GameEvent {}

class AgoniaResonanteDesactivada extends GameEvent {}

class EnergiaRegenerada extends GameEvent {
  const EnergiaRegenerada(this.cantidad);
  final int cantidad;
  @override
  List<Object?> get props => [cantidad];
}
