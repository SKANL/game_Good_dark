import 'package:audioplayers/audioplayers.dart';
import 'package:echo_world/game/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:echo_world/game/ui/screens/journey_page.dart';
import 'package:echo_world/loading/view/cleaning_loading_page.dart';
import 'package:echo_world/minigames/menu/view/minigames_menu_page.dart';

import 'package:echo_world/multiplayer/ui/multiplayer_login_page.dart';

class TitlePage extends StatelessWidget {
  const TitlePage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const TitlePage());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: MenuPrincipal(),
    );
  }
}

class MenuPrincipal extends StatefulWidget {
  const MenuPrincipal({super.key});

  @override
  State<MenuPrincipal> createState() => _MenuPrincipalState();
}

class _MenuPrincipalState extends State<MenuPrincipal>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _animController;

  // Usaremos FlameAudio, así que no necesitamos instancias manuales de AudioPlayer aquí
  // para el BGM y SFX, FlameAudio gestiona sus propios pools.

  // Lista de animaciones para cada botón
  final List<Animation<Offset>> _buttonAnimations = [];
  bool _isLoaded = false;

  // --- SECUENCIA DE VIDEOS ---
  final List<String> _videoSequence = [
    'assets/video/fondo_menu.mp4',
    'assets/video/efect_static.mp4',
  ];
  int _currentVideoIndex = 0;

  // --- GESTIÓN DE SELECCIÓN ---
  int? _focusedIndex; // Índice del botón actualmente seleccionado/iluminado
  final List<GlobalKey> _buttonKeys = List.generate(5, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    debugPrint("--- MenuPrincipal initState (FlameAudio) ---");

    // 1. Configurar AudioContext (CRÍTICO para Video y Mezcla)
    try {
      final audioContext = AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none, // No pausar video
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers, // Mezclar con video
          },
        ),
      );
      AudioPlayer.global.setAudioContext(audioContext);
      debugPrint("AudioContext configured successfully");
    } catch (e) {
      debugPrint("Error configuring AudioContext: $e");
    }

    // 2. Precargar audios con FlameAudio
    _loadAudio();

    // 3. Configuración de la animación
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
      ),
    );

    for (int i = 0; i < 5; i++) {
      final double start = i * 0.1;
      final double end = start + 0.5;
      _buttonAnimations.add(
        Tween<Offset>(begin: const Offset(-1.5, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );
    }

    // 4. Carga del video de fondo (secuencia)
    _loadVideo(_currentVideoIndex);
  }

  // --- MÉTODO PARA CARGAR UN VIDEO DE LA SECUENCIA ---
  void _loadVideo(int index) {
    debugPrint("Loading video: ${_videoSequence[index]}");
    _controller =
        VideoPlayerController.asset(
            _videoSequence[index],
            videoPlayerOptions: VideoPlayerOptions(
              mixWithOthers: true,
            ),
          )
          ..initialize()
              .then((_) {
                debugPrint("Video initialized: ${_videoSequence[index]}");
                _controller.setVolume(0.0);
                _controller.play();

                // Listener para detectar cuando el video termina
                _controller.addListener(_videoListener);

                if (mounted) {
                  setState(() => _isLoaded = true);
                  if (index == 0) {
                    // Solo animar botones en el primer video
                    _animController.forward();
                  }
                }
              })
              .catchError((Object error) {
                debugPrint("Error initializing video: $error");
              });
  }

  // --- LISTENER PARA DETECTAR FIN DEL VIDEO ---
  void _videoListener() {
    if (_controller.value.position >=
        _controller.value.duration - const Duration(milliseconds: 100)) {
      // Video terminó, cargar el siguiente
      _playNextVideo();
    }
  }

  // --- MÉTODO PARA REPRODUCIR EL SIGUIENTE VIDEO ---
  void _playNextVideo() {
    // Remover listener del video actual
    _controller.removeListener(_videoListener);

    // Incrementar índice (loop infinito)
    _currentVideoIndex = (_currentVideoIndex + 1) % _videoSequence.length;

    // Disponer del controller actual
    _controller.dispose();

    // Cargar el siguiente video
    _loadVideo(_currentVideoIndex);
  }

  Future<void> _loadAudio() async {
    try {
      // Cargar en caché
      await FlameAudio.audioCache.loadAll([
        'soundtrack_main.ogg',
        'select_main.mp3',
      ]);

      if (mounted) {
        // Reproducir BGM usando el módulo BGM de FlameAudio
        // Este módulo maneja automáticamente el looping y la persistencia
        FlameAudio.bgm.play('soundtrack_main.ogg', volume: 1.0);
        debugPrint("FlameAudio BGM started");
      }
    } catch (e) {
      debugPrint("Error loading/playing audio with FlameAudio: $e");
    }
  }

  @override
  void dispose() {
    debugPrint("Disposing MenuPrincipal");
    _controller.removeListener(_videoListener);
    _controller.dispose();
    _animController.dispose();
    // Detener BGM al salir
    FlameAudio.bgm.stop();
    // Limpiar caché si es necesario, o dejarlo para el juego
    super.dispose();
  }

  // --- LÓGICA DE GESTOS ---
  void _handlePointer(Offset globalPosition) {
    int? foundIndex;
    for (int i = 0; i < _buttonKeys.length; i++) {
      final key = _buttonKeys[i];
      final RenderBox? box =
          key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final Offset localPosition = box.globalToLocal(globalPosition);
        if (box.size.contains(localPosition)) {
          foundIndex = i;
          break;
        }
      }
    }

    if (_focusedIndex != foundIndex) {
      if (foundIndex != null) {
        // Reproducir SFX con FlameAudio
        // FlameAudio.play crea un nuevo player temporal optimizado para SFX
        FlameAudio.play('select_main.mp3', volume: 0.8);
      }

      setState(() {
        _focusedIndex = foundIndex;
      });
    }
  }

  void _handleTapUp() {
    if (_focusedIndex != null) {
      FlameAudio.play('select_main.mp3', volume: 1.0);

      switch (_focusedIndex) {
        case 0:
          debugPrint("Navigating to GamePage");
          FlameAudio.bgm.stop();
          Navigator.of(context).pushReplacement(
            CleaningLoadingPage.route(builder: (_) => const GamePage()),
          );
          break;
        case 1:
          debugPrint("Accediendo a Protocolos Multijugador...");
          Navigator.of(context).push(MultiplayerLoginPage.route());
          break;
        case 2:
          print("Accediendo a Pruebas...");
          Navigator.of(context).push(MinigamesMenu.route());
          break;
        case 3:
          print("Calibrando Sistema...");
          break;
        case 4:
          debugPrint("Cortando Señal (Saliendo)...");
          FlameAudio.bgm.stop();
          SystemNavigator.pop(); // Cierra la app
          break;
      }
    }
    setState(() => _focusedIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_isLoaded)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: Transform.scale(
                scaleX: -1,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
          )
        else
          const Center(child: CircularProgressIndicator(color: Colors.cyan)),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.2, 1.0],
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.transparent,
              ],
            ),
          ),
        ),

        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 60.0),
              child: Listener(
                onPointerDown: (event) => _handlePointer(event.position),
                onPointerMove: (event) => _handlePointer(event.position),
                onPointerUp: (_) => _handleTapUp(),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "BLACK ECHO",
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 5.0,
                        fontFamily: 'Courier',
                        shadows: [
                          BoxShadow(color: Colors.cyan, blurRadius: 20),
                        ],
                      ),
                    ),
                    const Text(
                      "PROYECTO CASANDRA // SUJETO 7",
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        letterSpacing: 2.0,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),

                    SlideTransition(
                      position: _buttonAnimations[0],
                      child: BotonSprite(
                        key: _buttonKeys[0],
                        isActive: _focusedIndex == 0,
                        alignmentY: -0.57,
                        ancho: 240,
                        alto: 45,
                        altoBase: 60,
                      ),
                    ),
                    const SizedBox(height: 0),

                    SlideTransition(
                      position: _buttonAnimations[1],
                      child: BotonSprite(
                        key: _buttonKeys[1],
                        isActive: _focusedIndex == 1,
                        alignmentY: -0.32,
                        ancho: 240,
                        alto: 45,
                        altoBase: 60,
                      ),
                    ),
                    const SizedBox(height: 0),

                    SlideTransition(
                      position: _buttonAnimations[2],
                      child: BotonSprite(
                        key: _buttonKeys[2],
                        isActive: _focusedIndex == 2,
                        alignmentY: 0.19,
                        ancho: 240,
                        alto: 45,
                        altoBase: 60,
                      ),
                    ),
                    const SizedBox(height: 0),

                    SlideTransition(
                      position: _buttonAnimations[3],
                      child: BotonSprite(
                        key: _buttonKeys[3],
                        isActive: _focusedIndex == 3,
                        alignmentY: 0.45,
                        ancho: 240,
                        alto: 45,
                        altoBase: 60,
                      ),
                    ),
                    const SizedBox(height: 0),

                    //Boton salir
                    SlideTransition(
                      position: _buttonAnimations[4],
                      child: BotonSprite(
                        key: _buttonKeys[4],
                        isActive: _focusedIndex == 4,
                        alignmentY: 0.7,
                        ancho: 240,
                        alto: 45,
                        altoBase: 60,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // NUEVO BOTÓN JOURNEY (Esquina inferior derecha)
        const Positioned(
          bottom: -30,
          right: 10,
          child: JourneyButton(),
        ),
      ],
    );
  }
}

