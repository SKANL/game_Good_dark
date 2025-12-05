import 'dart:async' as async;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:echo_world/game/audio/audio_manager.dart';
import 'package:echo_world/game/components/core/raycast_renderer_component.dart';
import 'package:echo_world/game/components/core/ruido_mental_system_component.dart';
import 'package:echo_world/game/components/lighting/lighting_layer_component.dart';
import 'package:echo_world/game/components/lighting/lighting_system.dart';
import 'package:echo_world/game/components/ui/crosshair_component.dart';
import 'package:echo_world/game/components/vfx/camera_shake_component.dart';
import 'package:echo_world/game/components/vfx/flash_overlay_component.dart';
import 'package:echo_world/game/components/vfx/screen_transition_component.dart';
import 'package:echo_world/game/cubit/audio/audio_cubit.dart';
import 'package:echo_world/game/cubit/checkpoint/checkpoint_bloc.dart';
import 'package:echo_world/game/cubit/game/game_bloc.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:echo_world/lore/cubit/lore_bloc.dart';
import 'package:echo_world/game/entities/player/player.dart';
import 'package:echo_world/game/input/input_manager.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:echo_world/game/level/manager/level_manager.dart';
import 'package:echo_world/game/level/core/sound_bus.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:echo_world/game/components/lighting/has_lighting.dart';

class BlackEchoGame extends FlameGame with HasCollisionDetection, HasLighting {
  BlackEchoGame({
    required this.audioCubit,
    required this.gameBloc,
    required this.checkpointBloc,
    required this.loreBloc,
  }) : super(world: World());

  final AudioCubit audioCubit;
  final GameBloc gameBloc;
  final CheckpointBloc checkpointBloc;
  final LoreBloc loreBloc;

  /// Loop ID del tinnitus ambiental
  String? _tinnitusLoopId;
  double _lastTinnitusVolume = -1.0;

  /// Loop ID de los susurros (High Stress)
  String? _whisperLoopId;
  double _lastWhisperVolume = -1.0;

  // Audio Atmosphere State
  bool _isHighNoiseAtmosphere = false;
  async.Timer? _bgmFadeTimer;
  async.Timer? _ambientFadeTimer;

  late final PlayerComponent player;
  late final LevelManagerComponent levelManager;

  late final InputManager input;
  late final SoundBusComponent soundBus;
  late final RuidoMentalSystemComponent ruidoMentalSystem;
  @override
  late final LightingSystem lightingSystem;
  bool _cameraReady = false;

  /// Input virtual desde Flutter (Joystick Overlay)
  Vector2 virtualJoystickInput = Vector2.zero();

  /// Renderizador de raycasting para el modo First-Person.
  ///
  /// Se añade al mundo solo cuando `enfoqueActual == Enfoque.firstPerson`.
  /// Este componente se integra directamente en el pipeline de renderizado
  /// de Flame, reemplazando la vista 2D con una proyección 3D desde la
  /// posición y orientación del jugador.
  ///
  /// **Lifecycle:**
  /// - `null` en modos topDown/sideScroll
  /// - Instanciado y añadido al world en modo firstPerson
  /// - Removido del world al cambiar de perspectiva
  RaycastRendererComponent? _raycastRenderer;
  async.StreamSubscription<GameState>? _sub;
  Enfoque? _lastEnfoque; // Cache para detectar cambios correctamente

  @override
  ui.Color backgroundColor() => const ui.Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    // Inicializar AudioManager (preload de assets)
    await AudioManager.instance.preload();

    // Resolución dinámica en función del alto lógico del dispositivo.
    // Mantiene una altura base de 360 y ajusta el ancho según el aspect ratio.
    // Evita deformaciones en pantallas muy alargadas o muy anchas mediante clamp.
    _cameraReady = true;
    _recalcularViewport();

    levelManager = LevelManagerComponent(checkpointBloc: checkpointBloc);
    await world.add(levelManager);

    player = PlayerComponent(gameBloc: gameBloc)..position = Vector2(80, 80);
    await world.add(player);

    camera.follow(player);

