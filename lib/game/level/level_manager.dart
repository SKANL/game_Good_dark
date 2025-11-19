import 'package:echo_world/game/components/abyss_component.dart';
import 'package:echo_world/game/components/batch_geometry_renderer.dart';
import 'package:echo_world/game/components/component_pool.dart';
import 'package:echo_world/game/components/transition_zone_component.dart';
import 'package:echo_world/game/components/wall_component.dart';
import 'package:echo_world/game/entities/enemies/enemies.dart';
import 'package:echo_world/game/level/level_models.dart';
import 'package:echo_world/game/level/level_chunks.dart';
import 'package:echo_world/game/cubit/checkpoint/cubit.dart';
import 'package:echo_world/game/black_echo_game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LevelManagerComponent extends Component with HasGameRef {
  LevelManagerComponent({required this.checkpointBloc});

  final CheckpointBloc checkpointBloc;
  static const double tileSize = 32;
  late final List<LevelData> _chunks;
  int _idx = 0;
  LevelData? _current; // Chunk actual cargado (expuesto para vistas)
  List<List<CeldaData>>? get currentGrid => _current?.grid;

  // Referencias a componentes del nivel para poder limpiarlos
  final List<Component> _levelComponents = [];

  // ===== COMPONENT POOLS (Optimización de rendimiento) =====
  // Pools para enemigos - reduce GC pressure en transiciones de chunks
  late final ComponentPool<CazadorComponent> _cazadorPool;
  late final ComponentPool<VigiaComponent> _vigiaPool;
  late final ComponentPool<BrutoComponent> _brutoPool;

  // ===== BATCH RENDERER (Optimización de draw calls) =====
  // Renderiza todas las paredes en 1 Picture en lugar de N draw calls
  late final BatchGeometryRenderer _wallBatchRenderer;

  @override
  Future<void> onLoad() async {
    // Inicializar batch renderer
    _wallBatchRenderer = BatchGeometryRenderer();
    await parent?.add(_wallBatchRenderer);

    // Inicializar pools con configuración optimizada para móvil
    _cazadorPool = ComponentPool<CazadorComponent>(
      factory: () => CazadorComponent(position: Vector2.zero()),
      maxSize: 20,
      preloadSize: 5,
    );

    _vigiaPool = ComponentPool<VigiaComponent>(
      factory: () => VigiaComponent(position: Vector2.zero()),
      maxSize: 10,
      preloadSize: 3,
    );

    _brutoPool = ComponentPool<BrutoComponent>(
      factory: () => BrutoComponent(position: Vector2.zero()),
      maxSize: 10,
      preloadSize: 2,
    );

    _chunks = [
      // ===== SECTOR 1: CONTENCIÓN (Tutorial + Sigilo Básico) =====
      ChunkInicioSeguro(), // 0: Tutorial movimiento + ECO
      ChunkAbismoSalto(), // 1: Tutorial Enfoque + Salto
      ChunkSigiloCazador(), // 2: Tutorial Sigilo + Ruptura
      _chunkCorredorEmboscada(), // 3: Sigilo con 2 Cazadores
      _chunkSalaSegura(), // 4: Respiro (sin enemigos)
      ChunkLaberintoVertical(), // 5: MEJORADO - Zigzag vertical + 3 enemigos
      _chunkPuzzleAbismos(), // 6: SideScroll + plataformas
      // ===== SECTOR 2: LABORATORIOS (Vigías + Puzzles) =====
      _chunkVigiaTest(), // 7: Introducción Vigía
      _chunkSilencioTotal(), // 8: Vigía + prohibido ECO
      _chunkParalelo(), // 9: 2 corredores (TopDown + SideScroll)
      _chunkDestruccionTactica(), // 10: Paredes destructibles estratégicas
      _chunkAlarmaEnCadena(), // 11: 2 Vigías + timing perfecto
      // ===== SECTOR 3: SALIDA (Combate Intenso) =====
      _chunkBrutoTest(), // 12: Introducción Bruto
      ChunkArenaBruto(), // 13: MEJORADO - Boss arena con Bruto + 2 Vigías
      _chunkInfierno(), // 14: Todos los arquetipos (final boss)
    ];
    await _cargarChunk(_chunks[_idx]);
  }

  Future<void> _cargarChunk(LevelData chunk) async {
    // Guardar referencia del chunk actual
    _current = chunk;
    // Auto-save: notificar al CheckpointBloc que cambiamos de chunk
    checkpointBloc.add(ChunkCambiado(_idx));

    // Limpiar batch renderer anterior
    _wallBatchRenderer.clearGeometries();

    // Liberar componentes del nivel anterior (devolverlos a los pools)
    for (final c in _levelComponents) {
      // Si es un enemigo, devolverlo al pool antes de remover
      if (c is CazadorComponent) {
        c.removeFromParent();
        _cazadorPool.release(c);
      } else if (c is VigiaComponent) {
        c.removeFromParent();
        _vigiaPool.release(c);
      } else if (c is BrutoComponent) {
        c.removeFromParent();
        _brutoPool.release(c);
      } else {
        // Otros componentes (abismos, transiciones) se destruyen normalmente
        c.removeFromParent();
      }
    }
    _levelComponents.clear();

    // Cargar geometría del chunk
    // OPTIMIZACIÓN: Paredes se agregan al batch renderer (1 draw call)
    // Solo WallComponents físicos invisibles para colisiones
    for (var y = 0; y < chunk.alto; y++) {
      for (var x = 0; x < chunk.ancho; x++) {
        final celda = chunk.grid[y][x];
        final pos = Vector2(x * tileSize, y * tileSize);

        if (celda.tipo == TipoCelda.pared) {
          // Agregar geometría al batch renderer para renderizado eficiente
          _wallBatchRenderer.addGeometry(
            position: pos,
            size: Vector2(tileSize, tileSize),
            color: celda.esDestructible
                ? const Color(0xFF444444) // Paredes destructibles más claras
                : const Color(0xFF222222), // Paredes normales
            destructible: celda.esDestructible,
          );

          // Crear WallComponent invisible solo para colisiones
          final wall = WallComponent(
            position: pos,
            size: Vector2(tileSize, tileSize),
            destructible: celda.esDestructible,
          );
          await parent?.add(wall);
          _levelComponents.add(wall);
        } else if (celda.tipo == TipoCelda.abismo) {
          final abyss = AbyssComponent(
            position: pos,
            size: Vector2(tileSize, tileSize),
          );
          await parent?.add(abyss);
          _levelComponents.add(abyss);
        }
      }
    }

    // Marcar el batch como dirty para que se re-renderice
    _wallBatchRenderer.markDirty();

    // Crear zonas de transición en los bordes del chunk
    // Solo si no es el último chunk
    if (_idx < _chunks.length - 1) {
      await _crearZonasDeTransicion(chunk);
    }

    // Spawnear entidades definidas en el chunk usando pools
    for (final spawn in chunk.entidadesIniciales) {
      final pos = Vector2(
        spawn.posicion.x * tileSize,
        spawn.posicion.y * tileSize,
      );

      // Usar pools en lugar de crear nuevas instancias
      if (spawn.tipoEnemigo == CazadorComponent) {
        final enemy = _cazadorPool.acquire();
        enemy.position = pos;
        await parent?.add(enemy);
        // Resetear DESPUÉS de agregar al árbol (behaviors ya están montados)
        enemy.reset();
        _levelComponents.add(enemy);
      } else if (spawn.tipoEnemigo == VigiaComponent) {
        final enemy = _vigiaPool.acquire();
        enemy.position = pos;
        await parent?.add(enemy);
        enemy.reset();
        _levelComponents.add(enemy);
      } else if (spawn.tipoEnemigo == BrutoComponent) {
        final enemy = _brutoPool.acquire();
        enemy.position = pos;
        await parent?.add(enemy);
        enemy.reset();
        _levelComponents.add(enemy);
      }
    }
  }

  @override
  void onRemove() {
    // Limpiar pools al destruir el LevelManager
    _cazadorPool.clear();
    _vigiaPool.clear();
    _brutoPool.clear();
    super.onRemove();
  }

  /// Verifica si un rectángulo en coordenadas del mundo está libre para
  /// que una entidad lo ocupe (sin paredes ni abismos).
  ///
  /// `rect` está en unidades de píxeles (coordenadas del juego). Devuelve
  /// `true` si todas las celdas ocupadas por `rect` son transitables.
  bool isRectWalkable(Rect rect) {
    final grid = _current?.grid;
    if (grid == null) return true; // si no hay grid, no bloqueamos

    final ts = tileSize;

    // Calcular índices de tiles cubiertos por el rect
    final startX = (rect.left / ts).floor().clamp(0, grid[0].length - 1);
    final endX = ((rect.right - 0.0001) / ts).floor().clamp(
      0,
      grid[0].length - 1,
    );
    final startY = (rect.top / ts).floor().clamp(0, grid.length - 1);
    final endY = ((rect.bottom - 0.0001) / ts).floor().clamp(
      0,
      grid.length - 1,
    );

    for (var y = startY; y <= endY; y++) {
      for (var x = startX; x <= endX; x++) {
        final cel = grid[y][x];
        if (cel.tipo != TipoCelda.suelo) {
          // pared o abismo -> no transitables
          return false;
        }
      }
    }
    return true;
  }

  // OBSOLETO: Reemplazado por ChunkInicioSeguro() en level_chunks.dart
  // LevelData _chunkInicioSeguro() {
  //   const w = 20, h = 12;
  //   final grid = List.generate(
  //     h,
  //     (y) => List.generate(
  //       w,
  //       (x) => (y == 0 || y == h - 1 || x == 0 || x == w - 1)
  //           ? CeldaData.pared
  //           : CeldaData.suelo,
  //     ),
  //   );
  //   return _SimpleLevel(
  //     ancho: w,
  //     alto: h,
  //     grid: grid,
  //     nombre: 'Inicio Seguro',
  //     dificultad: Dificultad.tutorial,
  //     sector: Sector.contencion,
  //   );
  // }

  // OBSOLETO: Reemplazado por ChunkAbismoSalto() en level_chunks.dart
  // LevelData _chunkAbismoSalto() {
  //   const w = 20, h = 12;
  //   final grid = List.generate(
  //     h,
  //     (y) => List.generate(
  //       w,
  //       (x) {
  //         if (y == 0 || y == h - 1 || x == 0 || x == w - 1)
  //           return CeldaData.pared;
  //         // crear una franja de "abismo" en el medio
  //         if (y == 7 && x > 3 && x < w - 4) return CeldaData.abismo;
  //         return CeldaData.suelo;
  //       },
  //     ),
  //   );
  //   return _SimpleLevel(
  //     ancho: w,
  //     alto: h,
  //     grid: grid,
  //     nombre: 'Abismo Salto',
  //     dificultad: Dificultad.tutorial,
  //     sector: Sector.contencion,
  //   );
  // }

  // OBSOLETO: Reemplazado por ChunkSigiloCazador() en level_chunks.dart
  // LevelData _chunkSigiloCazador() {
  //   const w = 20, h = 12;
  //   final grid = List.generate(
  //     h,
  //     (y) => List.generate(
  //       w,
  //       (x) {
  //         if (y == 0 || y == h - 1 || x == 0 || x == w - 1)
  //           return CeldaData.pared;
  //         // algunos muros "destructibles" de cobertura
  //         if ((x == 8 && y >= 3 && y <= 5) || (x == 12 && y >= 6 && y <= 8)) {
  //           return const CeldaData(tipo: TipoCelda.pared, esDestructible: true);
  //         }
  //         return CeldaData.suelo;
  //       },
  //     ),
  //   );
  //
  //   // Spawnear un Cazador en el centro del chunk
  //   final entidades = [
  //     EntidadSpawn(
  //       tipoEnemigo: CazadorComponent,
  //       posicion: Vector2(10, 6), // Centro del chunk
  //     ),
  //   ];
  //
  //   return _SimpleLevel(
  //     ancho: w,
  //     alto: h,
  //     grid: grid,
  //     entidades: entidades,
  //     nombre: 'Sigilo Cazador',
  //     dificultad: Dificultad.tutorial,
  //     sector: Sector.contencion,
  //   );
  // }

  LevelData _chunkVigiaTest() {
    const w = 20;
    const h = 12;
    final grid = List.generate(
      h,
      (y) => List.generate(
        w,
        (x) {
          if (y == 0 || y == h - 1 || x == 0 || x == w - 1) {
            return CeldaData.pared;
          }
          // Crear un corredor con un cuarto al final
          if (y == 6 && x >= 5 && x <= 7) {
            return CeldaData.pared; // pared horizontal
          }
          if (x == 5 && y >= 6 && y <= 8) {
            return CeldaData.pared; // pared vertical
          }
          return CeldaData.suelo;
        },
      ),
    );

    // Spawnear un Vigía en el cuarto (estático) y un Cazador al inicio
    final entidades = [
      EntidadSpawn(
        tipoEnemigo: VigiaComponent,
        posicion: Vector2(15, 6), // Vigía estático en el cuarto al fondo
      ),
      EntidadSpawn(
        tipoEnemigo: CazadorComponent,
        posicion: Vector2(8, 3), // Cazador patrullando cerca
      ),
    ];

    return _SimpleLevel(
      ancho: w,
      alto: h,
      grid: grid,
      entidades: entidades,
      nombre: 'Vigía Test',
      dificultad: Dificultad.media,
      sector: Sector.laboratorios,
    );
  }

  LevelData _chunkBrutoTest() {
    const w = 22;
    const h = 14;
    final grid = List.generate(
      h,
      (y) => List.generate(
        w,
        (x) {
          if (y == 0 || y == h - 1 || x == 0 || x == w - 1) {
            return CeldaData.pared;
          }
          // Crear un corredor con paredes destructibles
          if (y == 7 && x >= 8 && x <= 14) {
            return const CeldaData(tipo: TipoCelda.pared, esDestructible: true);
          }
          // Pared destructible vertical
          if (x == 11 && y >= 4 && y <= 6) {
            return const CeldaData(tipo: TipoCelda.pared, esDestructible: true);
          }
          return CeldaData.suelo;
        },
      ),
    );

    // Spawnear un Bruto que debe romper las paredes para llegar al jugador
    final entidades = [
      EntidadSpawn(
        tipoEnemigo: BrutoComponent,
        posicion: Vector2(11, 10), // Bruto detrás de la pared destructible
      ),
    ];

    return _SimpleLevel(
      ancho: w,
      alto: h,
      grid: grid,
      entidades: entidades,
      nombre: 'Bruto Test',
      dificultad: Dificultad.alta,
      sector: Sector.salida,
    );
  }

  // ========================================================================
  // SECTOR 1: CHUNKS DE CONTENCIÓN (Tutorial + Sigilo Básico)
  // ========================================================================

  /// Chunk 3: Corredor con Emboscada
  /// Objetivo: Enseñar a usar cobertura y sigilo contra múltiples enemigos
  LevelData _chunkCorredorEmboscada() {
    const w = 24;
    const h = 12;
    final grid = List.generate(
      h,
      (y) => List.generate(
        w,
        (x) {
          if (y == 0 || y == h - 1 || x == 0 || x == w - 1) {
            return CeldaData.pared;
          }

          // Corredor con obstáculos para cobertura
          if ((x == 8 || x == 16) && y >= 4 && y <= 7) return CeldaData.pared;
          if (x == 12 && (y == 3 || y == 8)) return CeldaData.pared;

          return CeldaData.suelo;
        },
      ),
    );

    // Dos Cazadores: uno al inicio, otro al final
    final entidades = [
      EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(6, 6)),
      EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(18, 6)),
    ];

    return _SimpleLevel(
      ancho: w,
      alto: h,
      grid: grid,
      entidades: entidades,
      nombre: 'Corredor Emboscada',
      dificultad: Dificultad.baja,
    );
  }

  /// Chunk 4: Sala Segura (Respiro)
  /// Objetivo: Dar respiro al jugador, permitir recuperación estratégica
  LevelData _chunkSalaSegura() {
    const w = 16;
    const h = 10;
    final grid = List.generate(
      h,
      (y) => List.generate(
        w,
        (x) {
          if (y == 0 || y == h - 1 || x == 0 || x == w - 1) {
            return CeldaData.pared;
          }

          // Sala amplia sin obstáculos
          return CeldaData.suelo;
        },
      ),
    );

    // Sin enemigos (sala segura)
    return _SimpleLevel(
      ancho: w,
      alto: h,
      grid: grid,
      nombre: 'Sala Segura',
    );
  }

  /// Chunk 5: Laberinto Simple
  /// Objetivo: Navegación + 1 Cazador patrullando
  // OBSOLETO: Reemplazado por ChunkLaberintoVertical() en level_chunks.dart
  // LevelData _chunkLaberintoSimple() {
  //   const w = 20, h = 14;
  //   final grid = List.generate(
  //     h,
  //     (y) => List.generate(
  //       w,
  //       (x) {
  //         if (y == 0 || y == h - 1 || x == 0 || x == w - 1)
  //           return CeldaData.pared;
  //
  //         // Crear un laberinto simple con forma de "E"
  //         if (x == 10 && (y >= 2 && y <= 4 || y >= 7 && y <= 9))
  //           return CeldaData.pared;
  //         if (y == 6 && x >= 5 && x <= 15) return CeldaData.pared;
  //         if (x == 5 && y >= 2 && y <= 11) return CeldaData.pared;
  //
  //         return CeldaData.suelo;
  //       },
  //     ),
  //   );
  //
  //   final entidades = [
  //     EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(12, 7)),
  //   ];
  //
  //   return _SimpleLevel(
  //     ancho: w,
  //     alto: h,
  //     grid: grid,
  //     entidades: entidades,
  //     nombre: 'Laberinto Simple',
  //     dificultad: Dificultad.baja,
  //     sector: Sector.contencion,
  //   );
  // }

  /// Chunk 6: Puzzle de Abismos
  /// Objetivo: Combinar SideScroll + plataformeo con timing
  LevelData _chunkPuzzleAbismos() {
    const w = 26;
    const h = 14;
    final grid = List.generate(
      h,
      (y) => List.generate(
        w,
        (x) {
          if (y == 0 || y == h - 1 || x == 0 || x == w - 1) {
            return CeldaData.pared;
          }

          // Crear plataformas con abismos entre ellas
          if (y == 8 &&
              (x >= 4 && x <= 7 || x >= 12 && x <= 15 || x >= 20 && x <= 23)) {
            return CeldaData.abismo;
          }
          if (y == 10 && x >= 8 && x <= 19) return CeldaData.abismo;

          return CeldaData.suelo;
        },
      ),
    );

    // Sin enemigos (enfocado en puzzle de plataformeo)
    return _SimpleLevel(
      ancho: w,
      alto: h,
      grid: grid,
      nombre: 'Puzzle Abismos',
      dificultad: Dificultad.baja,
    );
  }

  // ========================================================================
  // SECTOR 2: CHUNKS DE LABORATORIOS (Vigías + Puzzles Complejos)
  // ========================================================================

  /// Chunk 8: Silencio Total
  /// Objetivo: Vigía central + prohibido usar ECO (detecta sonido medio)
  LevelData _chunkSilencioTotal() {
    const w = 22;
    const h = 12;
    final grid = List.generate(
      h,
      (y) => List.generate(
        w,
        (x) {
          if (y == 0 || y == h - 1 || x == 0 || x == w - 1) {
            return CeldaData.pared;
          }

          // Corredor con Vigía en el centro
          if ((x == 7 || x == 15) && y >= 3 && y <= 8) return CeldaData.pared;

          return CeldaData.suelo;
        },
      ),
    );

    final entidades = [
      EntidadSpawn(
        tipoEnemigo: VigiaComponent,
        posicion: Vector2(11, 6),
      ), // Centro
    ];

    return _SimpleLevel(
      ancho: w,
      alto: h,
      grid: grid,
      entidades: entidades,
      nombre: 'Silencio Total',
      dificultad: Dificultad.media,
      sector: Sector.laboratorios,
    );
  }

  /// Chunk 9: Corredor Paralelo
  /// Objetivo: 2 corredores (TopDown superior + SideScroll inferior con abismos)
  LevelData _chunkParalelo() {
    const w = 28;
    const h = 16;
    final grid = List.generate(
      h,
      (y) => List.generate(
        w,
        (x) {
          if (y == 0 || y == h - 1 || x == 0 || x == w - 1) {
            return CeldaData.pared;
          }

          // Pared divisoria horizontal
          if (y == 8 && x >= 2 && x <= w - 3) return CeldaData.pared;

          // Abismos en el corredor inferior (requiere SideScroll)
          if (y == 11 && (x >= 6 && x <= 10 || x >= 16 && x <= 20)) {
            return CeldaData.abismo;
          }

          return CeldaData.suelo;
        },
      ),
    );

    final entidades = [
      EntidadSpawn(
        tipoEnemigo: CazadorComponent,
        posicion: Vector2(8, 4),
      ), // Corredor superior
      EntidadSpawn(
        tipoEnemigo: CazadorComponent,
        posicion: Vector2(20, 12),
      ), // Corredor inferior
    ];

    return _SimpleLevel(
      ancho: w,
      alto: h,
      grid: grid,
      entidades: entidades,
      nombre: 'Corredor Paralelo',
      dificultad: Dificultad.media,
      sector: Sector.laboratorios,
    );
  }

  /// Chunk 10: Destrucción Táctica
  /// Objetivo: Paredes destructibles crean shortcuts pero alertan enemigos
  LevelData _chunkDestruccionTactica() {
    const w = 24;
    const h = 14;
    final grid = List.generate(
      h,
      (y) => List.generate(
        w,
        (x) {
          if (y == 0 || y == h - 1 || x == 0 || x == w - 1) {
            return CeldaData.pared;
          }

          // Paredes destructibles estratégicas (shortcuts)
          if ((x == 8 || x == 16) && y >= 2 && y <= 11) {
            return const CeldaData(tipo: TipoCelda.pared, esDestructible: true);
          }

          // Paredes normales (laberinto)
          if (y == 6 && (x >= 3 && x <= 6 || x >= 18 && x <= 21)) {
            return CeldaData.pared;
          }

          return CeldaData.suelo;
        },
      ),
    );

    final entidades = [
      EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(12, 4)),
      EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(12, 10)),
    ];

    return _SimpleLevel(
      ancho: w,
      alto: h,
      grid: grid,
      entidades: entidades,
      nombre: 'Destrucción Táctica',
      dificultad: Dificultad.media,
      sector: Sector.laboratorios,
    );
  }

  /// Chunk 11: Alarma en Cadena
  /// Objetivo: 2 Vigías posicionados estratégicamente, timing perfecto requerido
  LevelData _chunkAlarmaEnCadena() {
    const w = 26;
    const h = 12;
    final grid = List.generate(
      h,
      (y) => List.generate(
        w,
        (x) {
          if (y == 0 || y == h - 1 || x == 0 || x == w - 1) {
            return CeldaData.pared;
          }

          // Dos cuartos separados con Vigías
          if (x == 12 && y >= 2 && y <= 9) {
            return CeldaData.pared; // División central
          }
          if (y == 6 && (x >= 4 && x <= 8 || x >= 16 && x <= 20)) {
            return CeldaData.pared;
          }

          return CeldaData.suelo;
        },
      ),
    );

    final entidades = [
      EntidadSpawn(
        tipoEnemigo: VigiaComponent,
        posicion: Vector2(6, 4),
      ), // Vigía izquierdo
      EntidadSpawn(
        tipoEnemigo: VigiaComponent,
        posicion: Vector2(18, 4),
      ), // Vigía derecho
    ];

    return _SimpleLevel(
      ancho: w,
      alto: h,
      grid: grid,
      entidades: entidades,
      nombre: 'Alarma en Cadena',
      dificultad: Dificultad.alta,
      sector: Sector.laboratorios,
    );
  }

  // ========================================================================
  // SECTOR 3: CHUNKS DE SALIDA (Combate Intenso + Boss)
  // ========================================================================

  /// Chunk 13: Arena
  /// Objetivo: 2 Brutos + 1 Cazador en sala cerrada (combate inevitable)
  // OBSOLETO: Reemplazado por ChunkArenaBruto() en level_chunks.dart
  // LevelData _chunkArena() {
  //   const w = 20, h = 16;
  //   final grid = List.generate(
  //     h,
  //     (y) => List.generate(
  //       w,
  //       (x) {
  //         if (y == 0 || y == h - 1 || x == 0 || x == w - 1)
  //           return CeldaData.pared;
  //
  //         // Sala amplia (arena) con algunos pilares
  //         if ((x == 6 || x == 14) && (y == 5 || y == 11))
  //           return CeldaData.pared;
  //
  //         // Paredes destructibles para táctica
  //         if ((x == 10 && y >= 4 && y <= 6) ||
  //             (x == 10 && y >= 10 && y <= 12)) {
  //           return const CeldaData(tipo: TipoCelda.pared, esDestructible: true);
  //         }
  //
  //         return CeldaData.suelo;
  //       },
  //     ),
  //   );
  //
  //   final entidades = [
  //     EntidadSpawn(tipoEnemigo: BrutoComponent, posicion: Vector2(6, 8)),
  //     EntidadSpawn(tipoEnemigo: BrutoComponent, posicion: Vector2(14, 8)),
  //     EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(10, 4)),
  //   ];
  //
  //   return _SimpleLevel(
  //     ancho: w,
  //     alto: h,
  //     grid: grid,
  //     entidades: entidades,
  //     nombre: 'Arena',
  //     dificultad: Dificultad.alta,
  //     sector: Sector.salida,
  //   );
  // }

  /// Chunk 14: Infierno (Final Boss)
  /// Objetivo: Todos los arquetipos + requiere los 3 enfoques + nivel más difícil
  LevelData _chunkInfierno() {
    const w = 30;
    const h = 18;
    final grid = List.generate(
      h,
      (y) => List.generate(
        w,
        (x) {
          if (y == 0 || y == h - 1 || x == 0 || x == w - 1) {
            return CeldaData.pared;
          }

          // Laberinto complejo
          if (x == 10 && y >= 2 && y <= 15) return CeldaData.pared;
          if (x == 20 && y >= 2 && y <= 15) return CeldaData.pared;
          if (y == 9 && x >= 3 && x <= 27) return CeldaData.pared;

          // Abismos estratégicos (requiere SideScroll)
          if (y == 12 && x >= 6 && x <= 8) return CeldaData.abismo;
          if (y == 12 && x >= 22 && x <= 24) return CeldaData.abismo;

          // Paredes destructibles
          if ((x == 15 && y >= 4 && y <= 7) ||
              (x == 15 && y >= 11 && y <= 14)) {
            return const CeldaData(tipo: TipoCelda.pared, esDestructible: true);
          }

          return CeldaData.suelo;
        },
      ),
    );

    final entidades = [
      // Brutos estratégicamente posicionados
      EntidadSpawn(tipoEnemigo: BrutoComponent, posicion: Vector2(5, 5)),
      EntidadSpawn(tipoEnemigo: BrutoComponent, posicion: Vector2(25, 5)),
      EntidadSpawn(tipoEnemigo: BrutoComponent, posicion: Vector2(15, 13)),
      // Vigías de alarma
      EntidadSpawn(tipoEnemigo: VigiaComponent, posicion: Vector2(15, 4)),
      EntidadSpawn(tipoEnemigo: VigiaComponent, posicion: Vector2(15, 14)),
      // Cazadores patrullando
      EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(7, 11)),
      EntidadSpawn(tipoEnemigo: CazadorComponent, posicion: Vector2(23, 11)),
    ];

    return _SimpleLevel(
      ancho: w,
      alto: h,
      grid: grid,
      entidades: entidades,
      nombre: 'Infierno',
      dificultad: Dificultad.alta,
      sector: Sector.salida,
    );
  }

  /// Crea zonas de transición en los bordes del chunk para detectar
  /// cuándo el jugador debe avanzar al siguiente nivel
  Future<void> _crearZonasDeTransicion(LevelData chunk) async {
    const zoneThickness = tileSize * 2; // 2 tiles de grosor

    // Zona Este (derecha): para avanzar al siguiente chunk
    final eastZone = TransitionZoneComponent(
      position: Vector2((chunk.ancho - 2) * tileSize, 0),
      size: Vector2(zoneThickness, chunk.alto * tileSize),
      targetChunkDirection: 'east',
    );
    await parent?.add(eastZone);
    _levelComponents.add(eastZone);

    // Podríamos añadir más zonas en otros bordes si el diseño lo requiere:
    // Norte, Sur, Oeste para navegación bidireccional
  }

  Future<void> siguienteChunk() async {
    _idx = (_idx + 1) % _chunks.length;
    await _cargarChunk(_chunks[_idx]);

    // Reposicionar al jugador al centro del nuevo chunk
    final game = gameRef as BlackEchoGame;
    final chunk = _chunks[_idx];
    game.player.position = Vector2(
      (chunk.ancho / 2) * tileSize,
      (chunk.alto / 2) * tileSize,
    );
  }
}

extension LevelManagerSnapshot on LevelManagerComponent {
  /// Acceso de solo lectura al grid del chunk actual
  List<List<CeldaData>>? get currentGrid => _current?.grid;
  LevelData? get currentChunk => _current;
}

class _SimpleLevel extends LevelData {
  const _SimpleLevel({
    required super.ancho,
    required super.alto,
    required super.grid,
    List<EntidadSpawn> entidades = const [],
    super.dificultad = Dificultad.tutorial,
    super.sector = Sector.contencion,
    super.nombre = 'Chunk',
  }) : super(entidadesIniciales: entidades);
}
