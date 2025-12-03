import 'dart:ui';

import 'package:echo_world/tutorial/bloc/tutorial_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class CalibrationOverlay extends StatefulWidget {
  const CalibrationOverlay({
    super.key,
    required this.keyJump,
    required this.keyEco,
    required this.keyAttack,
    required this.keyStealth,
    required this.keyEnfoque,
  });

  final GlobalKey keyJump;
  final GlobalKey keyEco;
  final GlobalKey keyAttack;
  final GlobalKey keyStealth;
  final GlobalKey keyEnfoque;

  @override
  State<CalibrationOverlay> createState() => _CalibrationOverlayState();
}

class _CalibrationOverlayState extends State<CalibrationOverlay> {
  Rect? _getRect(GlobalKey key) {
    try {
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) return null;
      if (!renderBox.hasSize) return null;

      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
    } catch (e) {
      print('⚠️ _getRect failed: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 Building CalibrationOverlay');
    return BlocConsumer<TutorialBloc, TutorialState>(
      listener: (context, state) {
        if (state.completed) {
          // Tutorial finished
        }
      },
      builder: (context, state) {
        if (state.completed) return const SizedBox.shrink();

        GlobalKey? targetKey;
        String title = '';
        String description = '';

        switch (state.step) {
          case TutorialStep.none:
          case TutorialStep.welcome:
            title = "INTERFAZ DE AYUDA";
            description = "TOCA LA PANTALLA PARA AVANZAR";
            break;
          case TutorialStep.calibrateEco:
            title = "ECO [SONAR]";
            description = "Usa el sonido para ver tu entorno.";
            targetKey = widget.keyEco;
            break;
          case TutorialStep.calibrateAttack:
            title = "RUPTURA [ATAQUE]";
            description = "Destruye obstáculos y enemigos cercanos.";
            targetKey = widget.keyAttack;
            break;
          case TutorialStep.calibrateStealth:
            title = "SIGILO [OCULTARSE]";
            description = "Reduce el ruido para evitar ser detectado.";
            targetKey = widget.keyStealth;
            break;
          case TutorialStep.calibrateEnfoque:
            title = "ENFOQUE [CÁMARA]";
            description = "Cambia la vista entre modos tácticos.";
            targetKey = widget.keyEnfoque;
            break;
          case TutorialStep.calibrateJump:
            title = "SALTO [ELEVACIÓN]";
            description = "Sube plataformas y esquiva peligros.";
            targetKey = widget.keyJump;
            break;
          case TutorialStep.complete:
            title = "TUTORIAL COMPLETADO";
            description = "INTERFAZ LISTA.\nBUENA SUERTE.";
            break;
        }

        // Calculate target rect if a key is provided
        Rect? targetRect;
        if (targetKey != null) {
          print('🔍 CalibrationOverlay: Calculating rect for key $targetKey');
          targetRect = _getRect(targetKey);
          // Add padding
          if (targetRect != null) {
            targetRect = targetRect.inflate(10.0);
          }
        }

        final size = MediaQuery.of(context).size;
        final hole = targetRect ?? Rect.zero;

        // If target exists but rect not found yet, wait (or dim all)
        if (targetKey != null && targetRect == null) {
          print(
            '⚠️ CalibrationOverlay: Target rect not found, scheduling rebuild',
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
          return const SizedBox.shrink();
        }

        // If no target (Welcome/Complete), dim everything and allow tap to advance
        if (targetKey == null) {
          return GestureDetector(
            onTap: () =>
                context.read<TutorialBloc>().add(TutorialStepCompleted()),
            child: Container(
              color: Colors.black.withAlpha((0.85 * 255).round()),
              width: double.infinity,
              height: double.infinity,
              child: CustomPaint(
                painter: _TextPainter(title: title, description: description),
              ),
            ),
          );
        }

        // If target exists but rect not found yet, wait (or dim all)
        if (targetRect == null) {
          return const SizedBox.shrink();
        }

        // 4-Rect Strategy for Spotlight
        return Stack(
          children: [
            // Top
            Positioned(
              top: 0,
              left: 0,
              width: size.width,
              height: hole.top,
              child: _DimmedArea(
                title: hole.top > 100 ? title : null,
                description: hole.top > 100 ? description : null,
              ),
            ),
            // Bottom
            Positioned(
              top: hole.bottom,
              left: 0,
              width: size.width,
              height: size.height - hole.bottom,
              child: _DimmedArea(
                title: hole.top <= 100 ? title : null,
                description: hole.top <= 100 ? description : null,
              ),
            ),
            // Left
            Positioned(
              top: hole.top,
              left: 0,
              width: hole.left,
              height: hole.height,
              child: const _DimmedArea(),
            ),
            // Right
            Positioned(
              top: hole.top,
              left: hole.right,
              width: size.width - hole.right,
              height: hole.height,
              child: const _DimmedArea(),
            ),
            // Visual Border around the hole (PointerEvents none to let clicks through)
            Positioned(
              top: hole.top,
              left: hole.left,
              width: hole.width,
              height: hole.height,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF00FFCC),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FFCC).withAlpha((0.5 * 255).round()),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DimmedArea extends StatelessWidget {
  final String? title;
  final String? description;

  const _DimmedArea({this.title, this.description});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Block input
      },
      child: Container(
      color: Colors.black.withAlpha((0.85 * 255).round()),
        child: title != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 24,
                        color: const Color(0xFF00FFCC),
                        fontWeight: FontWeight.bold,
                        shadows: [
                          const Shadow(
                            blurRadius: 10,
                            color: Color(0xFF00FFCC),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 16,
                        color: Colors.white.withAlpha((0.9 * 255).round()),
                      ),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

class _TextPainter extends CustomPainter {
  final String title;
  final String description;

  _TextPainter({required this.title, required this.description});

  @override
  void paint(Canvas canvas, Size size) {
    // Scanlines
    final scanlinePaint = Paint()
      ..color = Colors.white.withAlpha((0.05 * 255).round())
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }

    // Text
    final textStyleTitle = GoogleFonts.shareTechMono(
      fontSize: 24,
      color: const Color(0xFF00FFCC),
      fontWeight: FontWeight.bold,
      shadows: [const Shadow(blurRadius: 10, color: Color(0xFF00FFCC))],
    );

    final textStyleDesc = GoogleFonts.shareTechMono(
      fontSize: 16,
      color: Colors.white.withAlpha((0.9 * 255).round()),
    );

    final titleSpan = TextSpan(text: title, style: textStyleTitle);
    final descSpan = TextSpan(text: description, style: textStyleDesc);

    final titlePainter = TextPainter(
      text: titleSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    final descPainter = TextPainter(
      text: descSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    titlePainter.layout(maxWidth: size.width - 40);
    descPainter.layout(maxWidth: size.width - 40);

    final yPos = size.height / 2 - 30;
    final xPos = (size.width - titlePainter.width) / 2;

    titlePainter.paint(canvas, Offset(xPos, yPos));
    descPainter.paint(
      canvas,
      Offset((size.width - descPainter.width) / 2, yPos + 30),
    );
  }

  @override
  bool shouldRepaint(_TextPainter oldDelegate) =>
      oldDelegate.title != title || oldDelegate.description != description;
}