    input = InputManager();
    await add(input);

    soundBus = SoundBusComponent();
    await add(soundBus);

    ruidoMentalSystem = RuidoMentalSystemComponent(gameBloc: gameBloc);
    await add(ruidoMentalSystem);

    // Initialize Lighting System
    lightingSystem = LightingSystem();
    await add(lightingSystem);

    // Add Lighting Layer (2D Darkness/Lights)
    // Render priority is handled inside the component (100)
    await world.add(
      LightingLayerComponent(
        lightingSystem: lightingSystem,
        getEnfoque: () => gameBloc.state.enfoqueActual,
      ),
    );

    // Añadir retícula (crosshair) para first-person
    final crosshair = CrosshairComponent();
    await add(
      crosshair,
    ); // Agregar al game, no al viewport para no afectar layout

    // Inicializar cache para detección de cambios
    _lastEnfoque = gameBloc.state.enfoqueActual;

    _sub = gameBloc.stream.listen((newState) {
      if (newState.estadoJuego == EstadoJuego.pausado) {
        pauseEngine();
      } else {
        resumeEngine();
      }

      // Actualizar enfoque del jugador y ajustar cámara cuando cambie
      if (newState.enfoqueActual != _lastEnfoque) {
        final targetEnfoque = newState.enfoqueActual;
        _lastEnfoque = targetEnfoque;

        add(
          ScreenTransitionComponent(
            onTransition: () {
              player.setEnfoque(targetEnfoque);
              _ajustarCamara(targetEnfoque);
            },
          ),
        );
      }

      // Actualizar atmósfera de audio (Cross-fade BGM <-> Tinnitus)
      _updateAudioAtmosphere(newState.ruidoMental);
    });

    // Iniciar loop de tinnitus ambiental (silenciado inicialmente)
    _tinnitusLoopId = await AudioManager.instance.startPositionalLoop(
      soundId: 'amb_tinnitus_loop',
      sourcePosition: const math.Point(0, 0),
      listenerPosition: const math.Point(0, 0),
      maxDistance: 1, // No atenuación por distancia
      volume: 0, // Empieza en silencio
    );

    // Iniciar loop de susurros (silenciado inicialmente)
    // Se activa cuando ruidoMental > 75
    _whisperLoopId = await AudioManager.instance.startPositionalLoop(
      soundId: 'amb_whispers_loop',
      sourcePosition: const math.Point(0, 0),
      listenerPosition: const math.Point(0, 0),
      maxDistance: 1,
      volume: 0,
    );

