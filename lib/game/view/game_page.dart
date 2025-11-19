import 'dart:async';
// import 'dart:math' as math; // OBSOLETO: Ya no se usa para raycasting en overlay

import 'package:audioplayers/audioplayers.dart';
import 'package:echo_world/game/audio/audio_manager.dart';
import 'package:echo_world/game/game.dart';
import 'package:echo_world/game/cubit/checkpoint/cubit.dart';
// Importaciones específicas de GameBloc y GameState ya expuestas vía game.dart -> removidas.
// import 'package:echo_world/game/cubit/game/game_bloc.dart'; // OBSOLETO
// import 'package:echo_world/game/cubit/game/game_state.dart'; // OBSOLETO
// import 'package:echo_world/game/black_echo_game.dart'; // OBSOLETO (exportado por game.dart)
import 'package:echo_world/gen/assets.gen.dart';
import 'package:echo_world/game/level/level_models.dart';
import 'package:echo_world/lore/lore.dart';
// import 'package:echo_world/l10n/l10n.dart';
// import 'package:echo_world/game/components/components.dart'; // OBSOLETO: exportado por game.dart
import 'package:echo_world/loading/cubit/cubit.dart';
import 'package:flame/game.dart' hide Route;
import 'package:flame_audio/bgm.dart';
// import 'package:flutter/scheduler.dart' show Ticker; // OBSOLETO: Ya no se usa Ticker en HUD FP
// import 'package:echo_world/game/level/level_manager.dart'; // OBSOLETO: Para tileSize y currentGrid (ahora en Flame)
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
    unawaited(bgm.play(Assets.audio.background));
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
        game.overlays.clear();
        // Reanudar el motor si está pausado y no estamos en pausa explícita.
        // OBSOLETO: scan ya no pausa el motor por defecto.
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
          // case Enfoque.scan: // OBSOLETO
          //   // game.pauseEngine();
          //   // game.overlays.add('HudScan');
          //   game.overlays.add('HudFirstPerson');
          default:
            break;
        }
        // OBSOLETO: Punto único para marcar overlays en desuso. Si se elimina definitivamente un modo,
        // comentar su builder en overlayBuilderMap y añadir nota aquí para limpieza futura.
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
                // 'HudScan': (ctx, game) => _HudScan(), // OBSOLETO
                'HudFirstPerson': (ctx, game) =>
                    _HudFirstPerson(game! as BlackEchoGame),
                'PauseMenu': (ctx, game) => _PauseMenu(),
                'OverlayFracaso': (ctx, game) => _OverlayFracaso(),
              },
            ),
          ),
          // Overlay de ruido mental (se muestra sobre el juego cuando ruidoMental > 25)
          BlocBuilder<GameBloc, GameState>(
            builder: (context, state) {
              if (state.ruidoMental <= 25) return const SizedBox.shrink();
              return Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RuidoMentalPainter(
                      intensity: state.ruidoMental / 100,
                    ),
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
}

class _HudButton extends StatelessWidget {
  const _HudButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ElevatedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

class _HudTopDown extends StatelessWidget {
  const _HudTopDown(this.game);
  final BlackEchoGame game;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    final size = MediaQuery.of(context).size;
    final topInset = MediaQuery.of(context).padding.top;
    final hudScale = (size.shortestSide / 360).clamp(0.8, 1.4);
    final barHeight = 20.0 * hudScale;
    final labelWidth = 80.0 * hudScale;
    final valueWidth = 40.0 * hudScale;
    final fontSize = (14.0 * hudScale).clamp(12.0, 20.0);
    return Column(
      children: [
        // Barras de estado en la parte superior con fondo oscuro para mejor visibilidad
        Container(
          padding: EdgeInsets.fromLTRB(12, 12 + topInset, 12, 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            border: Border.all(color: const Color(0xFF00FFFF), width: 2),
          ),
          child: BlocBuilder<GameBloc, GameState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Energía de Grito (cyan)
                  Row(
                    children: [
                      SizedBox(
                        width: labelWidth,
                        child: Text(
                          'ENERGÍA:',
                          style: TextStyle(
                            color: const Color(0xFF00FFFF),
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF00FFFF),
                                  width: 2,
                                ),
                                color: Colors.black,
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: state.energiaGrito / 100,
                              child: Container(
                                height: barHeight,
                                color: const Color(0xFF00FFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8 * hudScale),
                      SizedBox(
                        width: valueWidth,
                        child: Text(
                          '${state.energiaGrito}',
                          style: TextStyle(
                            color: const Color(0xFF00FFFF),
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * hudScale),
                  // Ruido Mental (violeta)
                  Row(
                    children: [
                      SizedBox(
                        width: labelWidth,
                        child: Text(
                          'RUIDO:',
                          style: TextStyle(
                            color: const Color(0xFF8A2BE2),
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF8A2BE2),
                                  width: 2,
                                ),
                                color: Colors.black,
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: state.ruidoMental / 100,
                              child: Container(
                                height: barHeight,
                                color: const Color(0xFF8A2BE2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8 * hudScale),
                      SizedBox(
                        width: valueWidth,
                        child: Text(
                          '${state.ruidoMental}',
                          style: TextStyle(
                            color: const Color(0xFF8A2BE2),
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        // Botón [ABSORBER] contextual (aparece cuando puedeAbsorber=true)
        BlocSelector<GameBloc, GameState, bool>(
          selector: (state) => state.puedeAbsorber,
          builder: (context, puedeAbsorber) {
            if (!puedeAbsorber) return const SizedBox.shrink();
            return Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
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
                    // Encontrar el núcleo más cercano antes de confirmar
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

                      // Crear efecto visual de absorción
                      game.world.add(
                        AbsorptionVfxComponent(
                          nucleusPosition: closest.position.clone(),
                          playerPosition: game.player.position.clone(),
                        ),
                      );

                      // Reproducir sonido de absorción
                      AudioManager.instance.playSfx(
                        'absorb_inhale',
                        volume: 0.8,
                      );

                      // Destruir el núcleo
                      closest.removeFromParent();
                    }

                    // Confirmar absorción en el BLoC
                    bloc.add(AbsorcionConfirmada());
                  },
                  child: const Text(
                    '[ABSORBER]',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        ),
        const Spacer(),
        // Botones de control en la parte inferior
        Align(
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HudButton(
                label: 'ENFOQUE',
                onPressed: () => bloc.add(EnfoqueCambiado()),
              ),
              _HudButton(
                label: 'ECO',
                onPressed: () {
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

                  // Penalización: Sobrecarga Sensorial (> 50 ruidoMental)
                  if (bloc.state.ruidoMental > 50) {
                    // Aumentar 0.5 de ruido por cada ECO
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
              _HudButton(
                label: 'RUPTURA',
                onPressed: () async {
                  if (bloc.state.energiaGrito >= 40) {
                    await game.player.rupture();
                    bloc.add(GritoActivado());
                  }
                },
              ),
              // Botón SIGILO: mantener presionado
              Padding(
                padding: const EdgeInsets.all(8),
                child: BlocSelector<GameBloc, GameState, bool>(
                  selector: (state) => state.estaAgachado,
                  builder: (context, estaAgachado) {
                    return GestureDetector(
                      onTapDown: (_) => bloc.add(ModoSigiloActivado()),
                      onTapUp: (_) => bloc.add(ModoSigiloDesactivado()),
                      onTapCancel: () => bloc.add(ModoSigiloDesactivado()),
                      child: ElevatedButton(
                        onPressed: () {}, // El GestureDetector maneja la lógica
                        style: ElevatedButton.styleFrom(
                          backgroundColor: estaAgachado
                              ? const Color(0xFF00FFFF)
                              : null,
                          foregroundColor: estaAgachado
                              ? const Color(0xFF000000)
                              : null,
                        ),
                        child: Text(
                          estaAgachado ? 'SIGILO ✓' : 'SIGILO',
                          style: TextStyle(
                            fontWeight: estaAgachado
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // DEV ONLY: avanzar al siguiente chunk para probar tutoriales
              _HudButton(
                label: 'CHUNK +',
                onPressed: () => game.levelManager.siguienteChunk(),
              ),
            ],
          ),
        ),
      ],
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
    return Column(
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
                    final game =
                        (context
                                .findAncestorWidgetOfExactType<GameWidget>()!
                                .game)!
                            as BlackEchoGame;
                    bloc.add(AbsorcionConfirmada());
                    // Destruir el núcleo más cercano
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

                      // VFX: Partículas que fluyen hacia el jugador
                      final absorptionVfx = AbsorptionVfxComponent(
                        nucleusPosition: closest.position.clone(),
                        playerPosition: game.player.position.clone(),
                      );
                      game.world.add(absorptionVfx);

                      // Audio feedback
                      AudioManager.instance.playSfx('absorb_inhale');

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
        const Spacer(),
        Align(
          alignment: Alignment.bottomCenter,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HudButton(
                label: 'ENFOQUE',
                onPressed: () => bloc.add(EnfoqueCambiado()),
              ),
              _HudButton(
                label: 'ECO',
                onPressed: () {
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
                  bloc.add(EcoActivado());

                  // Penalización: Sobrecarga Sensorial (> 50 ruidoMental)
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
              _HudButton(
                label: 'RUPTURA',
                onPressed: () async {
                  if (bloc.state.energiaGrito >= 40) {
                    await game.player.rupture();
                    bloc.add(GritoActivado());
                  }
                },
              ),
              _HudButton(
                label: 'SALTAR',
                onPressed: () {
                  game.player.jump();
                },
              ),
              // Botón SIGILO: mantener presionado
              Padding(
                padding: const EdgeInsets.all(8),
                child: BlocSelector<GameBloc, GameState, bool>(
                  selector: (state) => state.estaAgachado,
                  builder: (context, estaAgachado) {
                    return GestureDetector(
                      onTapDown: (_) => bloc.add(ModoSigiloActivado()),
                      onTapUp: (_) => bloc.add(ModoSigiloDesactivado()),
                      onTapCancel: () => bloc.add(ModoSigiloDesactivado()),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: estaAgachado
                              ? const Color(0xFF00FFFF)
                              : null,
                          foregroundColor: estaAgachado
                              ? const Color(0xFF000000)
                              : null,
                        ),
                        child: Text(
                          estaAgachado ? 'SIGILO ✓' : 'SIGILO',
                          style: TextStyle(
                            fontWeight: estaAgachado
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// HUD para modo First-Person.
/// La vista 3D (raycasting) es renderizada por Flame (RaycastRendererComponent),
/// este HUD muestra: retícula (renderizada en Flame), barras de estado y botones de acción.
class _HudFirstPerson extends StatelessWidget {
  const _HudFirstPerson(this.game);
  final BlackEchoGame game;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GameBloc>();
    final size = MediaQuery.of(context).size;
    // Factor de escala relativo al lado corto para mantener proporciones.
    final hudScale = (size.shortestSide / 360).clamp(0.7, 1.3);
    final barHeight = (18.0 * hudScale).clamp(14.0, 24.0);
    final spacingTop = (12.0 * hudScale).clamp(8.0, 20.0);
    final spacingSide = (12.0 * hudScale).clamp(8.0, 20.0);
    final fontSmall = (9.0 * hudScale).clamp(8.0, 12.0);
    final fontLabel = (11.0 * hudScale).clamp(10.0, 16.0);
    final absorberTop = (80.0 * hudScale).clamp(60.0, 120.0);
    final absorberFont = (18.0 * hudScale).clamp(14.0, 24.0);
    final bottomSpacing = (12.0 * hudScale).clamp(8.0, 20.0);
    return Stack(
      children: [
        // Barras de estado superiores
        Positioned(
          top: spacingTop + MediaQuery.of(context).padding.top,
          left: spacingSide,
          right: spacingSide,
          child: Row(
            children: [
              // Energía Grito
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ENERGÍA',
                      style: TextStyle(
                        color: const Color(0xFF00FFFF),
                        fontSize: fontLabel,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(color: Color(0xFF00FFFF), blurRadius: 5),
                        ],
                      ),
                    ),
                    SizedBox(height: 4 * hudScale),
                    BlocSelector<GameBloc, GameState, int>(
                      selector: (state) => state.energiaGrito,
                      builder: (context, energia) {
                        final progress = energia / 100.0;
                        return Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF00FFFF),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.black.withOpacity(0.5),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                energia >= 50
                                    ? const Color(
                                        0xFF00FFFF,
                                      ) // Cyan: con escudo
                                    : const Color(
                                        0xFFFF4444,
                                      ), // Rojo: vulnerable
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    BlocSelector<GameBloc, GameState, int>(
                      selector: (state) => state.energiaGrito,
                      builder: (context, energia) {
                        return Text(
                          '$energia / 100',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: fontSmall,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16 * hudScale),
              // Ruido Mental
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RUIDO MENTAL',
                      style: TextStyle(
                        color: const Color(0xFF8A2BE2),
                        fontSize: fontLabel,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(color: Color(0xFF8A2BE2), blurRadius: 5),
                        ],
                      ),
                    ),
                    SizedBox(height: 4 * hudScale),
                    BlocSelector<GameBloc, GameState, int>(
                      selector: (state) => state.ruidoMental,
                      builder: (context, ruido) {
                        final progress = ruido / 100.0;
                        return Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF8A2BE2),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.black.withOpacity(0.5),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF8A2BE2),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    BlocSelector<GameBloc, GameState, int>(
                      selector: (state) => state.ruidoMental,
                      builder: (context, ruido) {
                        return Text(
                          '$ruido / 100',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: fontSmall,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Botón [ABSORBER] contextual (centro-superior)
        BlocSelector<GameBloc, GameState, bool>(
          selector: (s) => s.puedeAbsorber,
          builder: (context, puedeAbsorber) {
            if (!puedeAbsorber) return const SizedBox.shrink();
            return Positioned(
              top: absorberTop,
              left: 0,
              right: 0,
              child: Center(
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
                      AudioManager.instance.playSfx('absorb_inhale');
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

        // Botones de acción (parte inferior)
        Positioned(
          bottom: bottomSpacing,
          left: 0,
          right: 0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final buttonSpacing = 8.0 * hudScale;
              final buttons = <Widget>[
                _HudButton(
                  label: 'ENFOQUE',
                  onPressed: () => bloc.add(EnfoqueCambiado()),
                ),
                _HudButton(
                  label: 'ECO',
                  onPressed: () {
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
                _HudButton(
                  label: 'RUPTURA',
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
                    return GestureDetector(
                      onTapDown: (_) => bloc.add(ModoSigiloActivado()),
                      onTapUp: (_) => bloc.add(ModoSigiloDesactivado()),
                      onTapCancel: () => bloc.add(ModoSigiloDesactivado()),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: estaAgachado
                              ? const Color(0xFF00FFFF)
                              : null,
                          foregroundColor: estaAgachado
                              ? const Color(0xFF000000)
                              : null,
                        ),
                        child: Text(
                          estaAgachado ? 'SIGILO ✓' : 'SIGILO',
                          style: TextStyle(
                            fontWeight: estaAgachado
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ];
              // Calcular ancho total aproximado (botón ~100 + padding); si excede wrap
              final estimatedPerButton = 100.0 * hudScale + buttonSpacing;
              final fitsSingleRow =
                  estimatedPerButton * buttons.length <= maxWidth;
              if (fitsSingleRow) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: buttons
                      .expand((b) => [b, SizedBox(width: buttonSpacing)])
                      .toList()
                      .sublist(0, buttons.length * 2 - 1),
                );
              } else {
                // Wrap en dos filas centradas
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: buttonSpacing,
                      runSpacing: buttonSpacing,
                      children: buttons,
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ],
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
    return Align(
      child: _HudButton(
        label: 'REANUDAR',
        onPressed: () => bloc.add(JuegoReanudado()),
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
                _HudButton(
                  label: 'REINTENTAR',
                  onPressed: () {
                    gameBloc.add(
                      ReinicioSolicitado(
                        conMisericordia: activarMisericordia,
                      ),
                    );
                  },
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
class _RuidoMentalPainter extends CustomPainter {
  _RuidoMentalPainter({required this.intensity});
  final double intensity; // 0.0 a 1.0
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
    final drawCount = (_maxRects * intensity).toInt();
    final staticPaint = Paint()
      ..color = Colors.white.withOpacity(intensity * 0.12);
    for (var i = 0; i < drawCount; i++) {
      canvas.drawRect(_cachedRects[i], staticPaint);
    }

    // 3. Glitch (traslación de bandas horizontales)
    if (intensity > 0.5) {
      canvas.save();
      final phase = DateTime.now().millisecondsSinceEpoch % 400;
      final glitchOffset = ((phase / 400.0) * 20 - 10) * (intensity - 0.5);
      canvas.translate(glitchOffset, 0);
      final glitchPaint = Paint()
        ..color = const Color(0xFF8A2BE2).withOpacity((intensity - 0.5) * 0.4)
        ..blendMode = BlendMode.screen;
      for (var i = 0; i < 5; i++) {
        final y = (size.height / 5) * i;
        canvas.drawRect(
          Rect.fromLTWH(0, y, size.width, size.height / 5),
          glitchPaint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RuidoMentalPainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}
