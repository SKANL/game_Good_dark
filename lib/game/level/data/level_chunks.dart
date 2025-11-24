import 'package:echo_world/game/entities/enemies/cazador.dart';
import 'package:echo_world/game/entities/enemies/vigia.dart';
import 'package:echo_world/game/entities/enemies/bruto.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:flame/components.dart';

/// Chunk inicial seguro - Tutorial básico
/// Dimensiones: 15x10 tiles
/// Sin enemigos, espacio abierto con paredes perimétricas
class ChunkInicioSeguro extends LevelData {
  ChunkInicioSeguro()
    : super(
        ancho: 15,
        alto: 10,
        nombre: 'Inicio Seguro',
        dificultad: Dificultad.tutorial,
        sector: Sector.contencion,
        grid: _buildGrid(),
        entidadesIniciales: [], // Sin enemigos
        puntosDeConexion: {
          Direccion.este: Vector2(14.5, 5), // Salida al este
          Direccion.oeste: Vector2(0.5, 5), // Entrada desde oeste
        },
      );

  static Grid _buildGrid() {
    final grid = <List<CeldaData>>[];
    for (var y = 0; y < 10; y++) {
      final row = <CeldaData>[];
      for (var x = 0; x < 15; x++) {
        // Paredes perimetrales
        if (y == 0 || y == 9 || x == 0 || x == 14) {
          row.add(CeldaData.pared);
        } else {
          // Espacio abierto interior
          row.add(CeldaData.suelo);
        }
      }
      grid.add(row);
    }
    return grid;
  }
}

/// Chunk Abismo - Requiere salto lateral
/// Dimensiones: 20x12 tiles
/// Abismo central que obliga a usar enfoque lateral para detectar plataformas
class ChunkAbismoSalto extends LevelData {
  ChunkAbismoSalto()
    : super(
        ancho: 20,
        alto: 12,
        nombre: 'Abismo del Salto',
        dificultad: Dificultad.baja,
        sector: Sector.contencion,
        grid: _buildGrid(),
        entidadesIniciales: [
          // 1 Vigía patrullando la zona de entrada
          EntidadSpawn(
            tipoEnemigo: VigiaComponent,
            posicion: Vector2(3, 6),
          ),
        ],
        puntosDeConexion: {
          Direccion.este: Vector2(19.5, 6),
          Direccion.oeste: Vector2(0.5, 6),
        },
      );

  static Grid _buildGrid() {
    final grid = <List<CeldaData>>[];
    for (var y = 0; y < 12; y++) {
      final row = <CeldaData>[];
      for (var x = 0; x < 20; x++) {
        // Paredes perimetrales
        if (y == 0 || y == 11 || x == 0 || x == 19) {
          row.add(CeldaData.pared);
        }
        // Abismo central (columnas 8-11)
        else if (x >= 8 && x <= 11) {
          // Plataforma estrecha en el medio (fila 6)
          if (y == 6) {
            row.add(CeldaData.suelo);
          } else {
            row.add(CeldaData.abismo);
          }
        }
        // Zonas seguras a los lados
        else {
          row.add(CeldaData.suelo);
        }
      }
      grid.add(row);
    }
    return grid;
  }
}

/// Chunk Sigilo con Cazador - Combate básico
/// Dimensiones: 18x14 tiles
/// Pasillo con obstáculos destructibles, 2 Cazadores patrullando
class ChunkSigiloCazador extends LevelData {
  ChunkSigiloCazador()
    : super(
        ancho: 18,
        alto: 14,
        nombre: 'Sigilo del Cazador',
        dificultad: Dificultad.media,
        sector: Sector.laboratorios,
        grid: _buildGrid(),
        entidadesIniciales: [
          // Cazador #1: zona norte
          EntidadSpawn(
            tipoEnemigo: CazadorComponent,
            posicion: Vector2(6, 4),
          ),
          // Cazador #2: zona sur
          EntidadSpawn(
            tipoEnemigo: CazadorComponent,
            posicion: Vector2(12, 10),
          ),
        ],
        puntosDeConexion: {
          Direccion.este: Vector2(17.5, 7),
          Direccion.oeste: Vector2(0.5, 7),
        },
      );

