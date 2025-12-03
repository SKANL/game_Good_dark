import 'package:echo_world/game/audio/audio_manager.dart';
import 'package:flame/flame.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:echo_world/utils/unawaited.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CleaningLoadingPage extends StatefulWidget {
  const CleaningLoadingPage({
    super.key,
    required this.builder,
    this.minDuration = const Duration(seconds: 3),
  });

  final WidgetBuilder builder;
  final Duration minDuration;

  static Route<void> route({required WidgetBuilder builder}) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => CleaningLoadingPage(builder: builder),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  State<CleaningLoadingPage> createState() => _CleaningLoadingPageState();
}

class _CleaningLoadingPageState extends State<CleaningLoadingPage> {
  String _statusText = 'INICIANDO PROTOCOLO DE LIMPIEZA...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _executeCleaningProtocol();
  }

  Future<void> _executeCleaningProtocol() async {
    final startTime = DateTime.now();

    // FASE 1: LIMPIEZA (0% - 30%)
    if (mounted) setState(() => _statusText = 'PURGANDO MEMORIA...');
    await Future<void>.delayed(const Duration(milliseconds: 500));

    try {
      // 1. Detener y limpiar AudioManager (Nativo + Players)
      await AudioManager.instance.dispose();

      // 2. Limpiar caché de Flame Audio
      FlameAudio.audioCache.clearAll();

      // 3. Limpiar caché de imágenes de Flame
      Flame.images.clearCache();

      // 4. Forzar Garbage Collection (Sugerencia al VM)
      // Nota: En Dart no se puede forzar GC explícitamente, pero liberar referencias ayuda.
    } catch (e) {
      debugPrint('Error durante limpieza: $e');
    }

    if (mounted) setState(() => _progress = 0.3);

    // FASE 2: ESPERA TÉCNICA (30% - 50%)
    // Dar tiempo al sistema para liberar recursos reales
    if (mounted) setState(() => _statusText = 'ESTABILIZANDO SISTEMA...');
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _progress = 0.5);

    // FASE 3: RECARGA (50% - 90%)
    if (mounted) setState(() => _statusText = 'CARGANDO RECURSOS...');

    try {
      // Recargar sonidos esenciales
      await AudioManager.instance.preload();
    } catch (e) {
      debugPrint('Error durante recarga: $e');
    }

    if (mounted) setState(() => _progress = 0.9);

    // FASE 4: FINALIZACIÓN (90% - 100%)
    // Asegurar duración mínima para que no sea un parpadeo molesto
    final elapsed = DateTime.now().difference(startTime);
    final remaining = widget.minDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

      if (mounted) {
        setState(() {
          _progress = 1.0;
          _statusText = 'SISTEMA LISTO.';
        });

        // Navegar al destino
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          unawaited(
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: widget.builder),
            ),
          );
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo
          Image.asset(
            'assets/img/Pantalla_de_carga.png',
            fit: BoxFit.cover,
          ),

          // Overlay oscuro para mejorar legibilidad
          Container(
            color: Colors.black.withAlpha((0.3 * 255).round()),
          ),

          // Contenido
          Positioned(
            left: 40,
            right: 40,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Texto de estado estilo terminal
                Text(
                  _statusText,
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFF00FFEA), // Cyan Cyberpunk
                    fontSize: 18,
                    letterSpacing: 2.0,
                    shadows: [
                      const BoxShadow(
                        color: Color(0xFF00FFEA),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Barra de progreso
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FFEA),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF00FFEA),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Decoración extra
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'MEM_USAGE: OPTIMIZED',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white.withAlpha((0.5 * 255).round()),
                      fontSize: 12,
                    ),
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
