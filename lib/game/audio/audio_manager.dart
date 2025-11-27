import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Singleton para gestionar audio posicional y SFX del juego
class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  // Pools de audio para reproducción simultánea
  final Map<String, List<AudioPlayer>> _pools = {};
  final Map<String, bool> _isLoaded = {};

  // Referencias a sonidos activos para control posicional
  final Map<String, AudioPlayer> _positionalLoops = {};

  // Volumen maestro (0.0 - 1.0)
  double _masterVolume = 1;
  double _sfxVolume = 1;

  bool _isInitialized = false;

  /// Precarga todos los assets de audio necesarios
  Future<void> preload() async {
    if (_isInitialized) return;

    try {
      // Configurar el contexto de audio para juegos (baja latencia, foco)
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
          ),
          iOS: AudioContextIOS(
            options: const {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );

      // SFX del jugador
      await _preloadSound('eco_ping', poolSize: 3);
      await _preloadSound('rupture_blast', poolSize: 2);
      await _preloadSound('rejection_shield', poolSize: 2);
      await _preloadSound('absorb_inhale', poolSize: 2);
      await _preloadSound('footstep_normal_01', poolSize: 4);
      await _preloadSound('footstep_stealth_01', poolSize: 4);

      // SFX enemigos (loops posicionales necesitan 1 player dedicado)
      await _preloadSound('cazador_groan_loop', poolSize: 5);
      await _preloadSound('cazador_alert', poolSize: 3);
      await _preloadSound('cazador_hunt_scream', poolSize: 3);
      await _preloadSound('vigia_static_hum_loop', poolSize: 2);
      await _preloadSound('vigia_alarm_scream', poolSize: 2);
      await _preloadSound('bruto_footstep', poolSize: 3);

      // Ambiente
      await _preloadSound('amb_tinnitus_loop');
      await _preloadSound('amb_whispers_loop');

      _isInitialized = true;
      debugPrint('[AudioManager] Preload completo');
    } catch (e) {
      debugPrint('[AudioManager] Error CRÍTICO en preload: $e');
    }
  }

  Future<void> _preloadSound(String soundId, {int poolSize = 1}) async {
    final players = <AudioPlayer>[];
    for (var i = 0; i < poolSize; i++) {
      final player = AudioPlayer();
      // Configurar modo de liberación por defecto
      await player.setReleaseMode(ReleaseMode.stop);
      // Configurar fuente de audio
      try {
        await player.setSource(AssetSource('audio/$soundId.wav'));
        players.add(player);
      } catch (e) {
        debugPrint(
          '[AudioManager] FALLO al cargar asset: audio/$soundId.wav. Error: $e',
        );
        // Si falla, añadir player vacío para mantener consistencia del pool
        players.add(player);
      }
    }
    _pools[soundId] = players;
    _isLoaded[soundId] = true;
  }

  /// Reproduce un SFX no-posicional (UI, eventos globales)
  Future<void> playSfx(String soundId, {double volume = 1.0}) async {
    if (!(_isLoaded[soundId] ?? false)) {
      debugPrint('[AudioManager] Sound no cargado: $soundId');
      return;
    }

    final pool = _pools[soundId]!;
    // Buscar un player disponible
    AudioPlayer? available;
    for (final player in pool) {
      if (player.state != PlayerState.playing) {
        available = player;
        break;
      }
    }

    if (available != null) {
      try {
        await available.setVolume(_masterVolume * _sfxVolume * volume);
        await available.setReleaseMode(ReleaseMode.stop);
        await available.seek(Duration.zero);
        await available.resume();
      } catch (e) {
        debugPrint('[AudioManager] Error reproduciendo $soundId: $e');
      }
    }
  }

  /// Reproduce un SFX con audio posicional (calcula balance L/R y volumen por distancia)
  Future<void> playPositional({
    required String soundId,
    required math.Point<double> sourcePosition,
    required math.Point<double> listenerPosition,
    double maxDistance = 640.0,
    double volume = 1.0,
    bool loop = false,
  }) async {
    if (!(_isLoaded[soundId] ?? false)) {
      return;
    }

    final pool = _pools[soundId]!;
    AudioPlayer? available;
    for (final player in pool) {
      if (player.state != PlayerState.playing) {
        available = player;
        break;
      }
    }

    if (available == null) return;

    // Calcular distancia y dirección
    final dx = sourcePosition.x - listenerPosition.x;
    final dy = sourcePosition.y - listenerPosition.y;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Atenuación por distancia (inversa cuadrática)
    final distanceFactor = distance < maxDistance
        ? 1.0 - (distance / maxDistance).clamp(0.0, 1.0)
        : 0.0;

    if (distanceFactor == 0.0) return; // Demasiado lejos

    // Balance estéreo (-1.0 = izquierda, 1.0 = derecha)
    final balance = (dx / maxDistance).clamp(-1.0, 1.0);

    // Configurar y reproducir (con manejo de errores)
    try {
      await available.setVolume(
        _masterVolume * _sfxVolume * volume * distanceFactor,
      );
      await available.setBalance(balance);
      await available.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.stop,
      );
      await available.seek(Duration.zero);
      await available.resume();
    } catch (e) {
      // Silenciar errores de threading del plugin (son benignos)
    }
  }

  /// Inicia un loop posicional (para enemigos que emiten sonido constante)
  Future<String?> startPositionalLoop({
    required String soundId,
    required math.Point<double> sourcePosition,
    required math.Point<double> listenerPosition,
    double maxDistance = 640.0,
    double volume = 1.0,
  }) async {
    if (!(_isLoaded[soundId] ?? false)) return null;

    final pool = _pools[soundId]!;
    AudioPlayer? available;
    for (final player in pool) {
      if (player.state != PlayerState.playing) {
        available = player;
        break;
      }
    }

    if (available == null) return null;

    // Calcular parámetros posicionales
    final dx = sourcePosition.x - listenerPosition.x;
    final dy = sourcePosition.y - listenerPosition.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    final distanceFactor = distance < maxDistance
        ? 1.0 - (distance / maxDistance).clamp(0.0, 1.0)
        : 0.0;
    final balance = (dx / maxDistance).clamp(-1.0, 1.0);

    // Configurar loop (con manejo de errores)
    try {
      await available.setVolume(
        _masterVolume * _sfxVolume * volume * distanceFactor,
      );
      await available.setBalance(balance);
      await available.setReleaseMode(ReleaseMode.loop);
      await available.seek(Duration.zero);
      await available.resume();
    } catch (e) {
      return null;
    }

    // Generar ID único para este loop
    final loopId = '${soundId}_${DateTime.now().millisecondsSinceEpoch}';
    _positionalLoops[loopId] = available;
    return loopId;
  }

  /// Actualiza la posición de un loop activo (llamar en update() del enemigo)
  void updatePositionalLoop({
    required String loopId,
    required math.Point<double> sourcePosition,
    required math.Point<double> listenerPosition,
    double maxDistance = 640.0,
    double volume = 1.0,
  }) {
    final player = _positionalLoops[loopId];
    if (player == null || player.state != PlayerState.playing) return;

    final dx = sourcePosition.x - listenerPosition.x;
    final dy = sourcePosition.y - listenerPosition.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    final distanceFactor = distance < maxDistance
        ? 1.0 - (distance / maxDistance).clamp(0.0, 1.0)
        : 0.0;
    final balance = (dx / maxDistance).clamp(-1.0, 1.0);

    // Actualizar sin await para evitar bloqueos en update()
    try {
      player.setVolume(_masterVolume * _sfxVolume * volume * distanceFactor);
      player.setBalance(balance);
    } catch (e) {
      // Silenciar errores de threading
    }
  }

  /// Detiene un loop posicional específico
  Future<void> stopPositionalLoop(String loopId) async {
    final player = _positionalLoops.remove(loopId);
    if (player != null) {
      await player.stop();
    }
  }

  /// Detiene todos los loops posicionales
  Future<void> stopAllPositionalLoops() async {
    for (final player in _positionalLoops.values) {
      await player.stop();
    }
    _positionalLoops.clear();
  }

  /// Actualiza el volumen maestro (desde SettingsBloc)
  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
  }

  /// Actualiza el volumen de SFX
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  /// Limpia recursos al cerrar el juego
  Future<void> dispose() async {
    await stopAllPositionalLoops();
    for (final pool in _pools.values) {
      for (final player in pool) {
        await player.dispose();
      }
    }
    _pools.clear();
    _isLoaded.clear();
    _isInitialized = false;
  }

  /// Pausa todos los sonidos activos (para cuando la app va a segundo plano)
  Future<void> pauseAll() async {
    for (final pool in _pools.values) {
      for (final player in pool) {
        if (player.state == PlayerState.playing) {
          await player.pause();
        }
      }
    }
    for (final player in _positionalLoops.values) {
      if (player.state == PlayerState.playing) {
        await player.pause();
      }
    }
  }

  /// Reanuda los sonidos que estaban pausados (al volver a primer plano)
  /// Nota: Esto es simplificado, idealmente deberíamos trackear cuáles estaban sonando.
  /// Por ahora, asumimos que si estaba en 'playing' antes de pauseAll, debería reanudarse,
  /// pero PlayerState.paused es el estado después de pause().
  /// Una mejor estrategia es pausar el contexto o mutear.
  /// Sin embargo, audioplayers no tiene "pause context".
  /// Vamos a usar setMasterVolume(0) para "silenciar" globalmente si es más fácil,
  /// pero pause() ahorra CPU.
  ///
  /// Estrategia mejorada: Guardar lista de players pausados por nosotros.
  final List<AudioPlayer> _pausedByApp = [];

  Future<void> pauseAllWithMemory() async {
    _pausedByApp.clear();
    for (final pool in _pools.values) {
      for (final player in pool) {
        if (player.state == PlayerState.playing) {
          await player.pause();
          _pausedByApp.add(player);
        }
      }
    }
    for (final player in _positionalLoops.values) {
      if (player.state == PlayerState.playing) {
        await player.pause();
        _pausedByApp.add(player);
      }
    }
  }

  Future<void> resumeAllWithMemory() async {
    for (final player in _pausedByApp) {
      await player.resume();
    }
    _pausedByApp.clear();
  }
}
