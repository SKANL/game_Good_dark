import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:echo_world/game/audio/audio_manager.dart';
import 'package:echo_world/game/components/core/raycast_renderer_component.dart';
import 'package:echo_world/game/components/core/ruido_mental_system_component.dart';
import 'package:echo_world/game/components/lighting/lighting_layer_component.dart';
import 'package:echo_world/game/components/lighting/lighting_system.dart';
import 'package:echo_world/game/components/ui/crosshair_component.dart';
import 'package:echo_world/game/components/vfx/camera_shake_component.dart';
import 'package:echo_world/game/components/vfx/screen_transition_component.dart';
import 'package:echo_world/game/cubit/checkpoint/checkpoint_bloc.dart';
import 'package:echo_world/game/cubit/game/game_bloc.dart';
import 'package:echo_world/game/cubit/game/game_state.dart';
import 'package:echo_world/game/entities/player/player.dart';
import 'package:echo_world/game/input/input_manager.dart';
import 'package:echo_world/game/level/core/sound_bus.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:echo_world/game/level/manager/level_manager.dart';
import 'package:echo_world/lore/lore.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

class BlackEchoGame extends FlameGame with HasCollisionDetection {
  BlackEchoGame({
    required this.gameBloc,
    required this.checkpointBloc,
    required this.loreBloc,
  }) : super(world: World());

  final GameBloc gameBloc;
  final CheckpointBloc checkpointBloc;
  final LoreBloc loreBloc;

  /// Loop ID del tinnitus ambiental
  String? _tinnitusLoopId;

  late final PlayerComponent player;
  late final LevelManagerComponent levelManager;

  late final InputManager input;
  late final SoundBusComponent soundBus;
  late final RuidoMentalSystemComponent ruidoMentalSystem;
  late final LightingSystem lightingSystem;
  bool _cameraReady = false;

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
  StreamSubscription<GameState>? _sub;
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
    await world.add(LightingLayerComponent(lightingSystem: lightingSystem));

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

      // Actualizar volumen del tinnitus según ruidoMental
      _actualizarTinnitus(newState.ruidoMental);
    });

    // Iniciar loop de tinnitus ambiental
    _tinnitusLoopId = await AudioManager.instance.startPositionalLoop(
      soundId: 'amb_tinnitus_loop',
      sourcePosition: const math.Point(0, 0),
      listenerPosition: const math.Point(0, 0),
      maxDistance: 1, // No atenuación por distancia
      volume: gameBloc.state.ruidoMental / 100.0,
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

    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(deviceWidth, deviceHeight),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _recalcularViewport();
  }

  /// Actualiza el volumen del tinnitus según el ruidoMental
  void _actualizarTinnitus(int ruidoMental) {
    if (_tinnitusLoopId != null) {
      AudioManager.instance.updatePositionalLoop(
        loopId: _tinnitusLoopId!,
        sourcePosition: const math.Point(0, 0),
        listenerPosition: const math.Point(0, 0),
        maxDistance: 1,
        volume: ruidoMental / 100.0,
      );
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

  void emitSound(Vector2 pos, NivelSonido nivel, {double ttl = 1.0}) {
    soundBus.emit(pos, nivel, ttl: ttl);
  }
}