    // Activar overlay inicial según el enfoque al cargar
    Future.microtask(() {
      switch (gameBloc.state.enfoqueActual) {
        case Enfoque.topDown:
          overlays.add('HudTopDown');
        case Enfoque.sideScroll:
          overlays.add('HudSideScroll');
        case Enfoque.firstPerson:
          overlays.add('HudFirstPerson');
        // case Enfoque.scan:
        //   overlays.add('HudFirstPerson');
        default:
          break;
      }
    });
  }

  /// Recalcula la resolución del viewport cuando cambian las métricas.
  void _recalcularViewport() {
    if (!_cameraReady) return;
    final windowSize = ui.window.physicalSize / ui.window.devicePixelRatio;

    // Usar la resolución lógica completa del dispositivo (sin letterboxing)
    // Esto hace que la vista del raycaster ocupe TODO el área disponible
    // evitando barras negras laterales provocadas por mantener una resolución
    // fija con aspect ratio distinto al del dispositivo.
    final deviceWidth = windowSize.width;
    final deviceHeight = windowSize.height;

    camera.viewport = FixedSizeViewport(deviceWidth, deviceHeight);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _recalcularViewport();
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Enforce BGM silence in High Noise atmosphere (prevent leaks from volume toggle)
    if (_isHighNoiseAtmosphere &&
        audioCubit.bgm.audioPlayer.volume > 0 &&
        !(_bgmFadeTimer?.isActive ?? false)) {
      audioCubit.bgm.audioPlayer.setVolume(0);
    }
  }

  /// Gestiona la transición entre Música y Tinnitus según el nivel de ruido
  void _updateAudioAtmosphere(int ruidoMental) {
    final isHighNoise = ruidoMental > 40;

    // 1. Detectar cambio de estado (Normal <-> High Noise)
    if (isHighNoise != _isHighNoiseAtmosphere) {
      _isHighNoiseAtmosphere = isHighNoise;
      if (isHighNoise) {
        _crossFadeToAmbient();
      } else {
        _crossFadeToBgm();
      }
    }

    // 2. Si estamos en High Noise, actualizar volumen del tinnitus dinámicamente
    if (_isHighNoiseAtmosphere && _tinnitusLoopId != null) {
      final targetVolume = (ruidoMental / 100.0).clamp(0.0, 1.0);
      // Solo actualizar si el cambio es significativo (> 5%) para no saturar
      if ((targetVolume - _lastTinnitusVolume).abs() > 0.05) {
        _lastTinnitusVolume = targetVolume;
        AudioManager.instance.updatePositionalLoop(
          loopId: _tinnitusLoopId!,
          sourcePosition: const math.Point(0, 0),
          listenerPosition: const math.Point(0, 0),
          maxDistance: 1,
          volume: targetVolume,
        );
      }
    }

    // 3. Gestionar Susurros (Whispers) si ruidoMental > 75
    if (_whisperLoopId != null) {
      double targetWhisperVol = 0.0;
      if (ruidoMental > 75) {
        // Escalar de 0.0 a 0.5 entre 75 y 100 de ruido
        targetWhisperVol = ((ruidoMental - 75) / 25.0 * 0.5).clamp(0.0, 0.5);
      }

      if ((targetWhisperVol - _lastWhisperVolume).abs() > 0.05) {
        _lastWhisperVolume = targetWhisperVol;
        AudioManager.instance.updatePositionalLoop(
          loopId: _whisperLoopId!,
          sourcePosition: const math.Point(0, 0),
          listenerPosition: const math.Point(0, 0),
          maxDistance: 1,
          volume: targetWhisperVol,
        );
      }
    }
  }

  void _crossFadeToAmbient() {
    debugPrint('[AudioAtmosphere] Fading to AMBIENT (Tinnitus)');
    _bgmFadeTimer?.cancel();
    _ambientFadeTimer?.cancel();

    // Fade Out BGM
    _bgmFadeTimer = async.Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      final currentVol = audioCubit.bgm.audioPlayer.volume;
      if (currentVol <= 0) {
        audioCubit.bgm.audioPlayer.setVolume(0);
        timer.cancel();
      } else {
        audioCubit.bgm.audioPlayer.setVolume(
          (currentVol - 0.05).clamp(0.0, 1.0),
        );
      }
    });

    // Fade In Ambient (handled by update loop mostly, but ensure it starts)
    // El volumen del tinnitus se actualizará en el siguiente ciclo de _updateAudioAtmosphere
  }

  void _crossFadeToBgm() {
    debugPrint('[AudioAtmosphere] Fading to BGM');
    _bgmFadeTimer?.cancel();
    _ambientFadeTimer?.cancel();

    // Fade In BGM
    final targetBgmVol =
        audioCubit.state.volume * 0.1; // 10% max as per AudioCubit
    _bgmFadeTimer = async.Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      final currentVol = audioCubit.bgm.audioPlayer.volume;
      if (currentVol >= targetBgmVol) {
        audioCubit.bgm.audioPlayer.setVolume(targetBgmVol);
        timer.cancel();
      } else {
        audioCubit.bgm.audioPlayer.setVolume(
          (currentVol + 0.01).clamp(0.0, targetBgmVol),
        );
      }
    });

    // Fade Out Ambient
    if (_tinnitusLoopId != null) {
      _ambientFadeTimer = async.Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        // Bajamos el volumen interno del loop manualmente
        // Nota: Esto es un hack visual, idealmente AudioManager manejaría faders.
        // Por ahora, confiamos en que _updateAudioAtmosphere dejará de actualizarlo
        // y nosotros lo bajamos a 0.
        AudioManager.instance.updatePositionalLoop(
          loopId: _tinnitusLoopId!,
          sourcePosition: const math.Point(0, 0),
          listenerPosition: const math.Point(0, 0),
          maxDistance: 1,
          volume: 0, // Forzar silencio gradual? No, mejor corte suave.
        );
        timer
            .cancel(); // Instant cut for ambient for now, or implement manual fade logic if needed.
        // Realmente, al poner _isHighNoiseAtmosphere = false, el update deja de tocarlo.
        // Deberíamos bajarlo a 0 explícitamente.
        AudioManager.instance.updatePositionalLoop(
          loopId: _tinnitusLoopId!,
          sourcePosition: const math.Point(0, 0),
          listenerPosition: const math.Point(0, 0),
          maxDistance: 1,
          volume: 0,
        );
      });
    }
  }

  /// Ajustar la configuración de la cámara según el enfoque actual.
  ///
  /// **MODO FIRST-PERSON:**
  /// En FP, se añade el RaycastRendererComponent directamente al GAME (no al world)
  /// para que renderice en el canvas completo sin transformación de cámara.
  /// Este componente proyecta el nivel en 3D desde la posición del jugador.
  /// CRÍTICO: La cámara se DETIENE (no sigue al jugador) porque el raycaster
  /// renderiza desde la posición absoluta del jugador en el mundo.
  ///
  /// **MODOS TOP-DOWN Y SIDE-SCROLL:**
  /// Se quita el raycaster si existe y la cámara sigue al jugador normalmente.
  void _ajustarCamara(Enfoque enfoque) {
    switch (enfoque) {
      case Enfoque.topDown:
        // Quitar raycaster si existe
        if (_raycastRenderer != null) {
          remove(_raycastRenderer!);
          _raycastRenderer = null;
        }
        camera.follow(player);
      case Enfoque.sideScroll:
        // Quitar raycaster si existe
        if (_raycastRenderer != null) {
          remove(_raycastRenderer!);
          _raycastRenderer = null;
        }
        camera.follow(player);
      case Enfoque.firstPerson:
        // Añadir raycaster para renderizar en 3D
        // CRÍTICO: Se agrega al GAME directamente, no al world
        // Esto permite que renderice en el canvas completo sin transformación de cámara
        if (_raycastRenderer == null) {
          _raycastRenderer = RaycastRendererComponent();
          add(_raycastRenderer!);
        }
        // CRÍTICO: Detener la cámara. El raycaster maneja la vista.
        camera.stop();
      default:
        // Enfoque.scan y otros futuros
        break;
    }
  }

  @override
  void onRemove() {
    _sub?.cancel();
    if (_tinnitusLoopId != null) {
      AudioManager.instance.stopPositionalLoop(_tinnitusLoopId!);
    }
    if (_whisperLoopId != null) {
      AudioManager.instance.stopPositionalLoop(_whisperLoopId!);
    }
    super.onRemove();
  }

  @override
  void lifecycleStateChange(ui.AppLifecycleState state) {
    super.lifecycleStateChange(state);
    switch (state) {
      case ui.AppLifecycleState.paused:
      case ui.AppLifecycleState.detached:
      case ui.AppLifecycleState.inactive:
      case ui.AppLifecycleState.hidden:
        AudioManager.instance.pauseAllWithMemory();
      case ui.AppLifecycleState.resumed:
        AudioManager.instance.resumeAllWithMemory();
    }
  }

  void shakeCamera({double intensity = 5, double duration = 0.3}) {
    world.add(CameraShakeComponent(intensity: intensity, duration: duration));
  }

  void triggerFlash({
    Color color = const ui.Color(0xFFFFFFFF),
    double duration = 0.15,
  }) {
    camera.viewport.add(
      FlashOverlayComponent(color: color, duration: duration),
    );
  }

  void emitSound(Vector2 pos, NivelSonido nivel, {double ttl = 1.0}) {
    soundBus.emit(pos, nivel, ttl: ttl);
  }
}