  static Grid _buildGrid() {
    final grid = <List<CeldaData>>[];
    for (var y = 0; y < 14; y++) {
      final row = <CeldaData>[];
      for (var x = 0; x < 18; x++) {
        // Paredes perimetrales
        if (y == 0 || y == 13 || x == 0 || x == 17) {
          row.add(CeldaData.pared);
        }
        // Obstáculos destructibles (columnas internas)
        else if ((x == 5 || x == 12) && y > 2 && y < 11) {
          row.add(
            const CeldaData(
              tipo: TipoCelda.pared,
              esDestructible: true,
            ),
          );
        }
        // Corredor central
        else {
          row.add(CeldaData.suelo);
        }
      }
      grid.add(row);
    }
    return grid;
  }
}

/// Chunk Boss - Enfrentamiento con Bruto
/// Dimensiones: 25x18 tiles
/// Arena amplia con columnas no destructibles, 1 Bruto + 2 Vigías
class ChunkArenaBruto extends LevelData {
  ChunkArenaBruto()
    : super(
        ancho: 25,
        alto: 18,
        nombre: 'Arena del Bruto',
        dificultad: Dificultad.alta,
        sector: Sector.salida,
        grid: _buildGrid(),
        entidadesIniciales: [
          // Bruto en el centro
          EntidadSpawn(
            tipoEnemigo: BrutoComponent,
            posicion: Vector2(12.5, 9),
          ),
          // Vigía #1: esquina NE
          EntidadSpawn(
            tipoEnemigo: VigiaComponent,
            posicion: Vector2(20, 4),
          ),
          // Vigía #2: esquina SE
          EntidadSpawn(
            tipoEnemigo: VigiaComponent,
            posicion: Vector2(20, 14),
          ),
        ],
        puntosDeConexion: {
          Direccion.este: Vector2(24.5, 9),
          Direccion.oeste: Vector2(0.5, 9),
        },
      );

  static Grid _buildGrid() {
    final grid = <List<CeldaData>>[];
    for (var y = 0; y < 18; y++) {
      final row = <CeldaData>[];
      for (var x = 0; x < 25; x++) {
        // Paredes perimetrales
        if (y == 0 || y == 17 || x == 0 || x == 24) {
          row.add(CeldaData.pared);
        }
        // Columnas estructurales (no destructibles)
        else if ((x == 6 || x == 18) && (y == 6 || y == 12)) {
          row.add(
            const CeldaData(
              tipo: TipoCelda.pared,
            ),
          );
        }
        // Arena central
        else {
          row.add(CeldaData.suelo);
        }
      }
      grid.add(row);
    }
    return grid;
  }
}

/// Chunk Laberinto Vertical - Requiere enfoque top-down
/// Dimensiones: 16x20 tiles
/// Pasillo zigzag vertical con Cazadores escondidos
class ChunkLaberintoVertical extends LevelData {
  ChunkLaberintoVertical()
    : super(
        ancho: 16,
        alto: 20,
        nombre: 'Laberinto Vertical',
        dificultad: Dificultad.media,
        sector: Sector.laboratorios,
        grid: _buildGrid(),
        entidadesIniciales: [
          // Cazador en curva 1
          EntidadSpawn(
            tipoEnemigo: CazadorComponent,
            posicion: Vector2(4, 8),
          ),
          // Cazador en curva 2
          EntidadSpawn(
            tipoEnemigo: CazadorComponent,
            posicion: Vector2(12, 14),
          ),
          // Vigía en la salida
          EntidadSpawn(
            tipoEnemigo: VigiaComponent,
            posicion: Vector2(8, 18),
          ),
        ],
        puntosDeConexion: {
          Direccion.norte: Vector2(8, 0.5),
          Direccion.sur: Vector2(8, 19.5),
        },
      );

  static Grid _buildGrid() {
    final grid = <List<CeldaData>>[];
    for (var y = 0; y < 20; y++) {
      final row = <CeldaData>[];
      for (var x = 0; x < 16; x++) {
        // Paredes perimetrales
        if (y == 0 || y == 19 || x == 0 || x == 15) {
          row.add(CeldaData.pared);
        }
        // Zigzag: alternar paredes cada 5 filas
        else if ((y < 5 && x > 10) ||
            (y >= 5 && y < 10 && x < 5) ||
            (y >= 10 && y < 15 && x > 10) ||
            (y >= 15 && x < 5)) {
          row.add(CeldaData.pared);
        }
        // Corredor zigzag
        else {
          row.add(CeldaData.suelo);
        }
      }
      grid.add(row);
    }
    return grid;
  }
}

