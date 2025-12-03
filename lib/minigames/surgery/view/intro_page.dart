// lib/view/intro_screen.dart
import 'package:echo_world/minigames/surgery/widgets/glowing_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:echo_world/utils/unawaited.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0a101a),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 40,
                ), // Replace Spacer with SizedBox for FittedBox
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'ECO NEGRO',
                    style: GoogleFonts.orbitron(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        const Shadow(
                          blurRadius: 10,
                          color: Color(0xFF00FFFF),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'CIRUGÍA CASANDRA',
                    style: GoogleFonts.robotoMono(
                      fontSize: 18,
                      color: Colors.grey[300],
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 40), // Replace Spacer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Text(
                      '//: La interfaz neuronal del sujeto es inestable. Debes cortar las sinapsis corruptas sin dañar los nodos vitales. El tiempo es crítico.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(
                        fontSize: 14,
                        color: Colors.grey[400],
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40), // Replace Spacer
                GlowingButton(
                  text: 'INICIAR PROCEDIMIENTO',
                  onPressed: () {
                    unawaited(Navigator.pushReplacementNamed(context, '/surgery'));
                  },
                ),
                const SizedBox(height: 40), // Replace Spacer
              ],
            ),
          ),
        ),
      ),
    );
  }
}
