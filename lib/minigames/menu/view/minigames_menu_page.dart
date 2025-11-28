import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../surgery/surgery_game.dart';
import '../../escape/view/escape_page.dart';
import '../../fuga/view/fuga_page.dart';

class MinigamesMenu extends StatelessWidget {
  const MinigamesMenu({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const MinigamesMenu(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PRUEBAS DE ACCESO',
              style: GoogleFonts.orbitron(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.cyan,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 60),
            _MenuButton(
              label: 'PRUEBA 1: CIRUGÍA',
              color: Colors.green,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SurgeryGame()),
                );
              },
            ),
            const SizedBox(height: 20),
            _MenuButton(
              label: 'PRUEBA 2: ESCAPE',
              color: Colors.orange,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const EscapeGame()),
                );
              },
            ),
            const SizedBox(height: 20),
            _MenuButton(
              label: 'PRUEBA 3: FUGA',
              color: Colors.red,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const FugaPage()),
                );
              },
            ),
            const SizedBox(height: 60),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'VOLVER AL SISTEMA',
                style: GoogleFonts.orbitron(
                  color: Colors.white54,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