/// Chunk Vigía Test - Introducción al enemigo Vigía
class ChunkVigiaTest extends LevelData {
  ChunkVigiaTest()
    : super(
        ancho: 20,
        alto: 12,
        nombre: 'Vigía Test',
        dificultad: Dificultad.media,
        sector: Sector.laboratorios,
        grid: _buildGrid(),
        entidadesIniciales: [
          EntidadSpawn(
            tipoEnemigo: VigiaComponent,
            posicion: Vector2(15, 6),
          ),
          EntidadSpawn(
            tipoEnemigo: CazadorComponent,
            posicion: Vector2(8, 3),
          ),
        ],
      );

  static Grid _buildGrid() {
    final grid = <List<CeldaData>>[];
    for (var y = 0; y < 12; y++) {
      final row = <CeldaData>[];
      for (var x = 0; x < 20; x++) {
        if (y == 0 || y == 11 || x == 0 || x == 19) {
          row.add(CeldaData.pared);
        } else if (y == 6 && x >= 5 && x <= 7) {
          row.add(CeldaData.pared);
        } else if (x == 5 && y >= 6 && y <= 8) {
          row.add(CeldaData.pared);
        } else {
          row.add(CeldaData.suelo);
        }
      }
      grid.add(row);
    }
    return grid;
  }
}

/// Chunk Bruto Test - Introducción al enemigo Bruto
class ChunkBrutoTest extends LevelData {
  ChunkBrutoTest()
    : super(
        ancho: 22,
        alto: 14,
        nombre: 'Bruto Test',
        dificultad: Dificultad.alta,
        sector: Sector.salida,
        grid: _buildGrid(),
        entidadesIniciales: [
          EntidadSpawn(
            tipoEnemigo: BrutoComponent,
            posicion: Vector2(11, 10),
          ),
        ],
      );

  static Grid _buildGrid() {
    final grid = <List<CeldaData>>[];
    for (var y = 0; y < 14; y++) {
      final row = <CeldaData>[];
      for (var x = 0; x < 22; x++) {
        if (y == 0 || y == 13 || x == 0 || x == 21) {
          row.add(CeldaData.pared);
        } else if (y == 7 && x >= 8 && x <= 14) {
          row.add(const CeldaData(tipo: TipoCelda.pared, esDestructible: true));
        } else if (x == 11 && y >= 4 && y <= 6) {
          row.add(const CeldaData(tipo: TipoCelda.pared, esDestructible: true));
        } else {
          row.add(CeldaData.suelo);
        }
      }
      grid.add(row);
    }
    return grid;
  }
}

/// Chunk Corredor Emboscada
class ChunkCorredorEmboscada extends LevelData {
  ChunkCorredorEmboscada()
    : super(
        ancho: 24,
        alto: 12,
        nombre: 'Corredor Emboscada',
        dificultad: Dificultad.baja,
        sector: Sector.contencion,
        grid: _buildGrid(),
        entidadesIniciales: [
          EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(6, 6)),
          EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(18, 6)),
        ],
      );

  static Grid _buildGrid() {
    final grid = <List<CeldaData>>[];
    for (var y = 0; y < 12; y++) {
      final row = <CeldaData>[];
      for (var x = 0; x < 24; x++) {
        if (y == 0 || y == 11 || x == 0 || x == 23) {
          row.add(CeldaData.pared);
        } else if ((x == 8 || x == 16) && y >= 4 && y <= 7) {
          row.add(CeldaData.pared);
        } else if (x == 12 && (y == 3 || y == 8)) {
          row.add(CeldaData.pared);
        } else {
          row.add(CeldaData.suelo);
        }
      }
      grid.add(row);
    }
    return grid;
  }
}

/// Chunk Sala Segura
class ChunkSalaSegura extends LevelData {
  ChunkSalaSegura()
    : super(
        ancho: 16,
        alto: 10,
        nombre: 'Sala Segura',
        dificultad: Dificultad.tutorial,
        sector: Sector.contencion,
        grid: _buildGrid(),
        entidadesIniciales: [],
      );

