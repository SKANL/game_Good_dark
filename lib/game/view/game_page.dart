import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:echo_world/game/audio/audio_manager.dart';
import 'package:echo_world/game/game.dart';
import 'package:echo_world/game/entities/player/player.dart';
import 'package:echo_world/game/cubit/checkpoint/cubit.dart';
import 'package:echo_world/gen/assets.gen.dart';
import 'package:echo_world/game/level/data/level_models.dart';
import 'package:echo_world/lore/lore.dart';
import 'package:echo_world/loading/cubit/cubit.dart';
import 'package:flame/game.dart' hide Route;
import 'package:flame_audio/bgm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const GamePage());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final audioCache = context.read<PreloadCubit>().audio;
            return AudioCubit(
              audioPlayer: AudioPlayer()..audioCache = audioCache,
              backgroundMusic: Bgm(audioCache: audioCache),
            );
          },
        ),
        BlocProvider(create: (_) => CheckpointBloc()),
        BlocProvider(
          create: (context) => GameBloc(
            checkpointBloc: context.read<CheckpointBloc>(),
          ),
        ),
      ],
      child: const Scaffold(body: GameView()),
    );
  }
}

class GameView extends StatefulWidget {
  const GameView({super.key, this.game});

  final FlameGame? game;

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  FlameGame? _game;

  late final Bgm bgm;

  @override
  void initState() {
    super.initState();
    bgm = context.read<AudioCubit>().bgm;
    // Lower BGM volume significantly as requested
    unawaited(bgm.play(Assets.audio.background, volume: 0.1));
  }

