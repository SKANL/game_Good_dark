// lib/view/end_page.dart
import 'dart:async';

import 'package:echo_world/minigames/surgery/widgets/glowing_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EndPage extends StatefulWidget {
  const EndPage({super.key});

  @override
  State<EndPage> createState() => _EndPageState();
}

class _EndPageState extends State<EndPage> {
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    // After a delay, show the restart button
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showButton = true;
        });
      }
    });
  }

  void _restartGame() {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)!.settings.arguments! as Map<String, dynamic>;
    final success = (arguments['success'] as bool?) ?? false;
    final message =
        (arguments['message'] as String?) ?? 'An unknown error occurred.';

    final title = success ? 'ÉXITO DE LA MISIÓN' : 'FALLO CATASTRÓFICO';
    final titleColor = success ? const Color(0xFF00FFFF) : Colors.red;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0a101a),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.orbitron(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 15,
                      color: titleColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '//: $message',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.robotoMono(
                    fontSize: 16,
                    color: Colors.grey[300],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              AnimatedOpacity(
                opacity: _showButton ? 1.0 : 0.0,
                duration: const Duration(seconds: 1),
                child: GlowingButton(
                  text: 'REINICIAR',
                  onPressed: _restartGame,
                  color: titleColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