  static Grid _buildGrid() {
    final grid = <List<CeldaData>>[];
    for (var y = 0; y < 10; y++) {
      final row = <CeldaData>[];
      for (var x = 0; x < 16; x++) {
        if (y == 0 || y == 9 || x == 0 || x == 15) {
          row.add(CeldaData.pared);
        } else {
          row.add(CeldaData.suelo);
        }
      }
      grid.add(row);
    }
    return grid;
  }
}

/// Chunk Puzzle Abismos
class ChunkPuzzleAbismos extends LevelData {
  ChunkPuzzleAbismos()
    : super(
        ancho: 26,
        alto: 14,
        nombre: 'Puzzle Abismos',
        dificultad: Dificultad.baja,
        sector: Sector.contencion,
        grid: _buildGrid(),
        entidadesIniciales: [],
      );

  static Grid _buildGrid() {
    final grid = <List<CeldaData>>[];
    for (var y = 0; y < 14; y++) {
      final row = <CeldaData>[];
      for (var x = 0; x < 26; x++) {
        if (y == 0 || y == 13 || x == 0 || x == 25) {
          row.add(CeldaData.pared);
        } else if (y == 8 &&
            (x >= 4 && x <= 7 || x >= 12 && x <= 15 || x >= 20 && x <= 23)) {
          row.add(CeldaData.abismo);
        } else if (y == 10 && x >= 8 && x <= 19) {
          row.add(CeldaData.abismo);
        } else {
          row.add(CeldaData.suelo);
        }
      }
      grid.add(row);
    }
    return grid;
  }
}

/// Chunk Silencio Total
class ChunkSilencioTotal extends LevelData {
  ChunkSilencioTotal()
    : super(
        ancho: 22,
        alto: 12,
        nombre: 'Silencio Total',
        dificultad: Dificultad.media,
        sector: Sector.laboratorios,
        grid: _buildGrid(),
        entidadesIniciales: [
          EntidadSpawn(
            tipoEnemigo: VigiaComponent,
            posicion: Vector2(11, 6),
          ),
        ],
      );

  static Grid _buildGrid() {
    final grid = <List<CeldaData>>[];
    for (var y = 0; y < 12; y++) {
      final row = <CeldaData>[];
      for (var x = 0; x < 22; x++) {
        if (y == 0 || y == 11 || x == 0 || x == 21) {
          row.add(CeldaData.pared);
        } else if ((x == 7 || x == 15) && y >= 3 && y <= 8) {
          row.add(CeldaData.pared);
        } else {
          row.add(CeldaData.suelo);
        }
      }
      grid.add(row);
    }
    return grid;
  }
}

/// Chunk Corredor Paralelo
class ChunkParalelo extends LevelData {
  ChunkParalelo()
    : super(
        ancho: 28,
        alto: 16,
        nombre: 'Corredor Paralelo',
        dificultad: Dificultad.media,
        sector: Sector.laboratorios,
        grid: _buildGrid(),
        entidadesIniciales: [
          EntidadSpawn(
            tipoEnemigo: CazadorComponent,
            posicion: Vector2(8, 4),
          ),
          EntidadSpawn(
            tipoEnemigo: CazadorComponent,
            posicion: Vector2(20, 12),
          ),
        ],
      );

  static Grid _buildGrid() {
    final grid = <List<CeldaData>>[];
    for (var y = 0; y < 16; y++) {
      final row = <CeldaData>[];
      for (var x = 0; x < 28; x++) {
        if (y == 0 || y == 15 || x == 0 || x == 27) {
          row.add(CeldaData.pared);
        } else if (y == 8 && x >= 2 && x <= 25) {
          row.add(CeldaData.pared);
        } else if (y == 11 && (x >= 6 && x <= 10 || x >= 16 && x <= 20)) {
          row.add(CeldaData.abismo);
        } else {
          row.add(CeldaData.suelo);
        }
      }
      grid.add(row);
    }
    return grid;
  }
}

