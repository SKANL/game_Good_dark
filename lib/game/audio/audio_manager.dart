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
  final Map<String, int> _rrIndices = {}; // Round-Robin indices

  // Referencias a sonidos activos para control posicional
  final Map<String, AudioPlayer> _positionalLoops = {};

  // Ambient tracks handling
  AudioPlayer? _currentAmbient;
  AudioPlayer? _fadingOutAmbient;
  String? _currentAmbientId;

  // Volumen maestro (0.0 - 1.0)
  double _masterVolume = 1.0;
  double _sfxVolume = 1.0;

  // Dedicated player for footsteps (doesn't share pool)
  AudioPlayer? _footstepPlayer;
  String? _currentFootstepSoundId;

  bool _isInitialized = false;

  /// Precarga todos los assets de audio necesarios
  Future<void> preload() async {
    if (_isInitialized) return;

    try {
      // Configurar el contexto de audio para juegos (baja latencia, foco)
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus:
                AndroidAudioFocus.none, // Allow mixing, don't steal focus
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient, // Allow mixing
            options: {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );

      // SFX del jugador
      await _preloadSound('eco_ping', poolSize: 5);
      await _preloadSound('rupture_blast', poolSize: 4);
      await _preloadSound('rejection_shield', poolSize: 2);
      await _preloadSound('absorb_inhale', poolSize: 2);
      await _preloadSound('footstep_normal_01', poolSize: 6);
      await _preloadSound('footstep_stealth_01', poolSize: 4);
      await _preloadSound('select_main', poolSize: 3);
      await _preloadSound('jump', poolSize: 3); // Jump audio
      await _preloadSound('muerte_horror', poolSize: 1); // Death audio

      // Ambient Loops
      await _preloadSound('amb_tinnitus_loop', poolSize: 2);
      await _preloadSound('amb_whispers_loop', poolSize: 2);

      // SFX enemigos (DISABLED FOR PERFORMANCE)
      /*
      await _preloadSound('cazador_groan_loop', poolSize: 5);
      await _preloadSound('cazador_alert', poolSize: 3);
      await _preloadSound('cazador_hunt_scream', poolSize: 3);
      await _preloadSound('vigia_static_hum_loop', poolSize: 2);
      await _preloadSound('vigia_alarm_scream', poolSize: 2);
      await _preloadSound('bruto_footstep', poolSize: 3);
      */

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
      await player.setReleaseMode(ReleaseMode.stop);
      try {
        await player.setSource(AssetSource('audio/$soundId.wav'));
        if (soundId == 'select_main') {
          await player.setSource(AssetSource('audio/$soundId.mp3'));
        }
        players.add(player);
      } catch (e) {
        try {
          await player.setSource(AssetSource('audio/$soundId.mp3'));
          players.add(player);
        } catch (e2) {
          debugPrint(
            '[AudioManager] FALLO al cargar asset: $soundId. Error: $e2',
          );
          players.add(player);
        }
      }
    }
    _pools[soundId] = players;
    _isLoaded[soundId] = true;
  }

  /// Reproduce un SFX no-posicional
  Future<void> playSfx(String soundId, {double volume = 1.0}) async {
    if (!(_isLoaded[soundId] ?? false)) {
      debugPrint(
        '[AudioManager] Sound $soundId NOT LOADED. Attempting on-demand load.',
      );
      if (!_pools.containsKey(soundId)) {
        await _preloadSound(soundId, poolSize: 2);
      }
      if (!(_isLoaded[soundId] ?? false)) {
        debugPrint('[AudioManager] FAILED to load $soundId on-demand.');
        return;
      }
    }

    final pool = _pools[soundId]!;
    AudioPlayer? available;
    for (final player in pool) {
      if (player.state != PlayerState.playing) {
        available = player;
        break;
      }
    }

    // Round-Robin Fallback (evita saturar siempre al primer player)
    if (available == null) {
      var index = _rrIndices[soundId] ?? 0;
      index = (index + 1) % pool.length;
      _rrIndices[soundId] = index;
      available = pool[index];
    }

    debugPrint(
      '[AudioManager] playSfx $soundId | Vol: $volume | Master: $_masterVolume | SFX: $_sfxVolume',
    );

    // FIRE-AND-FORGET: Intentar reproducir sin esperar a stop().
    // Usamos seek(0) + resume() que funciona en cualquier estado (Playing/Paused/Stopped).
    try {
      final clampedVolume = (_masterVolume * _sfxVolume * volume).clamp(
        0.0,
        1.0,
      );

      // No usamos await para no bloquear, pero encadenamos las promesas
      // para mantener el orden de operaciones.
      available
          .setVolume(clampedVolume)
          .then((_) {
            return available!.setReleaseMode(ReleaseMode.stop);
          })
          .then((_) {
            return available!.seek(Duration.zero);
          })
          .then((_) {
            return available!.resume();
          })
          .then((_) {
            debugPrint('[AudioManager] SUCCESS playing $soundId');
          })
          .catchError((e) {
            debugPrint(
              '[AudioManager] ERROR playing $soundId: $e. Trying fallback player.',
            );
            // Fallback: Create a temporary player to ensure sound plays
            final tempPlayer = AudioPlayer();
            tempPlayer.setSource(AssetSource('audio/$soundId.wav')).then((_) {
              tempPlayer.setVolume(clampedVolume);
              tempPlayer.resume();
              // Dispose on complete OR after timeout (safety net)
              tempPlayer.onPlayerComplete.listen((_) => tempPlayer.dispose());
              Future.delayed(
                const Duration(seconds: 5),
                () => tempPlayer.dispose(),
              );
            });
          });
    } catch (e) {
      debugPrint('[AudioManager] CRITICAL ERROR starting $soundId: $e');
    }
  }

  /// Reproduce un sonido de ambiente con cross-fade
  Future<void> playAmbient(String soundId, {double volume = 1.0}) async {
    if (_currentAmbientId == soundId &&
        _currentAmbient?.state == PlayerState.playing)
      return;

    if (_currentAmbient != null) {
      _fadingOutAmbient = _currentAmbient;
      _fadeOut(_fadingOutAmbient!);
    }

    _currentAmbientId = soundId;
    _currentAmbient = AudioPlayer();
    await _currentAmbient!.setReleaseMode(ReleaseMode.loop);

    try {
      try {
        await _currentAmbient!.setSource(AssetSource('audio/$soundId.wav'));
      } catch (_) {
        await _currentAmbient!.setSource(AssetSource('audio/$soundId.mp3'));
      }

      await _currentAmbient!.setVolume(0);
      await _currentAmbient!.resume();
      _fadeIn(
        _currentAmbient!,
        targetVolume: (_masterVolume * _sfxVolume * volume).clamp(0.0, 1.0),
      );
    } catch (e) {
      debugPrint("Error playing ambient: $e");
    }
  }

  void _fadeIn(AudioPlayer player, {required double targetVolume}) {
    double vol = 0;
    const step = 0.05;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (player.state != PlayerState.playing) {
        timer.cancel();
        return;
      }
      vol += step;
      if (vol >= targetVolume) {
        vol = targetVolume;
        player.setVolume(vol);
        timer.cancel();
      } else {
        player.setVolume(vol);
      }
    });
  }

  void _fadeOut(AudioPlayer player) {
    double vol = player.volume;
    const step = 0.05;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      vol -= step;
      if (vol <= 0) {
        vol = 0;
        player.setVolume(0);
        player.stop();
        player.dispose();
        timer.cancel();
      } else {
        player.setVolume(vol);
      }
    });
  }

  Future<void> stopAmbient() async {
    if (_currentAmbient != null) {
      _fadeOut(_currentAmbient!);
      _currentAmbient = null;
      _currentAmbientId = null;
    }
  }

  /// Reproduce un SFX con audio posicional
  /// Reproduce un SFX con audio posicional (Fire-and-Forget + Fallback)
  void playPositional({
    required String soundId,
    required math.Point<double> sourcePosition,
    required math.Point<double> listenerPosition,
    double maxDistance = 640.0,
    double volume = 1.0,
    bool loop = false,
  }) {
    if (!(_isLoaded[soundId] ?? false)) {
      debugPrint(
        '[AudioManager] WARNING: $soundId not loaded for positional play',
      );
      return;
    }

    final pool = _pools[soundId]!;
    AudioPlayer? available;

    // 1. Round-Robin Selection
    final startIndex = _rrIndices[soundId] ?? 0;
    for (var i = 0; i < pool.length; i++) {
      final index = (startIndex + i) % pool.length;
      final player = pool[index];
      if (player.state != PlayerState.playing) {
        available = player;
        _rrIndices[soundId] = (index + 1) % pool.length;
        break;
      }
    }

    // Calculate 3D Audio Params
    final dx = sourcePosition.x - listenerPosition.x;
    final dy = sourcePosition.y - listenerPosition.y;
    final distance = math.sqrt(dx * dx + dy * dy);

    final distanceFactor = distance < maxDistance
        ? 1.0 - (distance / maxDistance).clamp(0.0, 1.0)
        : 0.0;

    if (distanceFactor <= 0.0) return; // Too far to hear

    final balance = (dx / maxDistance).clamp(-1.0, 1.0);
    final finalVolume = (_masterVolume * _sfxVolume * volume * distanceFactor)
        .clamp(0.0, 1.0);

    // 2. Play or Fallback
    if (available != null) {
      available
          .setVolume(finalVolume)
          .then((_) => available!.setBalance(balance))
          .then(
            (_) => available!.setReleaseMode(
              loop ? ReleaseMode.loop : ReleaseMode.stop,
            ),
          )
          .then((_) => available!.seek(Duration.zero))
          .then((_) => available!.resume())
          .catchError((e) {
            debugPrint(
              '[AudioManager] ERROR positional $soundId: $e. Using fallback.',
            );
            _playPositionalFallback(soundId, finalVolume, balance, loop);
          });
    } else {
      // Pool exhausted, force fallback
      debugPrint('[AudioManager] POOL EXHAUSTED for $soundId. Using fallback.');
      _playPositionalFallback(soundId, finalVolume, balance, loop);
    }
  }

  void _playPositionalFallback(
    String soundId,
    double volume,
    double balance,
    bool loop,
  ) {
    final tempPlayer = AudioPlayer();
    tempPlayer
        .setSource(AssetSource('audio/$soundId.wav'))
        .then((_) {
          tempPlayer.setVolume(volume);
          tempPlayer.setBalance(balance);
          tempPlayer.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
          tempPlayer.resume();

          // Safety disposal
          if (!loop) {
            tempPlayer.onPlayerComplete.listen((_) => tempPlayer.dispose());
            Future.delayed(
              const Duration(seconds: 5),
              () => tempPlayer.dispose(),
            );
          } else {
            // If it's a loop fallback, we can't easily track it to stop it later without an ID.
            // Ideally, positional loops shouldn't hit fallback often.
            // For now, we'll let it run but warn.
            debugPrint(
              '[AudioManager] WARNING: Fallback loop started for $soundId. Might leak if not tracked.',
            );
          }
        })
        .catchError((e) {
          debugPrint('[AudioManager] CRITICAL FALLBACK ERROR $soundId: $e');
          tempPlayer.dispose();
        });
  }

  /// Inicia un loop posicional (para enemigos)
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

    // Round-Robin Fallback for Positional Loops
    if (available == null) {
      var index = _rrIndices[soundId] ?? 0;
      index = (index + 1) % pool.length;
      _rrIndices[soundId] = index;
      available = pool[index];
    }

    final dx = sourcePosition.x - listenerPosition.x;
    final dy = sourcePosition.y - listenerPosition.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    final distanceFactor = distance < maxDistance
        ? 1.0 - (distance / maxDistance).clamp(0.0, 1.0)
        : 0.0;
    final balance = (dx / maxDistance).clamp(-1.0, 1.0);

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

    final loopId = '${soundId}_${DateTime.now().millisecondsSinceEpoch}';
    _positionalLoops[loopId] = available;
    return loopId;
  }

  /// Actualiza la posición de un loop activo
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

    try {
      player.setVolume(_masterVolume * _sfxVolume * volume * distanceFactor);
      player.setBalance(balance);
    } catch (e) {
      // Silenciar errores
    }
  }

  /// Detiene un loop posicional específico (Fire-and-Forget)
  Future<void> stopPositionalLoop(String loopId) async {
    final player = _positionalLoops.remove(loopId);
    if (player != null) {
      // No await para evitar bloqueos si el engine falla
      player.stop().then((_) => player.seek(Duration.zero)).catchError((e) {
        debugPrint('[AudioManager] Error stopping loop $loopId: $e');
      });
    }
  }

  /// Detiene todos los loops posicionales
  Future<void> stopAllPositionalLoops() async {
    for (final player in _positionalLoops.values) {
      await player.stop();
    }
    _positionalLoops.clear();
  }

  // --- FOOTSTEP LOGIC (ROBUST) ---

  Future<void> _createFootstepPlayer() async {
    _footstepPlayer = AudioPlayer();
    await _footstepPlayer!.setReleaseMode(ReleaseMode.loop);
    _currentFootstepSoundId = null; // Reset to force load
  }

  Future<void> _disposeFootstepPlayer() async {
    if (_footstepPlayer != null) {
      try {
        await _footstepPlayer!.dispose();
      } catch (_) {}
      _footstepPlayer = null;
      _currentFootstepSoundId = null;
    }
  }

  /// Inicia el loop de pasos dedicado (no comparte pool con otros sonidos)
  Future<void> startFootstepLoop({
    required String soundId,
    required double volume,
    double playbackRate = 1.0,
  }) async {
    try {
      // Ensure player exists
      if (_footstepPlayer == null) {
        await _createFootstepPlayer();
      }

      // If already playing, just update parameters
      if (_footstepPlayer!.state == PlayerState.playing) {
        await _footstepPlayer!.setVolume(_masterVolume * _sfxVolume * volume);
        await _footstepPlayer!.setPlaybackRate(playbackRate);
        return;
      }

      // Load source if needed
      if (_currentFootstepSoundId != soundId) {
        try {
          await _footstepPlayer!.setSource(AssetSource('audio/$soundId.wav'));
        } catch (_) {
          await _footstepPlayer!.setSource(AssetSource('audio/$soundId.mp3'));
        }
        _currentFootstepSoundId = soundId;
      }

      final clampedVolume = (_masterVolume * _sfxVolume * volume).clamp(
        0.0,
        1.0,
      );
      await _footstepPlayer!.setVolume(clampedVolume);
      await _footstepPlayer!.setPlaybackRate(playbackRate);
      await _footstepPlayer!.resume();
    } catch (e) {
      debugPrint('[AudioManager] Error starting footstep loop: $e');
      // Recovery: Dispose and try to recreate once
      await _disposeFootstepPlayer();
      try {
        await _createFootstepPlayer();
        // Retry load and play
        try {
          await _footstepPlayer!.setSource(AssetSource('audio/$soundId.wav'));
        } catch (_) {
          await _footstepPlayer!.setSource(AssetSource('audio/$soundId.mp3'));
        }
        _currentFootstepSoundId = soundId;
        final clampedVolume = (_masterVolume * _sfxVolume * volume).clamp(
          0.0,
          1.0,
        );
        await _footstepPlayer!.setVolume(clampedVolume);
        await _footstepPlayer!.setPlaybackRate(playbackRate);
        await _footstepPlayer!.resume();
      } catch (e2) {
        debugPrint('[AudioManager] Recovery failed: $e2');
      }
    }
  }

  /// Detiene el loop de pasos (Pausa para reutilizar el player)
  Future<void> stopFootstepLoop() async {
    if (_footstepPlayer != null) {
      try {
        if (_footstepPlayer!.state == PlayerState.playing) {
          await _footstepPlayer!.pause();
        }
      } catch (e) {
        // If error on stop/pause, dispose to be safe
        await _disposeFootstepPlayer();
      }
    }
  }

  /// Actualiza el volumen maestro
  void setMasterVolume(double volume) {
    _masterVolume = volume.clamp(0.0, 1.0);
  }

  /// Actualiza el volumen de SFX
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  /// Limpia recursos al cerrar el juego
  Future<void> dispose() async {
    debugPrint('[AudioManager] Disposing all resources...');
    await stopAllPositionalLoops();
    await stopAmbient();

    await _disposeFootstepPlayer();

    for (final pool in _pools.values) {
      for (final player in pool) {
        await player.dispose();
      }
    }
    _pools.clear();
    _isLoaded.clear();
    _rrIndices.clear();
    _positionalLoops.clear();

    // Reset initialization state to allow re-loading
    _isInitialized = false;
    debugPrint('[AudioManager] Disposed successfully.');
  }

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
    if (_currentAmbient?.state == PlayerState.playing) {
      await _currentAmbient?.pause();
      _pausedByApp.add(_currentAmbient!);
    }
  }

  Future<void> resumeAllWithMemory() async {
    for (final player in _pausedByApp) {
      await player.resume();
    }
    _pausedByApp.clear();
  }
}
