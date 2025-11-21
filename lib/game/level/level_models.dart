import 'dart:ui';
import 'package:flame/components.dart';

enum TipoCelda { pared, suelo, abismo }

enum Direccion { norte, sur, este, oeste }

enum NivelSonido { bajo, medio, alto, nulo }

/// Dificultad del chunk para el generador procedural
enum Dificultad { tutorial, baja, media, alta }

/// Sector temático del chunk (para progresión narrativa)
enum Sector { contencion, laboratorios, salida }

class EstimuloDeSonido {
  EstimuloDeSonido({
    required this.posicion,
    required this.nivel,
    this.ttl = 1.0,
  });
  final Vector2 posicion;
  final NivelSonido nivel;
  double ttl; // segundos restantes
}

typedef Grid = List<List<CeldaData>>;

class CeldaData {
  const CeldaData({
    required this.tipo,
    this.altura = 0.0,
    this.esDestructible = false,
    this.ecoNarrativoId,
  });
  final TipoCelda tipo;
  final double altura;
  final bool esDestructible;
  final String? ecoNarrativoId;

  static const CeldaData pared = CeldaData(tipo: TipoCelda.pared);
  static const CeldaData suelo = CeldaData(tipo: TipoCelda.suelo);
  static const CeldaData abismo = CeldaData(tipo: TipoCelda.abismo);
}

class EntidadSpawn {
  const EntidadSpawn({required this.tipoEnemigo, required this.posicion});
  final Type tipoEnemigo;
  final Vector2 posicion;
}

abstract class LevelData {
  // Para debugging

  const LevelData({
    required this.ancho,
    required this.alto,
    required this.grid,
    this.entidadesIniciales = const [],
    this.puntosDeConexion = const {},
    this.dificultad = Dificultad.tutorial,
    this.sector = Sector.contencion,
    this.nombre = 'Chunk Sin Nombre',
    this.spawnPoint,
    this.exitPoint,
    this.exitHint,
    this.ambientLight,
    this.fogColor,
  });
  final int ancho;
  final int alto;
  final Grid grid;
  final List<EntidadSpawn> entidadesIniciales;
  final Map<Direccion, Vector2> puntosDeConexion;

  // Metadata para generador procedural
  final Dificultad dificultad;
  final Sector sector;
  final String nombre;

  // New fields for procedural generation safety and lore
  final Vector2? spawnPoint;
  final Vector2? exitPoint;
  final String? exitHint;

  // Visual atmosphere
  final Color? ambientLight;
  final Color? fogColor;
}