/// Chunk Destrucción Táctica
class ChunkDestruccionTactica extends LevelData {
  ChunkDestruccionTactica()
    : super(
        ancho: 24,
        alto: 14,
        nombre: 'Destrucción Táctica',
        dificultad: Dificultad.media,
        sector: Sector.laboratorios,
        grid: _buildGrid(),
        entidadesIniciales: [
          EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(12, 4)),
          EntidadSpawn(
            tipoEnemigo: CazadorComponent,
            posicion: Vector2(12, 10),
          ),
        ],
      );

  static Grid _buildGrid() {
    final grid = <List<CeldaData>>[];
    for (var y = 0; y < 14; y++) {
      final row = <CeldaData>[];
      for (var x = 0; x < 24; x++) {
        if (y == 0 || y == 13 || x == 0 || x == 23) {
          row.add(CeldaData.pared);
        } else if ((x == 8 || x == 16) && y >= 2 && y <= 11) {
          row.add(const CeldaData(tipo: TipoCelda.pared, esDestructible: true));
        } else if (y == 6 && (x >= 3 && x <= 6 || x >= 18 && x <= 21)) {
          row.add(CeldaData.pared);
        } else {
          row.add(CeldaData.suelo);
        }
      }
      grid.add(row);
    }
    return grid;
  }
}

/// Chunk Alarma en Cadena
class ChunkAlarmaEnCadena extends LevelData {
  ChunkAlarmaEnCadena()
    : super(
        ancho: 26,
        alto: 12,
        nombre: 'Alarma en Cadena',
        dificultad: Dificultad.alta,
        sector: Sector.laboratorios,
        grid: _buildGrid(),
        entidadesIniciales: [
          EntidadSpawn(
            tipoEnemigo: VigiaComponent,
            posicion: Vector2(6, 4),
          ),
          EntidadSpawn(
            tipoEnemigo: VigiaComponent,
            posicion: Vector2(18, 4),
          ),
        ],
      );

  static Grid _buildGrid() {
    final grid = <List<CeldaData>>[];
    for (var y = 0; y < 12; y++) {
      final row = <CeldaData>[];
      for (var x = 0; x < 26; x++) {
        if (y == 0 || y == 11 || x == 0 || x == 25) {
          row.add(CeldaData.pared);
        } else if (x == 12 && y >= 2 && y <= 9) {
          row.add(CeldaData.pared);
        } else if (y == 6 && (x >= 4 && x <= 8 || x >= 16 && x <= 20)) {
          row.add(CeldaData.pared);
        } else {
          row.add(CeldaData.suelo);
        }
      }
      grid.add(row);
    }
    return grid;
  }
}

/// Chunk Infierno (Final Boss)
class ChunkInfierno extends LevelData {
  ChunkInfierno()
    : super(
        ancho: 30,
        alto: 18,
        nombre: 'Infierno',
        dificultad: Dificultad.alta,
        sector: Sector.salida,
        grid: _buildGrid(),
        entidadesIniciales: [
          EntidadSpawn(tipoEnemigo: BrutoComponent, posicion: Vector2(5, 5)),
          EntidadSpawn(tipoEnemigo: BrutoComponent, posicion: Vector2(25, 5)),
          EntidadSpawn(tipoEnemigo: BrutoComponent, posicion: Vector2(15, 13)),
          EntidadSpawn(tipoEnemigo: VigiaComponent, posicion: Vector2(15, 4)),
          EntidadSpawn(tipoEnemigo: VigiaComponent, posicion: Vector2(15, 14)),
          EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(7, 11)),
          EntidadSpawn(
            tipoEnemigo: CazadorComponent,
            posicion: Vector2(23, 11),
          ),
        ],
      );

  static Grid _buildGrid() {
    final grid = <List<CeldaData>>[];
    for (var y = 0; y < 18; y++) {
      final row = <CeldaData>[];
      for (var x = 0; x < 30; x++) {
        if (y == 0 || y == 17 || x == 0 || x == 29) {
          row.add(CeldaData.pared);
        } else if (x == 10 && y >= 2 && y <= 15) {
          row.add(CeldaData.pared);
        } else if (x == 20 && y >= 2 && y <= 15) {
          row.add(CeldaData.pared);
        } else if (y == 9 && x >= 3 && x <= 27) {
          row.add(CeldaData.pared);
        } else if (y == 12 && x >= 6 && x <= 8) {
          row.add(CeldaData.abismo);
        } else if (y == 12 && x >= 22 && x <= 24) {
          row.add(CeldaData.abismo);
        } else if ((x == 15 && y >= 4 && y <= 7) ||
            (x == 15 && y >= 11 && y <= 14)) {
          row.add(const CeldaData(tipo: TipoCelda.pared, esDestructible: true));
        } else {
          row.add(CeldaData.suelo);
        }
      }
      grid.add(row);
    }
    return grid;
  }
}