class BotonSprite extends StatelessWidget {
  final double alignmentY;
  final double ancho;
  final double alto;
  final double altoBase;
  final bool isActive;

  const BotonSprite({
    super.key,
    required this.alignmentY,
    this.ancho = 240,
    this.alto = 60,
    this.altoBase = 60,
    required this.isActive,
  });

  static const int factorEscalaAlto = 6;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      height: alto,
      child: ClipRect(
        child: OverflowBox(
          maxWidth: ancho * 2,
          maxHeight: altoBase * factorEscalaAlto,
          minWidth: ancho * 2,
          minHeight: altoBase * factorEscalaAlto,

          alignment: Alignment(
            isActive ? 1.0 : -1.0,
            alignmentY,
          ),

          child: Image.asset('assets/img/botones_sprite.png', fit: BoxFit.fill),
        ),
      ),
    );
  }
}

class JourneyButton extends StatefulWidget {
  const JourneyButton({super.key});

  @override
  State<JourneyButton> createState() => _JourneyButtonState();
}

class _JourneyButtonState extends State<JourneyButton> {
  bool _isPressed = false;

  void _onTapDown(PointerDownEvent event) {
    setState(() => _isPressed = true);
    FlameAudio.play('select_main.mp3', volume: 1.0);
  }

  void _onTapUp(PointerUpEvent event) {
    setState(() => _isPressed = false);
    // Navegar a JourneyPage
    Navigator.of(context).push(JourneyPage.route());
  }

  void _onTapCancel(PointerCancelEvent event) {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    // Dimensiones del botón (ajustar según necesidad)
    const double width = 125;
    const double height = 125;

    return Listener(
      onPointerDown: _onTapDown,
      onPointerUp: _onTapUp,
      onPointerCancel: _onTapCancel,
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRect(
          child: OverflowBox(
            maxWidth:
                width * 2, // El sprite sheet tiene 2 estados horizontalmente
            maxHeight: height,
            minWidth: width * 2,
            minHeight: height,
            alignment: _isPressed
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Image.asset(
              'assets/img/botton_jurnie.png',
              fit: BoxFit.fill,
              width: width * 2,
              height: height,
            ),
          ),
        ),
      ),
    );
  }
}