  @override
  void dispose() {
    unawaited(bgm.pause());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _game ??=
        widget.game ??
        BlackEchoGame(
          gameBloc: context.read<GameBloc>(),
          checkpointBloc: context.read<CheckpointBloc>(),
          loreBloc: context.read<LoreBloc>(),
        );

    return BlocListener<GameBloc, GameState>(
      listenWhen: (prev, curr) =>
          prev.enfoqueActual != curr.enfoqueActual ||
          prev.estadoJuego != curr.estadoJuego ||
          prev.estadoJugador != curr.estadoJugador,
      listener: (context, state) {
        final game = _game! as BlackEchoGame;
        _updateOverlays(game, state);
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: GameWidget(
              game: _game!,
              overlayBuilderMap: {
                'HudTopDown': (ctx, game) =>
                    _HudTopDown(game! as BlackEchoGame),
                'HudSideScroll': (ctx, game) =>
                    _HudSideScroll(game! as BlackEchoGame),
                'HudFirstPerson': (ctx, game) =>
                    _HudFirstPerson(game! as BlackEchoGame),
                'PauseMenu': (ctx, game) => _PauseMenu(),
                'OverlayFracaso': (ctx, game) => _OverlayFracaso(),
              },
              initialActiveOverlays: [
                switch (context.read<GameBloc>().state.enfoqueActual) {
                  Enfoque.topDown => 'HudTopDown',
                  Enfoque.sideScroll => 'HudSideScroll',
                  Enfoque.firstPerson => 'HudFirstPerson',
                  _ => 'HudTopDown',
                },
              ],
            ),
          ),
          // Overlay de ruido mental (se muestra sobre el juego cuando ruidoMental > 25)
          BlocBuilder<GameBloc, GameState>(
            builder: (context, state) {
              if (state.ruidoMental <= 25) return const SizedBox.shrink();
              return Positioned.fill(
                child: IgnorePointer(
                  child: _RuidoMentalOverlay(
                    intensity: state.ruidoMental / 100,
                  ),
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.topRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BlocBuilder<AudioCubit, AudioState>(
                  builder: (context, state) {
                    return IconButton(
                      icon: Icon(
                        state.volume == 0 ? Icons.volume_off : Icons.volume_up,
                      ),
                      onPressed: () =>
                          context.read<AudioCubit>().toggleVolume(),
                    );
                  },
                ),
                // Botón de DEBUG para avanzar chunks
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF00),
                    foregroundColor: const Color(0xFF000000),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    elevation: 8,
                  ),
                  onPressed: () async {
                    final game = _game! as BlackEchoGame;
                    await game.levelManager.siguienteChunk();
                  },
                  child: const Text(
                    'NEXT\nCHUNK',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateOverlays(BlackEchoGame game, GameState state) {
    game.overlays.clear();
    // Reanudar el motor si está pausado y no estamos en pausa explícita.
    if (game.paused && state.estadoJuego != EstadoJuego.pausado) {
      game.resumeEngine();
    }
    if (state.estadoJuego == EstadoJuego.pausado) {
      game.overlays.add('PauseMenu');
      return;
    }
    if (state.estadoJugador == EstadoJugador.atrapado) {
      game.overlays.add('OverlayFracaso');
      return;
    }
    switch (state.enfoqueActual) {
      case Enfoque.topDown:
        game.overlays.add('HudTopDown');
      case Enfoque.sideScroll:
        game.overlays.add('HudSideScroll');
      case Enfoque.firstPerson:
        game.overlays.add('HudFirstPerson');
      default:
        break;
    }
  }
}

class HexImgButton extends StatefulWidget {
  const HexImgButton({
    super.key,
    required this.assetPath,
    this.onPressed,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.posX = 0.0,
    this.posY = 0.0,
    this.width,
    this.height,
  });

  final String assetPath;
  final VoidCallback? onPressed;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final double posX;
  final double posY;
  final double? width;
  final double? height;

  @override
  State<HexImgButton> createState() => _HexImgButtonState();
}

class _HexImgButtonState extends State<HexImgButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(widget.posX, widget.posY),
      child: ClipPath(
        clipper: const HexagonClipper(),
        child: GestureDetector(
          onTapDown: (details) {
            AudioManager.instance.playSfx('select_main.mp3');
            setState(() => _isPressed = true);
            widget.onTapDown?.call(details);
          },
          onTapUp: (details) {
            setState(() => _isPressed = false);
            widget.onPressed?.call();
            widget.onTapUp?.call(details);
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
            widget.onTapCancel?.call();
          },
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: double.infinity,
                child: FractionalTranslation(
                  // Si está presionado, desplazar -50% del ancho de la imagen para mostrar la mitad derecha
                  translation: Offset(_isPressed ? -0.5 : 0.0, 0.0),
                  child: Image.asset(
                    widget.assetPath,
                    width:
                        (widget.width ?? 100) *
                        2, // El spritesheet es el doble de ancho
                    height: widget.height,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HexagonClipper extends CustomClipper<Path> {
  const HexagonClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    // Hexágono vertical (Pointy Top)
    // Puntos: Arriba-Centro, Arriba-Der, Abajo-Der, Abajo-Centro, Abajo-Izq, Arriba-Izq
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _HudTopDown extends StatelessWidget {
  const _HudTopDown(this.game);
  final BlackEchoGame game;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    final size = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).padding.top;
    final hudWidth = size.width.clamp(300.0, 600.0);

    return SizedBox.expand(
      child: Stack(
        children: [
          // Parte Superior: HUD + Botón Absorber
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: topInset + 10), // Margen superior seguro
                // --- HUD CYBERPUNK ---
                SizedBox(
                  width: hudWidth,
                  child: BlocBuilder<GameBloc, GameState>(
                    buildWhen: (previous, current) =>
                        previous.energiaGrito != current.energiaGrito ||
                        previous.ruidoMental != current.ruidoMental,
                    builder: (context, state) {
                      return BlackEchoHUD(
                        energia: state.energiaGrito,
                        ruido: state.ruidoMental,
                      );
                    },
                  ),
                ),
                // ---------------------

                // Botón [ABSORBER] contextual
                BlocSelector<GameBloc, GameState, bool>(
                  selector: (state) => state.puedeAbsorber,
                  builder: (context, puedeAbsorber) {
                    if (!puedeAbsorber) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: HexImgButton(
                        assetPath: 'assets/img/Botton_Absorver.png',
                        posX: 0.0,
                        posY: 20.0,
                        width: 84,
                        height: 112,
                        onPressed: () {
                          final nucleos = game.world.children
                              .query<NucleoResonanteComponent>();
                          if (nucleos.isNotEmpty) {
                            final closest = nucleos.reduce(
                              (a, b) =>
                                  a.position.distanceTo(game.player.position) <
                                      b.position.distanceTo(
                                        game.player.position,
                                      )
                                  ? a
                                  : b,
                            );

                            game.world.add(
                              AbsorptionVfxComponent(
                                nucleusPosition: closest.position.clone(),
                                playerPosition: game.player.position.clone(),
                              ),
                            );

                            AudioManager.instance.playSfx(
                              'absorb_inhale',
                              volume: 0.5,
                            );

                            closest.removeFromParent();
                          }

                          bloc.add(AbsorcionConfirmada());
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Botones de control inferiores
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 150,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  HexImgButton(
                    assetPath: 'assets/img/Botton_Enfoque.png',
                    posX: 640.0,
                    posY: 0.0,
                    width: 80,
                    height: 105,
                    onPressed: () => bloc.add(EnfoqueCambiado()),
                  ),
                  HexImgButton(
                    assetPath: 'assets/img/Botton_Eco.png',
                    posX: 600.0,
                    posY: 45.0,
                    width: 80,
                    height: 105,
                    onPressed: () {
                      // SFX: Reproducir sonido de eco
                      AudioManager.instance.playSfx('eco_ping', volume: 2);

                      game.world.add(
                        EcholocationVfxComponent(
                          origin: game.player.position.clone(),
                        ),
                      );
                      game.emitSound(
                        game.player.position.clone(),
                        NivelSonido.medio,
                        ttl: 0.8,
                      );

                      if (bloc.state.ruidoMental > 50) {
                        final nuevoRuido = (bloc.state.ruidoMental + 0.5)
                            .clamp(0, 100)
                            .toInt();
                        bloc.add(
                          EcoNarrativoAbsorbido(
                            'sobrecarga_sensorial',
                            nuevoRuido - bloc.state.ruidoMental,
                          ),
                        );
                      }
                    },
                  ),
                  HexImgButton(
                    assetPath: 'assets/img/Botton_Ruptura.png',
                    posX: 562.0,
                    posY: -4.0,
                    width: 84,
                    height: 112,
                    onPressed: () async {
                      if (bloc.state.energiaGrito >= 40) {
                        await game.player.rupture();
                        bloc.add(GritoActivado());
                      }
                    },
                  ),

                  BlocSelector<GameBloc, GameState, bool>(
                    selector: (state) => state.estaAgachado,
                    builder: (context, estaAgachado) {
                      return HexImgButton(
                        assetPath: 'assets/img/Botton_Sigilo.png',
                        posX: 675.0,
                        posY: 45.0,
                        width: 82,
                        height: 107,
                        onTapDown: (_) => bloc.add(ModoSigiloActivado()),
                        onTapUp: (_) => bloc.add(ModoSigiloDesactivado()),
                        onTapCancel: () => bloc.add(ModoSigiloDesactivado()),
                      );
                    },
                  ),
                  //                  HexImgButton(
                  //                    assetPath: 'assets/img/Botton_Chunk.png',
                  //                    posX: 523.0,
                  //                    posY: 42.0,
                  //                    width: 84,
                  //                    height: 112,
                  //                    onPressed: () => game.levelManager.siguienteChunk(),
                  //                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudSideScroll extends StatelessWidget {
  const _HudSideScroll(this.game);
  final BlackEchoGame game;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    final size = MediaQuery.of(context).size;
    final hudScale = (size.shortestSide / 360).clamp(0.8, 1.4);
    final topInset = MediaQuery.of(context).padding.top;
    final absorberTop = (80.0 * hudScale) + topInset;
    final absorberFont = (18.0 * hudScale).clamp(16.0, 26.0);

    return SizedBox.expand(
      child: Stack(
        children: [
          // Botón [ABSORBER] contextual
          BlocSelector<GameBloc, GameState, bool>(
            selector: (state) => state.puedeAbsorber,
            builder: (context, puedeAbsorber) {
              if (!puedeAbsorber) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: absorberTop),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: const Color(0xFF000000),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    onPressed: () {
                      bloc.add(AbsorcionConfirmada());
                      final nucleos = game.world.children
                          .query<NucleoResonanteComponent>();
                      if (nucleos.isNotEmpty) {
                        final closest = nucleos.reduce(
                          (a, b) =>
                              a.position.distanceTo(game.player.position) <
                                  b.position.distanceTo(game.player.position)
                              ? a
                              : b,
                        );

                        final absorptionVfx = AbsorptionVfxComponent(
                          nucleusPosition: closest.position.clone(),
                          playerPosition: game.player.position.clone(),
                        );
                        game.world.add(absorptionVfx);
                        AudioManager.instance.playSfx(
                          'absorb_inhale',
                          volume: 0.5,
                        );
                        closest.removeFromParent();
                      }
                    },
                    child: Text(
                      '[ABSORBER]',
                      style: TextStyle(
                        fontSize: absorberFont,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Botones de control inferiores
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 150,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  HexImgButton(
                    assetPath: 'assets/img/Botton_Enfoque.png',
                    posX: 640.0,
                    posY: 0.0,
                    width: 80,
                    height: 105,
                    onPressed: () => bloc.add(EnfoqueCambiado()),
                  ),
                  HexImgButton(
                    assetPath: 'assets/img/Botton_Eco.png',
                    posX: 600.0,
                    posY: 45.0,
                    width: 80,
                    height: 105,
                    onPressed: () {
                      // SFX: Reproducir sonido de eco
                      AudioManager.instance.playSfx('eco_ping', volume: 2);

                      game.world.add(
                        EcholocationVfxComponent(
                          origin: game.player.position.clone(),
                        ),
                      );
                      game.emitSound(
                        game.player.position.clone(),
                        NivelSonido.medio,
                        ttl: 0.8,
                      );

                      if (bloc.state.ruidoMental > 50) {
                        final nuevoRuido = (bloc.state.ruidoMental + 0.5)
                            .clamp(0, 100)
                            .toInt();
                        bloc.add(
                          EcoNarrativoAbsorbido(
                            'sobrecarga_sensorial',
                            nuevoRuido - bloc.state.ruidoMental,
                          ),
                        );
                      }
                    },
                  ),
                  HexImgButton(
                    assetPath: 'assets/img/Botton_Ruptura.png',
                    posX: 562.0,
                    posY: -4.0,
                    width: 84,
                    height: 112,
                    onPressed: () async {
                      if (bloc.state.energiaGrito >= 40) {
                        await game.player.rupture();
                        bloc.add(GritoActivado());
                      }
                    },
                  ),
                  HexImgButton(
                    assetPath: 'assets/img/Botton_Salto.png',
                    posX: 524.0,
                    posY: 35.0,
                    width: 84,
                    height: 124,
                    onPressed: () {
                      AudioManager.instance.playSfx(
                        'jump',
                        volume: 1.5,
                      ); // Ensure it's audible
                      game.player.jump();
                    },
                  ),
                  BlocSelector<GameBloc, GameState, bool>(
                    selector: (state) => state.estaAgachado,
                    builder: (context, estaAgachado) {
                      return HexImgButton(
                        assetPath: 'assets/img/Botton_Sigilo.png',
                        posX: 675.0,
                        posY: 45.0,
                        width: 82,
                        height: 107,
                        onTapDown: (_) => bloc.add(ModoSigiloActivado()),
                        onTapUp: (_) => bloc.add(ModoSigiloDesactivado()),
                        onTapCancel: () => bloc.add(ModoSigiloDesactivado()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudFirstPerson extends StatelessWidget {
  const _HudFirstPerson(this.game);
  final BlackEchoGame game;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    final size = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).padding.top;
    final hudWidth = size.width.clamp(300.0, 600.0);

    return SizedBox.expand(
      child: Stack(
        // Usamos Stack como base
        children: [
          // 1. EL NUEVO HUD EN LA PARTE SUPERIOR
          Positioned(
            top: topInset + 10,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: hudWidth,
                child: BlocBuilder<GameBloc, GameState>(
                  builder: (context, state) {
                    return BlackEchoHUD(
                      energia: state.energiaGrito,
                      ruido: state.ruidoMental,
                    );
                  },
                ),
              ),
            ),
          ),

          // 2. BOTÓN ABSORBER (Centrado)
          BlocSelector<GameBloc, GameState, bool>(
            selector: (s) => s.puedeAbsorber,
            builder: (context, puedeAbsorber) {
              if (!puedeAbsorber) return const SizedBox.shrink();
              return Center(
                // Centrado en pantalla para FP
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF000000),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    elevation: 8,
                  ),
                  onPressed: () {
                    bloc.add(AbsorcionConfirmada());
                    // Destruir núcleo más cercano con VFX
                    final nucleos = game.world.children
                        .query<NucleoResonanteComponent>();
                    if (nucleos.isNotEmpty) {
                      final closest = nucleos.reduce(
                        (a, b) =>
                            a.position.distanceTo(game.player.position) <
                                b.position.distanceTo(game.player.position)
                            ? a
                            : b,
                      );
                      final absorptionVfx = AbsorptionVfxComponent(
                        nucleusPosition: closest.position.clone(),
                        playerPosition: game.player.position.clone(),
                      );
                      game.world.add(absorptionVfx);
                      AudioManager.instance.playSfx(
                        'absorb_inhale',
                        volume: 0.5,
                      );
                      closest.removeFromParent();
                    }
                  },
                  child: const Text(
                    '[ABSORBER]',
                    style: TextStyle(
                      fontSize:
                          18, // Fixed size for simplicity or use hudScale if needed
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),

          // 3. BOTONES DE ACCIÓN (Abajo)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 150, // Altura fija para el área de botones
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  HexImgButton(
                    assetPath: 'assets/img/Botton_Enfoque.png',
                    posX: 640.0,
                    posY: 0.0,
                    width: 80,
                    height: 105,
                    onPressed: () => bloc.add(EnfoqueCambiado()),
                  ),
                  HexImgButton(
                    assetPath: 'assets/img/Botton_Eco.png',
                    posX: 600.0,
                    posY: 45.0,
                    width: 80,
                    height: 105,
                    onPressed: () {
                      // SFX: Reproducir sonido de eco
                      AudioManager.instance.playSfx('eco_ping', volume: 2);

                      final p = game.player.position.clone();
                      game.world.add(EcholocationVfxComponent(origin: p));
                      game.emitSound(p, NivelSonido.medio, ttl: 0.8);
                      bloc.add(EcoActivado());
                      if (bloc.state.ruidoMental > 50) {
                        final nuevo = (bloc.state.ruidoMental + 0.5)
                            .clamp(0, 100)
                            .toInt();
                        bloc.add(
                          EcoNarrativoAbsorbido(
                            'sobrecarga_sensorial',
                            nuevo - bloc.state.ruidoMental,
                          ),
                        );
                      }
                    },
                  ),
                  HexImgButton(
                    assetPath: 'assets/img/Botton_Ruptura.png',
                    posX: 562.0,
                    posY: -4.0,
                    width: 84,
                    height: 112,
                    onPressed: () async {
                      if (bloc.state.energiaGrito >= 40) {
                        await game.player.rupture();
                        bloc.add(GritoActivado());
                      }
                    },
                  ),
                  BlocSelector<GameBloc, GameState, bool>(
                    selector: (s) => s.estaAgachado,
                    builder: (context, estaAgachado) {
                      return HexImgButton(
                        assetPath: 'assets/img/Botton_Sigilo.png',
                        posX: 675.0,
                        posY: 45.0,
                        width: 82,
                        height: 107,
                        onTapDown: (_) => bloc.add(ModoSigiloActivado()),
                        onTapUp: (_) => bloc.add(ModoSigiloDesactivado()),
                        onTapCancel: () => bloc.add(ModoSigiloDesactivado()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*
// OBSOLETO: _RaycastPainter (CustomPainter) usado para renderizar FP desde Flutter.
// Ahora el raycasting 3D se hace directamente en Flame (RaycastRendererComponent).
// Este código se conserva como referencia histórica pero ya no se usa.
// 
// class _RaycastPainter extends CustomPainter {
//   ...
//   @override
//   void paint(Canvas canvas, Size size) {
//     // Lógica de raycasting en overlay Flutter
//   }
// }
*/

/*
// OBSOLETO: Modo "scan" reemplazado por primera persona con raycasting.
// Se conserva como referencia histórica, pero está deshabilitado.
// class _HudScan extends StatelessWidget { ... }
// class _ScanScenePainter extends CustomPainter { ... }
*/

class _PauseMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    return Center(
      child: ElevatedButton(
        onPressed: () => bloc.add(JuegoReanudado()),
        child: const Text('REANUDAR'),
      ),
    );
  }
}

class _OverlayFracaso extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gameBloc = context.read<GameBloc>();

    return BlocBuilder<CheckpointBloc, CheckpointState>(
      builder: (context, checkpointState) {
        final muertes = checkpointState.muertesEnChunkActual;
        final activarMisericordia = checkpointState.debeActivarMisericordia;

        return ColoredBox(
          color: Colors.black.withOpacity(0.8),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título
                const Text(
                  'ATRAPADO',
                  style: TextStyle(
                    color: Color(0xFF00FFFF),
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Color(0xFF00FFFF),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Información de muertes
                Text(
                  'Muertes en este sector: $muertes',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),

                // Mensaje de Misericordia
                if (activarMisericordia) ...[
                  const Text(
                    '⚡ SISTEMA DE MISERICORDIA ACTIVADO ⚡',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Color(0xFFFFD700),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reiniciarás con Escudo Sónico completo',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],

                // Botón de reinicio
                ElevatedButton(
                  onPressed: () {
                    gameBloc.add(
                      ReinicioSolicitado(
                        conMisericordia: activarMisericordia,
                      ),
                    );
                  },
                  child: const Text('REINTENTAR'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// CustomPainter para renderizar el VFX de ruido mental.
/// Dibuja estática, viñeta y efectos de glitch según la intensidad (0.0 - 1.0).
class _RuidoMentalOverlay extends StatefulWidget {
  const _RuidoMentalOverlay({required this.intensity});
  final double intensity;

  @override
  State<_RuidoMentalOverlay> createState() => _RuidoMentalOverlayState();
}

class _RuidoMentalOverlayState extends State<_RuidoMentalOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Duration arbitrary, just to drive the tick
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _RuidoMentalPainter(
            intensity: widget.intensity,
            tick: _controller.value,
          ),
        );
      },
    );
  }
}

/// CustomPainter para renderizar el VFX de ruido mental.
/// Dibuja estática, viñeta y efectos de glitch según la intensidad (0.0 - 1.0).
class _RuidoMentalPainter extends CustomPainter {
  _RuidoMentalPainter({required this.intensity, required this.tick});
  final double intensity; // 0.0 a 1.0
  final double tick; // 0.0 a 1.0 (animación)

  // Cache estática para reducir costo por frame.
  static List<Rect> _cachedRects = [];
  static Size? _cachedSize;
  static const int _maxRects = 120; // límite superior

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;

    // 1. Viñeta oscura (más intensa a mayor ruido)
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(intensity * 0.6),
        ],
        stops: const [0.4, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Offset.zero & size, vignette);

    // 2. Estática (rectángulos) con cache
    if (_cachedSize != size || _cachedRects.isEmpty) {
      _cachedSize = size;
      _cachedRects = [];
      final randSeed = size.width.toInt() ^ size.height.toInt();
      for (var i = 0; i < _maxRects; i++) {
        final x = ((i * 31 + randSeed) % size.width.toInt()).toDouble();
        final y = ((i * 37 + randSeed) % size.height.toInt()).toDouble();
        final w = ((i * 7 + randSeed) % 20 + 5).toDouble();
        final h = ((i * 11 + randSeed) % 20 + 5).toDouble();
        _cachedRects.add(Rect.fromLTWH(x, y, w, h));
      }
    }

    // Animar la estática cambiando cuáles se dibujan o su opacidad
    // Usamos el tick para variar el "seed" visual de la estática
    final drawCount = (_maxRects * intensity).toInt();
    final staticPaint = Paint()
      ..color = Colors.white.withOpacity(intensity * 0.12);

    // Desplazamiento de índice basado en el tiempo para que la estática "baile"
    final indexOffset = (tick * 100).toInt();

    for (var i = 0; i < drawCount; i++) {
      final index = (i + indexOffset) % _cachedRects.length;
      canvas.drawRect(_cachedRects[index], staticPaint);
    }

    // 3. Glitch (traslación de bandas horizontales)
    if (intensity > 0.5) {
      canvas.save();
      // Usar tick para el desplazamiento en lugar de DateTime.now()
      final glitchOffset = ((tick * 20) % 20 - 10) * (intensity - 0.5);
      canvas.translate(glitchOffset, 0);
      final glitchPaint = Paint()
        ..color = const Color(0xFF8A2BE2).withOpacity((intensity - 0.5) * 0.4)
        ..blendMode = BlendMode.screen;
      for (var i = 0; i < 5; i++) {
        final y = (size.height / 5) * i;
        // Variar ligeramente por banda
        if ((i + (tick * 10).toInt()) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(0, y, size.width, size.height / 5),
            glitchPaint,
          );
        }
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RuidoMentalPainter oldDelegate) {
    return oldDelegate.intensity != intensity || oldDelegate.tick != tick;
  }
}

// --- NUEVO COMPONENTE VISUAL: HUD CYBERPUNK ---

class BlackEchoHUD extends StatelessWidget {
  final int energia;
  final int ruido;

  const BlackEchoHUD({
    super.key,
    required this.energia,
    required this.ruido,
  });

  @override
  Widget build(BuildContext context) {
    // --- VARIABLES DE AJUSTE MANUAL DEL CONTENEDOR ---
    // Modifica estos valores para mover/escalar la imagen de fondo principal
    const double containerX = 0.0;
    const double containerY = -13.5;
    const double containerW = 600.0; // Ancho por defecto
    const double containerH = 85.0; // Alto por defecto

    // --- VARIABLES DE AJUSTE BARRA CENTRAL (VIDA) ---
    const double centralX = 248.0;
    const double centralY = -13.5;
    const double centralW = 103.0; // Ancho por defecto
    const double centralH = 81.0; // Alto por defecto

    // --- FÓRMULA DE VIDA ---
    // Convierte energía (0-100) a vida con un mínimo de 10%
    // Si energía = 0 -> vida = 10%
    // Si energía = 100 -> vida = 100%
    final int vidaPorcentaje = energia == 0 ? 10 : energia;

    return AspectRatio(
      aspectRatio: 21 / 5, // Proporción aproximada del contenedor
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none, // Permitir que elementos salgan del área
        children: [
          // 1. FONDO (El contenedor ancho de rejilla)
          Positioned(
            left: containerX,
            top: containerY,
            child: SizedBox(
              width: containerW,
              height: containerH,
              child: Image.asset(
                'assets/img/contenedor_barras.png',
                fit: BoxFit.fill, // Estirar imagen
              ),
            ),
          ),

          // 2. BARRAS DE PROGRESO (Izquierda y Derecha)
          // Usamos FractionallySizedBox para márgenes porcentuales seguros
          Positioned.fill(
            child: FractionallySizedBox(
              widthFactor: 1.0, // ~4% margen lateral
              heightFactor: 1.75, // ~12% margen vertical
              child: Row(
                children: [
                  // --- BARRA IZQUIERDA (ENERGÍA) ---
                  Expanded(
                    child: Padding(
                      // Ajustamos márgenes para que no toque los bordes del contenedor
                      padding: const EdgeInsets.only(
                        left: 12.0,
                        right: 4.0,
                        top: 8,
                        bottom: 8,
                      ),
                      child: HUDBar(
                        frameAsset: 'assets/img/barra_energia.png',
                        fillAsset: 'assets/img/barra_azul.png',
                        bgAsset: 'assets/img/barra_gris.png',
                        percentage: energia / 100.0,

                        // --- AJUSTES MANUALES BARRA IZQUIERDA ---

                        // MARCO (Frame)
                        frameX: 21.0,
                        frameY: 20.0,
                        frameWidth: 226, // null = automático
                        frameHeight: 100, // null = automático
                        // FONDO (Gris)
                        bgX: 47.0,
                        bgY: 64.0,
                        bgWidth: 175,
                        bgHeight: 17,

                        // RELLENO (Azul)
                        fillX: 47.0,
                        fillY: 64.0,
                        fillWidth: 175,
                        fillHeight: 16,
                      ),
                    ),
                  ),

                  // Espacio central reservado para el conector
                  const SizedBox(width: 40),

                  // --- BARRA DERECHA (RUIDO MENTAL) ---
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 4.0,
                        right: 12.0,
                        top: 8,
                        bottom: 8,
                      ),
                      child: HUDBar(
                        frameAsset: 'assets/img/barra_ruido.png',
                        fillAsset: 'assets/img/barra_morada.png',
                        bgAsset: 'assets/img/barra_gris.png',
                        percentage: ruido / 100.0,

                        // --- AJUSTES MANUALES BARRA DERECHA ---

                        // MARCO (Frame)
                        frameX: 15.0,
                        frameY: 20.0,
                        frameWidth: 226, // null = automático
                        frameHeight: 100, // null = automático
                        // FONDO (Gris)
                        bgX: 41.0,
                        bgY: 64.0,
                        bgWidth: 175,
                        bgHeight: 17,

                        // RELLENO (Morado)
                        fillX: 41.0,
                        fillY: 64.0,
                        fillWidth: 175,
                        fillHeight: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. CONECTOR CENTRAL (SALUD/INFO)
          Positioned(
            left: centralX,
            top: centralY,
            child: SizedBox(
              width: centralW,
              height: centralH,
              child: Image.asset(
                'assets/img/barra_central_vida.png',
                fit: BoxFit.fill, // Estirar imagen
              ),
            ),
          ),

          // 4. TEXTO DE ESTADO (Restaurado - Dinámico)
          Positioned(
            left: centralX,
            top: centralY,
            child: SizedBox(
              width: centralW,
              height: centralH,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "   $vidaPorcentaje%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sub-widget corregido para usar el Marco como ancla de tamaño
class HUDBar extends StatelessWidget {
  final String frameAsset;
  final String fillAsset;
  final String bgAsset;
  final double percentage;

  // Parámetros para ajuste manual de Posición y Tamaño

  // Marco (Frame)
  final double frameX;
  final double frameY;
  final double? frameWidth;
  final double? frameHeight;

  // Fondo
  final double bgX;
  final double bgY;
  final double? bgWidth;
  final double? bgHeight;

  // Relleno
  final double fillX;
  final double fillY;
  final double? fillWidth;
  final double? fillHeight;

  const HUDBar({
    super.key,
    required this.frameAsset,
    required this.fillAsset,
    required this.bgAsset,
    required this.percentage,

    // Valores por defecto
    this.frameX = 0.0,
    this.frameY = 0.0,
    this.frameWidth,
    this.frameHeight,

    this.bgX = 0.0,
    this.bgY = 0.0,
    this.bgWidth,
    this.bgHeight,

    this.fillX = 0.0,
    this.fillY = 0.0,
    this.fillWidth,
    this.fillHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Lógica de tamaño: Si es null o 0, usar valores por defecto
    final fW = (frameWidth != null && frameWidth! > 0) ? frameWidth! : 300.0;
    final fH = (frameHeight != null && frameHeight! > 0) ? frameHeight! : 100.0;

    // SOLUCIÓN: Usamos Stack con Clip.none para permitir que los marcos sobresalgan
    return Stack(
      alignment: Alignment.center,
      clipBehavior:
          Clip.none, // IMPORTANTE: Permite que los elementos salgan del área
      children: [
        // 1. EL MARCO (CAPA INFERIOR)
        Positioned(
          left: frameX,
          top: frameY,
          child: SizedBox(
            width: fW,
            height: fH,
            child: Image.asset(frameAsset, fit: BoxFit.fill),
          ),
        ),

        // 2. FONDO (Detrás del relleno)
        Positioned(
          left: bgX,
          top: bgY,
          child: SizedBox(
            width: bgWidth,
            height: bgHeight,
            child: Image.asset(bgAsset, fit: BoxFit.fill),
          ),
        ),

        // 3. RELLENO (Animado/Variable)
        Positioned(
          left: fillX,
          top: fillY,
          child: SizedBox(
            width: fillWidth,
            height: fillHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: percentage.clamp(0.0, 1.0),
                heightFactor: 1.0,
                child: Image.asset(fillAsset, fit: BoxFit.fill),
              ),
            ),
          ),
        ),

        // 4. MARCO (CAPA SUPERIOR) - Cubre bordes del relleno
        Positioned(
          left: frameX,
          top: frameY,
          child: SizedBox(
            width: fW,
            height: fH,
            child: Image.asset(frameAsset, fit: BoxFit.fill),
          ),
        ),
      ],
    );
  }
}
